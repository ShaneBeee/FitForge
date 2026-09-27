import SwiftUI
import SwiftData

/// Progress section for tape measurements: latest values with changes, and a chart for one site.
struct MeasurementsSection: View {
    let profile: UserProfile
    let entries: [TapeMeasurement]      // oldest first
    let domainStart: Date
    let onAdd: () -> Void

    @State private var chartSite: MeasureSite?

    /// Tracked sites that have at least one entry.
    private var sitesWithData: [MeasureSite] {
        profile.trackedSites.filter { site in entries.contains { $0.site == site } }
    }

    private var activeSite: MeasureSite? {
        if let chartSite, sitesWithData.contains(chartSite) { return chartSite }
        return sitesWithData.first
    }

    private var latestDate: Date? { entries.last?.date }

    /// Days since the last measurement.
    private var daysSinceLast: Int? {
        latestDate.flatMap { Calendar.current.dateComponents([.day], from: $0, to: .now).day }
    }

    var body: some View {
        VStack(spacing: 16) {
            summaryCard

            if let site = activeSite {
                if sitesWithData.count > 1 {
                    sitePicker
                }
                MetricChartCard(
                    title: site.title,
                    systemImage: "ruler",
                    unit: "in",
                    readings: readings(for: site, since: domainStart),
                    start: entries.first(where: { $0.site == site })?.inches,
                    goal: nil,
                    tint: Theme.teal,
                    domainStart: domainStart
                )
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Measurements", systemImage: "ruler")
                    .font(.headline)
                    .foregroundStyle(Theme.teal)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(Theme.teal)
            }

            if sitesWithData.isEmpty {
                Text("Measuring your belly, waist, chest and arms every few weeks shows changes the scale can miss, like losing belly fat while building muscle.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sitesWithData) { site in
                    summaryRow(site)
                }
                if let daysSinceLast {
                    Text(daysSinceLast >= 28 ? "It's been \(daysSinceLast) days — time for a new set of measurements." : "Last measured \(daysSinceLast == 0 ? "today" : "\(daysSinceLast) day\(daysSinceLast == 1 ? "" : "s") ago"). Changes are since your first measurement.")
                        .font(.caption)
                        .foregroundStyle(daysSinceLast >= 28 ? Theme.teal : .secondary)
                }
            }
        }
        .cardStyle()
    }

    private func summaryRow(_ site: MeasureSite) -> some View {
        let siteEntries = entries.filter { $0.site == site }
        let latest = siteEntries.last?.inches ?? 0
        let first = siteEntries.first?.inches ?? latest
        let change = latest - first

        return HStack {
            Text(site.title)
            Spacer()
            if siteEntries.count > 1 && abs(change) >= 0.05 {
                Text(changeText(change))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isGood(change, for: site) ? Theme.green : Color.secondary)
            }
            Text("\(latest.formatted(.number.precision(.fractionLength(0...2)))) in")
                .fontWeight(.semibold)
                .frame(minWidth: 64, alignment: .trailing)
        }
        .monospacedDigit()
    }

    private var sitePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sitesWithData) { site in
                    let isSelected = site == activeSite
                    Button(site.title) { chartSite = site }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .background(
                            isSelected ? AnyShapeStyle(Theme.teal) : AnyShapeStyle(.background.secondary),
                            in: Capsule()
                        )
                        .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private func readings(for site: MeasureSite, since start: Date) -> [HealthKitManager.Reading] {
        entries
            .filter { $0.site == site && $0.date >= start }
            .map { HealthKitManager.Reading(value: $0.inches, date: $0.date) }
    }

    private func changeText(_ change: Double) -> String {
        (change > 0 ? "+" : "−") + abs(change).formatted(.number.precision(.fractionLength(0...2))) + " in"
    }

    private func isGood(_ change: Double, for site: MeasureSite) -> Bool {
        switch site.goodDirection {
        case .smaller: change < 0
        case .bigger: change > 0
        case .neutral: false
        }
    }
}

/// Body fat two ways: the smart scale reading and the tape-measure (US Navy) estimate.
struct TapeBodyFatCard: View {
    let profile: UserProfile
    let entries: [TapeMeasurement]     // oldest first
    let scaleBodyFat: Double?
    let onAdd: () -> Void

    private func latest(_ site: MeasureSite) -> Double? {
        entries.last(where: { $0.site == site })?.inches
    }

    private var estimate: Double? {
        guard let ranges = profile.bodyFatRanges, let height = profile.heightInches else { return nil }
        return TapeBodyFat.estimate(
            ranges: ranges,
            heightInches: height,
            neck: latest(.neck),
            belly: latest(.belly),
            waist: latest(.waist),
            hips: latest(.hips)
        )
    }

    private var missingSites: [MeasureSite] {
        guard let ranges = profile.bodyFatRanges else { return [] }
        return TapeBodyFat.requiredSites(for: ranges).filter { latest($0) == nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Body fat, two ways", systemImage: "arrow.left.arrow.right")
                .font(.headline)
                .foregroundStyle(Theme.green)

            if let estimate {
                HStack(spacing: 10) {
                    value("Smart scale", scaleBodyFat)
                    value("Tape measure", estimate)
                }
                Text("Two completely different methods. Neither is perfect, but if both trend down together, the progress is real.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if profile.bodyFatRanges == nil {
                Text("Choose male or female body fat ranges (on the body fat card above, or in Profile) to get a tape-measure estimate.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Add your \(missingSites.map { $0.title.lowercased() }.joined(separator: " and ")) measurement\(missingSites.count == 1 ? "" : "s") to see a body fat estimate from a tape measure, as a cross-check on your scale.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Add measurements", action: onAdd)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(Theme.green)
            }
        }
        .cardStyle()
    }

    private func value(_ title: String, _ percent: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(percent.map { "\($0.formatted(.number.precision(.fractionLength(1))))%" } ?? "—")
                .font(.title2.weight(.bold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
