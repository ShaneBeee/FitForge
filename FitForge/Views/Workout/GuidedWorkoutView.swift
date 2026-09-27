import SwiftUI
import UIKit

/// The full-screen guided workout: start set → rest → ready, over and over.
struct GuidedWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var engine: WorkoutEngine
    @State private var confirmExit = false
    @State private var detail: PlannedExercise?

    init(engine: WorkoutEngine) {
        _engine = State(initialValue: engine)
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            VStack(spacing: 0) {
                topBar

                if engine.phase == .finished {
                    WorkoutSummaryView(engine: engine) { dismiss() }
                } else {
                    progressHeader
                        .padding(.top, 8)

                    if isLandscape {
                        HStack(spacing: 32) {
                            mainDisplay(ringSize: min(geometry.size.height * 0.62, 280))
                                .frame(maxWidth: .infinity)
                            controls
                                .frame(width: min(380, geometry.size.width * 0.42))
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        Spacer(minLength: 12)
                        mainDisplay(ringSize: min(geometry.size.width * 0.72, 300))
                        Spacer(minLength: 12)
                        controls
                    }
                }
            }
            .padding()
        }
        .background(alignment: .top) {
            LinearGradient(colors: [Theme.blue.opacity(0.18), .clear], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
        }
        .animation(.snappy, value: engine.phase)
        .animation(.snappy, value: engine.exerciseIndex)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            engine.begin()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            engine.stopTimers()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { engine.reconcile() }
        }
        .confirmationDialog("Leave this workout?", isPresented: $confirmExit, titleVisibility: .visible) {
            Button("End and save what I've done") { engine.endEarly() }
            Button("Discard workout") {
                engine.discard()
                dismiss()
            }
            Button("Keep going", role: .cancel) {}
        }
        .sheet(item: $detail) { planned in
            ExerciseDetailView(planned: planned)
        }
    }

    // MARK: - Top

    private var topBar: some View {
        HStack {
            if engine.phase != .finished {
                circleButton("xmark") { confirmExit = true }
            }
            Spacer()
            VStack(spacing: 0) {
                Text(engine.plan.day.title)
                    .font(.headline)
                if engine.phase != .finished {
                    Text(engine.startedAt, style: .timer)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if engine.phase != .finished {
                HStack(spacing: 8) {
                    circleButton(engine.voiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill") {
                        engine.toggleVoice()
                    }
                    circleButton(engine.isPaused ? "play.fill" : "pause.fill") {
                        engine.togglePause()
                    }
                }
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Exercise \(min(engine.exerciseIndex + 1, engine.plan.exercises.count)) of \(engine.plan.exercises.count)")
                Spacer()
                Text("\(engine.results.count) / \(engine.totalSets) sets")
                    .monospacedDigit()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            ProgressView(value: engine.progress)
                .tint(Theme.green)
        }
    }

    // MARK: - Main display

    @ViewBuilder
    private func mainDisplay(ringSize: CGFloat) -> some View {
        if let current = engine.current {
            switch engine.phase {
            case .notStarted, .ready:
                readyDisplay(current)
            case .working:
                if current.exercise.measure == .time {
                    VStack(spacing: 16) {
                        TimerRing(engine: engine, label: current.exercise.isUnilateral ? "Each side" : "Hold", size: ringSize)
                        Text(current.exercise.name)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)
                    }
                } else {
                    workingRepsDisplay(current)
                }
            case .resting:
                VStack(spacing: 16) {
                    TimerRing(engine: engine, label: "Rest", size: ringSize)
                    upNext(current)
                }
            case .finished:
                EmptyView()
            }
        }
    }

    private func readyDisplay(_ current: PlannedExercise) -> some View {
        VStack(spacing: 12) {
            Text("SET \(engine.setIndex + 1) OF \(current.sets)")
                .font(.headline)
                .tracking(2)
                .foregroundStyle(Theme.blue)

            Text(current.exercise.name)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)

            Text(targetText(current))
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)

            if engine.isStartOfExercise, let cue = current.exercise.cues.first {
                Label(cue, systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            Button {
                detail = current
            } label: {
                Label("How to do it", systemImage: "info.circle")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private func workingRepsDisplay(_ current: PlannedExercise) -> some View {
        VStack(spacing: 12) {
            Text("GO")
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gradient)
            Text(current.exercise.name)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)
            Text(targetText(current))
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Set \(engine.setIndex + 1) of \(current.sets)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func upNext(_ next: PlannedExercise) -> some View {
        VStack(spacing: 4) {
            Text("UP NEXT")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(.secondary)
            Text(next.exercise.name)
                .font(.title3.weight(.bold))
            Text("Set \(engine.setIndex + 1) of \(next.sets) · \(targetText(next))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 12) {
            switch engine.phase {
            case .notStarted, .ready:
                primaryButton("Start set \(engine.setIndex + 1)", systemImage: "play.fill") {
                    engine.startSet()
                }
                skipRow

            case .working:
                if engine.current?.exercise.measure == .time {
                    secondaryButton("Done early", systemImage: "checkmark") { engine.completeSet() }
                } else {
                    primaryButton("Done", systemImage: "checkmark") { engine.completeSet() }
                }
                skipRow

            case .resting:
                repsAdjuster
                HStack(spacing: 10) {
                    secondaryButton("−15s") { engine.adjustRest(by: -15) }
                    primaryButton("Skip rest", systemImage: "forward.fill") { engine.skipRest() }
                    secondaryButton("+15s") { engine.adjustRest(by: 15) }
                }

            case .finished:
                EmptyView()
            }

            if engine.isPaused {
                Text("Paused — tap ▶︎ to resume")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.teal)
            }
        }
        .disabled(engine.isPaused)
    }

    private var skipRow: some View {
        HStack(spacing: 10) {
            secondaryButton("Skip set", systemImage: "forward") { engine.skipSet() }
            secondaryButton("Skip exercise", systemImage: "forward.end") { engine.skipExercise() }
        }
    }

    @ViewBuilder
    private var repsAdjuster: some View {
        if let log = engine.lastRepsLog, let reps = log.actualReps {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reps you just did")
                        .font(.subheadline.weight(.semibold))
                    Text(log.exerciseName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    engine.setRepsForLastSet(reps - 1)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)

                Text("\(reps)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .frame(minWidth: 36)
                    .contentTransition(.numericText())

                Button {
                    engine.setRepsForLastSet(reps + 1)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
            }
            .cardStyle()
            .animation(.snappy, value: reps)
        }
    }

    // MARK: - Buttons

    private func primaryButton(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.title3.weight(.bold))
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(Theme.blue)
    }

    private func secondaryButton(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(Theme.blue)
    }

    private func circleButton(_ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .tint(.secondary)
    }

    // MARK: - Helpers

    private func targetText(_ planned: PlannedExercise) -> String {
        let perSide = planned.exercise.isUnilateral ? " per side" : ""
        if let seconds = planned.seconds { return "\(seconds) sec\(perSide)" }
        if let reps = planned.reps { return "\(reps.lowerBound)–\(reps.upperBound) reps\(perSide)" }
        return ""
    }
}
