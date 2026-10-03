import Foundation

/// How close you are to unlocking the next training phase.
struct PhaseProgress {
    enum Requirement {
        /// Body fat drop since your start, in percentage points (nil if there's no body fat data).
        case bodyFat(drop: Double?, needed: Double)
        /// Share of recent rep-based sets where you hit the top of the range (nil if no sets yet).
        case reps(hitRate: Double?, needed: Double)
    }

    let current: TrainingPhase
    let next: TrainingPhase?
    let workoutsDone: Int
    let workoutsNeeded: Int
    let requirement: Requirement?

    var workoutsMet: Bool { workoutsDone >= workoutsNeeded }

    var requirementMet: Bool {
        switch requirement {
        case .bodyFat(let drop, let needed): (drop ?? 0) >= needed
        case .reps(let hitRate, let needed): (hitRate ?? 0) >= needed
        case nil: true
        }
    }

    /// Both requirements met and there's a phase to move to.
    var isNextUnlocked: Bool { next != nil && workoutsMet && requirementMet }
}

enum PhaseEvaluator {

    /// Share of recent rep-based sets that must reach the top of the rep range ("build muscle" goal).
    static let repHitRateNeeded = 0.75
    /// How many recent workouts to look at for the rep-range check.
    static let recentWorkoutsForReps = 6

    static func progress(
        for profile: UserProfile,
        sessions: [WorkoutSession],
        latestBodyFat: Double?
    ) -> PhaseProgress {
        let current = profile.phase
        let counted = sessions
            .filter { WeekSchedule.counts($0) && $0.startDate >= Calendar.current.startOfDay(for: profile.startDate) }
            .sorted { $0.startDate > $1.startDate }

        guard let next = current.next else {
            return PhaseProgress(current: current, next: nil, workoutsDone: counted.count,
                                 workoutsNeeded: 0, requirement: nil)
        }

        let requirement: PhaseProgress.Requirement
        if profile.goalType == .buildMuscle {
            requirement = .reps(hitRate: repHitRate(in: Array(counted.prefix(recentWorkoutsForReps))),
                                needed: repHitRateNeeded)
        } else {
            let drop: Double? = {
                guard let start = profile.startBodyFatPercent, let latestBodyFat else { return nil }
                return start - latestBodyFat
            }()
            requirement = .bodyFat(drop: drop, needed: next.bodyFatDropToUnlock)
        }

        return PhaseProgress(
            current: current,
            next: next,
            workoutsDone: counted.count,
            workoutsNeeded: next.workoutsToUnlock,
            requirement: requirement
        )
    }

    /// Of the rep-based sets done in these workouts, the share that reached the top of the target range.
    private static func repHitRate(in sessions: [WorkoutSession]) -> Double? {
        let sets = sessions
            .flatMap { $0.sets ?? [] }
            .filter { !$0.wasSkipped && $0.targetRepsHigh != nil && $0.actualReps != nil }
        guard !sets.isEmpty else { return nil }
        let hits = sets.filter { ($0.actualReps ?? 0) >= ($0.targetRepsHigh ?? .max) }.count
        return Double(hits) / Double(sets.count)
    }
}
