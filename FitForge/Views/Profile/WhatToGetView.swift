import SwiftUI
import SwiftData

/// "What to get next": heavier weights you've outgrown, then the equipment that would add the
/// most for your goals and focus areas, with rough prices.
struct WhatToGetView: View {
    let profile: UserProfile
    @Query private var sessions: [WorkoutSession]

    private var heavier: [HeavierWeightAdvice] {
        EquipmentAdvisor.heavierWeights(for: profile, history: sessions)
    }

    private var suggestions: [EquipmentSuggestion] {
        EquipmentAdvisor.suggestions(for: profile)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !heavier.isEmpty {
                    sectionTitle("Time for heavier weights", systemImage: "arrow.up.circle.fill")
                    ForEach(heavier) { advice in
                        heavierCard(advice)
                    }
                }

                sectionTitle(heavier.isEmpty ? "Ideas for your setup" : "Other ideas", systemImage: "lightbulb.fill")
                if suggestions.isEmpty {
                    Text("Your setup already covers everything in the exercise library at your level. Nice.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .cardStyle()
                } else {
                    ForEach(suggestions) { suggestion in
                        suggestionCard(suggestion)
                    }
                }

                Text("Prices are rough, for new gear in Canada. Thrift stores and Marketplace are often much cheaper. After buying, add it in Profile → Equipment and your workouts update automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("What to get next")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pieces

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title3.weight(.bold))
            .foregroundStyle(Theme.blue)
    }

    private func heavierCard(_ advice: HeavierWeightAdvice) -> some View {
        let current = EquipmentItem.format(advice.currentMax)
        let next = EquipmentItem.format(advice.nextWeight)
        let unit = advice.kind == .dumbbells ? "lb pair" : "lb kettlebell"
        let names = advice.exercises.map(\.name)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: advice.kind.systemImage)
                    .font(.title2)
                    .foregroundStyle(Theme.gradient)
                VStack(alignment: .leading, spacing: 2) {
                    Text("You've outgrown your \(current) lb \(advice.kind == .dumbbells ? "dumbbells" : "kettlebell")")
                        .font(.headline)
                    Text("Top of the rep range, two workouts in a row")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Too light now for: \(names.joined(separator: ", ")). Until you get heavier ones, these use slow 3-second lowering and higher reps to keep you progressing.")
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 6) {
                optionRow(
                    title: "Next step: a \(next) \(unit)",
                    price: EquipmentAdvisor.priceRange(forWeight: advice.nextWeight, kind: advice.kind)
                )
                if advice.kind == .dumbbells {
                    optionRow(
                        title: "Or adjustable dumbbells (about 5–50 lb), to cover years of progress",
                        price: EquipmentAdvisor.priceRange(for: .dumbbells).replacingOccurrences(of: " adjustable", with: "")
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func optionRow(title: String, price: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "cart")
                .foregroundStyle(Theme.green)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 8)
            Text(price)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func suggestionCard(_ suggestion: EquipmentSuggestion) -> some View {
        let kind = suggestion.kind
        let count = suggestion.unlocks.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: kind.systemImage)
                    .font(.title2)
                    .foregroundStyle(Theme.gradient)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title)
                        .font(.headline)
                    Text(kind.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text(EquipmentAdvisor.priceRange(for: kind))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.blue)
            }

            Text(reason(for: suggestion))
                .font(.subheadline)

            FlowTags(items: suggestion.unlocks.prefix(6).map(\.name) + (count > 6 ? ["+\(count - 6) more"] : []))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func reason(for suggestion: EquipmentSuggestion) -> String {
        let count = suggestion.unlocks.count
        let adds = "Adds \(count) exercise\(count == 1 ? "" : "s") at your level"
        guard !suggestion.focusMatches.isEmpty else { return adds + "." }
        let areas = suggestion.focusMatches.map { $0.title.lowercased() }
        let list = areas.count == 1 ? areas[0] : areas.dropLast().joined(separator: ", ") + " and " + areas.last!
        return adds + ", including work for your \(list) focus."
    }
}

/// Small wrapping tags (exercise names).
private struct FlowTags: View {
    let items: [String]

    var body: some View {
        TagFlowLayout(spacing: 6) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(Theme.green)
                    .background(Theme.green.opacity(0.15), in: Capsule())
            }
        }
    }
}

/// Lays children out left to right, wrapping to a new line when the row is full.
private struct TagFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
