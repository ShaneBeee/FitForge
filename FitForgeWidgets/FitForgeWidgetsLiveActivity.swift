import ActivityKit
import WidgetKit
import SwiftUI

/// FitForge colours (the widget can't see the app's Theme file).
private enum WidgetTheme {
    static let blue = Color(red: 0.15, green: 0.45, blue: 0.95)
    static let green = Color(red: 0.12, green: 0.70, blue: 0.52)
    static let gradient = LinearGradient(colors: [blue, green], startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// The workout Live Activity: rest countdown, current exercise and progress,
/// on the lock screen and in the Dynamic Island.
struct FitForgeWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            let display = Display(state: context.state, isStale: context.isStale)
            LockScreenView(attributes: context.attributes, display: display)
                .activityBackgroundTint(Color.black.opacity(0.75))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let display = Display(state: context.state, isStale: context.isStale)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.workoutTitle, systemImage: display.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetTheme.green)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(display: display)
                        .font(.title2.weight(.bold).monospacedDigit())
                        .frame(maxWidth: 90, alignment: .trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(display.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(display.state.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        ProgressBar(display: display)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: display.icon)
                    .foregroundStyle(WidgetTheme.green)
            } compactTrailing: {
                CompactTrailing(display: display)
            } minimal: {
                Image(systemName: display.icon)
                    .foregroundStyle(WidgetTheme.green)
            }
            .keylineTint(WidgetTheme.green)
        }
    }
}

// MARK: - What to show

/// Works out the text and icons from the state, including after a countdown has run out
/// while the app was asleep (iOS marks the content "stale" at that moment).
private struct Display {
    let state: WorkoutActivityAttributes.ContentState
    let isStale: Bool

    /// The rest or timed-set countdown has finished.
    var timerOver: Bool {
        guard state.phase == .resting || state.phase == .working, let end = state.timerEnd else { return false }
        return isStale || end <= .now
    }

    /// A live countdown window, when one is running.
    var countdown: ClosedRange<Date>? {
        guard state.phase != .paused, !timerOver, let start = state.timerStart, let end = state.timerEnd, start < end else { return nil }
        return start...end
    }

    var title: String {
        if timerOver && state.phase == .resting { return "Rest's up" }
        if timerOver && state.phase == .working { return "Set complete" }
        return state.title
    }

    var icon: String {
        if timerOver { return "bell.fill" }
        switch state.phase {
        case .ready: return "figure.strengthtraining.traditional"
        case .working: return "flame.fill"
        case .resting: return "timer"
        case .paused: return "pause.fill"
        case .finished: return "checkmark.seal.fill"
        }
    }

    /// Short label shown instead of a countdown.
    var label: String {
        if timerOver { return "Go" }
        switch state.phase {
        case .ready: return "Ready"
        case .working: return "Go"
        case .finished: return "Done"
        default: return "—"
        }
    }
}

// MARK: - Lock screen

private struct LockScreenView: View {
    let attributes: WorkoutActivityAttributes
    let display: Display

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: display.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(WidgetTheme.gradient, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(attributes.workoutTitle.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(WidgetTheme.green)
                    Text(display.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(display.state.detail)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                TimerText(display: display)
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(display.timerOver ? WidgetTheme.green : .white)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 110, alignment: .trailing)
            }

            ProgressBar(display: display)
        }
        .padding(16)
    }
}

// MARK: - Pieces

/// The big number on the right: a live countdown when there's a timer, otherwise a short label.
private struct TimerText: View {
    let display: Display

    var body: some View {
        if display.state.phase == .paused, let remaining = display.state.pausedRemaining {
            Text(Self.format(remaining))
        } else if let countdown = display.countdown {
            Text(timerInterval: countdown, countsDown: true)
        } else {
            Text(display.label)
        }
    }

    static func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// Compact Dynamic Island: countdown during rest/timed sets, otherwise sets done.
private struct CompactTrailing: View {
    let display: Display

    var body: some View {
        if let countdown = display.countdown {
            Text(timerInterval: countdown, countsDown: true)
                .monospacedDigit()
                .frame(maxWidth: 44)
                .foregroundStyle(WidgetTheme.green)
        } else if display.timerOver {
            Text("Go")
                .foregroundStyle(WidgetTheme.green)
        } else {
            Text("\(display.state.setsDone)/\(display.state.totalSets)")
                .monospacedDigit()
                .foregroundStyle(WidgetTheme.green)
        }
    }
}

/// Rest/timed-set countdown bar, or overall workout progress when there's no timer.
private struct ProgressBar: View {
    let display: Display

    var body: some View {
        if let countdown = display.countdown {
            ProgressView(timerInterval: countdown, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(WidgetTheme.green)
        } else {
            ProgressView(value: Double(display.state.setsDone), total: Double(max(display.state.totalSets, 1)))
                .tint(WidgetTheme.green)
        }
    }
}

// MARK: - Previews

extension WorkoutActivityAttributes {
    fileprivate static var preview: WorkoutActivityAttributes {
        WorkoutActivityAttributes(workoutTitle: "Day A", startedAt: .now)
    }
}

extension WorkoutActivityAttributes.ContentState {
    fileprivate static var resting: Self {
        Self(phase: .resting, title: "Rest", detail: "Up next: Push-Up · set 2 of 3",
             timerStart: .now, timerEnd: .now.addingTimeInterval(60), pausedRemaining: nil,
             setsDone: 4, totalSets: 12)
    }

    fileprivate static var restOver: Self {
        Self(phase: .resting, title: "Rest", detail: "Up next: Push-Up · set 2 of 3",
             timerStart: .now.addingTimeInterval(-60), timerEnd: .now.addingTimeInterval(-1), pausedRemaining: nil,
             setsDone: 4, totalSets: 12)
    }

    fileprivate static var ready: Self {
        Self(phase: .ready, title: "Goblet Squat", detail: "Set 1 of 3 · 8–12 reps",
             timerStart: nil, timerEnd: nil, pausedRemaining: nil,
             setsDone: 0, totalSets: 12)
    }
}

#Preview("Lock screen", as: .content, using: WorkoutActivityAttributes.preview) {
    FitForgeWidgetsLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState.resting
    WorkoutActivityAttributes.ContentState.restOver
    WorkoutActivityAttributes.ContentState.ready
}
