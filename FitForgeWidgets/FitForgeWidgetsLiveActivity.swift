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
            LockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.75))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.workoutTitle, systemImage: PhaseIcon.name(for: context.state.phase))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetTheme.green)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(state: context.state)
                        .font(.title2.weight(.bold).monospacedDigit())
                        .frame(maxWidth: 90, alignment: .trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(context.state.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        ProgressBar(state: context.state)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: PhaseIcon.name(for: context.state.phase))
                    .foregroundStyle(WidgetTheme.green)
            } compactTrailing: {
                CompactTrailing(state: context.state)
            } minimal: {
                Image(systemName: PhaseIcon.name(for: context.state.phase))
                    .foregroundStyle(WidgetTheme.green)
            }
            .keylineTint(WidgetTheme.green)
        }
    }
}

// MARK: - Lock screen

private struct LockScreenView: View {
    let attributes: WorkoutActivityAttributes
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: PhaseIcon.name(for: state.phase))
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(WidgetTheme.gradient, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(attributes.workoutTitle.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(WidgetTheme.green)
                    Text(state.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(state.detail)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                TimerText(state: state)
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 110, alignment: .trailing)
            }

            ProgressBar(state: state)
        }
        .padding(16)
    }
}

// MARK: - Pieces

private enum PhaseIcon {
    static func name(for phase: WorkoutActivityAttributes.ContentState.Phase) -> String {
        switch phase {
        case .ready: "figure.strengthtraining.traditional"
        case .working: "flame.fill"
        case .resting: "timer"
        case .paused: "pause.fill"
        case .finished: "checkmark.seal.fill"
        }
    }
}

/// The big number on the right: a live countdown when there's a timer, otherwise a short label.
private struct TimerText: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        if state.phase == .paused, let remaining = state.pausedRemaining {
            Text(Self.format(remaining))
        } else if let start = state.timerStart, let end = state.timerEnd, end > .now {
            Text(timerInterval: start...end, countsDown: true)
        } else {
            switch state.phase {
            case .ready: Text("Ready")
            case .working: Text("Go")
            case .finished: Text("Done")
            default: Text("—")
            }
        }
    }

    static func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// Compact Dynamic Island: countdown during rest/timed sets, otherwise sets done.
private struct CompactTrailing: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        if let start = state.timerStart, let end = state.timerEnd, end > .now, state.phase != .paused {
            Text(timerInterval: start...end, countsDown: true)
                .monospacedDigit()
                .frame(maxWidth: 44)
                .foregroundStyle(WidgetTheme.green)
        } else {
            Text("\(state.setsDone)/\(state.totalSets)")
                .monospacedDigit()
                .foregroundStyle(WidgetTheme.green)
        }
    }
}

/// Rest/timed-set countdown bar, or overall workout progress when there's no timer.
private struct ProgressBar: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        if let start = state.timerStart, let end = state.timerEnd, end > .now, state.phase != .paused {
            ProgressView(timerInterval: start...end, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(WidgetTheme.green)
        } else {
            ProgressView(value: Double(state.setsDone), total: Double(max(state.totalSets, 1)))
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
    WorkoutActivityAttributes.ContentState.ready
}
