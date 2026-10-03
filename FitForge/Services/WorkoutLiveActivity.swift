import Foundation
import ActivityKit

/// Starts, updates and ends the workout Live Activity (lock screen + Dynamic Island).
final class WorkoutLiveActivity {
    private var activity: Activity<WorkoutActivityAttributes>?

    func start(workoutTitle: String, startedAt: Date, state: WorkoutActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }
        let attributes = WorkoutActivityAttributes(workoutTitle: workoutTitle, startedAt: startedAt)
        activity = try? Activity.request(
            attributes: attributes,
            content: Self.content(for: state)
        )
    }

    func update(_ state: WorkoutActivityAttributes.ContentState) {
        guard let activity else { return }
        Task {
            await activity.update(Self.content(for: state))
        }
    }

    /// Ends the activity. A finished workout lingers briefly on the lock screen; a discarded one goes right away.
    func end(_ state: WorkoutActivityAttributes.ContentState, immediately: Bool = false) {
        guard let activity else { return }
        self.activity = nil
        Task {
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: immediately ? .immediate : .after(.now.addingTimeInterval(5 * 60))
            )
        }
    }

    /// Marks the content as stale the moment a countdown ends, so iOS redraws the
    /// lock screen ("Rest's up") even while FitForge is asleep.
    private static func content(for state: WorkoutActivityAttributes.ContentState) -> ActivityContent<WorkoutActivityAttributes.ContentState> {
        let countsDown = state.phase == .resting || state.phase == .working
        return ActivityContent(state: state, staleDate: countsDown ? state.timerEnd : nil)
    }
}
