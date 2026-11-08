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
                Text("\(draft.focusAreas.count) of \(draft.maxFocusAreas)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text("Optional. Pick up to \(draft.maxFocusAreas) areas to prioritize. They get worked earlier and more often, while the rest of your body still gets trained. Longer workouts have room for more (4 at 45 min, 5 at 60).")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(FocusArea.allCases) { area in
                    ChipButton(
                        title: area.title,
                        isSelected: draft.focusAreas.contains(area),
                        isEnabled: draft.focusAreas.count < draft.maxFocusAreas
                    ) {
                        draft.toggleFocus(area)
                    }
                }
            }

            if let covered = alreadyCoveredNote {
                Label {
                    Text(covered)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .font(.caption)
                .foregroundStyle(Theme.green)
                .padding(.top, 4)
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

    /// e.g. "Glutes and legs are already a main lift in all 3 of your workouts, so there's no need
    /// to pick them unless you want extra."
    private var alreadyCoveredNote: String? {
        let days = draft.rotation
        guard !days.isEmpty else { return nil }
        let covered = FocusArea.allCases.filter {
            !draft.focusAreas.contains($0) && $0.mainLiftDays(in: days) == days.count
        }
        guard !covered.isEmpty else { return nil }

        let names = covered.map(\.title)
        let list = names.count == 1
            ? names[0]
            : names.dropLast().joined(separator: ", ") + " and " + names.last!.lowercased()
        let verb = names.count == 1 ? "is" : "are"
        return "\(list) \(verb) already a main lift in all \(days.count) of your workouts, so there's no need to pick \(names.count == 1 ? "it" : "them") unless you want extra."
    }
}
