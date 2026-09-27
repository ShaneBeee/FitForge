import SwiftUI

struct GoalStep: View {
    @Bindable var draft: OnboardingDraft

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StepHeader(
                title: "What's your main goal?",
                subtitle: "This shapes how your workouts are built — reps, rest times and how hard each session pushes.",
                systemImage: "target"
            )

            ForEach(GoalType.allCases) { goal in
                OptionCard(
                    title: goal.title,
                    detail: goal.detail,
                    systemImage: goal.systemImage,
                    isSelected: draft.goalType == goal
                ) {
                    draft.setGoal(goal)
                }
            }

            focusSection
                .padding(.top, 12)
        }
    }

    private var focusSection: some View {
        FormCard {
            HStack {
                Text("Focus areas")
                    .font(.headline)
                Spacer()
                Text("\(draft.focusAreas.count) of \(FocusArea.maxSelections)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text("Optional. Pick up to 3 areas to prioritize. They get worked earlier and more often, while the rest of your body still gets trained.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(FocusArea.allCases) { area in
                    ChipButton(
                        title: area.title,
                        isSelected: draft.focusAreas.contains(area),
                        isEnabled: draft.focusAreas.count < FocusArea.maxSelections
                    ) {
                        draft.toggleFocus(area)
                    }
                }
            }

            if draft.focusAreas.contains(.bellyFat) {
                Label {
                    Text("No exercise burns fat from one spot, so a belly-fat focus leans your plan toward overall fat loss, keeps core work in every session, and tracks your belly with measurements. Deep belly fat usually responds well to exactly that.")
                } icon: {
                    Image(systemName: "lightbulb.fill")
                }
                .font(.caption)
                .foregroundStyle(Theme.teal)
                .padding(.top, 4)
            }
        }
    }
}
