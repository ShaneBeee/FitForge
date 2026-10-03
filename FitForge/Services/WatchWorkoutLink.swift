import Foundation
import HealthKit
import WatchConnectivity
import Observation

/// The iPhone's connection to the Apple Watch during a workout.
///
/// When a workout starts, the phone launches FitForge on the Watch, which runs a real
/// workout session (live heart rate + Apple-measured calories). The two apps talk over
/// WatchConnectivity, which works on real devices and in paired simulators.
@Observable
final class WatchWorkoutLink: NSObject, WCSessionDelegate {

    /// The Watch has reported that its workout session is running.
    private(set) var isConnected = false
    /// Latest heart rate from the Watch (beats per minute).
    private(set) var heartRate: Double?
    /// Active calories so far, measured by the Watch.
    private(set) var activeCalories: Double = 0

    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var heartRateTotal: Double = 0
    @ObservationIgnored private var heartRateCount = 0

    /// Called when a button is pressed on the Watch.
    @ObservationIgnored var onCommand: ((WatchCommand) -> Void)?
    /// Called when the Watch's workout first connects, so the current state can be sent right away.
    @ObservationIgnored var onConnect: (() -> Void)?

    /// Average heart rate over the workout so far.
    var averageHeartRate: Double? {
        heartRateCount > 0 ? heartRateTotal / Double(heartRateCount) : nil
    }

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Starting and ending

    /// Launches FitForge on the Watch and asks it to start a strength workout.
    /// Does nothing (quietly) if there's no paired Watch or the app isn't installed.
    func startWatchWorkout() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        resetMetrics()
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        store.startWatchApp(with: configuration) { _, _ in }
    }

    /// Tells the Watch to finish and save the workout.
    func endWatchWorkout() {
        send(.end)
        isConnected = false
    }

    /// Tells the Watch to stop without saving.
    func discardWatchWorkout() {
        send(.discard)
        isConnected = false
    }

    /// Sends the latest workout state to the Watch's control screen.
    func sendState(_ state: WatchWorkoutState) {
        guard isConnected else { return }
        send(.state(state))
    }

    // MARK: - Internals

    private func resetMetrics() {
        isConnected = false
        heartRate = nil
        activeCalories = 0
        heartRateTotal = 0
        heartRateCount = 0
    }

    private func send(_ message: WatchMessage) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              let data = message.encoded()
        else { return }
        WCSession.default.sendMessageData(data, replyHandler: nil) { _ in }
    }

    private func handle(_ message: WatchMessage) {
        switch message {
        case .started:
            markConnected()
        case .metrics(let heartRate, let calories):
            markConnected()
            if let heartRate, heartRate > 0 {
                self.heartRate = heartRate
                heartRateTotal += heartRate
                heartRateCount += 1
            }
            activeCalories = max(activeCalories, calories)
        case .command(let command):
            onCommand?(command)
        case .stopped:
            isConnected = false
        case .state, .end, .discard:
            break   // only sent phone → watch
        }
    }

    private func markConnected() {
        guard !isConnected else { return }
        isConnected = true
        onConnect?()
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate after switching between paired Watches.
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let message = WatchMessage.decode(messageData) else { return }
        Task { @MainActor in self.handle(message) }
    }
}
