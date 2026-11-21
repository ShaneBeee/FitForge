import SwiftUI
import SwiftData
import Charts

/// Visceral fat on the rating scale most smart scales use.
struct VisceralFatRangeCard: View {
    let rating: Double
    var compact = false

    private let bands: [RangeBand] = [
        RangeBand(label: "Standard", range: 1...9.5, color: Theme.green),
        RangeBand(label: "High", range: 9.5...14.5, color: Theme.blue),
        RangeBand(label: "Excessive", range: 14.5...20, color: Theme.blue.opacity(0.6)),
    ]

    var body: some View {
        let status = RangeBar.band(for: rating, in: bands)?.label ?? ""

        RangeCard(
            title: compact ? "Where you stand" : "Visceral fat",
            systemImage: "target",
            tint: Theme.teal,
            valueText: rating.formatted(.number.precision(.fractionLength(0))),
            statusText: "\(status) range",
            bands: bands,
            value: rating,
            note: "A smart scale rating for fat stored deep around your organs, mostly in the belly. Lower is better, and it usually drops steadily with regular training.",
            compact: compact
        )
    }
}

/// One smart scale measurement that can be charted.
enum CompositionMetric: String, CaseIterable, Identifiable {
    case muscleMass, fatFreeMass, skeletalMuscle, subcutaneousFat, bodyWater, protein, boneMass, bmr, metabolicAge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .muscleMass: "Muscle mass"
        case .fatFreeMass: "Fat-free mass"
        case .skeletalMuscle: "Skeletal muscle"
        case .subcutaneousFat: "Subcutaneous fat"
        case .bodyWater: "Body water"
        case .protein: "Protein"
        case .boneMass: "Bone mass"
        case .bmr: "BMR"
        case .metabolicAge: "Metabolic age"
        }
    }

    /// Short label for the picker chips.
    var shortTitle: String {
        switch self {
        case .muscleMass: "Muscle"
        case .fatFreeMass: "Fat-free"
        case .skeletalMuscle: "Skeletal"
        case .subcutaneousFat: "Subcut. fat"
        case .bodyWater: "Water"
        case .protein: "Protein"
        case .boneMass: "Bone"
        case .bmr: "BMR"
        case .metabolicAge: "Met. age"
        }
    }

    var unit: String {
        switch self {
        case .muscleMass, .fatFreeMass, .boneMass: "lb"
        case .skeletalMuscle, .subcutaneousFat, .bodyWater, .protein: "%"
        case .bmr: "kcal"
        case .metabolicAge: "yrs"
        }
    }

    var digits: Int {
        switch self {
        case .bmr, .metabolicAge: 0
        default: 1
        }
    }

    /// Whether going up is good news (nil when neither direction is clearly better).
    var higherIsBetter: Bool? {
        switch self {
        case .muscleMass, .fatFreeMass, .skeletalMuscle, .protein, .bmr: true
        case .subcutaneousFat, .metabolicAge: false
        case .bodyWater, .boneMass: nil
        }
    }

    func value(_ measurement: BodyMeasurement) -> Double? {
        switch self {
        case .muscleMass: measurement.muscleMassLbs
        case .fatFreeMass: measurement.fatFreeMassLbs
        case .skeletalMuscle: measurement.skeletalMusclePercent
        case .subcutaneousFat: measurement.subcutaneousFatPercent
        case .bodyWater: measurement.bodyWaterPercent
        case .protein: measurement.proteinPercent
        case .boneMass: measurement.boneMassLbs
        case .bmr: measurement.bmrKcal
        case .metabolicAge: measurement.metabolicAge.map(Double.init)
        }
    }
}

// MARK: - Where you stand (smart scale extras)

extension CompositionMetric {
    /// What the number means, shown under its chart.
    var explanation: String {
        switch self {
        case .muscleMass:
            "All the muscle in your body, including the water inside it. The range is based on your height."
        case .fatFreeMass:
            "Everything that isn't fat: muscle, bone, organs and water. There's no healthy range for it, but if it holds steady while your weight drops, you're losing fat, not muscle."
        case .skeletalMuscle:
            "The muscles you train, as a share of your body weight."
        case .subcutaneousFat:
            "Fat stored just under the skin, the kind you can pinch. Lower is better."
        case .bodyWater:
            "How much of you is water. It dips when you're dehydrated, and creatine can nudge it up."
        case .protein:
            "Protein in your body, mostly in your muscles."
        case .boneMass:
            "Estimated weight of your bones. It barely changes, so a flat line is normal."
        case .bmr:
            "Calories your body burns in a day at complete rest. There's no healthy range: it mostly reflects your size, and gaining muscle raises it a little."
        case .metabolicAge:
            "Your BMR compared with the average person at each age. Under your real age is a good sign."
        }
    }

    /// Renpho's standard ranges for this measurement, or nil when there isn't a meaningful one.
    func bands(ranges: BodyFatRanges, heightInches: Double?, weightLbs: Double?, age: Int?) -> [RangeBand]? {
        let male = ranges == .male

        // For measurements where higher is fine (muscle, protein): low is the one to watch.
        func standard(_ low: Double, _ high: Double, below: Double, above: Double, highColor: Color = Theme.green.opacity(0.65)) -> [RangeBand] {
            [
                RangeBand(label: "Low", range: below...low, color: Theme.teal),
                RangeBand(label: "Standard", range: low...high, color: Theme.green),
                RangeBand(label: "High", range: high...above, color: highColor),
            ]
        }

        switch self {
        case .skeletalMuscle:
            return male ? standard(49, 59, below: 40, above: 65) : standard(40, 50, below: 31, above: 56)
        case .subcutaneousFat:
            return male
                ? standard(8.6, 16.7, below: 4, above: 25, highColor: Theme.blue)
                : standard(18.5, 26.7, below: 12, above: 35, highColor: Theme.blue)
        case .bodyWater:
            return male
                ? standard(55, 65, below: 45, above: 70, highColor: Theme.teal)
                : standard(45, 60, below: 35, above: 65, highColor: Theme.teal)
        case .protein:
            return standard(16, 20, below: 12, above: 24)
        case .muscleMass:
            guard let heightInches else { return nil }
            let cm = heightInches * 2.54
            let kg: ClosedRange<Double> = male
                ? (cm < 160 ? 38.5...46.5 : cm <= 170 ? 44...52.4 : 49.4...59.4)
                : (cm < 150 ? 29.1...34.7 : cm <= 160 ? 32.9...37.5 : 36.5...42.5)
            let low = kg.lowerBound * 2.2046, high = kg.upperBound * 2.2046
            return standard(low, high, below: low - 20, above: high + 25)
        case .boneMass:
            guard let weightLbs else { return nil }
            let kg = weightLbs / 2.2046
            let typicalKg = male
                ? (kg < 60 ? 2.5 : kg <= 75 ? 2.9 : 3.2)
                : (kg < 45 ? 1.8 : kg <= 60 ? 2.2 : 2.5)
            let typical = typicalKg * 2.2046
            return standard(typical - 0.5, typical + 0.5, below: typical - 2, above: typical + 2, highColor: Theme.teal)
        case .metabolicAge:
            guard let age else { return nil }
            let years = Double(age)
            return [
                RangeBand(label: "Younger", range: (years - 15)...(years - 2), color: Theme.green),
                RangeBand(label: "About your age", range: (years - 2)...(years + 2), color: Theme.green.opacity(0.65)),
                RangeBand(label: "Older", range: (years + 2)...(years + 15), color: Theme.blue),
            ]
        case .fatFreeMass, .bmr:
            return nil
        }
    }

    /// The words shown next to "Where you stand" for a band.
    func statusText(forBand label: String) -> String {
        switch (self, label) {
        case (.metabolicAge, "Younger"): "Younger than you"
        case (.metabolicAge, "Older"): "Older than you"
        case (.metabolicAge, _): "About your age"
        default: "\(label) range"
        }
    }
}

private struct ChartPoint: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}

/// The smart scale extras: a chart for the chosen measurement, then the latest of each.
struct BodyCompositionCard: View {
    /// Weigh-ins with extras, oldest first.
    let measurements: [BodyMeasurement]
    let age: Int?
    /// The chart shows entries from here on (the screen's time range).
    let rangeStart: Date
    let domainStart: Date
    /// Off on the Scale readings page, which only shows the latest numbers
    /// (the Body card on Progress has the charts).
    var showsChart = true
    let onAdd: () -> Void

    @State private var selected: CompositionMetric = .muscleMass

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    /// Measurements that have been logged at least once.
    private var loggedMetrics: [CompositionMetric] {
        CompositionMetric.allCases.filter { metric in
            measurements.contains { metric.value($0) != nil }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Body composition", systemImage: "figure.stand")
                    .font(.headline)
                    .foregroundStyle(Theme.blue)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(Theme.blue)
            }

            if loggedMetrics.isEmpty {
                Text("If your smart scale measures more than weight and body fat (muscle mass, fat-free mass, body water, BMR and so on), log those numbers on weigh-in day to chart them here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                if showsChart {
                    metricPicker
                    chart(for: loggedMetrics.contains(selected) ? selected : loggedMetrics[0])
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(loggedMetrics) { metric in
                        tile(metric)
                    }
                }

                if let latest = measurements.last {
                    Text("Latest from \(latest.date.formatted(.dateTime.month(.abbreviated).day())). Changes are since your first entry.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle()
        .onAppear {
            if !loggedMetrics.contains(selected), let first = loggedMetrics.first {
                selected = first
            }
        }
    }

    // MARK: - Chart

    private var metricPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(loggedMetrics) { metric in
                    let isOn = metric == selected
                    Button {
                        selected = metric
                    } label: {
                        Text(metric.shortTitle)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(isOn ? .white : Theme.blue)
                            .background(isOn ? AnyShapeStyle(Theme.blue) : AnyShapeStyle(Theme.blue.opacity(0.12)), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .animation(.snappy, value: selected)
    }

    @ViewBuilder
    private func chart(for metric: CompositionMetric) -> some View {
        let points: [ChartPoint] = measurements
            .filter { $0.date >= rangeStart }
            .compactMap { measurement in metric.value(measurement).map { ChartPoint(date: measurement.date, value: $0) } }

        if points.count < 2 {
            Text(points.isEmpty
                 ? "No \(metric.title.lowercased()) entries in this time range."
                 : "Log \(metric.title.lowercased()) on another weigh-in to see the trend.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 80)
        } else {
            let values = points.map(\.value)
            let low = values.min() ?? 0
            let high = values.max() ?? 1
            let padding = max((high - low) * 0.25, metric.digits == 0 ? 1 : 0.5)

            Chart(points) { point in
                LineMark(x: .value("Date", point.date), y: .value(metric.title, point.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Theme.blue)
                PointMark(x: .value("Date", point.date), y: .value(metric.title, point.value))
                    .foregroundStyle(Theme.blue)
                    .symbolSize(30)
            }
            .chartXScale(domain: domainStart...Date.now)
            .chartYScale(domain: (low - padding)...(high + padding))
            .chartYAxisLabel(metric.unit)
            .frame(height: 160)
        }
    }

    // MARK: - Tiles

    private func tile(_ metric: CompositionMetric) -> some View {
        let values = measurements.compactMap { metric.value($0) }
        let latest = values.last
        let first = values.first

        return Button {
            selected = metric
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let latest {
                    Text("\(format(latest, metric.digits)) \(metric.unit)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(.primary)

                    if let first, values.count > 1 {
                        let change = latest - first
                        Text(changeText(change, digits: metric.digits, unit: metric.unit))
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(changeColor(change, metric: metric))
                    }
                }

                if metric == .metabolicAge, let age {
                    Text("Your age: \(age)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                if showsChart && metric == selected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.blue.opacity(0.5), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func changeColor(_ change: Double, metric: CompositionMetric) -> Color {
        guard abs(change) >= 0.05, let higherIsBetter = metric.higherIsBetter else { return .secondary }
        let improving = higherIsBetter ? change > 0 : change < 0
        return improving ? Theme.green : .secondary
    }

    private func format(_ value: Double, _ digits: Int) -> String {
        value.formatted(.number.precision(.fractionLength(digits)))
    }

    private func changeText(_ change: Double, digits: Int, unit: String) -> String {
        if abs(change) < 0.05 { return "No change" }
        return (change > 0 ? "+" : "−") + "\(format(abs(change), digits)) \(unit)"
    }
}
