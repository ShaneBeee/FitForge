import Foundation

/// The three rotating workouts.
enum WorkoutDay: String, CaseIterable, Identifiable, Codable {
    case a = "A", b = "B", c = "C"

    var id: String { rawValue }
    var title: String { "Day \(rawValue)" }

    /// The movement slots that make up this day, in order.
    var slots: [MovementPattern] {
        switch self {
        case .a: [.squat, .push, .hinge, .core]
        case .b: [.lunge, .pull, .push, .core]
        case .c: [.hinge, .pull, .lunge, .carry]
        }
    }

    var focus: String {
        slots.map(\.title).joined(separator: " · ")
    }
}

/// One exercise in a built workout, with its sets and target.
struct PlannedExercise: Identifiable, Hashable {
    let exercise: Exercise
    let sets: Int
    /// Rep target for rep-based exercises.
    let reps: ClosedRange<Int>?
    /// Hold/carry time for timed exercises.
    let seconds: Int?
    let restSeconds: Int

    var id: String { exercise.id }

    /// e.g. "3 × 8–12" or "3 × 30 sec", with "per side" for one-sided exercises.
    var prescription: String {
        let perSide = exercise.isUnilateral ? " per side" : ""
        if let seconds {
            return "\(sets) × \(seconds) sec\(perSide)"
        }
        if let reps {
            let range = reps.lowerBound == reps.upperBound ? "\(reps.lowerBound)" : "\(reps.lowerBound)–\(reps.upperBound)"
            return "\(sets) × \(range)\(perSide)"
        }
        return "\(sets) sets"
    }
}

struct PlannedWorkout: Identifiable {
    let day: WorkoutDay
    let exercises: [PlannedExercise]

    var id: String { day.id }

    /// Rough length: sets × (work + rest), in minutes.
    var estimatedMinutes: Int {
        let seconds = exercises.reduce(0) { total, item in
            let work = item.seconds ?? 40
            let sides = item.exercise.isUnilateral ? 2 : 1
            return total + item.sets * (work * sides + item.restSeconds)
        }
        return max(5, Int((Double(seconds) / 60).rounded()))
    }
}

/// Builds Day A/B/C from the user's profile: equipment, ability, joints and goal.
enum WorkoutBuilder {

    /// Builds all three days at once so exercises aren't repeated across the week.
    static func buildWeek(for profile: UserProfile) -> [PlannedWorkout] {
        var used: Set<String> = []
        return WorkoutDay.allCases.map { day in
            let exercises = day.slots.compactMap { pattern -> PlannedExercise? in
                guard let exercise = pick(pattern, for: profile, avoiding: used)
                        ?? (pattern == .carry ? pick(.core, for: profile, avoiding: used) : nil)
                else { return nil }
                used.insert(exercise.id)
                return prescribe(exercise, for: profile)
            }
            return PlannedWorkout(day: day, exercises: exercises)
        }
    }

    static func build(_ day: WorkoutDay, for profile: UserProfile) -> PlannedWorkout {
        buildWeek(for: profile).first { $0.day == day } ?? PlannedWorkout(day: day, exercises: [])
    }

    // MARK: - Level

    /// The starting difficulty for a movement pattern, from the ability answers and experience.
    static func level(for pattern: MovementPattern, profile: UserProfile) -> Difficulty {
        let tier: Int = switch pattern {
        case .push, .pull: profile.pushUpTier
        case .core, .carry: profile.plankTier
        case .squat, .lunge, .hinge: profile.squatTier
        }

        var result: Difficulty = switch tier {
        case 3: .advanced
        case 2: .intermediate
        default: .beginner
        }

        switch profile.experience {
        case .new:
            result = min(result, .intermediate)
        case .experienced where tier >= 1:
            result = max(result, .intermediate)
        default:
            break
        }
        return result
    }

    // MARK: - Picking

    /// Chooses the best exercise for a slot: the hardest one at or below the user's level
    /// that fits their equipment and joints, preferring ones not already used this week.
    static func pick(_ pattern: MovementPattern, for profile: UserProfile, avoiding used: Set<String>) -> Exercise? {
        let userLevel = level(for: pattern, profile: profile)
        let candidates = ExerciseLibrary.all.filter { $0.pattern == pattern && isAvailable($0, for: profile) }
        guard !candidates.isEmpty else { return nil }

        let fresh = candidates.filter { !used.contains($0.id) }
        let pool = fresh.isEmpty ? candidates : fresh

        let atOrBelow = pool.filter { $0.difficulty <= userLevel }
        if let best = atOrBelow.map(\.difficulty).max() {
            // Among the hardest suitable options, library order decides.
            return atOrBelow.first { $0.difficulty == best }
        }
        // Nothing easy enough — use the easiest available.
        return pool.min { $0.difficulty < $1.difficulty }
    }

    /// Whether the user has the equipment (at a suitable weight) and no joint conflicts.
    static func isAvailable(_ exercise: Exercise, for profile: UserProfile) -> Bool {
        let items = profile.equipment ?? []
        let owned = Set(items.map(\.kind))
        guard exercise.equipment.isSubset(of: owned) else { return false }
        guard exercise.cautions.isDisjoint(with: profile.jointCautions) else { return false }

        if let range = exercise.weightRange {
            let weightedKinds = exercise.equipment.filter(\.hasWeight)
            for kind in weightedKinds {
                let weights = items.filter { $0.kind == kind }.map(\.weightLbs)
                // Unknown weight counts as a fit; otherwise at least one must be in range.
                let fits = weights.contains { weight in
                    guard let weight else { return true }
                    return range.contains(weight)
                }
                if !fits { return false }
            }
        }
        return true
    }

    // MARK: - Sets and reps

    static func prescribe(_ exercise: Exercise, for profile: UserProfile) -> PlannedExercise {
        let goal = profile.goalType
        let sets = 3

        switch exercise.measure {
        case .time:
            let userLevel = level(for: exercise.pattern, profile: profile)
            let seconds: Int
            if exercise.pattern == .carry {
                seconds = 40
            } else {
                seconds = switch userLevel {
                case .beginner: 20
                case .intermediate: 30
                case .advanced: 45
                }
            }
            return PlannedExercise(exercise: exercise, sets: sets, reps: nil, seconds: seconds, restSeconds: profile.restSeconds)

        case .reps:
            let reps: ClosedRange<Int> = switch goal {
            case .loseFat: 12...15
            case .both, .buildMuscle: 8...12
            }
            return PlannedExercise(exercise: exercise, sets: sets, reps: reps, seconds: nil, restSeconds: profile.restSeconds)
        }
    }
}

/// Maps the calendar onto the A → B → C rotation.
enum WorkoutSchedule {

    /// The profile's workout days in week order (e.g. Sun, Wed, Fri).
    static func orderedWorkoutDays(for profile: UserProfile) -> [Int] {
        Weekday.ordered.filter { profile.workoutWeekdays.contains($0) }
    }

    /// Which workout falls on this date, or nil for a rest day.
    static func workoutDay(on date: Date, for profile: UserProfile) -> WorkoutDay? {
        let weekday = Calendar.current.component(.weekday, from: date)
        guard let index = orderedWorkoutDays(for: profile).firstIndex(of: weekday),
              index < WorkoutDay.allCases.count
        else { return nil }
        return WorkoutDay.allCases[index]
    }

    /// The next scheduled workout strictly after the given date.
    static func nextWorkout(after date: Date, for profile: UserProfile) -> (date: Date, day: WorkoutDay)? {
        let calendar = Calendar.current
        for offset in 1...7 {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: date),
                  let day = workoutDay(on: candidate, for: profile)
            else { continue }
            return (candidate, day)
        }
        return nil
    }
}
