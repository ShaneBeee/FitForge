import Foundation
import ActivityKit

/// What the lock screen / Dynamic Island Live Activity shows during a workout.
/// Shared between the FitForge app and the FitForgeWidgets extension
/// (this file must be a member of both targets).
nonisolated struct WorkoutActivityAttributes: ActivityAttributes {

    nonisolated struct ContentState: Codable, Hashable {
        enum Phase: String, Codable, Hashable {
            case ready, working, resting, paused, finished
        }

        var phase: Phase
        /// e.g. "Push-Up", or "Rest"
        var title: String
        /// e.g. "Set 2 of 3 · 8–12 reps" or "Up next: Goblet Squat"
        var detail: String
        /// Countdown window for rest or a timed set (nil when there's no timer).
        var timerStart: Date?
        var timerEnd: Date?
        /// Time left when paused (the countdown is frozen).
        var pausedRemaining: TimeInterval?
        var setsDone: Int
        var totalSets: Int
    }

    /// e.g. "Day A"
    var workoutTitle: String
    var startedAt: Date
}
