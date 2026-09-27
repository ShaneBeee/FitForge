import SwiftUI

struct ScheduleStep: View {
    @Bindable var draft: OnboardingDraft

    private let restOptions = [30, 45, 60, 75, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: "Your schedule",
                subtitle: "Pick your workout days. If life gets busy, you can always make up a missed workout later in the week.",
                systemImage: "calendar"
            )

            FormCard {
                HStack {
                    Text("Workout days")
                        .font(.headline)
                    Spacer()
                    Text("\(draft.workoutWeekdays.count) of \(OnboardingDraft.requiredWorkoutDays)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(draft.canContinue ? Theme.green : .secondary)
                }

                HStack(spacing: 6) {
                    ForEach(Weekday.ordered, id: \.self) { weekday in
                        dayButton(weekday)
                    }
                }

                Text("Your workouts rotate Day A → B → C through the week.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            FormCard {
                HStack {
                    Text("Weigh-in day")
                        .font(.headline)
                    Spacer()
                    Picker("Weigh-in day", selection: $draft.weighInWeekday) {
                        ForEach(Weekday.ordered, id: \.self) { weekday in
                            Text(Weekday.name(weekday)).tag(weekday)
                        }
                    }
                    .labelsHidden()
                }
                Text("Weigh in first thing in the morning, before breakfast, for the most consistent numbers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            FormCard {
                Text("Rest between sets")
                    .font(.headline)
                Picker("Rest between sets", selection: restBinding) {
                    ForEach(restOptions, id: \.self) { seconds in
                        Text("\(seconds)s").tag(seconds)
                    }
                }
                .pickerStyle(.segmented)
                Text("Suggested for your goal: \(draft.goalType.defaultRestSeconds) seconds. You can add or skip time during a workout too.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var restBinding: Binding<Int> {
        Binding(get: { draft.restSeconds }, set: { draft.setRest($0) })
    }

    private func dayButton(_ weekday: Int) -> some View {
        let isSelected = draft.workoutWeekdays.contains(weekday)
        let isFull = draft.workoutWeekdays.count >= OnboardingDraft.requiredWorkoutDays

        return Button {
            draft.toggleWorkoutDay(weekday)
        } label: {
            Text(String(Weekday.shortName(weekday).prefix(3)))
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    isSelected ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(.background),
                    in: Circle()
                )
                .opacity(!isSelected && isFull ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .animation(.snappy, value: isSelected)
    }
}
