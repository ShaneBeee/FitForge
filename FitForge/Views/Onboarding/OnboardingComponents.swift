import SwiftUI

// Reusable pieces for the setup screens.

/// Big title + explanation at the top of each setup step.
struct StepHeader: View {
    let title: String
    let subtitle: String
    var systemImage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Theme.gradient)
                    .padding(.bottom, 4)
            }
            Text(title)
                .font(.largeTitle.weight(.bold))
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
}

/// A large tappable card for picking an option.
struct OptionCard: View {
    let title: String
    var detail: String? = nil
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .frame(width: 36)
                        .foregroundStyle(isSelected ? Theme.blue : .secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let detail {
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.blue : Color.secondary.opacity(0.5))
            }
            .padding()
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Theme.blue : .clear, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .animation(.snappy, value: isSelected)
    }
}

/// A small capsule button for quick choices.
struct ChipButton: View {
    let title: String
    let isSelected: Bool
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    isSelected ? AnyShapeStyle(Theme.blue) : AnyShapeStyle(.background.secondary),
                    in: Capsule()
                )
                .opacity(isEnabled || isSelected ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled && !isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
        .animation(.snappy, value: isSelected)
    }
}

/// A labelled number entry row, e.g. "Weight [ 181.2 ] lb".
struct NumberEntryRow: View {
    let title: String
    let unit: String
    @Binding var value: Double?
    var prompt = "0"

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(prompt, value: $value, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.body.monospacedDigit().weight(.semibold))
                .frame(maxWidth: 100)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

/// A grouped card holding a few rows, with thin dividers.
struct FormCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .cardStyle()
    }
}

/// Section label used above groups of options.
struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
}
