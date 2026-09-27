import SwiftUI

/// A row of this week's planned workouts with their status: done, missed, today or upcoming.
struct ThisWeekStrip: View {
    let week: [ScheduledWorkout]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(week) { slot in
                VStack(spacing: 6) {
                    Text(slot.date, format: .dateTime.weekday(.abbreviated))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Image(systemName: icon(for: slot.status))
                        .font(.title2)
                        .foregroundStyle(color(for: slot.status))
                        .symbolRenderingMode(.hierarchical)

                    Text(slot.day.title)
                        .font(.caption.weight(.bold))
                    Text(label(for: slot.status))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    if slot.status == .today {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Theme.blue, lineWidth: 2)
                    }
                }
            }
        }
    }

    private func icon(for status: ScheduledWorkout.Status) -> String {
        switch status {
        case .done: "checkmark.circle.fill"
        case .missed: "arrow.uturn.backward.circle.fill"
        case .today: "flame.circle.fill"
        case .upcoming: "circle.dashed"
        }
    }

    private func color(for status: ScheduledWorkout.Status) -> Color {
        switch status {
        case .done: Theme.green
        case .missed: Theme.teal
        case .today: Theme.blue
        case .upcoming: .secondary
        }
    }

    private func label(for status: ScheduledWorkout.Status) -> String {
        switch status {
        case .done: "Done"
        case .missed: "Make up"
        case .today: "Today"
        case .upcoming: "Upcoming"
        }
    }
}
