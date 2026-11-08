import Foundation

/// Chooses which dumbbells (or kettlebell) to use for each exercise, when to move up,
/// and when the user has outgrown the heaviest weight they own.
///
/// - First time: heaviest weight for big leg/hip movements, a middle one for presses and rows,
///   the lightest for small muscles (raises, curls, flys).
/// - After that: the weight used last time, or the next one up if every set last time
///   reached the top of the rep range (or the full time). This is "double progression".
/// - Outgrown: the top of the range with the *heaviest* weight owned, two workouts in a row.
///   The exercise then gets harder without more weight (slow lowering, higher reps), and it
///   shows up in "What to get next".
enum WeightProgression {

    /// How an exercise was done with a weight in one workout.
    struct Use {
        let weight: Double
        /// Every set reached the top of its target.
        let hitTop: Bool
    }

    struct Suggestion {
        let weight: Double
        /// A step up from last time.
        let isIncrease: Bool
        /// Ready for more, but there's no heavier weight to use.
        let isOutgrown: Bool
    }

    /// The two most recent weighted uses of each exercise (newest first), keyed by exercise ID.
    static func recentUses(in history: [WorkoutSession]) -> [String: [Use]] {
        var result: [String: [Use]] = [:]
        for session in history.sorted(by: { $0.startDate > $1.startDate }) {
            let sets = (session.sets ?? []).filter { !$0.wasSkipped && $0.weightLbs != nil }
            for (exerciseID, exerciseSets) in Dictionary(grouping: sets, by: \.exerciseID)
            where (result[exerciseID]?.count ?? 0) < 2 {
                guard let weight = exerciseSets.compactMap(\.weightLbs).max() else { continue }
                // Two or more sets, all at the top of the range.
                let hitTop = exerciseSets.count >= 2 && exerciseSets.allSatisfy(\.hitTarget)
                result[exerciseID, default: []].append(Use(weight: weight, hitTop: hitTop))
            }
        }
        return result
    }

    /// The weights the user owns that suit an exercise, lightest first.
    static func options(for exercise: Exercise, profile: UserProfile) -> [Double] {
        guard let kind = exercise.equipment.first(where: \.hasWeight) else { return [] }
        var options = profile.availableWeights(for: kind)
        if let range = exercise.weightRange {
            options = options.filter { range.contains($0) }
        }
        return options
    }

    /// The weight to use for an exercise, or nil if it doesn't use one (or the weight is unknown).
    static func suggestion(for exercise: Exercise, profile: UserProfile, uses: [Use]?) -> Suggestion? {
        let options = options(for: exercise, profile: profile)
        guard !options.isEmpty else { return nil }

        if let uses, let last = uses.first {
            // Closest weight they still have to what they used last time.
            let current = options.min { abs($0 - last.weight) < abs($1 - last.weight) } ?? options[0]
            let heavier = options.first { $0 > current }

            if last.hitTop, let heavier {
                return Suggestion(weight: heavier, isIncrease: true, isOutgrown: false)
            }
            // Top of the range with the heaviest weight, twice in a row.
            let outgrown = heavier == nil
                && uses.count >= 2
                && uses.prefix(2).allSatisfy { $0.hitTop && $0.weight >= current }
            return Suggestion(weight: current, isIncrease: false, isOutgrown: outgrown)
        }

        let weight: Double = switch role(for: exercise.pattern) {
        case .heavy: options[options.count - 1]
        case .medium: options[(options.count - 1) / 2]
        case .light: options[0]
        }
        return Suggestion(weight: weight, isIncrease: false, isOutgrown: false)
    }

    /// Exercises the user has outgrown their heaviest weight on, with that weight.
    static func outgrown(for profile: UserProfile, history: [WorkoutSession]) -> [(exercise: Exercise, weight: Double)] {
        recentUses(in: history).compactMap { id, uses in
            guard let exercise = ExerciseLibrary.exercise(id: id),
                  let suggestion = suggestion(for: exercise, profile: profile, uses: uses),
                  suggestion.isOutgrown
            else { return nil }
            return (exercise, suggestion.weight)
        }
        .sorted { $0.exercise.name < $1.exercise.name }
    }

    /// Big leg and hip movements need the most weight.
    static func needsHeavy(_ pattern: MovementPattern) -> Bool {
        role(for: pattern) == .heavy
    }

    private enum Role { case heavy, medium, light }

    private static func role(for pattern: MovementPattern) -> Role {
        switch pattern {
        case .squat, .hinge, .carry, .calves: .heavy
        case .push, .pull, .lunge, .conditioning: .medium
        case .shoulders, .biceps, .triceps, .core: .light
        }
    }
}
