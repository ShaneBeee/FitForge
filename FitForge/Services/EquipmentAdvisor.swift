import Foundation

/// "Time for heavier weights": the user has outgrown their heaviest dumbbells or kettlebell.
struct HeavierWeightAdvice: Identifiable {
    let kind: EquipmentKind
    /// The heaviest weight they own (lb).
    let currentMax: Double
    /// Exercises that have outgrown it.
    let exercises: [Exercise]
    /// The next weight to get (lb).
    let nextWeight: Double

    var id: String { kind.rawValue }
}

/// A piece of equipment the user doesn't own, and what it would add.
struct EquipmentSuggestion: Identifiable {
    let kind: EquipmentKind
    /// Exercises it would add to the user's options.
    let unlocks: [Exercise]
    /// Focus areas those exercises train.
    let focusMatches: [FocusArea]

    var id: String { kind.rawValue }
}

/// A more capable bench than the one the user has, and what it would add.
struct BenchUpgrade {
    let from: BenchType
    let to: BenchType
    /// Incline/decline exercises it would add to the user's options.
    let unlocks: [Exercise]
    let focusMatches: [FocusArea]
}

/// Works out what equipment would help most next, for this user's goals, level and focus areas.
enum EquipmentAdvisor {

    // MARK: - Heavier weights

    static func heavierWeights(for profile: UserProfile, history: [WorkoutSession]) -> [HeavierWeightAdvice] {
        let outgrown = WeightProgression.outgrown(for: profile, history: history)
        let byKind = Dictionary(grouping: outgrown) { item in
            item.exercise.equipment.first(where: \.hasWeight) ?? .dumbbells
        }
        return byKind.compactMap { kind, items in
            guard let currentMax = items.map(\.weight).max() else { return nil }
            // Legs and hips can jump 10 lb; smaller lifts go up 5.
            let step: Double = items.contains { WeightProgression.needsHeavy($0.exercise.pattern) } ? 10 : 5
            return HeavierWeightAdvice(
                kind: kind,
                currentMax: currentMax,
                exercises: items.map(\.exercise),
                nextWeight: currentMax + step
            )
        }
        .sorted { $0.kind.rawValue < $1.kind.rawValue }
    }

    // MARK: - New equipment

    /// The most useful equipment the user doesn't own yet, best first.
    static func suggestions(for profile: UserProfile, limit: Int = 5) -> [EquipmentSuggestion] {
        let owned = Set((profile.equipment ?? []).map(\.kind))
        let focusPatterns = Set(profile.focusAreas.flatMap(\.patterns))

        let scored: [(suggestion: EquipmentSuggestion, score: Int)] = EquipmentKind.allCases.compactMap { kind in
            guard !owned.contains(kind) else { return nil }

            // Exercises this item would add, at a level the user can do now or soon.
            let unlocks = ExerciseLibrary.all.filter { exercise in
                WorkoutBuilder.isAvailable(exercise, for: profile, adding: kind)
                    && !WorkoutBuilder.isAvailable(exercise, for: profile)
                    && exercise.difficulty.rawValue <= WorkoutBuilder.level(for: exercise.pattern, profile: profile).rawValue + 1
            }
            guard !unlocks.isEmpty else { return nil }

            let matches = profile.focusAreas.filter { area in
                unlocks.contains { area.patterns.contains($0.pattern) }
            }
            let focusUnlocks = unlocks.filter { focusPatterns.contains($0.pattern) }.count
            let score = unlocks.count + focusUnlocks * 2 + matches.count * 3

            return (EquipmentSuggestion(kind: kind, unlocks: unlocks, focusMatches: matches), score)
        }

        return scored
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map(\.suggestion)
    }

    // MARK: - Bench upgrade

    /// For someone with a flat (or incline-only) bench: what an adjustable bench with decline would add.
    /// Folding adjustable benches usually include the decline leg holder, so that's the one suggested.
    static func benchUpgrade(for profile: UserProfile) -> BenchUpgrade? {
        guard let current = profile.benchType, current < .adjustableDecline else { return nil }
        let target = BenchType.adjustableDecline

        let unlocks = ExerciseLibrary.all.filter { exercise in
            exercise.benchAngle != nil
                && WorkoutBuilder.isAvailable(exercise, for: profile, bench: target)
                && !WorkoutBuilder.isAvailable(exercise, for: profile)
                && exercise.difficulty.rawValue <= WorkoutBuilder.level(for: exercise.pattern, profile: profile).rawValue + 1
        }
        guard !unlocks.isEmpty else { return nil }

        let matches = profile.focusAreas.filter { area in
            unlocks.contains { area.patterns.contains($0.pattern) }
        }
        return BenchUpgrade(from: current, to: target, unlocks: unlocks, focusMatches: matches)
    }

    // MARK: - Prices

    /// Rough price for new gear in Canada. Thrift stores and Marketplace are often much cheaper.
    static func priceRange(for kind: EquipmentKind) -> String {
        switch kind {
        case .dumbbells: "$150–400 adjustable"
        case .kettlebell: "$40–100"
        case .medicineBall: "$30–70"
        case .chair: "Free"
        case .bench: "$100–250"
        case .step: "$40–90"
        case .pullUpBar: "$30–60"
        case .dipStation: "$60–150"
        case .pushUpHandles: "$15–30"
        case .suspensionTrainer: "$40–150"
        case .abWheel: "$15–30"
        case .stabilityBall: "$20–40"
        case .band: "$20–40"
        case .miniBands: "$15–25"
        case .jumpRope: "$10–25"
        }
    }

    /// Rough price for one pair of fixed dumbbells (or one kettlebell) at a weight, new.
    static func priceRange(forWeight weight: Double, kind: EquipmentKind) -> String {
        let pounds = kind == .dumbbells ? weight * 2 : weight
        let low = Int((pounds * 1.5 / 5).rounded()) * 5
        let high = Int((pounds * 2.5 / 5).rounded()) * 5
        return "$\(low)–\(high)"
    }
}
