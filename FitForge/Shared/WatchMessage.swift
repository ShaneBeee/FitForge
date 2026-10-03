import Foundation

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
