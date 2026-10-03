import Foundation

/// A snapshot of the workout for the Watch's control screen, sent by the iPhone whenever it changes.
nonisolated struct WatchWorkoutState: Codable, Sendable, Equatable {
    enum Phase: String, Codable, Sendable {
        case ready, working, resting, finished
    }

    var phase: Phase
    var isPaused: Bool
    /// e.g. "Push-Up", or "Rest"
    var title: String
    /// e.g. "Set 2 of 3 · 8–12 reps" or "Up next: Goblet Squat · set 2 of 3"
    var detail: String
    /// Countdown window for rest or a timed set (nil when there's no timer).
    var timerStart: Date?
    var timerEnd: Date?
    /// Time left when paused (the countdown is frozen).
    var pausedRemaining: TimeInterval?
    var setsDone: Int
    var totalSets: Int
    /// What the main button says, e.g. "Start set 2", "Done", "Skip rest".
    var primaryLabel: String
}

/// Buttons pressed on the Watch, handled by the iPhone's workout engine.
nonisolated enum WatchCommand: String, Codable, Sendable {
    /// The main button: start set / done / skip rest, depending on the moment.
    case primary
    case skipSet
    case skipExercise
    case togglePause
    case addRest
    case removeRest
}

/// Messages passed between the iPhone and Apple Watch during a workout (via WatchConnectivity).
/// Shared between the FitForge app and the FitForgeWatch app
/// (this file must be a member of both targets).
nonisolated enum WatchMessage: Codable, Sendable {
    /// Watch → phone: the Watch's workout session is running.
    case started
    /// Watch → phone: live numbers from the Watch's workout session.
    case metrics(heartRate: Double?, activeCalories: Double)
    /// Watch → phone: the Watch's workout session has ended.
    case stopped
    /// Watch → phone: a button was pressed on the Watch.
    case command(WatchCommand)
    /// Phone → watch: the current state of the workout.
    case state(WatchWorkoutState)
    /// Phone → watch: finish and save the workout.
    case end
    /// Phone → watch: stop without saving (the workout was discarded).
    case discard

    func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func decode(_ data: Data) -> WatchMessage? {
        try? JSONDecoder().decode(WatchMessage.self, from: data)
    }
}
