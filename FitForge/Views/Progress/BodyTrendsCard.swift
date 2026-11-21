import SwiftUI
import SwiftData

// The top of the Progress screen: the Goals card (weight and body fat progress at a glance)
// and the Body card (one chart, with chips to switch between every body metric).

/// Anything the Body card can chart.
enum BodyMetric: Hashable, Identifiable {
    case weight, bodyFat, visceral
    case composition(CompositionMetric)

    /// Stable text id for each chip.
    var id: String {
        switch self {
        case .weight: "weight"
        case .bodyFat: "bodyFat"
        case .visceral: "visceral"
        case .composition(let metric): metric.rawValue
        }
    }

    init?(id: String) {
        switch id {
        case "weight": self = .weight
        case "bodyFat": self = .bodyFat
        case "visceral": self = .visceral
        default:
            guard let metric = CompositionMetric(rawValue: id) else { return nil }
            self = .composition(metric)
        }
    }

    var chipTitle: String {
        switch self {
        case .weight: "Weight"
        case .bodyFat: "Body fat"
        case .visceral: "Visceral"
        case .composition(let metric): metric.shortTitle
        }
    }
}

/// The chip style used for every "pick one" row on the Progress screen, so they all look alike.
struct MetricChip: View {
    let title: String
    let isSelected: Bool
    var tint: Color = Theme.blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? .white : tint)
                .background(isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.14)), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Goals

/// Weight and body fat progress side by side. Tapping a row shows that metric in the Body chart.
struct GoalsCard: View {
    let weight: Double?
    let startWeight: Double?
    let goalWeight: Double?
    let bodyFat: Double?
    let startBodyFat: Double?
    let goalBodyFat: Double?
    let onSelect: (BodyMetric) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Your goals", systemImage: "flag.checkered")
                .font(.headline)
                .foregroundStyle(Theme.green)

            GoalRow(title: "Weight", unit: "lb", tint: Theme.blue,
                    current: weight, start: startWeight, goal: goalWeight) {
                onSelect(.weight)
            }

            Divider()

            GoalRow(title: "Body fat", unit: "%", tint: Theme.green,
                    current: bodyFat, start: startBodyFat, goal: goalBodyFat) {
                onSelect(.bodyFat)
            }
        }
        .cardStyle()
    }
}

private struct GoalRow: View {
    let title: String
    let unit: String
    let tint: Color
    let current: Double?
    let start: Double?
    let goal: Double?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)
                    Spacer()
                    if let current {
                        Text(text(current))
                            .font(.title3.weight(.bold).monospacedDigit())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                if let current, let start, let goal, abs(start - goal) > 0.01 {
                    let fraction = min(max((start - current) / (start - goal), 0), 1)
                    let change = current - start
                    let towardGoal = abs(change) >= 0.05 && (goal < start ? change < 0 : change > 0)

                    ProgressView(value: fraction)
                        .tint(Theme.green)

                    HStack {
                        Text(changeText(change) + " since start")
                            .foregroundStyle(towardGoal ? Theme.green : .secondary)
                        Spacer()
                        Text(fraction >= 1
                             ? "Goal reached!"
                             : "\(Int((fraction * 100).rounded()))% · \(text(abs(current - goal))) to go")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption.weight(.semibold).monospacedDigit())
                } else if goal == nil {
                    Text("Set a goal in Profile to track progress here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if current == nil {
                    Text("No readings yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func text(_ value: Double) -> String {
        let number = value.formatted(.number.precision(.fractionLength(1)))
        return unit == "%" ? "\(number)%" : "\(number) \(unit)"
    }

    private func changeText(_ change: Double) -> String {
        if abs(change) < 0.05 { return "No change" }
        return (change > 0 ? "+" : "−") + text(abs(change))
    }
}

// MARK: - Body

/// One chart for every body metric: weight, body fat, visceral fat and the smart scale extras.
/// Under the chart: where you stand for that metric, plus BMI (weight) or the tape-measure cross-check (body fat).
struct BodyTrendsCard: View {
    let profile: UserProfile
    /// Readings within the chosen time range.
    let weights: [HealthKitManager.Reading]
    let bodyFats: [HealthKitManager.Reading]
    let latestWeight: Double?
    let latestBodyFat: Double?
    /// All weigh-ins with smart scale extras, oldest first.
    let extras: [BodyMeasurement]
    let tapeEntries: [TapeMeasurement]
    let age: Int?
    let rangeStart: Date
    let domainStart: Date
    @Binding var selection: BodyMetric
    let onAddMeasurements: () -> Void
    let onAddExtras: () -> Void

    /// Chips for metrics that have data (weight and body fat always show).
    private var available: [BodyMetric] {
        var metrics: [BodyMetric] = [.weight, .bodyFat]
        if extras.contains(where: { $0.visceralFat != nil }) {
            metrics.append(.visceral)
        }
        metrics += CompositionMetric.allCases
            .filter { metric in extras.contains { metric.value($0) != nil } }
            .map { .composition($0) }
        return metrics
    }

    private var active: BodyMetric {
        available.contains(selection) ? selection : .weight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Body", systemImage: "figure.stand")
                .font(.headline)
                .foregroundStyle(Theme.blue)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(available) { metric in
                        MetricChip(title: metric.chipTitle, isSelected: metric == active) {
                            selection = metric
                        }
                    }
                }
            }

            chart(for: active)
                .id(active.id)   // fresh chart (and tap selection) for each metric

            details(for: active)

            Divider()
            footer
        }
        .cardStyle()
        .animation(.snappy, value: active)
    }

    // MARK: - Chart

    @ViewBuilder
    private func chart(for metric: BodyMetric) -> some View {
        switch metric {
        case .weight:
            MetricChartCard(
                title: "Weight", systemImage: "scalemass.fill", unit: "lb",
                readings: weights, start: profile.startWeightLbs, goal: profile.targetWeightLbs,
                tint: Theme.blue, domainStart: domainStart,
                embedded: true, showsGoalProgress: false
            )
        case .bodyFat:
            MetricChartCard(
                title: "Body fat", systemImage: "percent", unit: "%",
                readings: bodyFats, start: profile.startBodyFatPercent, goal: profile.targetBodyFatPercent,
                tint: Theme.green, domainStart: domainStart,
                embedded: true, showsGoalProgress: false
            )
        case .visceral:
            MetricChartCard(
                title: "Visceral fat", systemImage: "target", unit: "",
                readings: readings { $0.visceralFat },
                start: extras.first(where: { $0.visceralFat != nil })?.visceralFat, goal: nil,
                tint: Theme.teal, domainStart: domainStart, fractionDigits: 0,
                embedded: true, higherIsBetter: false
            )
        case .composition(let composition):
            MetricChartCard(
                title: composition.title, systemImage: "figure.stand", unit: composition.unit,
                readings: readings { composition.value($0) },
                start: extras.lazy.compactMap { composition.value($0) }.first, goal: nil,
                tint: Theme.blue, domainStart: domainStart, fractionDigits: composition.digits,
                embedded: true, higherIsBetter: composition.higherIsBetter
            )
        }
    }

    /// Smart scale readings for one measurement, within the time range.
    private func readings(_ value: (BodyMeasurement) -> Double?) -> [HealthKitManager.Reading] {
        extras
            .filter { $0.date >= rangeStart }
            .compactMap { measurement in
                value(measurement).map { HealthKitManager.Reading(value: $0, date: measurement.date) }
            }
    }

    // MARK: - Under the chart

    @ViewBuilder
    private func details(for metric: BodyMetric) -> some View {
        let height = profile.heightInches ?? 0

        switch metric {
        case .weight:
            if let latestWeight, height > 0 {
                Divider()
                WeightRangeCard(weightLbs: latestWeight, heightInches: height,
                                goalLbs: profile.targetWeightLbs, compact: true)
                Divider()
                BMICard(weightLbs: latestWeight, heightInches: height,
                        goalWeightLbs: profile.targetWeightLbs, compact: true)
            }
        case .bodyFat:
            if let latestBodyFat {
                Divider()
                BodyFatRangeCard(profile: profile, bodyFatPercent: latestBodyFat,
                                 goalPercent: profile.targetBodyFatPercent, compact: true)
            }
            Divider()
            TapeBodyFatCard(profile: profile, entries: tapeEntries,
                            scaleBodyFat: latestBodyFat, embedded: true, onAdd: onAddMeasurements)
        case .visceral:
            if let rating = extras.last(where: { $0.visceralFat != nil })?.visceralFat {
                Divider()
                VisceralFatRangeCard(rating: rating, compact: true)
            }
        case .composition(let composition):
            Divider()
            compositionStanding(composition)
        }
    }

    /// Where you stand for a smart scale extra, or just what it means when there's no range for it.
    @ViewBuilder
    private func compositionStanding(_ composition: CompositionMetric) -> some View {
        let latest = extras.last(where: { composition.value($0) != nil }).flatMap { composition.value($0) }
        let bands = profile.bodyFatRanges.flatMap {
            composition.bands(ranges: $0, heightInches: profile.heightInches, weightLbs: latestWeight, age: age)
        }

        if let latest, let bands {
            let band = RangeBar.band(for: latest, in: bands)?.label ?? ""
            RangeCard(
                title: "Where you stand",
                systemImage: "figure.stand",
                tint: Theme.blue,
                valueText: "",
                statusText: composition.statusText(forBand: band),
                bands: bands,
                value: latest,
                note: composition.explanation + " Ranges are Renpho's standards, and smart scale readings are estimates.",
                compact: true
            )
        } else {
            Text(composition.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var footer: some View {
        if extras.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("If your smart scale also shows muscle, body water, visceral fat and so on, log them on weigh-in day to chart them here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Log scale extras", action: onAddExtras)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(Theme.blue)
            }
        } else {
            NavigationLink {
                ScaleReadingsView(age: age)
            } label: {
                HStack {
                    Label("See all scale readings", systemImage: "list.bullet")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.blue)
        }
    }
}

// MARK: - Scale readings page

/// Every smart scale number from your latest weigh-in, with the change since your first.
struct ScaleReadingsView: View {
    let age: Int?

    @Query(sort: \BodyMeasurement.date) private var measurements: [BodyMeasurement]
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            BodyCompositionCard(
                measurements: measurements.filter(\.hasExtras),
                age: age,
                rangeStart: .distantPast,
                domainStart: .distantPast,
                showsChart: false
            ) {
                showAdd = true
            }
            .padding()
        }
        .navigationTitle("Scale readings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) {
            WeighInExtrasSheet()
        }
    }
}
