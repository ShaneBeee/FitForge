import Foundation
import SwiftData

enum SessionStatus: String, Codable {
    case inProgress
    case completed
    case endedEarly
}

/// One workout, from start to finish. Saved as it happens, so nothing is lost if the app closes.
@Model
final class WorkoutSession {
    var startDate: Date = Date.now
    var endDate: Date? = nil
    var dayRaw: String = "A"
    var statusRaw: String = SessionStatus.inProgress.rawValue
    var savedToHealth: Bool = false

    /// Estimated active calories, and how they were estimated (CalorieMethod raw value).
    var activeCalories: Double? = nil
    var calorieMethodRaw: String = ""
    var averageHeartRate: Double? = nil
    /// How hard it felt, 1–10 (Apple's workout effort scale).
    var effort: Int? = nil

    @Relationship(deleteRule: .cascade, inverse: \SetLog.session)
    var sets: [SetLog]? = []

    init(day: WorkoutDay, startDate: Date = .now) {
        self.dayRaw = day.id
        self.startDate = startDate
    }

    var day: WorkoutDay {
        get { WorkoutPlans.day(id: dayRaw) }
        set { dayRaw = newValue.id }
    }

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    var calorieMethod: CalorieMethod? {
        CalorieMethod(rawValue: calorieMethodRaw)
    }
}

/// One set within a workout — done or skipped.
@Model
final class SetLog {
    var exerciseID: String = ""
    var exerciseName: String = ""
    var exerciseIndex: Int = 0
    var setNumber: Int = 1

    var targetRepsLow: Int? = nil
    var targetRepsHigh: Int? = nil
    var targetSeconds: Int? = nil

    var actualReps: Int? = nil
    var actualSeconds: Int? = nil
    var wasSkipped: Bool = false
    var completedAt: Date = Date.now

    var session: WorkoutSession?

    init(planned: PlannedExercise, exerciseIndex: Int, setNumber: Int) {
        self.exerciseID = planned.exercise.id
        self.exerciseName = planned.exercise.name
        self.exerciseIndex = exerciseIndex
        self.setNumber = setNumber
        self.targetRepsLow = planned.reps?.lowerBound
        self.targetRepsHigh = planned.reps?.upperBound
        self.targetSeconds = planned.seconds
    }

    /// e.g. "12 reps", "30 sec" or "Skipped"
    var resultText: String {
        if wasSkipped { return "Skipped" }
        if let actualReps { return "\(actualReps) reps" }
        if let actualSeconds { return "\(actualSeconds) sec" }
        return "Done"
    }
}
