import SwiftUI

/// A single stat, e.g. "Weight · 178.2 lb · 2 days ago".
struct StatTile: View {
    let title: String
    let systemImage: String
    let value: String?
    let unit: String
    let date: Date?
    var tint: Color = Theme.blue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)

            if let value {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())
                    Text(unit)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No data yet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if let date {
                Text(date, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }
}

#Preview {
    HStack {
        StatTile(title: "Weight", systemImage: "scalemass.fill", value: "178.2", unit: "lb", date: .now.addingTimeInterval(-86_400))
        StatTile(title: "Body fat", systemImage: "percent", value: nil, unit: "%", date: nil, tint: Theme.green)
    }
    .padding()
}
