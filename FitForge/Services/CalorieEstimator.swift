import Foundation

enum CalorieMethod: String, Codable {
    /// From heart rate recorded during the workout (e.g. by an Apple Watch).
    case heartRate
    /// From the exercises, sets and work/rest time (no heart rate available).
    case activity

    var description: String {
        switch self {
        case .heartRate: "Estimated from your heart rate"
        case .activity: "Estimated from your exercises and sets"
        }
    }
}

struct CalorieEstimate {
    /// Calories burned above resting (what Apple calls "active" calories).
    let activeCalories: Double
    let method: CalorieMethod
    let averageHeartRate: Double?
}

/// Estimates active calories for a finished workout.
/// Uses heart rate when there's enough of it; otherwise falls back to MET values for the work done.
enum CalorieEstimator {

    static func estimate(
        sets: [SetLog],
        start: Date,
        end: Date,
        weightLbs: Double,
        heightInches: Double?,
        age: Int?,
        ranges: BodyFatRanges?,
        heartRates: [Double]
    ) -> CalorieEstimate? {
        let minutes = end.timeIntervalSince(start) / 60
        guard minutes >= 1, weightLbs > 0 else { return nil }

        let kg = weightLbs * 0.453592
        let restingPerMinute = basalCalories(kg: kg, heightInches: heightInches, age: age, ranges: ranges) / 1440

        // 1. Heart rate (Keytel et al. 2005), when there's enough data to trust it.
        if heartRates.count >= 3, let age, let ranges {
            let averageHR = heartRates.reduce(0, +) / Double(heartRates.count)
            if averageHR >= 80 {
                let grossPerMinute: Double = switch ranges {
                case .male: (-55.0969 + 0.6309 * averageHR + 0.1988 * kg + 0.2017 * Double(age)) / 4.184
                case .female: (-20.4022 + 0.4472 * averageHR - 0.1263 * kg + 0.074 * Double(age)) / 4.184
                }
                let active = max(0, grossPerMinute - restingPerMinute) * minutes
                return CalorieEstimate(activeCalories: active.rounded(), method: .heartRate, averageHeartRate: averageHR.rounded())
            }
        }

        // 2. Activity (METs): intensity of each set's work time, plus light activity while resting.
        let totalSeconds = end.timeIntervalSince(start)
        var workSeconds = 0.0
        var metSeconds = 0.0

        for log in sets where !log.wasSkipped {
            let exercise = ExerciseLibrary.exercise(id: log.exerciseID)
            let sides = (exercise?.isUnilateral ?? false) ? 2.0 : 1.0
            let seconds: Double
            if let actual = log.actualSeconds {
                seconds = Double(actual) * sides
            } else {
                seconds = Double(log.actualReps ?? 10) * 3 * sides   // about 3 seconds per rep
            }
            workSeconds += seconds
            metSeconds += seconds * met(for: exercise?.pattern)
        }

        workSeconds = min(workSeconds, totalSeconds)
        let restSeconds = max(0, totalSeconds - workSeconds)
        metSeconds += restSeconds * 1.8   // standing, walking around, catching your breath

        let averageMET = metSeconds / totalSeconds
        let active = max(0, averageMET - 1) * kg * (totalSeconds / 3600)
        return CalorieEstimate(activeCalories: active.rounded(), method: .activity, averageHeartRate: nil)
    }

    /// Typical MET values while working, by movement type.
    private static func met(for pattern: MovementPattern?) -> Double {
        switch pattern {
        case .conditioning: 8.0
        case .squat, .lunge, .hinge, .carry: 5.5
        case .push, .pull: 5.0
        case .core: 3.8
        case .shoulders, .biceps, .triceps, .calves: 3.5
        case nil: 4.5
        }
    }

    /// Basal metabolic rate (Mifflin–St Jeor), in calories per day.
    private static func basalCalories(kg: Double, heightInches: Double?, age: Int?, ranges: BodyFatRanges?) -> Double {
        let cm = (heightInches ?? 68) * 2.54
        let years = Double(age ?? 35)
        let base = 10 * kg + 6.25 * cm - 5 * years
        switch ranges {
        case .male: return base + 5
        case .female: return base - 161
        case nil: return base - 78
        }
    }
}
