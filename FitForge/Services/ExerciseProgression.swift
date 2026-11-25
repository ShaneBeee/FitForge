import Foundation

/// Keeps bodyweight and timed exercises challenging (weighted ones are handled by WeightProgression):
/// - holds you complete get longer, 10 seconds at a time, up to a minute
/// - when a bodyweight exercise (or a one-minute hold) is easy two workouts in a row, FitForge offers
///   to move that movement up a level, which swaps in a harder exercise
enum ExerciseProgression {

    /// Longest hold before the next step is a harder exercise instead of more time.
    static let maxHoldSeconds = 60
    /// Seconds added each time a hold is completed two workouts in a row.
    static let holdStep = 10

    // MARK: - Longer holds

    /// The hold time for the next workout: up 10 seconds once every set was held for the full time
    /// in the last two workouts at the current target, never below the usual time for your level.
    static func holdSeconds(for exerciseID: String, base: Int, history: [WorkoutSession]) -> Int {
        let recent = recentSets(of: exerciseID, in: history, count: 2)
        guard let lastTarget = recent.first?.first?.targetSeconds else { return base }

        let current = max(base, lastTarget)
        let completedTwice = recent.count == 2 && recent.allSatisfy { sets in
            sets.count >= 2 && sets.allSatisfy { $0.targetSeconds == lastTarget && $0.hitTarget }
        }
        guard completedTwice, lastTarget >= base else { return current }
        return min(lastTarget + holdStep, max(maxHoldSeconds, base))
    }

    // MARK: - Ready for a harder exercise

    struct Graduation: Identifiable {
        /// The exercise that's become easy.
        let from: Exercise
        /// An example of what the next level brings for this movement.
        let to: Exercise
        var pattern: MovementPattern { from.pattern }
        var id: String { from.id }

        /// Why it's being offered, e.g. "Every set at the top of the range, two workouts in a row."
        var reason: String {
            from.measure == .time
                ? "You've held it for a full minute, two workouts in a row."
                : "Every set at the top of the range, two workouts in a row."
        }
    }

    /// Exercises in your latest workout that are ready to be swapped for something harder.
    static func graduations(for profile: UserProfile, history: [WorkoutSession], limit: Int = 2) -> [Graduation] {
        guard let latest = history.max(by: { $0.startDate < $1.startDate }) else { return [] }

        let exerciseIDs = (latest.sets ?? [])
            .filter { !$0.wasSkipped }
            .sorted { $0.exerciseIndex < $1.exerciseIndex }
            .map(\.exerciseID)

        var offers: [Graduation] = []
        var seenPatterns: Set<MovementPattern> = []
        var seenIDs: Set<String> = []
        for id in exerciseIDs where !seenIDs.contains(id) {
            seenIDs.insert(id)
            guard offers.count < limit,
                  let exercise = ExerciseLibrary.exercise(id: id),
                  !seenPatterns.contains(exercise.pattern),
                  isEasy(exercise, history: history),
                  !profile.isGraduationSnoozed(exercise.id),
                  let harder = harderOption(than: exercise, for: profile)
            else { continue }
            offers.append(Graduation(from: exercise, to: harder))
            seenPatterns.insert(exercise.pattern)
        }
        return offers
    }

    /// Bodyweight exercise with every set at the top two workouts in a row
    /// (or a hold done for the full minute twice).
    private static func isEasy(_ exercise: Exercise, history: [WorkoutSession]) -> Bool {
        // Weighted exercises move up by weight instead (WeightProgression).
        guard !exercise.equipment.contains(where: \.hasWeight), exercise.pattern != .carry else { return false }

        let recent = recentSets(of: exercise.id, in: history, count: 2)
        guard recent.count == 2 else { return false }
        return recent.allSatisfy { sets in
            guard sets.count >= 2, sets.allSatisfy(\.hitTarget) else { return false }
            if exercise.measure == .time {
                return sets.allSatisfy { ($0.targetSeconds ?? 0) >= maxHoldSeconds }
            }
            return true
        }
    }

    /// What one level up looks like for this movement, preferring exercises that use weights you own.
    private static func harderOption(than exercise: Exercise, for profile: UserProfile) -> Exercise? {
        let level = WorkoutBuilder.level(for: exercise.pattern, profile: profile)
        guard level < .advanced, let nextLevel = Difficulty(rawValue: level.rawValue + 1) else { return nil }

        let candidates = ExerciseLibrary.all.filter {
            $0.pattern == exercise.pattern
                && $0.id != exercise.id
                && $0.difficulty > exercise.difficulty
                && $0.difficulty <= nextLevel
                && WorkoutBuilder.isAvailable($0, for: profile)
        }
        // Weighted options first (you have dumbbells), then the gentlest step up.
        return candidates.min { lhs, rhs in
            let lhsWeighted = lhs.equipment.contains(where: \.hasWeight)
            let rhsWeighted = rhs.equipment.contains(where: \.hasWeight)
            if lhsWeighted != rhsWeighted { return lhsWeighted }
            return lhs.difficulty < rhs.difficulty
        }
    }

    // MARK: - Helpers

    /// The done (not skipped) sets of an exercise in its most recent workouts, newest first.
    private static func recentSets(of exerciseID: String, in history: [WorkoutSession], count: Int) -> [[SetLog]] {
        var result: [[SetLog]] = []
        for session in history.sorted(by: { $0.startDate > $1.startDate }) {
            let sets = (session.sets ?? []).filter { $0.exerciseID == exerciseID && !$0.wasSkipped }
            if !sets.isEmpty { result.append(sets) }
            if result.count == count { break }
        }
        return result
    }
}
