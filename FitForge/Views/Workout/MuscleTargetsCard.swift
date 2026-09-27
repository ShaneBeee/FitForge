import SwiftUI

/// Shows which muscle groups a workout hits, laid out by body region.
/// Worked muscles are highlighted; the rest are dimmed, so it's easy to see the day is full-body.
struct MuscleTargetsCard: View {
    let muscles: [MuscleGroup]
    var subtitle: String = DayKind.fullBody.description

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 6)]

    private var regions: [(title: String, groups: [MuscleGroup])] {
        [
            ("Upper body", MuscleGroup.allCases.filter(\.isUpperBody)),
            ("Core", [.abs, .lowerBack]),
            ("Lower body", MuscleGroup.allCases.filter(\.isLowerBody)),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Label("What this works", systemImage: "figure.arms.open")
                    .font(.headline)
                    .foregroundStyle(Theme.blue)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(regions, id: \.title) { region in
                VStack(alignment: .leading, spacing: 6) {
                    Text(region.title.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                        ForEach(region.groups) { group in
                            chip(group, isWorked: muscles.contains(group))
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private func chip(_ group: MuscleGroup, isWorked: Bool) -> some View {
        Text(group.title)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .padding(.horizontal, 6)
            .foregroundStyle(isWorked ? .white : .secondary)
            .background(
                isWorked ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(.background),
                in: Capsule()
            )
            .opacity(isWorked ? 1 : 0.6)
    }
}
