import SwiftUI

struct GoalStep: View {
    @Bindable var draft: OnboardingDraft

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
        }
    }
}
