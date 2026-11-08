import Foundation

/// What a workout day focuses on.
enum DayKind {
    case fullBody, upper, lower, push, pull, legs

    var description: String {
        switch self {
        case .fullBody: "A full-body day: upper body, core and lower body every session."
        case .upper: "An upper-body day: chest, back, shoulders and arms."
        case .lower: "A lower-body day: legs, glutes and core."
        case .push: "A push day: chest, shoulders and triceps."
        case .pull: "A pull day: back, biceps and grip."
        case .legs: "A leg day: quads, glutes, hamstrings and calves."
        }
    }

    /// Whether a movement fits this kind of day (so an arm focus doesn't add curls to leg day).
    func allows(_ pattern: MovementPattern) -> Bool {
        switch self {
        case .fullBody: true
        case .upper: [.push, .pull, .shoulders, .biceps, .triceps, .core].contains(pattern)
        case .lower: [.squat, .lunge, .hinge, .calves, .core, .carry].contains(pattern)
        case .push: [.push, .shoulders, .triceps, .core].contains(pattern)
        case .pull: [.pull, .biceps, .core, .carry].contains(pattern)
        case .legs: [.squat, .lunge, .hinge, .calves, .core].contains(pattern)
        }
    }
}

/// One workout in the weekly rotation (e.g. "Day A", "Upper B", "Push A").
struct WorkoutDay: Identifiable, Hashable {
    /// Stable ID saved with each workout. The 3-day plan keeps "A", "B" and "C".
    let id: String
    let title: String
    /// Short label for round badges, e.g. "A" or "UA".
    let badge: String
    let kind: DayKind
    /// Movement slots in priority order. Shorter workouts use the first few.
    let slots: [MovementPattern]

    static func == (lhs: WorkoutDay, rhs: WorkoutDay) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Body areas of the day's main movements, e.g. "Legs · Chest · Glutes · Core".
    var focus: String {
        var areas: [String] = []
        for pattern in slots.prefix(4) where !areas.contains(pattern.areaTitle) {
            areas.append(pattern.areaTitle)
        }
        return areas.joined(separator: " · ")
    }
}

/// The workout rotations for each number of days per week.
enum WorkoutPlans {

    // 3 days: full body A/B/C (IDs kept as "A", "B", "C" so older workouts still match)
    static let fullBody3: [WorkoutDay] = [
        WorkoutDay(id: "A", title: "Day A", badge: "A", kind: .fullBody,
                   slots: [.squat, .push, .hinge, .core, .pull, .shoulders, .triceps, .calves]),
        WorkoutDay(id: "B", title: "Day B", badge: "B", kind: .fullBody,
                   slots: [.lunge, .pull, .push, .core, .hinge, .biceps, .shoulders, .calves]),
        WorkoutDay(id: "C", title: "Day C", badge: "C", kind: .fullBody,
                   slots: [.hinge, .pull, .lunge, .carry, .push, .core, .triceps, .biceps]),
    ]

    // 2 days: full body A/B, each covering everything
    static let fullBody2: [WorkoutDay] = [
        WorkoutDay(id: "2A", title: "Day A", badge: "A", kind: .fullBody,
                   slots: [.squat, .push, .pull, .core, .hinge, .shoulders, .biceps, .calves]),
        WorkoutDay(id: "2B", title: "Day B", badge: "B", kind: .fullBody,
                   slots: [.hinge, .pull, .push, .lunge, .core, .triceps, .shoulders, .carry]),
    ]

    // 4 days: upper / lower, twice each
    static let upperA = WorkoutDay(id: "UA", title: "Upper A", badge: "UA", kind: .upper,
                                   slots: [.push, .pull, .push, .pull, .shoulders, .triceps, .biceps, .core])
    static let lowerA = WorkoutDay(id: "LA", title: "Lower A", badge: "LA", kind: .lower,
                                   slots: [.squat, .hinge, .lunge, .core, .calves, .carry, .core, .hinge])
    static let upperB = WorkoutDay(id: "UB", title: "Upper B", badge: "UB", kind: .upper,
                                   slots: [.pull, .push, .pull, .push, .shoulders, .biceps, .triceps, .core])
    static let lowerB = WorkoutDay(id: "LB", title: "Lower B", badge: "LB", kind: .lower,
                                   slots: [.hinge, .lunge, .squat, .core, .calves, .core, .carry, .lunge])

    static let upperLower: [WorkoutDay] = [upperA, lowerA, upperB, lowerB]

    // 5 days: upper / lower twice, plus a full-body day
    static let fullBodyExtra = WorkoutDay(id: "FB", title: "Full body", badge: "FB", kind: .fullBody,
                                          slots: [.squat, .pull, .push, .hinge, .core, .carry, .shoulders, .calves])

    // 6 days: push / pull / legs, twice each
    static let pushPullLegs: [WorkoutDay] = [
        WorkoutDay(id: "PsA", title: "Push A", badge: "Ps", kind: .push,
                   slots: [.push, .push, .shoulders, .triceps, .push, .shoulders, .triceps, .core]),
        WorkoutDay(id: "PlA", title: "Pull A", badge: "Pl", kind: .pull,
                   slots: [.pull, .pull, .biceps, .pull, .carry, .biceps, .core, .pull]),
        WorkoutDay(id: "LgA", title: "Legs A", badge: "Lg", kind: .legs,
                   slots: [.squat, .hinge, .lunge, .calves, .core, .lunge, .hinge, .calves]),
        WorkoutDay(id: "PsB", title: "Push B", badge: "Ps", kind: .push,
                   slots: [.push, .shoulders, .push, .triceps, .shoulders, .push, .core, .triceps]),
        WorkoutDay(id: "PlB", title: "Pull B", badge: "Pl", kind: .pull,
                   slots: [.pull, .biceps, .pull, .pull, .core, .biceps, .carry, .pull]),
        WorkoutDay(id: "LgB", title: "Legs B", badge: "Lg", kind: .legs,
                   slots: [.hinge, .lunge, .squat, .calves, .core, .squat, .lunge, .calves]),
    ]

    static let allDays: [WorkoutDay] = fullBody3 + fullBody2 + upperLower + [fullBodyExtra] + pushPullLegs

    static let daysPerWeekOptions = 2...6
    static let lengthOptions = [20, 30, 45, 60]

    /// The rotation for a number of workout days per week.
    static func days(forDaysPerWeek count: Int) -> [WorkoutDay] {
        switch count {
        case ...2: fullBody2
        case 3: fullBody3
        case 4: upperLower
        case 5: upperLower + [fullBodyExtra]
        default: pushPullLegs
        }
    }

    static func days(for profile: UserProfile) -> [WorkoutDay] {
        days(forDaysPerWeek: profile.workoutWeekdays.count)
    }

    /// Looks up a day from a saved workout's ID.
    static func day(id: String) -> WorkoutDay {
        allDays.first { $0.id == id }
            ?? WorkoutDay(id: id, title: "Day \(id)", badge: id, kind: .fullBody, slots: [])
    }

    /// A plain-English description of the plan style.
    static func planDescription(forDaysPerWeek count: Int) -> String {
        switch count {
        case ...2: "Full body, alternating Day A and Day B."
        case 3: "Full body, rotating Day A → B → C."
        case 4: "Upper / lower split: Upper A, Lower A, Upper B, Lower B."
        case 5: "Upper / lower twice each, plus a full-body day."
        default: "Push / Pull / Legs, twice each."
        }
    }

    /// A sensible default spread of weekdays (1 = Sunday … 7 = Saturday).
    static func suggestedWeekdays(forDaysPerWeek count: Int) -> Set<Int> {
        switch count {
        case ...2: [2, 5]             // Mon, Thu
        case 3: [2, 4, 6]             // Mon, Wed, Fri
        case 4: [2, 3, 5, 6]          // Mon, Tue, Thu, Fri
        case 5: [2, 3, 4, 5, 6]       // Mon–Fri
        default: [2, 3, 4, 5, 6, 7]   // Mon–Sat
        }
    }
}

/// One exercise in a built workout, with its sets and target.
struct PlannedExercise: Identifiable, Hashable {
    let exercise: Exercise
    let sets: Int
    /// Rep target for rep-based exercises.
    var reps: ClosedRange<Int>?
    /// Hold/carry time for timed exercises.
    let seconds: Int?
    let restSeconds: Int
    /// True when this exercise is here because of one of the user's focus areas.
    var isFocus = false
    /// Suggested weight in lb (per dumbbell, or the kettlebell) for weighted exercises.
    var weightLbs: Double? = nil
    /// True when the suggested weight is a step up from last time.
    var isWeightIncrease = false
    /// Outgrown the heaviest weight owned: lower slowly (3 seconds) with more reps instead.
    var isSlowTempo = false

    var id: String { exercise.id }

    /// e.g. "15 lb"
    var weightText: String? {
        weightLbs.map { "\(EquipmentItem.format($0)) lb" }
    }

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

    /// Every muscle group this workout hits, head to toe.
    var targetedMuscles: [MuscleGroup] {
        let worked = Set(exercises.flatMap(\.exercise.muscles))
        return MuscleGroup.allCases.filter { worked.contains($0) }
    }

    /// Body areas this workout actually covers, e.g. "Chest · Back · Shoulders · Arms".
    var focus: String {
        var areas: [String] = []
        for item in exercises where !areas.contains(item.exercise.pattern.areaTitle) {
            areas.append(item.exercise.pattern.areaTitle)
        }
        return areas.joined(separator: " · ")
    }

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

/// Builds the week's workouts from the profile: days per week, workout length,
/// equipment, ability, joints and goal.
enum WorkoutBuilder {

    /// How many movement slots fit in a workout of this length.
    static func slotCount(forMinutes minutes: Int) -> Int {
        switch minutes {
        case ..<25: 4
        case ..<40: 5
        case ..<55: 7
        default: 8
        }
    }

    /// Builds every day at once, so exercises vary across the week and never repeat within a day.
    ///
    /// `history` (past workouts) lets it suggest the weight used last time, or a step up.
    static func buildWeek(for profile: UserProfile, history: [WorkoutSession] = []) -> [PlannedWorkout] {
        var weekUsed: Set<String> = []
        let recentUses = WeightProgression.recentUses(in: history)

        return WorkoutPlans.days(for: profile).enumerated().map { dayIndex, day in
            var dayUsed: Set<String> = []
            let plan = slots(for: day, dayIndex: dayIndex, profile: profile)

            var exercises: [PlannedExercise] = []
            for (index, pattern) in plan.slots.enumerated() {
                let exercise = pick(pattern, for: profile, avoiding: weekUsed, excluding: dayUsed)
                    ?? fallback(for: pattern).flatMap { pick($0, for: profile, avoiding: weekUsed, excluding: dayUsed) }
                guard let exercise else { continue }
                dayUsed.insert(exercise.id)
                weekUsed.insert(exercise.id)
                var planned = prescribe(
                    exercise,
                    for: profile,
                    isMainLift: index < 2,
                    isFocus: plan.focus.contains(exercise.pattern)
                )
                if let suggestion = WeightProgression.suggestion(for: exercise, profile: profile, uses: recentUses[exercise.id]) {
                    planned.weightLbs = suggestion.weight
                    planned.isWeightIncrease = suggestion.isIncrease
                    if suggestion.isOutgrown, planned.reps != nil {
                        // No heavier weight to move to: make it harder with slower, longer sets.
                        planned.isSlowTempo = true
                        planned.reps = 10...15
                    }
                }
                exercises.append(planned)
            }
            return PlannedWorkout(day: day, exercises: exercises)
        }
    }

    /// The movement slots for one day, with the user's focus areas moved up (or added),
    /// trimmed to fit the workout length. The day's first two main lifts always stay,
    /// so the plan keeps its balance.
    static func slots(for day: WorkoutDay, dayIndex: Int, profile: UserProfile) -> (slots: [MovementPattern], focus: Set<MovementPattern>) {
        let minutes = profile.workoutMinutes
        let focusAreas = todaysFocusAreas(profile.focusAreas, dayIndex: dayIndex, minutes: minutes)

        // Focus patterns for this day. Areas with two patterns (arms: biceps + triceps)
        // alternate day to day in shorter workouts, and both appear in longer ones.
        var focusPatterns: [MovementPattern] = []
        for area in focusAreas {
            let allowed = area.patterns.filter { day.kind.allows($0) }
            guard !allowed.isEmpty else { continue }
            let chosen = minutes >= 45 ? allowed : [allowed[dayIndex % allowed.count]]
            for pattern in chosen where !focusPatterns.contains(pattern) {
                focusPatterns.append(pattern)
            }
        }

        let fixed = Array(day.slots.prefix(2))
        var rest = Array(day.slots.dropFirst(2))
        var prioritized: [MovementPattern] = []
        for pattern in focusPatterns {
            if let index = rest.firstIndex(of: pattern) {
                prioritized.append(rest.remove(at: index))
            } else if !fixed.contains(pattern) {
                prioritized.append(pattern)
            } else if minutes >= 30 {
                // Already a main lift today — add a second exercise for it in longer workouts.
                prioritized.append(pattern)
            }
        }

        var slots = Array((fixed + prioritized + rest).prefix(slotCount(forMinutes: minutes)))

        let wantsFinisher = (minutes >= 45 && profile.goalType != .buildMuscle)
            || (minutes >= 30 && focusAreas.contains(.bellyFat))
        if wantsFinisher { slots.append(.conditioning) }

        return (slots, Set(focusPatterns))
    }

    /// The focus areas for one day. When there are more than the workout length has room for
    /// (e.g. 5 picked, then workouts shortened to 30 min), they take turns across the days.
    private static func todaysFocusAreas(_ areas: [FocusArea], dayIndex: Int, minutes: Int) -> [FocusArea] {
        let allowed = FocusArea.maxSelections(forMinutes: minutes)
        guard areas.count > allowed else { return areas }
        let start = (dayIndex * allowed) % areas.count
        return (0..<allowed).map { areas[(start + $0) % areas.count] }
    }

    static func build(_ day: WorkoutDay, for profile: UserProfile, history: [WorkoutSession] = []) -> PlannedWorkout {
        buildWeek(for: profile, history: history).first { $0.day == day } ?? PlannedWorkout(day: day, exercises: [])
    }

    /// What to use when nothing fits a slot (e.g. no carry without dumbbells).
    private static func fallback(for pattern: MovementPattern) -> MovementPattern? {
        switch pattern {
        case .carry, .conditioning: .core
        case .shoulders, .triceps: .push
        case .biceps: .pull
        case .calves: .squat
        default: nil
        }
    }

    // MARK: - Level

    /// The starting difficulty for a movement pattern, from the ability answers and experience.
    static func level(for pattern: MovementPattern, profile: UserProfile) -> Difficulty {
        let tier: Int = switch pattern {
        case .push, .pull, .shoulders, .biceps, .triceps: profile.pushUpTier
        case .core, .carry, .conditioning: profile.plankTier
        case .squat, .lunge, .hinge, .calves: profile.squatTier
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

        // Each training phase after Foundation moves everything up one level.
        let phaseBonus = profile.phase.rawValue - TrainingPhase.foundation.rawValue
        result = Difficulty(rawValue: min(result.rawValue + phaseBonus, Difficulty.advanced.rawValue)) ?? result
        return result
    }

    // MARK: - Picking

    /// Chooses the best exercise for a slot: the hardest one at or below the user's level
    /// that fits their equipment and joints. Never repeats within a day; prefers ones
    /// not already used this week.
    static func pick(
        _ pattern: MovementPattern,
        for profile: UserProfile,
        avoiding weekUsed: Set<String>,
        excluding dayUsed: Set<String> = []
    ) -> Exercise? {
        let userLevel = level(for: pattern, profile: profile)
        let candidates = ExerciseLibrary.all.filter {
            $0.pattern == pattern && isAvailable($0, for: profile) && !dayUsed.contains($0.id)
        }
        guard !candidates.isEmpty else { return nil }

        let fresh = candidates.filter { !weekUsed.contains($0.id) }
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
    /// `adding` asks "what if they also had this?" (used by What to get next).
    static func isAvailable(_ exercise: Exercise, for profile: UserProfile, adding extra: EquipmentKind? = nil) -> Bool {
        // Only equipment switched on for workouts (owned-but-not-yet items are left out).
        var owned = Set(profile.equipmentInUse.map(\.kind))
        if let extra { owned.insert(extra) }
        guard exercise.equipment.isSubset(of: owned) else { return false }
        guard exercise.cautions.isDisjoint(with: profile.jointCautions) else { return false }

        if let range = exercise.weightRange {
            for kind in exercise.equipment where kind.hasWeight && kind != extra {
                // Unknown weight counts as a fit; otherwise at least one weight must be in range.
                let fits = profile.hasUnknownWeight(for: kind)
                    || profile.availableWeights(for: kind).contains { range.contains($0) }
                if !fits { return false }
            }
        }
        return true
    }

    // MARK: - Sets and reps

    static func prescribe(_ exercise: Exercise, for profile: UserProfile, isMainLift: Bool = false, isFocus: Bool = false) -> PlannedExercise {
        let goal = profile.goalType
        let minutes = profile.workoutMinutes
        // Extra set for the main lifts in longer workouts (and always in the Push phase),
        // and for focus areas from 30 minutes up.
        let extraSet = exercise.measure == .reps
            && ((minutes >= 45 && isMainLift) || (minutes >= 30 && isFocus) || (profile.phase == .push && isMainLift))
        let sets = extraSet ? 4 : 3
        // The Push phase trims rest a little for fat-loss goals.
        let rest = (profile.phase == .push && goal != .buildMuscle) ? max(30, profile.restSeconds - 15) : profile.restSeconds

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
            return PlannedExercise(exercise: exercise, sets: sets, reps: nil, seconds: seconds, restSeconds: rest, isFocus: isFocus)

        case .reps:
            let reps: ClosedRange<Int> = switch exercise.pattern {
            case .calves:
                15...20
            case .shoulders, .biceps, .triceps:
                goal == .loseFat ? 12...15 : 10...15
            default:
                goal == .loseFat ? 12...15 : 8...12
            }
            return PlannedExercise(exercise: exercise, sets: sets, reps: reps, seconds: nil, restSeconds: rest, isFocus: isFocus)
        }
    }
}

/// Maps the calendar onto the weekly rotation.
enum WorkoutSchedule {

    /// The profile's workout days in week order (e.g. Sun, Wed, Fri).
    static func orderedWorkoutDays(for profile: UserProfile) -> [Int] {
        Weekday.ordered.filter { profile.workoutWeekdays.contains($0) }
    }

    /// Which workout falls on this date, or nil for a rest day.
    static func workoutDay(on date: Date, for profile: UserProfile) -> WorkoutDay? {
        let weekday = Calendar.current.component(.weekday, from: date)
        let rotation = WorkoutPlans.days(for: profile)
        guard let index = orderedWorkoutDays(for: profile).firstIndex(of: weekday),
              index < rotation.count
        else { return nil }
        return rotation[index]
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
