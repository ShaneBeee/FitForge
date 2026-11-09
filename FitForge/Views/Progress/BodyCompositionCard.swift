import SwiftUI
import SwiftData
import Charts

/// Visceral fat on the rating scale most smart scales use.
struct VisceralFatRangeCard: View {
    let rating: Double

    private let bands: [RangeBand] = [
        RangeBand(label: "Standard", range: 1...9.5, color: Theme.green),
        RangeBand(label: "High", range: 9.5...14.5, color: Theme.blue),
        RangeBand(label: "Excessive", range: 14.5...20, color: Theme.blue.opacity(0.6)),
    ]

    var body: some View {
        let status = RangeBar.band(for: rating, in: bands)?.label ?? ""

        RangeCard(
            title: "Visceral fat",
            systemImage: "target",
            tint: Theme.teal,
            valueText: rating.formatted(.number.precision(.fractionLength(0))),
            statusText: "\(status) range",
            bands: bands,
            value: rating,
            note: "A smart scale rating for fat stored deep around your organs, mostly in the belly. Lower is better, and it usually drops steadily with regular training."
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
                metricPicker
                chart(for: loggedMetrics.contains(selected) ? selected : loggedMetrics[0])

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
                if metric == selected {
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
