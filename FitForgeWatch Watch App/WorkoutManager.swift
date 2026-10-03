import Foundation
import HealthKit
import WatchConnectivity
import Observation

/// Runs the Apple Watch side of a FitForge workout: a real HealthKit workout session
/// (live heart rate + Apple-measured calories), reporting to the iPhone over WatchConnectivity.
@Observable
final class WorkoutManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, WCSessionDelegate {

    static let shared = WorkoutManager()

    private(set) var isRunning = false
    private(set) var startDate: Date?
    /// Latest heart rate (beats per minute).
    private(set) var heartRate: Double?
    /// Active calories so far.
    private(set) var activeCalories: Double = 0

    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?
    @ObservationIgnored private var shouldDiscard = false

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Permissions

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        let read: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKObjectType.workoutType()
        ]
        try? await store.requestAuthorization(toShare: share, read: read)
    }

    // MARK: - Starting and ending

    /// Starts a workout session (called when the iPhone launches the Watch app for a workout).
    func start(with configuration: HKWorkoutConfiguration) async {
        guard session == nil else { return }
        await requestAuthorization()

        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
            session.delegate = self
            builder.delegate = self
            self.session = session
            self.builder = builder

            let start = Date()
            session.startActivity(with: start)
            try await builder.beginCollection(at: start)

            startDate = start
            isRunning = true
            send(.started)
        } catch {
            reset()
        }
    }

    /// Ends the session. The workout is saved to Apple Health unless it's being discarded.
    func end(discard: Bool) {
        shouldDiscard = discard
        session?.end()
    }

    // MARK: - Internals

    private func finishCollection(at date: Date) async {
        guard let builder else {
            reset()
            return
        }
        do {
            try await builder.endCollection(at: date)
            if shouldDiscard {
                builder.discardWorkout()
            } else {
                _ = try await builder.finishWorkout()
            }
        } catch {
            // Nothing more we can do; the session is over either way.
        }
        send(.stopped)
        reset()
    }

    private func reset() {
        session = nil
        builder = nil
        isRunning = false
        startDate = nil
        heartRate = nil
        activeCalories = 0
        shouldDiscard = false
    }

    private func update(heartRate: Double?, calories: Double?) {
        if let heartRate { self.heartRate = heartRate }
        if let calories { activeCalories = calories }
        send(.metrics(heartRate: self.heartRate, activeCalories: activeCalories))
    }

    private func send(_ message: WatchMessage) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              WCSession.default.isReachable,
              let data = message.encoded()
        else { return }
        WCSession.default.sendMessageData(data, replyHandler: nil) { _ in }
    }

    private func handle(_ message: WatchMessage) {
        switch message {
        case .end: end(discard: false)
        case .discard: end(discard: true)
        case .started, .metrics, .stopped: break   // only sent watch → phone
        }
    }

    // MARK: - HKWorkoutSessionDelegate

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {
        guard toState == .ended else { return }
        Task { @MainActor in await self.finishCollection(at: date) }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in self.reset() }
    }

    // MARK: - HKLiveWorkoutBuilderDelegate

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        let heartRate = workoutBuilder.statistics(for: HKQuantityType(.heartRate))?
            .mostRecentQuantity()?.doubleValue(for: heartRateUnit)
        let calories = workoutBuilder.statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()?.doubleValue(for: .kilocalorie())
        Task { @MainActor in self.update(heartRate: heartRate, calories: calories) }
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let message = WatchMessage.decode(messageData) else { return }
        Task { @MainActor in self.handle(message) }
    }
}
