import SwiftUI
import SwiftData

/// Shown when a guided workout ends.
struct WorkoutSummaryView: View {
    let engine: WorkoutEngine
    let onDone: () -> Void

    private var duration: TimeInterval {
        (engine.finishedAt ?? .now).timeIntervalSince(engine.startedAt)
    }

    private var isComplete: Bool { engine.session.status == .completed }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: isComplete ? "checkmark.seal.fill" : "flag.checkered")
                        .font(.system(size: 64))
                        .foregroundStyle(Theme.gradient)
                        .symbolEffect(.bounce, value: isComplete)
                    Text(isComplete ? "Workout complete!" : "Workout saved")
                        .font(.largeTitle.weight(.bold))
                    Text("\(engine.plan.day.title) · \(engine.plan.day.focus)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)

                HStack(spacing: 12) {
                    stat("Time", Duration.seconds(duration).formatted(.time(pattern: .minuteSecond)))
                    stat("Sets done", "\(engine.completedSets.count)")
                    stat("Calories", engine.calorieEstimate.map { "\(Int($0.activeCalories))" } ?? "—")
                }

                if let estimate = engine.calorieEstimate {
                    Label {
                        Text(caloriesNote(estimate))
                    } icon: {
                        Image(systemName: estimate.method == .activity ? "flame.fill" : "heart.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                effortPicker

                VStack(spacing: 10) {
                    ForEach(Array(engine.plan.exercises.enumerated()), id: \.element.id) { index, planned in
                        exerciseResult(index: index, planned: planned)
                    }
                }

                healthStatus

                Button {
                    engine.commitEffort()
                    onDone()
                } label: {
                    Text("Done")
                        .font(.title3.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(Theme.blue)
                .padding(.top, 8)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Calories and effort

    private func caloriesNote(_ estimate: CalorieEstimate) -> String {
        let amount = estimate.method == .watch ? "\(Int(estimate.activeCalories))" : "About \(Int(estimate.activeCalories))"
        var note = "\(amount) active calories. \(estimate.method.description)"
        if let heartRate = estimate.averageHeartRate {
            note += " (average \(Int(heartRate)) bpm)"
        }
        return note + "."
    }

    private var effortPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("How hard was that?")
                    .font(.headline)
                Spacer()
                if let effort = engine.effort {
                    Text(effortLabel(effort))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.blue)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(1...10, id: \.self) { score in
                    let isSelected = engine.effort == score
                    Button {
                        engine.setEffort(score)
                    } label: {
                        Text("\(score)")
                            .font(.headline.monospacedDigit())
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .background(
                                isSelected ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(.background),
                                in: Circle()
                            )
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: isSelected)
                }
            }

            Text("Saved to Apple Health as the workout's effort when you tap Done.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
        .animation(.snappy, value: engine.effort)
    }

    private func effortLabel(_ score: Int) -> String {
        switch score {
        case ...3: "Easy"
        case 4...6: "Moderate"
        case 7...8: "Hard"
        default: "All out"
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func exerciseResult(index: Int, planned: PlannedExercise) -> some View {
        let logs = engine.results
            .filter { $0.exerciseIndex == index }
            .sorted { $0.setNumber < $1.setNumber }

        return VStack(alignment: .leading, spacing: 8) {
            Text(planned.exercise.name)
                .font(.headline)
            if logs.isEmpty {
                Text("Not reached")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 6) {
                    ForEach(logs) { log in
                        Text(log.resultText)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                log.wasSkipped ? AnyShapeStyle(.background) : AnyShapeStyle(Theme.green.opacity(0.2)),
                                in: Capsule()
                            )
                            .foregroundStyle(log.wasSkipped ? Color.secondary : Theme.green)
                    }
                }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var healthStatus: some View {
        switch engine.healthSaveState {
        case .saving:
            Label("Saving to Apple Health…", systemImage: "heart")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .saved:
            Label("Saved to Apple Health", systemImage: "heart.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.green)
        case .failed:
            Label("Couldn't save to Apple Health", systemImage: "heart.slash")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .notAttempted:
            EmptyView()
        }
    }
}
