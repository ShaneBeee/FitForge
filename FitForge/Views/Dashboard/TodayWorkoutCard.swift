import SwiftUI

/// Dashboard card: today's workout with a Start button, a make-up if one is waiting,
/// or the next workout on rest days. Also shows this week's plan.
struct TodayWorkoutCard: View {
    let profile: UserProfile
    let week: [ScheduledWorkout]
    let onStart: (WorkoutDay) -> Void

    private var todaySlot: ScheduledWorkout? {
        week.first { Calendar.current.isDateInToday($0.date) }
    }

    private var makeUp: ScheduledWorkout? {
        week.first { $0.status == .missed }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
            if !week.isEmpty {
                ThisWeekStrip(week: week)
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var content: some View {
        if let todaySlot, todaySlot.status == .today {
            startSection(
                eyebrow: "Today's workout",
                day: todaySlot.day,
                buttonTitle: "Start \(todaySlot.day.title)"
            )
        } else if let makeUp {
            startSection(
                eyebrow: "Make-up available",
                day: makeUp.day,
                buttonTitle: "Make up \(makeUp.day.title)",
                note: "Missed on \(makeUp.date.formatted(.dateTime.weekday(.wide))). You can still do it this week."
            )
        } else if let todaySlot, todaySlot.status == .done {
            message(
                icon: "checkmark.seal.fill",
                title: "\(todaySlot.day.title) done today",
                subtitle: "Nice work. Rest up and recover."
            )
        } else if let next = WorkoutSchedule.nextWorkout(after: .now, for: profile) {
            message(
                icon: "moon.zzz.fill",
                title: "Rest day",
                subtitle: "Next up: \(next.day.title) on \(next.date.formatted(.dateTime.weekday(.wide)))."
            )
        }
    }

    private func startSection(eyebrow: String, day: WorkoutDay, buttonTitle: String, note: String? = nil) -> some View {
        let plan = WorkoutBuilder.build(day, for: profile)

        return VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Theme.blue)
            Text(day.title)
                .font(.title.weight(.bold))
            Text("\(day.focus) · \(plan.exercises.count) exercises · about \(plan.estimatedMinutes) min")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button {
                onStart(day)
            } label: {
                Label(buttonTitle, systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Theme.blue)
            .disabled(plan.exercises.isEmpty)
        }
    }

    private func message(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Theme.gradient)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}
