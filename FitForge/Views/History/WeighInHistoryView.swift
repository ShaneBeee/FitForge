import SwiftUI

/// Weigh-ins from Apple Health, newest first, with the change since the one before.
struct WeighInHistoryView: View {
    @Environment(HealthKitManager.self) private var health

    private struct WeighIn: Identifiable {
        let date: Date
        let weight: Double?
        let bodyFat: Double?
        var id: Date { date }
    }

    @State private var weighIns: [WeighIn] = []
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if hasLoaded && weighIns.isEmpty {
                Text("No weigh-ins found in Apple Health for the past year.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(weighIns.enumerated()), id: \.element.id) { index, weighIn in
                    let previous = index + 1 < weighIns.count ? weighIns[index + 1] : nil
                    row(weighIn, previous: previous)
                }
            }
        }
        .task { await load() }
    }

    private func row(_ weighIn: WeighIn, previous: WeighIn?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(weighIn.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.subheadline.weight(.semibold))
                Text(weighIn.date, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let weight = weighIn.weight {
                    HStack(spacing: 6) {
                        if let change = change(weighIn.weight, previous?.weight) {
                            Text(change + " lb")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("\(format(weight)) lb")
                            .fontWeight(.semibold)
                    }
                }
                if let bodyFat = weighIn.bodyFat {
                    HStack(spacing: 6) {
                        if let change = change(weighIn.bodyFat, previous?.bodyFat) {
                            Text(change + "%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("\(format(bodyFat))%")
                            .font(.subheadline)
                            .foregroundStyle(Theme.green)
                    }
                }
            }
            .monospacedDigit()
        }
    }

    private func change(_ current: Double?, _ previous: Double?) -> String? {
        guard let current, let previous else { return nil }
        let difference = current - previous
        guard abs(difference) >= 0.05 else { return "±0.0" }
        return (difference > 0 ? "+" : "−") + format(abs(difference))
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    private func load() async {
        let start = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
        let weights = await health.weightHistory(since: start)
        let bodyFats = await health.bodyFatHistory(since: start)

        // Merge weight and body fat readings taken on the same day.
        var byDay: [Date: (date: Date, weight: Double?, bodyFat: Double?)] = [:]
        for reading in weights {
            let day = Calendar.current.startOfDay(for: reading.date)
            byDay[day] = (reading.date, reading.value, byDay[day]?.bodyFat)
        }
        for reading in bodyFats {
            let day = Calendar.current.startOfDay(for: reading.date)
            byDay[day] = (byDay[day]?.date ?? reading.date, byDay[day]?.weight, reading.value)
        }

        weighIns = byDay.values
            .map { WeighIn(date: $0.date, weight: $0.weight, bodyFat: $0.bodyFat) }
            .sorted { $0.date > $1.date }
        hasLoaded = true
    }
}
