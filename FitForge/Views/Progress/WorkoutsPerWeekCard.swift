import SwiftUI
import SwiftData
import Charts

/// Bar chart of workouts done each week, with the weekly target as a line.
struct WorkoutsPerWeekCard: View {
    let sessions: [WorkoutSession]
    let target: Int
    let domainStart: Date

    private struct WeekCount: Identifiable {
        let weekStart: Date
        let count: Int
        var id: Date { weekStart }
    }

    /// Workouts that were finished (or ended early) with at least one set done.
    private var counted: [WorkoutSession] {
        sessions.filter { session in
            session.status != .inProgress
                && session.startDate >= domainStart
                && (session.sets ?? []).contains { !$0.wasSkipped }
        }
    }

    private var weeks: [WeekCount] {
        let calendar = Calendar.current
        guard let firstWeek = calendar.dateInterval(of: .weekOfYear, for: max(domainStart, earliestSessionWeek))?.start,
              let thisWeek = calendar.dateInterval(of: .weekOfYear, for: .now)?.start
        else { return [] }

        var counts: [Date: Int] = [:]
        for session in counted {
            if let week = calendar.dateInterval(of: .weekOfYear, for: session.startDate)?.start {
                counts[week, default: 0] += 1
            }
        }

        var result: [WeekCount] = []
        var week = firstWeek
        while week <= thisWeek {
            result.append(WeekCount(weekStart: week, count: counts[week] ?? 0))
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: week) else { break }
            week = next
        }
        return result
    }

    /// Don't draw empty weeks from before the first workout ever logged.
    private var earliestSessionWeek: Date {
        counted.map(\.startDate).min() ?? .now
    }

    private var thisWeekCount: Int { weeks.last?.count ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label("Workouts", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.blue)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(thisWeekCount) of \(target)")
                        .font(.title2.weight(.bold).monospacedDigit())
                    Text("this week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if counted.isEmpty {
                Text("Finish a workout and it'll show up here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart {
                    RuleMark(y: .value("Target", target))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .foregroundStyle(Theme.green)

                    ForEach(weeks) { week in
                        BarMark(
                            x: .value("Week", week.weekStart, unit: .weekOfYear),
                            y: .value("Workouts", week.count)
                        )
                        .foregroundStyle(week.count >= target ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Theme.blue.opacity(0.5)))
                        .cornerRadius(4)
                    }
                }
                .chartYScale(domain: 0...max(target + 1, (weeks.map(\.count).max() ?? 0) + 1))
                .chartYAxis {
                    AxisMarks(values: .stride(by: 1))
                }
                .frame(height: 160)
            }

            Text("\(counted.count) workout\(counted.count == 1 ? "" : "s") in this time range")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}
