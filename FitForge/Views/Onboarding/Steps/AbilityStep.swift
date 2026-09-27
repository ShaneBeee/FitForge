import SwiftUI

struct AbilityStep: View {
    @Bindable var draft: OnboardingDraft

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: "What can you do right now?",
                subtitle: "No wrong answers — this just sets your starting difficulty. FitForge moves you up as you get stronger.",
                systemImage: "chart.bar.fill"
            )

            ForEach(AbilityQuestion.allCases) { question in
                FormCard {
                    Label(question.prompt, systemImage: question.systemImage)
                        .font(.headline)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                            ChipButton(title: option, isSelected: draft.abilityTiers[question] == index) {
                                draft.abilityTiers[question] = index
                            }
                        }
                    }
                }
            }

            FormCard {
                Label("Any joints that need care?", systemImage: "bandage.fill")
                    .font(.headline)
                Text("FitForge will steer away from exercises that are hard on these.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(JointCaution.allCases) { joint in
                        ChipButton(title: joint.title, isSelected: draft.jointCautions.contains(joint)) {
                            if draft.jointCautions.contains(joint) {
                                draft.jointCautions.remove(joint)
                            } else {
                                draft.jointCautions.insert(joint)
                            }
                        }
                    }
                }
            }
        }
    }
}
