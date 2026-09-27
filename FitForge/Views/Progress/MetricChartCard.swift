import SwiftUI
import Charts

/// A metric chart (weight or body fat) with goal line, change chips and goal progress.
struct MetricChartCard: View {
    let title: String
    let systemImage: String
    let unit: String
    let readings: [HealthKitManager.Reading]
    let start: Double?
    let goal: Double?
    let tint: Color
    let domainStart: Date

    @State private var selectedDate: Date?

    private var latest: HealthKitManager.Reading? { readings.last }

    private var selected: HealthKitManager.Reading? {
        guard let selectedDate else { return nil }
        return readings.min {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if readings.isEmpty {
                Text("No readings in this time range.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                chart
                    .frame(height: 220)
            }

            changeChips
            goalProgress
        }
        .cardStyle()
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
            Spacer()
            if let latest {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(Self.format(latest.value)) \(unit)")
                        .font(.title2.weight(.bold).monospacedDigit())
                    Text(latest.date, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            if let goal {
                RuleMark(y: .value("Goal", goal))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(Theme.green)
                    .annotation(position: .top, alignment: .leading) {
                        Text("Goal \(Self.format(goal)) \(unit)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.green)
                    }
            }

            ForEach(readings, id: \.date) { reading in
                LineMark(
                    x: .value("Date", reading.date),
                    y: .value(title, reading.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(tint)

                PointMark(
                    x: .value("Date", reading.date),
                    y: .value(title, reading.value)
                )
                .foregroundStyle(tint)
                .symbolSize(readings.count > 40 ? 10 : 36)
            }

            if let selected {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        VStack(spacing: 2) {
                            Text("\(Self.format(selected.value)) \(unit)")
                                .font(.caption.weight(.bold).monospacedDigit())
                            Text(selected.date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
            }
        }
        .chartYScale(domain: yDomain)
        .chartXScale(domain: domainStart...Date.now)
        .chartXSelection(value: $selectedDate)
    }

    private var yDomain: ClosedRange<Double> {
        var values = readings.map(\.value)
        if let goal { values.append(goal) }
        guard let low = values.min(), let high = values.max() else { return 0...1 }
        let padding = max((high - low) * 0.15, 1)
        return (low - padding)...(high + padding)
    }

    // MARK: - Change

    @ViewBuilder
    private var changeChips: some View {
        if let latest {
            HStack(spacing: 8) {
                if let start {
                    changeChip("Since start", latest.value - start)
                }
                if let monthAgo = readings.last(where: { $0.date <= Date.now.addingTimeInterval(-28 * 86_400) }) {
                    changeChip("Last 4 weeks", latest.value - monthAgo.value)
                }
            }
        }
    }

    private func changeChip(_ label: String, _ change: Double) -> some View {
        let towardGoal: Bool = {
            guard let goal, let start, abs(change) >= 0.05 else { return false }
            return goal < start ? change < 0 : change > 0
        }()
        let sign = change > 0.05 ? "+" : (change < -0.05 ? "−" : "")

        return VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(sign)\(Self.format(abs(change))) \(unit)")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(towardGoal ? Theme.green : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Goal progress

    @ViewBuilder
    private var goalProgress: some View {
        if let start, let goal, let latest, abs(start - goal) > 0.01 {
            let fraction = min(max((start - latest.value) / (start - goal), 0), 1)
            let remaining = abs(latest.value - goal)

            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: fraction)
                    .tint(Theme.green)
                HStack {
                    Text("\(Int((fraction * 100).rounded()))% of the way to your goal")
                    Spacer()
                    Text(fraction >= 1 ? "Goal reached!" : "\(Self.format(remaining)) \(unit) to go")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
    }

    static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }
}
