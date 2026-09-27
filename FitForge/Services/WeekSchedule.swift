import Foundation
import SwiftData

/// One planned workout in a week, and what happened to it.
struct ScheduledWorkout: Identifiable {
    enum Status {
        case done       // a workout for this day was finished this week
        case missed     // its day has passed and it wasn't done (can be made up this week)
        case today      // planned for today, not done yet
        case upcoming   // later this week
    }

    /// The planned date (start of day).
    let date: Date
    let day: WorkoutDay
    let status: Status
    /// The workout that covered this slot, if done.
    let session: WorkoutSession?

    var id: Date { date }
}

/// Applies the week rules: each week starts fresh on Day A, a workout not done on its day is
/// missed, and missed workouts can be made up any later day in the same week.
enum WeekSchedule {

    /// Whether a session counts as a real workout (finished or ended early, with at least one set done).
    static func counts(_ session: WorkoutSession) -> Bool {
        session.status != .inProgress && (session.sets ?? []).contains { !$0.wasSkipped }
    }

    /// The planned workouts for the week containing `date`, with their status.
    /// Days before the profile was created are left out, so nothing shows as missed before you started.
    static func week(containing date: Date, profile: UserProfile, sessions: [WorkoutSession], now: Date = .now) -> [ScheduledWorkout] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }

        let today = calendar.startOfDay(for: now)
        let firstDay = calendar.startOfDay(for: profile.startDate)
        let weekSessions = sessions
            .filter { counts($0) && interval.contains($0.startDate) }
            .sorted { $0.startDate < $1.startDate }

        var used: Set<PersistentIdentifier> = []
        var result: [ScheduledWorkout] = []

        for offset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: offset, to: interval.start),
                  let day = WorkoutSchedule.workoutDay(on: dayDate, for: profile)
            else { continue }

            let session = weekSessions.first { $0.day == day && !used.contains($0.persistentModelID) }
            if let session { used.insert(session.persistentModelID) }

            let status: ScheduledWorkout.Status
            if session != nil {
                status = .done
            } else if dayDate < firstDay {
                continue
            } else if dayDate < today {
                status = .missed
            } else if dayDate == today {
                status = .today
            } else {
                status = .upcoming
            }
            result.append(ScheduledWorkout(date: dayDate, day: day, status: status, session: session))
        }
        return result
    }

    /// True if the session was done on a different day than its workout was planned for.
    static func isMakeUp(_ session: WorkoutSession, profile: UserProfile) -> Bool {
        WorkoutSchedule.workoutDay(on: session.startDate, for: profile) != session.day
    }
}

extension WorkoutSession {
    /// Tidies up workouts that were interrupted (e.g. the app was closed mid-workout).
    /// Ones with sets done are kept as "ended early"; empty ones are removed.
    static func finalizeUnfinished(in context: ModelContext) {
        let inProgress = SessionStatus.inProgress.rawValue
        let descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.statusRaw == inProgress })
        guard let sessions = try? context.fetch(descriptor), !sessions.isEmpty else { return }

        for session in sessions {
            let sets = session.sets ?? []
            if sets.contains(where: { !$0.wasSkipped }) {
                session.status = .endedEarly
                session.endDate = sets.map(\.completedAt).max() ?? session.startDate
            } else {
                context.delete(session)
            }
        }
        try? context.save()
    }
}
