import SwiftUI

struct WhyStep: View {
    @Bindable var draft: OnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: "What's your real goal?",
                subtitle: "In your own words. On days you don't feel like working out, FitForge will remind you of this.",
                systemImage: "heart.circle.fill"
            )

            FormCard {
                TextField("e.g. Clothes that fit, more energy, feeling great", text: $draft.why, axis: .vertical)
                    .lineLimit(3...6)
                    .font(.title3)
            }

            Text("Optional — leave it blank if you'd rather not.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
