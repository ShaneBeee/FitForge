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

/// Training phases. Each one makes the workouts harder; the next unlocks as you progress.
enum TrainingPhase: Int, CaseIterable, Identifiable, Codable {
    case foundation = 1
    case build = 2
    case push = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .foundation: "Foundation"
        case .build: "Build"
        case .push: "Push"
        }
    }

    var tagline: String {
        switch self {
        case .foundation: "Learn the movements and build the habit."
        case .build: "Harder variations across the board."
        case .push: "Harder again, with more volume and shorter rests."
        }
    }

    var systemImage: String {
        switch self {
        case .foundation: "square.stack.3d.up.fill"
        case .build: "hammer.fill"
        case .push: "bolt.fill"
        }
    }

    var next: TrainingPhase? { TrainingPhase(rawValue: rawValue + 1) }

    /// Total workouts needed to unlock this phase.
    var workoutsToUnlock: Int {
        switch self {
        case .foundation: 0
        case .build: 12
        case .push: 30
        }
    }

    /// Body fat drop (percentage points from your start) needed to unlock this phase.
    var bodyFatDropToUnlock: Double {
        switch self {
        case .foundation: 0
        case .build: 1.5
        case .push: 3.5
        }
    }
}

/// Areas to prioritize, on top of the main goal.
enum FocusArea: String, CaseIterable, Identifiable, Codable {
    case bellyFat, arms, chest, shoulders, back, abs, glutes, legs

    /// How many focus areas fit a workout of this length: more time, more room to honor them.
    static func maxSelections(forMinutes minutes: Int) -> Int {
        switch minutes {
        case ..<40: 3
        case ..<55: 4
        default: 5
        }
    }

    /// How many workouts in a rotation already open with a main lift that trains this area.
    func mainLiftDays(in days: [WorkoutDay]) -> Int {
        days.filter { day in
            day.slots.prefix(2).contains { coveragePatterns.contains($0) }
        }.count
    }

    /// Movements that train this area hard, whether or not it's a focus.
    private var coveragePatterns: [MovementPattern] {
        switch self {
        case .bellyFat, .abs: [.core]
        case .arms: [.biceps, .triceps]
        case .chest: [.push]
        case .shoulders: [.shoulders]
        case .back: [.pull]
        case .glutes, .legs: [.squat, .lunge, .hinge]
        }
    }

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

/// How the equipment list is grouped on screen.
enum EquipmentCategory: String, CaseIterable, Identifiable {
    case weights, bodyweight, bands, cardio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weights: "Weights"
        case .bodyweight: "Bodyweight helpers"
        case .bands: "Bands"
        case .cardio: "Cardio"
        }
    }

    var kinds: [EquipmentKind] {
        EquipmentKind.allCases.filter { $0.category == self }
    }
}

enum EquipmentKind: String, CaseIterable, Identifiable, Codable {
    // Weights
    case dumbbells
    case kettlebell
    case medicineBall
    // Bodyweight helpers
    case chair
    case bench
    case step
    case pullUpBar
    case pushUpHandles
    case suspensionTrainer
    case abWheel
    case stabilityBall
    // Bands
    case band
    case miniBands
    // Cardio
    case jumpRope

    var id: String { rawValue }

    var category: EquipmentCategory {
        switch self {
        case .dumbbells, .kettlebell, .medicineBall: .weights
        case .chair, .bench, .step, .pullUpBar, .pushUpHandles, .suspensionTrainer, .abWheel, .stabilityBall: .bodyweight
        case .band, .miniBands: .bands
        case .jumpRope: .cardio
        }
    }

    var title: String {
        switch self {
        case .dumbbells: "Dumbbells"
        case .kettlebell: "Kettlebell"
        case .medicineBall: "Medicine or slam ball"
        case .chair: "Sturdy chair"
        case .bench: "Bench"
        case .step: "Step or box"
        case .pullUpBar: "Pull-up bar"
        case .pushUpHandles: "Push-up handles"
        case .suspensionTrainer: "Suspension trainer"
        case .abWheel: "Ab wheel"
        case .stabilityBall: "Stability ball"
        case .band: "Resistance band"
        case .miniBands: "Mini loop bands"
        case .jumpRope: "Jump rope"
        }
    }

    var detail: String {
        switch self {
        case .dumbbells: "A pair of fixed or adjustable dumbbells"
        case .kettlebell: "Any single kettlebell"
        case .medicineBall: "A weighted ball for throws, slams and twists"
        case .chair: "Something solid to step on or lean on"
        case .bench: "A workout or weight bench"
        case .step: "An aerobic step, plyo box or the bottom stair"
        case .pullUpBar: "A doorway or mounted bar"
        case .pushUpHandles: "Handles or parallettes — easier on the wrists"
        case .suspensionTrainer: "TRX-style straps over a door or anchor"
        case .abWheel: "A wheel with handles for rollouts"
        case .stabilityBall: "A large inflatable exercise ball"
        case .band: "Long loop or tube resistance bands"
        case .miniBands: "Small fabric or rubber loops for hips and glutes"
        case .jumpRope: "Any skipping rope"
        }
    }

    var systemImage: String {
        switch self {
        case .dumbbells: "dumbbell.fill"
        case .kettlebell: "scalemass.fill"
        case .medicineBall: "basketball.fill"
        case .chair: "chair.fill"
        case .bench: "bed.double.fill"
        case .step: "figure.step.training"
        case .pullUpBar: "figure.climbing"
        case .pushUpHandles: "figure.strengthtraining.functional"
        case .suspensionTrainer: "figure.flexibility"
        case .abWheel: "circle.circle"
        case .stabilityBall: "circle.fill"
        case .band: "arrow.left.and.right"
        case .miniBands: "circle.dashed"
        case .jumpRope: "figure.jumprope"
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
