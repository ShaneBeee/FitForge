import SwiftUI

/// Big countdown ring used for rest and timed sets.
struct TimerRing: View {
    let engine: WorkoutEngine
    let label: String
    var size: CGFloat = 280

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { context in
            let remaining = engine.remaining(at: context.date) ?? 0
            let fraction = engine.phaseDuration > 0 ? remaining / engine.phaseDuration : 0

            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 18)

                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(Theme.gradient, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text(label.uppercased())
                        .font(.headline)
                        .tracking(2)
                        .foregroundStyle(.secondary)
                    Text(Self.format(remaining))
                        .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                    if engine.isPaused {
                        Text("Paused")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.teal)
                    }
                }
            }
            .frame(width: size, height: size)
        }
    }

    static func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        return total >= 60 ? String(format: "%d:%02d", total / 60, total % 60) : "\(total)"
    }
}
