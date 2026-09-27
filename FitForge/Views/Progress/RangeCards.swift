import SwiftUI
import SwiftData

// "Where you stand" cards: weight, body fat and BMI shown against their ranges.

struct RangeBand: Identifiable {
    let label: String
    let range: ClosedRange<Double>
    let color: Color
    var id: String { label }
}

/// A segmented bar with a marker for the current value and a green tick for the goal.
struct RangeBar: View {
    let bands: [RangeBand]
    let value: Double
    var goal: Double? = nil

    private let gap: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            VStack(spacing: 6) {
                ZStack(alignment: .leading) {
                    HStack(spacing: gap) {
                        ForEach(bands) { band in
                            band.color
                                .frame(width: bandWidth(band, total: width))
                        }
                    }
                    .frame(height: 12)
                    .clipShape(Capsule())

                    if let goal {
                        Capsule()
                            .fill(Theme.green)
                            .overlay(Capsule().stroke(.white, lineWidth: 1))
                            .frame(width: 4, height: 24)
                            .offset(x: x(for: goal, total: width) - 2)
                    }

                    Circle()
                        .fill(.white)
                        .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 1))
                        .frame(width: 20, height: 20)
                        .shadow(radius: 2)
                        .offset(x: x(for: value, total: width) - 10)
                }
                .frame(height: 24)

                HStack(spacing: gap) {
                    ForEach(bands) { band in
                        Text(band.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(width: bandWidth(band, total: width))
                    }
                }
            }
        }
        .frame(height: 46)
    }

    private var span: Double {
        (bands.last?.range.upperBound ?? 1) - (bands.first?.range.lowerBound ?? 0)
    }

    private func bandWidth(_ band: RangeBand, total: CGFloat) -> CGFloat {
        let usable = total - gap * CGFloat(max(bands.count - 1, 0))
        return max(0, usable * (band.range.upperBound - band.range.lowerBound) / span)
    }

    /// Horizontal position of a value, accounting for the gaps between bands.
    private func x(for value: Double, total: CGFloat) -> CGFloat {
        guard let first = bands.first, let last = bands.last else { return 0 }
        if value <= first.range.lowerBound { return 0 }
        if value >= last.range.upperBound { return total }

        var position: CGFloat = 0
        for band in bands {
            let bandW = bandWidth(band, total: total)
            if value <= band.range.upperBound {
                let fraction = (value - band.range.lowerBound) / (band.range.upperBound - band.range.lowerBound)
                return position + bandW * fraction
            }
            position += bandW + gap
        }
        return total
    }

    /// The band a value falls in (values past either end count as the end band).
    static func band(for value: Double, in bands: [RangeBand]) -> RangeBand? {
        bands.first { value < $0.range.upperBound } ?? bands.last
    }
}

/// Shared card layout for the range cards.
struct RangeCard<Extra: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    let valueText: String
    let statusText: String
    let bands: [RangeBand]
    let value: Double
    var goal: Double? = nil
    var goalText: String? = nil
    var note: String? = nil
    @ViewBuilder var extra: Extra

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(valueText)
                        .font(.title2.weight(.bold).monospacedDigit())
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            RangeBar(bands: bands, value: value, goal: goal)

            if let goalText {
                HStack(spacing: 6) {
                    Capsule()
                        .fill(Theme.green)
                        .frame(width: 4, height: 12)
                    Text(goalText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.green)
                }
            }

            extra

            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }
}

extension RangeCard where Extra == EmptyView {
    init(title: String, systemImage: String, tint: Color, valueText: String, statusText: String,
         bands: [RangeBand], value: Double, goal: Double? = nil, goalText: String? = nil, note: String? = nil) {
        self.init(title: title, systemImage: systemImage, tint: tint, valueText: valueText, statusText: statusText,
                  bands: bands, value: value, goal: goal, goalText: goalText, note: note) { EmptyView() }
    }
}

private func format(_ value: Double, digits: Int = 1) -> String {
    value.formatted(.number.precision(.fractionLength(digits)))
}

// MARK: - Weight

/// Weight against the healthy range for your height (BMI 18.5–25, shown in pounds).
struct WeightRangeCard: View {
    let weightLbs: Double
    let heightInches: Double
    let goalLbs: Double?

    private func pounds(atBMI bmi: Double) -> Double {
        bmi * heightInches * heightInches / 703
    }

    private var bands: [RangeBand] {
        [
            RangeBand(label: "Under", range: pounds(atBMI: 16)...pounds(atBMI: 18.5), color: Theme.teal),
            RangeBand(label: "Healthy", range: pounds(atBMI: 18.5)...pounds(atBMI: 25), color: Theme.green),
            RangeBand(label: "Over", range: pounds(atBMI: 25)...pounds(atBMI: 30), color: Theme.blue),
            RangeBand(label: "Obesity", range: pounds(atBMI: 30)...pounds(atBMI: 35), color: Theme.blue.opacity(0.6)),
        ]
    }

    private var heightText: String {
        let total = Int(heightInches.rounded())
        return "\(total / 12)′\(total % 12)″"
    }

    static func statusText(for band: String) -> String {
        switch band {
        case "Under": "Underweight range"
        case "Over": "Overweight range"
        default: "\(band) range"
        }
    }

    var body: some View {
        let status = RangeBar.band(for: weightLbs, in: bands)?.label ?? ""
        let healthyLow = Int(pounds(atBMI: 18.5).rounded())
        let healthyHigh = Int(pounds(atBMI: 25).rounded(.down))

        RangeCard(
            title: "Weight",
            systemImage: "scalemass.fill",
            tint: Theme.blue,
            valueText: "\(format(weightLbs)) lb",
            statusText: Self.statusText(for: status),
            bands: bands,
            value: weightLbs,
            goal: goalLbs,
            goalText: goalLbs.map { "Your goal: \(format($0)) lb" },
            note: "Healthy weight for \(heightText): about \(healthyLow)–\(healthyHigh) lb."
        )
    }
}

// MARK: - Body fat

/// Body fat against the American Council on Exercise categories.
struct BodyFatRangeCard: View {
    @Environment(\.modelContext) private var context
    let profile: UserProfile
    let bodyFatPercent: Double
    let goalPercent: Double?

    private func bands(for ranges: BodyFatRanges) -> [RangeBand] {
        switch ranges {
        case .male:
            [
                RangeBand(label: "Essential", range: 2...6, color: Theme.teal),
                RangeBand(label: "Athletic", range: 6...14, color: Theme.green),
                RangeBand(label: "Fit", range: 14...18, color: Theme.green.opacity(0.65)),
                RangeBand(label: "Average", range: 18...25, color: Theme.blue),
                RangeBand(label: "High", range: 25...35, color: Theme.blue.opacity(0.6)),
            ]
        case .female:
            [
                RangeBand(label: "Essential", range: 10...14, color: Theme.teal),
                RangeBand(label: "Athletic", range: 14...21, color: Theme.green),
                RangeBand(label: "Fit", range: 21...25, color: Theme.green.opacity(0.65)),
                RangeBand(label: "Average", range: 25...32, color: Theme.blue),
                RangeBand(label: "High", range: 32...42, color: Theme.blue.opacity(0.6)),
            ]
        }
    }

    var body: some View {
        if let ranges = profile.bodyFatRanges {
            let bands = bands(for: ranges)
            let status = RangeBar.band(for: bodyFatPercent, in: bands)?.label ?? ""

            RangeCard(
                title: "Body fat",
                systemImage: "percent",
                tint: Theme.green,
                valueText: "\(format(bodyFatPercent))%",
                statusText: "\(status) range",
                bands: bands,
                value: bodyFatPercent,
                goal: goalPercent,
                goalText: goalPercent.map { "Your goal: \(format($0))%" },
                note: "Ranges from the American Council on Exercise (\(ranges.title.lowercased()))."
            )
        } else {
            chooser
        }
    }

    private var chooser: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Body fat ranges", systemImage: "percent")
                .font(.headline)
                .foregroundStyle(Theme.green)
            Text("Healthy body fat ranges are different for men and women. Which ranges should FitForge show you?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(BodyFatRanges.allCases) { option in
                    ChipButton(title: option.title, isSelected: false) {
                        withAnimation(.snappy) {
                            profile.bodyFatRanges = option
                            try? context.save()
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - BMI

/// BMI from your latest weight and height.
struct BMICard: View {
    let weightLbs: Double
    let heightInches: Double
    let goalWeightLbs: Double?

    private func bmi(for pounds: Double) -> Double {
        703 * pounds / (heightInches * heightInches)
    }

    private let bands: [RangeBand] = [
        RangeBand(label: "Under", range: 16...18.5, color: Theme.teal),
        RangeBand(label: "Healthy", range: 18.5...25, color: Theme.green),
        RangeBand(label: "Over", range: 25...30, color: Theme.blue),
        RangeBand(label: "Obesity", range: 30...35, color: Theme.blue.opacity(0.6)),
    ]

    var body: some View {
        let value = bmi(for: weightLbs)
        let status = RangeBar.band(for: value, in: bands)?.label ?? ""
        let goal = goalWeightLbs.map { bmi(for: $0) }

        RangeCard(
            title: "BMI",
            systemImage: "figure.stand",
            tint: Theme.teal,
            valueText: format(value),
            statusText: WeightRangeCard.statusText(for: status),
            bands: bands,
            value: value,
            goal: goal,
            goalText: goal.map { "BMI at your goal weight: \(format($0))" },
            note: "BMI only looks at height and weight, so it can't tell muscle from fat. Your body fat % is the better measure of progress."
        )
    }
}
