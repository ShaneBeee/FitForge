import Foundation

/// The kind of movement an exercise trains. Workout templates are built from these.
enum MovementPattern: String, CaseIterable, Identifiable, Codable {
    case squat, lunge, hinge, push, pull, core, carry

    var id: String { rawValue }

    var title: String {
        switch self {
        case .squat: "Squat"
        case .lunge: "Lunge"
        case .hinge: "Hinge"
        case .push: "Push"
        case .pull: "Pull"
        case .core: "Core"
        case .carry: "Carry"
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
}
