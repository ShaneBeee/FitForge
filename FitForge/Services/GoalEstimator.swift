import Foundation

/// Rough, healthy-pace timeline estimates for weight and body fat goals.
struct GoalEstimate {
    let minWeeks: Int
    let maxWeeks: Int
    let notes: [String]

    var earliestDate: Date { Calendar.current.date(byAdding: .weekOfYear, value: minWeeks, to: .now) ?? .now }
    var latestDate: Date { Calendar.current.date(byAdding: .weekOfYear, value: maxWeeks, to: .now) ?? .now }
}

enum GoalEstimator {

    // Healthy rates of change
    private static let lossRatePerWeek = 0.005...0.01          // 0.5–1% of body weight per week
    private static let gainRatePerWeek = 0.0025...0.005        // 0.25–0.5% of body weight per week
    private static let bodyFatPointsPerWeek = 0.15...0.30      // body fat % points per week

    static func estimate(
        currentWeight: Double?,
        targetWeight: Double?,
        currentBodyFat: Double?,
        targetBodyFat: Double?
    ) -> GoalEstimate? {
        var ranges: [ClosedRange<Double>] = []
        var notes: [String] = []

        // Weight
        if let current = currentWeight, let target = targetWeight, current > 0, abs(target - current) >= 0.5 {
            let change = abs(target - current)
            let rates = target < current ? lossRatePerWeek : gainRatePerWeek
            let fastest = change / (current * rates.upperBound)
            let slowest = change / (current * rates.lowerBound)
            ranges.append(fastest...slowest)

            if change / current > 0.20 {
                notes.append("That's a big change. Consider setting a closer milestone first — you can always move the target later.")
            }
        }

        // Body fat
        if let current = currentBodyFat, let target = targetBodyFat, target < current - 0.1 {
            let change = current - target
            ranges.append((change / bodyFatPointsPerWeek.upperBound)...(change / bodyFatPointsPerWeek.lowerBound))
        }

        if let targetBodyFat, targetBodyFat < 10 {
            notes.append("A body fat target under 10% is very lean and hard to maintain for most people. The low-to-mid teens is a strong, sustainable goal.")
        }

        guard !ranges.isEmpty else {
            return notes.isEmpty ? nil : GoalEstimate(minWeeks: 0, maxWeeks: 0, notes: notes)
        }

        // Both goals have to be reached, so the slower one sets the pace.
        let minWeeks = ranges.map(\.lowerBound).max() ?? 0
        let maxWeeks = ranges.map(\.upperBound).max() ?? 0
        return GoalEstimate(
            minWeeks: max(1, Int(minWeeks.rounded())),
            maxWeeks: max(1, Int(maxWeeks.rounded())),
            notes: notes
        )
    }
}
