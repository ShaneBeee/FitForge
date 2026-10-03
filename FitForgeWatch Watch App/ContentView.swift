import SwiftUI

/// FitForge colours (the Watch app can't see the iPhone app's Theme file).
private enum WatchTheme {
    static let blue = Color(red: 0.15, green: 0.45, blue: 0.95)
    static let green = Color(red: 0.12, green: 0.70, blue: 0.52)
}

struct ContentView: View {
    @Environment(WorkoutManager.self) private var workout

    var body: some View {
        Group {
            if workout.isRunning {
                LiveWorkoutView()
            } else {
                IdleView()
            }
        }
        .task { await workout.requestAuthorization() }
        .animation(.snappy, value: workout.isRunning)
    }
}

/// Shown when no workout is running.
private struct IdleView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 36))
                .foregroundStyle(WatchTheme.green)
            Text("FitForge")
                .font(.headline)
            Text("Start a workout on your iPhone and it'll appear here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

/// During a workout: swipe up/down between controls, heart rate, and more options.
private struct LiveWorkoutView: View {
    var body: some View {
        TabView {
            ControlsPage()
            MetricsPage()
            MoreOptionsPage()
        }
        .tabViewStyle(.verticalPage)
    }
}

// MARK: - Controls (main page)

private struct ControlsPage: View {
    @Environment(WorkoutManager.self) private var workout

    var body: some View {
        if let state = workout.phoneState {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let timerOver = state.timerEnd.map { $0 <= context.date } ?? false
                let restUp = state.phase == .resting && timerOver && !state.isPaused

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label(workout.heartRate.map { "\(Int($0))" } ?? "--", systemImage: "heart.fill")
                            .foregroundStyle(WatchTheme.green)
                        Spacer()
                        Text("\(state.setsDone)/\(state.totalSets)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption2.weight(.semibold).monospacedDigit())

                    Text(restUp ? "Rest's up" : state.title)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Text(state.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Spacer(minLength: 2)

                    timer(state, timerOver: timerOver)

                    Spacer(minLength: 2)

                    Button {
                        workout.sendCommand(.primary)
                    } label: {
                        Text(restUp ? "Ready" : state.primaryLabel)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(restUp || state.phase == .ready ? WatchTheme.green : WatchTheme.blue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        } else {
            VStack(spacing: 8) {
                ProgressView()
                Text("Syncing with your iPhone…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func timer(_ state: WatchWorkoutState, timerOver: Bool) -> some View {
        if state.isPaused {
            Text(state.pausedRemaining.map(format) ?? "Paused")
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)
        } else if let start = state.timerStart, let end = state.timerEnd, start < end, !timerOver {
            Text(timerInterval: start...end, countsDown: true)
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(state.phase == .resting ? WatchTheme.blue : .primary)
        } else if state.phase == .working {
            Text("GO")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(WatchTheme.green)
        }
    }

    private func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Heart rate and calories

private struct MetricsPage: View {
    @Environment(WorkoutManager.self) private var workout

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let start = workout.startDate {
                Text(start, style: .timer)
                    .font(.system(.title2, design: .rounded, weight: .semibold).monospacedDigit())
                    .foregroundStyle(WatchTheme.blue)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(workout.heartRate.map { "\(Int($0))" } ?? "--")
                    .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                Image(systemName: "heart.fill")
                    .foregroundStyle(WatchTheme.green)
                    .symbolEffect(.pulse, isActive: workout.heartRate != nil)
                Text("BPM")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(workout.activeCalories))")
                    .font(.system(.title3, design: .rounded, weight: .semibold).monospacedDigit())
                Text("CAL")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(WatchTheme.green)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Skips, pause and rest time

private struct MoreOptionsPage: View {
    @Environment(WorkoutManager.self) private var workout

    var body: some View {
        let state = workout.phoneState

        ScrollView {
            VStack(spacing: 8) {
                if state?.phase == .resting {
                    HStack(spacing: 8) {
                        Button("−15s") { workout.sendCommand(.removeRest) }
                        Button("+15s") { workout.sendCommand(.addRest) }
                    }
                }

                if state?.phase == .ready || state?.phase == .working {
                    Button {
                        workout.sendCommand(.skipSet)
                    } label: {
                        Label("Skip set", systemImage: "forward")
                            .frame(maxWidth: .infinity)
                    }
                    Button {
                        workout.sendCommand(.skipExercise)
                    } label: {
                        Label("Skip exercise", systemImage: "forward.end")
                            .frame(maxWidth: .infinity)
                    }
                }

                Button {
                    workout.sendCommand(.togglePause)
                } label: {
                    Label(state?.isPaused == true ? "Resume" : "Pause",
                          systemImage: state?.isPaused == true ? "play.fill" : "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(WatchTheme.blue)

                Text("End the workout from your iPhone.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(WorkoutManager.shared)
}
