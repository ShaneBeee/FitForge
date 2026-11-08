import Foundation

/// Chooses which dumbbells (or kettlebell) to use for each exercise, and when to move up.
///
/// - First time: heaviest weight for big leg/hip movements, a middle one for presses and rows,
///   the lightest for small muscles (raises, curls, flys).
/// - After that: the weight used last time, or the next one up if every set last time
///   reached the top of the rep range (or the full time).
enum WeightProgression {

    /// How an exercise was last done with a weight.
    struct LastUse {
        let weight: Double
        /// Every set reached the top of its target.
        let hitTop: Bool
    }

    /// The most recent weighted use of each exercise, keyed by exercise ID.
    static func lastUses(in history: [WorkoutSession]) -> [String: LastUse] {
        var result: [String: LastUse] = [:]
        for session in history.sorted(by: { $0.startDate > $1.startDate }) {
            let sets = (session.sets ?? []).filter { !$0.wasSkipped && $0.weightLbs != nil }
            for (exerciseID, exerciseSets) in Dictionary(grouping: sets, by: \.exerciseID)
            where result[exerciseID] == nil {
                guard let weight = exerciseSets.compactMap(\.weightLbs).max() else { continue }
                // Two or more sets, all at the top of the range, before moving up.
                let hitTop = exerciseSets.count >= 2 && exerciseSets.allSatisfy(\.hitTarget)
                result[exerciseID] = LastUse(weight: weight, hitTop: hitTop)
            }
        }
        return result
    }

    /// The weight to use for an exercise, or nil if it doesn't use one (or the weight is unknown).
    static func suggestedWeight(
        for exercise: Exercise,
        profile: UserProfile,
        lastUse: LastUse?
    ) -> (weight: Double, isIncrease: Bool)? {
        guard let kind = exercise.equipment.first(where: \.hasWeight) else { return nil }
        var options = profile.availableWeights(for: kind)
        if let range = exercise.weightRange {
            options = options.filter { range.contains($0) }
        }
        guard !options.isEmpty else { return nil }

        if let lastUse {
            // Closest weight they still have to what they used last time.
            let current = options.min { abs($0 - lastUse.weight) < abs($1 - lastUse.weight) } ?? options[0]
            if lastUse.hitTop, let heavier = options.first(where: { $0 > current }) {
                return (heavier, true)
            }
            return (current, false)
        }

        switch role(for: exercise.pattern) {
        case .heavy: return (options[options.count - 1], false)
        case .medium: return (options[(options.count - 1) / 2], false)
        case .light: return (options[0], false)
        }
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
