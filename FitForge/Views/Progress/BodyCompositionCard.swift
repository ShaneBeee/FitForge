import SwiftUI
import SwiftData

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

/// Muscle mass, skeletal muscle, BMR and metabolic age from the scale extras.
struct BodyCompositionCard: View {
    /// Weigh-ins with extras, oldest first.
    let measurements: [BodyMeasurement]
    let age: Int?
    let onAdd: () -> Void

    private var first: BodyMeasurement? { measurements.first }
    private var latest: BodyMeasurement? { measurements.last }

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

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

            if let latest {
                LazyVGrid(columns: columns, spacing: 10) {
                    tile("Muscle mass", latest.muscleMassLbs, first?.muscleMassLbs, unit: "lb", higherIsBetter: true)
                    tile("Skeletal muscle", latest.skeletalMusclePercent, first?.skeletalMusclePercent, unit: "%", higherIsBetter: true)
                    tile("BMR", latest.bmrKcal, first?.bmrKcal, unit: "kcal", digits: 0, higherIsBetter: true)
                    tile("Metabolic age", latest.metabolicAge.map(Double.init), first?.metabolicAge.map(Double.init),
                         unit: "yrs", digits: 0, higherIsBetter: false,
                         footnote: age.map { "Your age: \($0)" })
                }

                Text("From your weigh-in on \(latest.date.formatted(.dateTime.month(.abbreviated).day())). Changes are since your first entry.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("If your smart scale measures more than weight and body fat (visceral fat, muscle mass, skeletal muscle, BMR or metabolic age), log those numbers on weigh-in day to track them here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private func tile(
        _ title: String,
        _ value: Double?,
        _ firstValue: Double?,
        unit: String,
        digits: Int = 1,
        higherIsBetter: Bool,
        footnote: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let value {
                Text("\(format(value, digits)) \(unit)")
                    .font(.title3.weight(.bold).monospacedDigit())

                if let firstValue, measurements.count > 1 {
                    let change = value - firstValue
                    let improving = higherIsBetter ? change > 0 : change < 0
                    Text(changeText(change, digits: digits, unit: unit))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(abs(change) < 0.05 ? Color.secondary : (improving ? Theme.green : Color.secondary))
                }
            } else {
                Text("—")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            if let footnote {
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func format(_ value: Double, _ digits: Int) -> String {
        value.formatted(.number.precision(.fractionLength(digits)))
    }

    private func changeText(_ change: Double, digits: Int, unit: String) -> String {
        if abs(change) < 0.05 { return "No change" }
        return (change > 0 ? "+" : "−") + "\(format(abs(change), digits)) \(unit)"
    }
}
