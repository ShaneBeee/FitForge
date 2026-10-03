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

/// Live heart rate, calories and elapsed time during a workout.
private struct LiveWorkoutView: View {
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
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
        .environment(WorkoutManager.shared)
}
