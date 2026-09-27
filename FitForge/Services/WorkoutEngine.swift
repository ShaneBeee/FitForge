import Foundation
import SwiftData
import UIKit
import UserNotifications
import Observation

/// Runs a guided workout: start set → (timed set) → rest countdown → ready for the next set.
///
/// Timers are based on end *times* rather than counting ticks, so they stay accurate
/// even if the app is briefly in the background.
@Observable
final class WorkoutEngine: Identifiable {

    enum Phase: Equatable {
        case notStarted
        case ready      // waiting for the user to start the current set
        case working    // doing a set (timed sets count down on their own)
        case resting    // rest countdown before the next set
        case finished
    }

    enum HealthSaveState {
        case notAttempted, saving, saved, failed
    }

    let id = UUID()
    let plan: PlannedWorkout
    let session: WorkoutSession

    private(set) var phase: Phase = .notStarted
    private(set) var exerciseIndex = 0
    private(set) var setIndex = 0

    /// When the current timed phase (timed set or rest) ends, and how long it was.
    private(set) var phaseEndsAt: Date?
    private(set) var phaseDuration: TimeInterval = 0

    private(set) var isPaused = false
    private(set) var voiceEnabled = true
    private(set) var results: [SetLog] = []
    /// The most recent rep-based set, so reps can be adjusted during the rest after it.
    private(set) var lastRepsLog: SetLog?
    private(set) var healthSaveState: HealthSaveState = .notAttempted

    var startedAt: Date { session.startDate }
    var finishedAt: Date? { session.endDate }

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let health: HealthKitManager
    @ObservationIgnored private let voice = VoiceCoach()
    @ObservationIgnored private var tickTask: Task<Void, Never>?
    @ObservationIgnored private var pausedRemaining: TimeInterval?
    @ObservationIgnored private var setStartedAt: Date?
    @ObservationIgnored private var hapticSecondsFired: Set<Int> = []
    @ObservationIgnored private var saidSwitchSides = false

    private static let notificationID = "fitforge.workout.phase"

    init(plan: PlannedWorkout, context: ModelContext, health: HealthKitManager) {
        self.plan = plan
        self.context = context
        self.health = health
        self.session = WorkoutSession(day: plan.day)
        context.insert(session)
        try? context.save()
    }

    // MARK: - Derived state

    var current: PlannedExercise? {
        plan.exercises.indices.contains(exerciseIndex) ? plan.exercises[exerciseIndex] : nil
    }

    var totalSets: Int { plan.exercises.reduce(0) { $0 + $1.sets } }
    var completedSets: [SetLog] { results.filter { !$0.wasSkipped } }
    var skippedSets: [SetLog] { results.filter(\.wasSkipped) }
    var progress: Double { totalSets == 0 ? 0 : Double(results.count) / Double(totalSets) }

    /// True when the set the user is about to do is the first of a new exercise.
    var isStartOfExercise: Bool { setIndex == 0 }

    /// Time left in the current timed phase.
    func remaining(at date: Date) -> TimeInterval? {
        if isPaused { return pausedRemaining }
        guard let phaseEndsAt else { return nil }
        return max(0, phaseEndsAt.timeIntervalSince(date))
    }

    // MARK: - Flow

    func begin() {
        guard phase == .notStarted else { return }
        Task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) }
        phase = .ready
        if let current {
            speak("Let's go. First up, \(current.exercise.name). \(spokenTarget(current)).")
        }
    }

    func startSet() {
        guard phase == .ready, !isPaused, let current else { return }
        setStartedAt = .now
        haptic(.medium)

        if current.exercise.measure == .time, let seconds = current.seconds {
            let sides = current.exercise.isUnilateral ? 2 : 1
            beginTimedPhase(.working, duration: TimeInterval(seconds * sides))
            speak(current.exercise.isUnilateral ? "Go. First side." : "Go.")
        } else {
            phase = .working
            phaseEndsAt = nil
            phaseDuration = 0
            if let reps = current.reps {
                speak("Go. \(reps.lowerBound) to \(reps.upperBound) reps\(current.exercise.isUnilateral ? " per side" : "").")
            }
        }
    }

    /// The user tapped Done, or a timed set ran out.
    func completeSet() {
        guard phase == .working, let current else { return }

        let log = makeLog(for: current)
        if current.exercise.measure == .time {
            let elapsed = Date.now.timeIntervalSince(setStartedAt ?? .now)
            let sides = current.exercise.isUnilateral ? 2.0 : 1.0
            log.actualSeconds = min(current.seconds ?? 0, Int((elapsed / sides).rounded()))
            lastRepsLog = nil
        } else {
            log.actualReps = current.reps?.upperBound
            lastRepsLog = log
        }
        record(log)

        let rest = current.restSeconds
        guard advance() else {
            finish(status: .completed)
            return
        }
        beginTimedPhase(.resting, duration: TimeInterval(rest))
        haptic(.light)
        speak("Rest.")
    }

    func skipSet() {
        guard phase == .ready || phase == .working, let current else { return }
        let log = makeLog(for: current)
        log.wasSkipped = true
        record(log)
        lastRepsLog = nil
        guard advance() else {
            finish(status: .completed)
            return
        }
        enterReady()
    }

    func skipExercise() {
        guard phase == .ready || phase == .working, let current else { return }
        for set in setIndex..<current.sets {
            let log = SetLog(planned: current, exerciseIndex: exerciseIndex, setNumber: set + 1)
            log.wasSkipped = true
            record(log)
        }
        lastRepsLog = nil
        exerciseIndex += 1
        setIndex = 0
        guard exerciseIndex < plan.exercises.count else {
            finish(status: .completed)
            return
        }
        enterReady()
    }

    func skipRest() {
        guard phase == .resting else { return }
        enterReady()
    }

    func adjustRest(by seconds: TimeInterval) {
        guard phase == .resting else { return }
        if isPaused {
            pausedRemaining = max(0, (pausedRemaining ?? 0) + seconds)
            return
        }
        guard let end = phaseEndsAt else { return }
        let newEnd = max(Date.now, end.addingTimeInterval(seconds))
        phaseDuration = max(1, phaseDuration + newEnd.timeIntervalSince(end))
        phaseEndsAt = newEnd
        hapticSecondsFired = []
        scheduleNotification()
        haptic(.light)
    }

    func setRepsForLastSet(_ reps: Int) {
        lastRepsLog?.actualReps = max(0, reps)
        try? context.save()
    }

    func togglePause() {
        if isPaused {
            isPaused = false
            if let pausedRemaining {
                phaseEndsAt = Date.now.addingTimeInterval(pausedRemaining)
                startTicker()
                scheduleNotification()
            }
            pausedRemaining = nil
            speak("Resuming.")
        } else {
            pausedRemaining = remaining(at: .now)
            isPaused = true
            stopTicker()
            cancelNotification()
            voice.stop()
        }
    }

    func toggleVoice() {
        voiceEnabled.toggle()
        voice.isEnabled = voiceEnabled
        if !voiceEnabled { voice.stop() }
    }

    func endEarly() {
        finish(status: .endedEarly)
    }

    /// Throws the workout away entirely.
    func discard() {
        stopTimers()
        context.delete(session)
        try? context.save()
    }

    /// Call when the app comes back to the foreground to catch up on any timer that ran out.
    func reconcile() {
        tick()
    }

    func stopTimers() {
        stopTicker()
        cancelNotification()
        voice.stop()
    }

    // MARK: - Internals

    /// Moves to the next set (or next exercise). Returns false when the workout is done.
    private func advance() -> Bool {
        guard let current else { return false }
        setIndex += 1
        if setIndex >= current.sets {
            exerciseIndex += 1
            setIndex = 0
        }
        return exerciseIndex < plan.exercises.count
    }

    private func enterReady() {
        stopTicker()
        cancelNotification()
        phase = .ready
        phaseEndsAt = nil
        phaseDuration = 0
        haptic(.success)

        guard let current else { return }
        if isStartOfExercise {
            speak("Next up, \(current.exercise.name). \(spokenTarget(current)).")
        } else {
            speak("Rest's up. Set \(setIndex + 1) of \(current.sets).")
        }
    }

    private func beginTimedPhase(_ newPhase: Phase, duration: TimeInterval) {
        phase = newPhase
        phaseDuration = duration
        phaseEndsAt = Date.now.addingTimeInterval(duration)
        hapticSecondsFired = []
        saidSwitchSides = false
        startTicker()
        scheduleNotification()
    }

    private func tick() {
        guard !isPaused, let end = phaseEndsAt else { return }
        let remaining = end.timeIntervalSinceNow

        // Countdown taps for the last 3 seconds
        let wholeSeconds = Int(remaining.rounded(.up))
        if (1...3).contains(wholeSeconds), !hapticSecondsFired.contains(wholeSeconds) {
            hapticSecondsFired.insert(wholeSeconds)
            haptic(.light)
        }

        // Halfway through a one-sided timed set
        if phase == .working, current?.exercise.isUnilateral == true, !saidSwitchSides, remaining <= phaseDuration / 2 {
            saidSwitchSides = true
            haptic(.medium)
            speak("Switch sides.")
        }

        if remaining <= 0 {
            stopTicker()
            switch phase {
            case .working: completeSet()
            case .resting: enterReady()
            default: break
            }
        }
    }

    private func startTicker() {
        stopTicker()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    private func stopTicker() {
        tickTask?.cancel()
        tickTask = nil
    }

    private func finish(status: SessionStatus) {
        stopTimers()
        phase = .finished
        phaseEndsAt = nil
        session.status = status
        session.endDate = .now
        try? context.save()

        haptic(.success)
        speak(status == .completed ? "Workout complete. Great work." : "Workout saved.")
        saveToHealth()
    }

    private func saveToHealth() {
        guard !completedSets.isEmpty, let end = session.endDate else { return }
        healthSaveState = .saving
        let start = session.startDate
        Task {
            do {
                try await health.saveStrengthWorkout(start: start, end: end)
                session.savedToHealth = true
                try? context.save()
                healthSaveState = .saved
            } catch {
                healthSaveState = .failed
            }
        }
    }

    private func makeLog(for planned: PlannedExercise) -> SetLog {
        SetLog(planned: planned, exerciseIndex: exerciseIndex, setNumber: setIndex + 1)
    }

    private func record(_ log: SetLog) {
        context.insert(log)
        log.session = session
        results.append(log)
        try? context.save()
    }

    private func spokenTarget(_ planned: PlannedExercise) -> String {
        let perSide = planned.exercise.isUnilateral ? " per side" : ""
        if let seconds = planned.seconds {
            return "\(planned.sets) sets of \(seconds) seconds\(perSide)"
        }
        if let reps = planned.reps {
            return "\(planned.sets) sets of \(reps.lowerBound) to \(reps.upperBound) reps\(perSide)"
        }
        return "\(planned.sets) sets"
    }

    // MARK: - Feedback

    private func speak(_ text: String) {
        voice.speak(text)
    }

    private enum Haptic { case light, medium, success }

    private func haptic(_ kind: Haptic) {
        switch kind {
        case .light: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium: UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Notifications (for when the phone is locked)

    private func scheduleNotification() {
        cancelNotification()
        guard let end = phaseEndsAt else { return }
        let interval = end.timeIntervalSinceNow
        guard interval > 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = "FitForge"
        switch phase {
        case .resting:
            if let current {
                content.body = isStartOfExercise
                    ? "Rest's up — next is \(current.exercise.name)."
                    : "Rest's up — time for set \(setIndex + 1) of \(current.sets)."
            } else {
                content.body = "Rest's up."
            }
        case .working:
            content.body = "Time! Set complete."
        default:
            return
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: Self.notificationID,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
    }
}
