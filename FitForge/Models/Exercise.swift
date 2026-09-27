import Foundation

/// The kind of movement an exercise trains. Workout templates are built from these.
enum MovementPattern: String, CaseIterable, Identifiable, Codable {
    // Big compound movements
    case squat, lunge, hinge, push, pull, core, carry
    // Smaller muscles, used to fill longer workouts
    case shoulders, biceps, triceps, calves
    // Short cardio finisher
    case conditioning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .squat: "Squat"
        case .lunge: "Lunge"
        case .hinge: "Hip hinge"
        case .push: "Push"
        case .pull: "Pull"
        case .core: "Core"
        case .carry: "Carry"
        case .shoulders: "Shoulders"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .calves: "Calves"
        case .conditioning: "Finisher"
        }
    }

    /// Short body-area name used in a day's summary, e.g. "Legs · Chest · Glutes · Core".
    var areaTitle: String {
        switch self {
        case .squat, .lunge: "Legs"
        case .hinge: "Glutes"
        case .push: "Chest"
        case .pull: "Back"
        case .core: "Core"
        case .carry: "Grip"
        case .shoulders: "Shoulders"
        case .biceps, .triceps: "Arms"
        case .calves: "Calves"
        case .conditioning: "Cardio"
        }
    }

    /// The main muscles this kind of movement works.
    var muscles: [MuscleGroup] {
        switch self {
        case .squat: [.quads, .glutes]
        case .lunge: [.quads, .glutes, .hamstrings]
        case .hinge: [.glutes, .hamstrings, .lowerBack]
        case .push: [.chest, .shoulders, .triceps]
        case .pull: [.upperBack, .biceps]
        case .core: [.abs]
        case .carry: [.grip, .abs, .shoulders]
        case .shoulders: [.shoulders]
        case .biceps: [.biceps]
        case .triceps: [.triceps]
        case .calves: [.calves]
        case .conditioning: [.quads, .abs]
        }
    }

    var systemImage: String {
        switch self {
        case .squat: "figure.cross.training"
        case .lunge: "figure.step.training"
        case .hinge: "figure.strengthtraining.traditional"
        case .push: "figure.strengthtraining.functional"
        case .pull: "figure.rower"
        case .core: "figure.core.training"
        case .carry: "figure.walk"
        case .shoulders: "figure.arms.open"
        case .biceps, .triceps: "dumbbell.fill"
        case .calves: "figure.stairs"
        case .conditioning: "heart.circle.fill"
        }
    }
}

enum Difficulty: Int, CaseIterable, Comparable, Codable {
    case beginner = 0, intermediate, advanced

    var title: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Whether a set is counted in reps or held for time.
enum ExerciseMeasure: String, Codable {
    case reps, time
}

/// One exercise in the built-in library. Library data lives in code, not the database.
struct Exercise: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let cues: [String]
    let pattern: MovementPattern
    let difficulty: Difficulty
    var measure: ExerciseMeasure = .reps
    /// Equipment required beyond bodyweight.
    var equipment: Set<EquipmentKind> = []
    /// Suitable weight (lb, per dumbbell / kettlebell) if the exercise uses weights.
    var weightRange: ClosedRange<Double>? = nil
    /// Joints this exercise can be hard on.
    var cautions: Set<JointCaution> = []
    /// Done one side at a time.
    var isUnilateral = false
    /// Muscles worked, when they differ from the usual for this movement.
    var muscleOverride: [MuscleGroup]? = nil

    /// The main muscles this exercise works.
    var muscles: [MuscleGroup] { muscleOverride ?? pattern.muscles }
}

/// Muscle groups, in head-to-toe order.
enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
    case shoulders, chest, upperBack, biceps, triceps, abs, lowerBack, glutes, quads, hamstrings, calves, grip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shoulders: "Shoulders"
        case .chest: "Chest"
        case .upperBack: "Upper back"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .abs: "Abs & core"
        case .lowerBack: "Lower back"
        case .glutes: "Glutes"
        case .quads: "Quads"
        case .hamstrings: "Hamstrings"
        case .calves: "Calves"
        case .grip: "Grip"
        }
    }

    var isUpperBody: Bool {
        switch self {
        case .shoulders, .chest, .upperBack, .biceps, .triceps, .grip: true
        default: false
        }
    }

    var isLowerBody: Bool {
        switch self {
        case .glutes, .quads, .hamstrings, .calves: true
        default: false
        }
    }
}
