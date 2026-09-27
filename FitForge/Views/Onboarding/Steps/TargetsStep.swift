import SwiftUI

struct TargetsStep: View {
    @Bindable var draft: OnboardingDraft

    private var estimate: GoalEstimate? {
        GoalEstimator.estimate(
            currentWeight: draft.currentWeightLbs,
            targetWeight: draft.targetWeightLbs,
            currentBodyFat: draft.currentBodyFatPercent,
            targetBodyFat: draft.targetBodyFatPercent
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: "Your targets",
                subtitle: "Where do you want to end up? Leave either one blank if it doesn't matter to you.",
                systemImage: "flag.checkered"
            )

            FormCard {
                NumberEntryRow(title: "Target weight", unit: "lb", value: $draft.targetWeightLbs)
                currentValue(draft.currentWeightLbs, unit: "lb")
                Divider()
                NumberEntryRow(title: "Target body fat", unit: "%", value: $draft.targetBodyFatPercent)
                currentValue(draft.currentBodyFatPercent, unit: "%")
            }

            if let estimate {
                estimateCard(estimate)
                    .transition(.opacity)
            }
        }
        .animation(.default, value: estimate?.maxWeeks)
    }

    @ViewBuilder
    private func currentValue(_ value: Double?, unit: String) -> some View {
        if let value {
            Text("Now: \(value.formatted(.number.precision(.fractionLength(0...1)))) \(unit)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func estimateCard(_ estimate: GoalEstimate) -> some View {
        FormCard {
            if estimate.maxWeeks > 0 {
                Label("Estimated timeline", systemImage: "calendar")
                    .font(.headline)
                    .foregroundStyle(Theme.blue)

                Text("About \(estimate.minWeeks)–\(estimate.maxWeeks) weeks")
                    .font(.title2.weight(.bold))

                Text("Somewhere between \(estimate.earliestDate.formatted(.dateTime.month(.wide).year())) and \(estimate.latestDate.formatted(.dateTime.month(.wide).year())), at a healthy, sustainable pace.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(estimate.notes, id: \.self) { note in
                Label(note, systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.teal)
                    .padding(.top, 4)
            }
        }
    }
}
