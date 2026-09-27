import Foundation

// Choices made during first-time setup and editable in Profile.
// Stored in SwiftData as raw strings/ints (CloudKit-friendly), exposed as enums.

enum GoalType: String, CaseIterable, Identifiable, Codable {
    case loseFat
    case buildMuscle
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .loseFat: "Lose fat"
        case .buildMuscle: "Build muscle"
        case .both: "Both"
        }
    }

    var detail: String {
        switch self {
        case .loseFat: "Higher reps, shorter rests and circuits to burn more."
        case .buildMuscle: "Harder variations, more sets and longer rests to get stronger."
        case .both: "Drop fat while building muscle — a mix of both styles."
        }
    }

    var systemImage: String {
        switch self {
        case .loseFat: "flame.fill"
        case .buildMuscle: "dumbbell.fill"
        case .both: "arrow.triangle.2.circlepath"
        }
    }

    /// Suggested rest between sets for this goal.
    var defaultRestSeconds: Int {
        switch self {
        case .loseFat: 45
        case .both: 60
        case .buildMuscle: 90
        }
    }
}

enum ActivityLevel: String, CaseIterable, Identifiable, Codable {
    case mostlySitting
    case onFeet
    case veryActive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mostlySitting: "Mostly sitting"
        case .onFeet: "On my feet"
        case .veryActive: "Very active"
        }
    }

    var detail: String {
        switch self {
        case .mostlySitting: "Desk work, driving, not much walking"
        case .onFeet: "Standing or walking for a good part of the day"
        case .veryActive: "Physical job or lots of daily activity"
        }
    }

    var systemImage: String {
        switch self {
        case .mostlySitting: "chair.lounge.fill"
        case .onFeet: "figure.walk"
        case .veryActive: "figure.run"
        }
    }
}

enum Experience: String, CaseIterable, Identifiable, Codable {
    case new
    case some
    case experienced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: "New to this"
        case .some: "Some experience"
        case .experienced: "Experienced"
        }
    }
}

enum JointCaution: String, CaseIterable, Identifiable, Codable {
    case knees
    case lowerBack
    case shoulders
    case wrists

    var id: String { rawValue }

    var title: String {
        switch self {
        case .knees: "Knees"
        case .lowerBack: "Lower back"
        case .shoulders: "Shoulders"
        case .wrists: "Wrists"
        }
    }
}

/// Areas to prioritize, on top of the main goal (pick up to 3).
enum FocusArea: String, CaseIterable, Identifiable, Codable {
    case bellyFat, arms, chest, shoulders, back, abs, glutes, legs

    static let maxSelections = 3

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bellyFat: "Belly fat"
        case .arms: "Arms"
        case .chest: "Chest"
        case .shoulders: "Shoulders"
        case .back: "Back"
        case .abs: "Abs"
        case .glutes: "Glutes"
        case .legs: "Legs"
        }
    }

    var systemImage: String {
        switch self {
        case .bellyFat: "flame.fill"
        case .arms: "dumbbell.fill"
        case .chest: "figure.strengthtraining.functional"
        case .shoulders: "figure.arms.open"
        case .back: "figure.rower"
        case .abs: "figure.core.training"
        case .glutes: "figure.strengthtraining.traditional"
        case .legs: "figure.step.training"
        }
    }

    /// The movement patterns that get extra priority and volume.
    var patterns: [MovementPattern] {
        switch self {
        case .bellyFat, .abs: [.core]
        case .arms: [.biceps, .triceps]
        case .chest: [.push]
        case .shoulders: [.shoulders]
        case .back: [.pull]
        case .glutes: [.hinge]
        case .legs: [.squat, .lunge]
        }
    }
}

/// Which set of body fat ranges to show (they differ for men and women).
enum BodyFatRanges: String, CaseIterable, Identifiable, Codable {
    case male
    case female

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        }
    }
}

/// The ability questions asked during setup. Each answer is stored as a tier (0–3).
enum AbilityQuestion: String, CaseIterable, Identifiable, Codable {
    case pushUps
    case plank
    case squats

    var id: String { rawValue }

    var prompt: String {
        switch self {
        case .pushUps: "How many push-ups can you do in a row?"
        case .plank: "How long can you hold a plank?"
        case .squats: "How many bodyweight squats in a row?"
        }
    }

    var options: [String] {
        switch self {
        case .pushUps: ["None yet", "1–5", "6–15", "16+"]
        case .plank: ["Under 15 sec", "15–30 sec", "30–60 sec", "Over a minute"]
        case .squats: ["Under 5", "5–15", "16–30", "30+"]
        }
    }

    var systemImage: String {
        switch self {
        case .pushUps: "figure.strengthtraining.functional"
        case .plank: "figure.core.training"
        case .squats: "figure.cross.training"
        }
    }
}

enum EquipmentKind: String, CaseIterable, Identifiable, Codable {
    case dumbbells
    case chair
    case bench
    case pullUpBar
    case band
    case kettlebell

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dumbbells: "Dumbbells"
        case .chair: "Sturdy chair"
        case .bench: "Bench"
        case .pullUpBar: "Pull-up bar"
        case .band: "Resistance band"
        case .kettlebell: "Kettlebell"
        }
    }

    var detail: String {
        switch self {
        case .dumbbells: "A pair of fixed or adjustable dumbbells"
        case .chair: "Something solid to step on or lean on"
        case .bench: "A workout or weight bench"
        case .pullUpBar: "A doorway or mounted bar"
        case .band: "Loop or tube resistance bands"
        case .kettlebell: "Any single kettlebell"
        }
    }

    var systemImage: String {
        switch self {
        case .dumbbells: "dumbbell.fill"
        case .chair: "chair.fill"
        case .bench: "bed.double.fill"
        case .pullUpBar: "figure.climbing"
        case .band: "arrow.left.and.right"
        case .kettlebell: "scalemass.fill"
        }
    }

    /// Whether this kind of equipment has a weight worth recording.
    var hasWeight: Bool {
        self == .dumbbells || self == .kettlebell
    }
}

/// Helpers for Calendar weekday numbers (1 = Sunday … 7 = Saturday).
enum Weekday {
    /// All seven weekdays, in the order the user's calendar starts the week.
    static var ordered: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    static func shortName(_ weekday: Int) -> String {
        Calendar.current.shortWeekdaySymbols[weekday - 1]
    }

    static func name(_ weekday: Int) -> String {
        Calendar.current.weekdaySymbols[weekday - 1]
    }
}
