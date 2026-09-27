import SwiftUI
import SwiftData

/// The History tab: this week at a glance, past workouts grouped by week (with missed ones),
/// and weigh-ins.
struct HistoryScreen: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]

    enum Mode: String, CaseIterable, Identifiable {
        case workouts = "Workouts"
        case weighIns = "Weigh-ins"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .workouts
    @State private var pendingDelete: WorkoutSession?

    /// One week in the list: its workouts and missed slots, newest first.
    private struct WeekGroup: Identifiable {
        let start: Date
        let entries: [Entry]
        var id: Date { start }
    }

    private enum Entry: Identifiable {
        case session(WorkoutSession)
        case missed(ScheduledWorkout)

        var id: String {
            switch self {
            case .session(let session): "s-\(session.persistentModelID.hashValue)"
            case .missed(let slot): "m-\(slot.date.timeIntervalSince1970)"
            }
        }

        var date: Date {
            switch self {
            case .session(let session): session.startDate
            case .missed(let slot): slot.date
            }
        }
    }

    private var countedSessions: [WorkoutSession] {
        sessions.filter { WeekSchedule.counts($0) }
    }

    private var thisWeek: [ScheduledWorkout] {
        WeekSchedule.week(containing: .now, profile: profile, sessions: sessions)
    }

    private var weeks: [WeekGroup] {
        let calendar = Calendar.current
        let earliest = min(profile.startDate, countedSessions.last?.startDate ?? profile.startDate)
        guard let firstWeek = calendar.dateInterval(of: .weekOfYear, for: earliest)?.start else { return [] }

        var groups: [WeekGroup] = []
        var weekStart = firstWeek
        while weekStart <= .now {
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { break }

            let weekSessions = countedSessions
                .filter { interval.contains($0.startDate) }
                .map(Entry.session)
            let missed = WeekSchedule.week(containing: weekStart, profile: profile, sessions: sessions)
                .filter { $0.status == .missed }
                .map(Entry.missed)

            let entries = (weekSessions + missed).sorted { $0.date > $1.date }
            if !entries.isEmpty {
                groups.append(WeekGroup(start: interval.start, entries: entries))
            }
            weekStart = interval.end
        }
        return groups.reversed()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Show", selection: $mode) {
                        ForEach(Mode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                switch mode {
                case .workouts:
                    workoutSections
                case .weighIns:
                    Section("Past year") {
                        WeighInHistoryView()
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: WorkoutSession.self) { session in
                SessionDetailView(session: session, profile: profile)
            }
            .confirmationDialog("Delete this workout?", isPresented: deleteBinding, titleVisibility: .visible) {
                Button("Delete workout") {
                    if let pendingDelete {
                        context.delete(pendingDelete)
                        try? context.save()
                    }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("It will be removed from your history and won't count toward its week. Anything saved to Apple Health stays there.")
            }
        }
    }

    // MARK: - Workouts

    @ViewBuilder
    private var workoutSections: some View {
        Section("This week's plan") {
            if thisWeek.isEmpty {
                Text("No workouts scheduled this week.")
                    .foregroundStyle(.secondary)
            } else {
                ThisWeekStrip(week: thisWeek)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
        }

        if weeks.isEmpty {
            Section {
                ContentUnavailableView(
                    "No workouts yet",
                    systemImage: "calendar",
                    description: Text("Finished workouts will show up here, grouped by week.")
                )
            }
        }

        ForEach(weeks) { week in
            Section(title(for: week.start)) {
                ForEach(week.entries) { entry in
                    switch entry {
                    case .session(let session):
                        NavigationLink(value: session) {
                            sessionRow(session)
                        }
                        .swipeActions {
                            Button("Delete", systemImage: "trash") {
                                pendingDelete = session
                            }
                            .tint(Theme.teal)
                        }
                    case .missed(let slot):
                        missedRow(slot)
                    }
                }
            }
        }
    }

    private func sessionRow(_ session: WorkoutSession) -> some View {
        let sets = session.sets ?? []
        let done = sets.filter { !$0.wasSkipped }.count
        let duration = session.endDate.map { $0.timeIntervalSince(session.startDate) }

        return HStack(spacing: 12) {
            Text(session.day.badge)
                .font(.subheadline.weight(.bold))
                .minimumScaleFactor(0.7)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Theme.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(session.day.title)
                        .font(.subheadline.weight(.semibold))
                    if WeekSchedule.isMakeUp(session, profile: profile) {
                        Text("Make-up")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.teal)
                    }
                    if session.status == .endedEarly {
                        Text("Ended early")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(session.startDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + " · \(done) of \(sets.count) sets" + (duration.map { " · " + Duration.seconds($0).formatted(.time(pattern: .minuteSecond)) } ?? ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private func missedRow(_ slot: ScheduledWorkout) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Missed \(slot.day.title)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(slot.date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func title(for weekStart: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(weekStart, equalTo: .now, toGranularity: .weekOfYear) {
            return "This week"
        }
        if let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: .now),
           calendar.isDate(weekStart, equalTo: lastWeek, toGranularity: .weekOfYear) {
            return "Last week"
        }
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(weekStart.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }
}
