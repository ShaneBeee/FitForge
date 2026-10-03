import SwiftUI
import SwiftData

/// Dashboard card: current training phase, progress toward the next, and the unlock button.
struct PhaseCard: View {
    let profile: UserProfile
    let progress: PhaseProgress

    @Environment(\.modelContext) private var context
    @State private var unlockTrigger = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if let next = progress.next {
                if progress.isNextUnlocked {
                    unlocked(next)
                } else {
                    requirements(for: next)
                }
            } else {
                Text("You're in the final phase. Workouts keep getting harder as you move up to harder variations.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
        .sensoryFeedback(.success, trigger: unlockTrigger)
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: progress.current.systemImage)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Theme.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("PHASE \(progress.current.rawValue) OF \(TrainingPhase.allCases.count)")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.blue)
                Text(progress.current.title)
                    .font(.title3.weight(.bold))
                Text(progress.current.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func requirements(for next: TrainingPhase) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("To unlock \(next.title)")
                .font(.subheadline.weight(.semibold))

            requirementRow(
                title: "Workouts",
                value: "\(min(progress.workoutsDone, progress.workoutsNeeded)) of \(progress.workoutsNeeded)",
                fraction: Double(progress.workoutsDone) / Double(max(progress.workoutsNeeded, 1)),
                met: progress.workoutsMet
            )

            switch progress.requirement {
            case .bodyFat(let drop, let needed):
                requirementRow(
                    title: "Body fat drop",
                    value: drop.map { "\(format(max($0, 0))) of \(format(needed))%" } ?? "Needs a weigh-in",
                    fraction: (drop ?? 0) / needed,
                    met: progress.requirementMet
                )
            case .reps(let hitRate, let needed):
                requirementRow(
                    title: "Hitting the top of your rep ranges",
                    value: hitRate.map { "\(Int(($0 * 100).rounded()))% of \(Int(needed * 100))%" } ?? "After your first workouts",
                    fraction: (hitRate ?? 0) / needed,
                    met: progress.requirementMet
                )
            case nil:
                EmptyView()
            }
        }
    }

    private func requirementRow(title: String, value: String, fraction: Double, met: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: met ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(met ? Theme.green : .secondary)
                Spacer()
                Text(value)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(max(fraction, 0), 1))
                .tint(met ? Theme.green : Theme.blue)
        }
    }

    private func unlocked(_ next: TrainingPhase) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("\(next.title) phase unlocked!", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(Theme.green)
            Text("\(next.tagline) Start it whenever you're ready — your workouts update right away.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                startPhase(next)
            } label: {
                Label("Start \(next.title) phase", systemImage: next.systemImage)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Theme.green)
        }
    }

    // MARK: - Actions

    private func startPhase(_ phase: TrainingPhase) {
        withAnimation(.snappy) {
            profile.phase = phase
            profile.phaseStartedDate = .now
            try? context.save()
        }
        unlockTrigger.toggle()
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }
}
