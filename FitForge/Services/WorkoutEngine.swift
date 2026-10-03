import Foundation
import SwiftData
import UIKit
import UserNotifications
import Observation
import HealthKit

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
    /// Estimated calories, available once the workout is finished.
    private(set) var calorieEstimate: CalorieEstimate?
    /// How hard it felt (1–10), if rated on the summary screen.
    private(set) var effort: Int?

    var startedAt: Date { session.startDate }
    var finishedAt: Date? { session.endDate }

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let health: HealthKitManager
    @ObservationIgnored private let profile: UserProfile
    /// The Apple Watch connection (live heart rate and calories when a Watch is running the workout).
    @ObservationIgnored let watch: WatchWorkoutLink
    @ObservationIgnored private var usedWatch = false
    @ObservationIgnored private var watchCalories: Double = 0
    @ObservationIgnored private var watchAverageHeartRate: Double?
    @ObservationIgnored private var healthWorkout: HKWorkout?
    @ObservationIgnored private var effortCommitted = false
    @ObservationIgnored private var effortSavedToHealth = false
    @ObservationIgnored private let voice = VoiceCoach()
    @ObservationIgnored private let liveActivity = WorkoutLiveActivity()
    @ObservationIgnored private var tickTask: Task<Void, Never>?
    @ObservationIgnored private var pausedRemaining: TimeInterval?
    @ObservationIgnored private var setStartedAt: Date?
    @ObservationIgnored private var hapticSecondsFired: Set<Int> = []
    @ObservationIgnored private var saidSwitchSides = false

    private static let notificationID = "fitforge.workout.phase"

    init(plan: PlannedWorkout, context: ModelContext, health: HealthKitManager, profile: UserProfile, watch: WatchWorkoutLink) {
        self.plan = plan
        self.context = context
        self.health = health
        self.profile = profile
        self.watch = watch
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
        liveActivity.start(workoutTitle: plan.day.title, startedAt: session.startDate, state: liveState())
        // Launch FitForge on the Apple Watch for live heart rate and calories (if there is one),
        // and let its buttons control this workout.
        watch.onCommand = { [weak self] command in self?.handleWatchCommand(command) }
        watch.onConnect = { [weak self] in self?.sendWatchState() }
        watch.startWatchWorkout()
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
        refreshLiveActivity()
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
        refreshLiveActivity()
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
        refreshLiveActivity()
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
        refreshLiveActivity()
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
        liveActivity.end(liveState(), immediately: true)
        if watch.isConnected { watch.discardWatchWorkout() }
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
        refreshLiveActivity()
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
        liveActivity.end(liveState())

        // If the Watch ran the workout, it saves it to Apple Health with its own measurements.
        if watch.isConnected {
            usedWatch = true
            watchCalories = watch.activeCalories
            watchAverageHeartRate = watch.averageHeartRate
            watch.endWatchWorkout()
        }
        saveToHealth()
    }

    // MARK: - Live Activity

    private func refreshLiveActivity() {
        liveActivity.update(liveState())
        sendWatchState()
    }

    // MARK: - Apple Watch

    /// Sends the current workout state to the Watch's control screen.
    private func sendWatchState() {
        watch.sendState(watchState())
    }

    /// Handles a button pressed on the Watch, exactly as if it were tapped on the phone.
    private func handleWatchCommand(_ command: WatchCommand) {
        switch command {
        case .primary:
            if isPaused {
                togglePause()
                return
            }
            switch phase {
            case .notStarted, .ready: startSet()
            case .working: completeSet()
            case .resting: skipRest()
            case .finished: break
            }
        case .skipSet: skipSet()
        case .skipExercise: skipExercise()
        case .togglePause: togglePause()
        case .addRest: adjustRest(by: 15)
        case .removeRest: adjustRest(by: -15)
        }
        // Make sure the Watch reflects the result even if nothing visibly changed.
        sendWatchState()
    }

    private func watchState() -> WatchWorkoutState {
        let live = liveState()
        let watchPhase: WatchWorkoutState.Phase = switch phase {
        case .notStarted, .ready: .ready
        case .working: .working
        case .resting: .resting
        case .finished: .finished
        }
        let primaryLabel: String = switch phase {
        case .notStarted, .ready: "Start set \(setIndex + 1)"
        case .working: phaseEndsAt == nil ? "Done" : "Done early"
        case .resting: "Skip rest"
        case .finished: "Done"
        }
        return WatchWorkoutState(
            phase: watchPhase,
            isPaused: isPaused,
            title: live.title,
            detail: live.detail,
            timerStart: live.timerStart,
            timerEnd: live.timerEnd,
            pausedRemaining: live.pausedRemaining,
            setsDone: live.setsDone,
            totalSets: live.totalSets,
            primaryLabel: isPaused ? "Resume" : primaryLabel
        )
    }

    /// What the lock screen and Dynamic Island should show right now.
    private func liveState() -> WorkoutActivityAttributes.ContentState {
        let done = results.count
        let total = totalSets
        let timerStart = phaseEndsAt.map { $0.addingTimeInterval(-phaseDuration) }
        let frozen = isPaused ? pausedRemaining : nil

        switch phase {
        case .finished:
            let minutes = Int(((session.endDate ?? .now).timeIntervalSince(session.startDate) / 60).rounded())
            return .init(phase: .finished, title: "Workout complete",
                         detail: "\(completedSets.count) sets · \(minutes) min",
                         timerStart: nil, timerEnd: nil, pausedRemaining: nil,
                         setsDone: done, totalSets: total)

        case .resting:
            let next = current.map { "Up next: \($0.exercise.name) · set \(setIndex + 1) of \($0.sets)" } ?? "Rest"
            return .init(phase: isPaused ? .paused : .resting, title: "Rest", detail: next,
                         timerStart: timerStart, timerEnd: phaseEndsAt, pausedRemaining: frozen,
                         setsDone: done, totalSets: total)

        case .working:
            return .init(phase: isPaused ? .paused : .working,
                         title: current?.exercise.name ?? "Workout",
                         detail: current.map { "Set \(setIndex + 1) of \($0.sets) · \(shortTarget($0))" } ?? "",
                         timerStart: timerStart, timerEnd: phaseEndsAt, pausedRemaining: frozen,
                         setsDone: done, totalSets: total)

        case .notStarted, .ready:
            return .init(phase: isPaused ? .paused : .ready,
                         title: current?.exercise.name ?? "Workout",
                         detail: current.map { "Set \(setIndex + 1) of \($0.sets) · \(shortTarget($0))" } ?? "",
                         timerStart: nil, timerEnd: nil, pausedRemaining: nil,
                         setsDone: done, totalSets: total)
        }
    }

    /// e.g. "8–12 reps" or "30 sec per side"
    private func shortTarget(_ planned: PlannedExercise) -> String {
        let perSide = planned.exercise.isUnilateral ? " per side" : ""
        if let seconds = planned.seconds { return "\(seconds) sec\(perSide)" }
        if let reps = planned.reps { return "\(reps.lowerBound)–\(reps.upperBound) reps\(perSide)" }
        return ""
    }

    private func saveToHealth() {
        guard !completedSets.isEmpty, let end = session.endDate else { return }
        healthSaveState = .saving
        let start = session.startDate

        // The Apple Watch measured this workout and saves it to Health itself, with real
        // calories and heart rate. Just record its numbers here; no estimate, no duplicate workout.
        if usedWatch {
            let measured = CalorieEstimate(
                activeCalories: watchCalories.rounded(),
                method: .watch,
                averageHeartRate: watchAverageHeartRate?.rounded()
            )
            calorieEstimate = measured
            session.activeCalories = measured.activeCalories
            session.calorieMethodRaw = measured.method.rawValue
            session.averageHeartRate = measured.averageHeartRate
            session.savedToHealth = true
            try? context.save()
            healthSaveState = .saved
            return
        }

        Task {
            // Estimate calories: heart rate if the Watch recorded enough, otherwise the work done.
            let heartRates = await health.heartRates(from: start, to: end)
            let age = profile.birthDate.flatMap { Calendar.current.dateComponents([.year], from: $0, to: .now).year }
            let estimate = CalorieEstimator.estimate(
                sets: results,
                start: start,
                end: end,
                weightLbs: health.latestWeight?.value ?? profile.startWeightLbs ?? 170,
                heightInches: profile.heightInches,
                age: age,
                ranges: profile.bodyFatRanges,
                heartRates: heartRates
            )
            calorieEstimate = estimate
            session.activeCalories = estimate?.activeCalories
            session.calorieMethodRaw = estimate?.method.rawValue ?? ""
            session.averageHeartRate = estimate?.averageHeartRate
            try? context.save()

            do {
                healthWorkout = try await health.saveStrengthWorkout(
                    start: start,
                    end: end,
                    activeCalories: estimate?.activeCalories
                )
                session.savedToHealth = true
                try? context.save()
                healthSaveState = .saved

                // If the effort was already confirmed while saving, attach it now.
                if effortCommitted, let effort { await saveEffortToHealth(effort) }
            } catch {
                healthSaveState = .failed
            }
        }
    }

    /// Rates how hard the workout felt (1–10). Saved to Health when the summary is closed,
    /// so changing your mind doesn't save several ratings.
    func setEffort(_ score: Int) {
        effort = score
        session.effort = score
        try? context.save()
    }

    /// Call when leaving the summary: saves the final effort rating to Health.
    func commitEffort() {
        effortCommitted = true
        guard let effort, healthWorkout != nil || usedWatch else { return }
        Task { await saveEffortToHealth(effort) }
    }

    private func saveEffortToHealth(_ score: Int) async {
        guard !effortSavedToHealth else { return }
        effortSavedToHealth = true

        var workout = healthWorkout
        if workout == nil, usedWatch, let end = session.endDate {
            // The Watch saves its workout a few seconds after finishing, so look for it.
            for delay in [2, 5, 10] {
                try? await Task.sleep(for: .seconds(delay))
                if let found = await health.strengthWorkout(near: session.startDate, end: end) {
                    workout = found
                    break
                }
            }
            healthWorkout = workout
        }

        guard let workout else {
            effortSavedToHealth = false
            return
        }
        do {
            try await health.saveEffort(score, for: workout)
        } catch {
            effortSavedToHealth = false
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
