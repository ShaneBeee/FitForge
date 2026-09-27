import SwiftUI

struct ScheduleStep: View {
    @Bindable var draft: OnboardingDraft

    private let restOptions = [30, 45, 60, 75, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: "Your schedule",
                subtitle: "How often and how long can you work out? Your plan is built around it. If life gets busy, you can make up a missed workout later in the week.",
                systemImage: "calendar"
            )

            FormCard {
                Text("Days per week")
                    .font(.headline)
                HStack(spacing: 6) {
                    ForEach(Array(WorkoutPlans.daysPerWeekOptions), id: \.self) { count in
                        ChipButton(title: "\(count)", isSelected: draft.daysPerWeek == count) {
                            draft.setDaysPerWeek(count)
                        }
                    }
                }
                Label(WorkoutPlans.planDescription(forDaysPerWeek: draft.daysPerWeek), systemImage: "list.bullet.rectangle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.blue)
            }

            FormCard {
                Text("Workout length")
                    .font(.headline)
                HStack(spacing: 6) {
                    ForEach(WorkoutPlans.lengthOptions, id: \.self) { minutes in
                        ChipButton(title: "\(minutes) min", isSelected: draft.workoutMinutes == minutes) {
                            draft.workoutMinutes = minutes
                        }
                    }
                }
                Text(lengthDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            FormCard {
                HStack {
                    Text("Which days?")
                        .font(.headline)
                    Spacer()
                    Text("\(draft.workoutWeekdays.count) of \(draft.daysPerWeek)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(draft.workoutWeekdays.count == draft.daysPerWeek ? Theme.green : .secondary)
                }

                HStack(spacing: 6) {
                    ForEach(Weekday.ordered, id: \.self) { weekday in
                        dayButton(weekday)
                    }
                }

                Text(rotationPreview)
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

    // MARK: - Text

    private var lengthDescription: String {
        let slots = WorkoutBuilder.slotCount(forMinutes: draft.workoutMinutes)
        var text = "About \(slots) exercises per workout"
        if draft.workoutMinutes >= 45 {
            text += ", with an extra set on the main lifts"
            if draft.goalType != .buildMuscle {
                text += " and a short cardio finisher"
            }
        }
        return text + "."
    }

    /// e.g. "Sun: Day A · Wed: Day B · Fri: Day C"
    private var rotationPreview: String {
        let chosen = Weekday.ordered.filter { draft.workoutWeekdays.contains($0) }
        let rotation = WorkoutPlans.days(forDaysPerWeek: draft.daysPerWeek)
        guard !chosen.isEmpty else { return "Tap \(draft.daysPerWeek) days." }
        return zip(chosen, rotation)
            .map { "\(Weekday.shortName($0)): \($1.title)" }
            .joined(separator: " · ")
    }

    private var restBinding: Binding<Int> {
        Binding(get: { draft.restSeconds }, set: { draft.setRest($0) })
    }

    private func dayButton(_ weekday: Int) -> some View {
        let isSelected = draft.workoutWeekdays.contains(weekday)
        let isFull = draft.workoutWeekdays.count >= draft.daysPerWeek

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
