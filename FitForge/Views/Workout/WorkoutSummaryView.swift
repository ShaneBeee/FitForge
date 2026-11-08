import SwiftUI
import SwiftData

/// Shown when a guided workout ends.
struct WorkoutSummaryView: View {
    let engine: WorkoutEngine
    let onDone: () -> Void

    /// The set being corrected in the reps editor.
    @State private var editingLog: SetLog?

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

                // The last set had no rest screen after it, so its reps can be set here.
                if let log = engine.lastRepsLog, log.actualReps != nil {
                    RepsStepper(
                        title: "Reps on your last set",
                        subtitle: log.exerciseName,
                        log: log,
                        engine: engine
                    )
                    .cardStyle()
                }

                effortPicker

                VStack(spacing: 10) {
                    ForEach(Array(engine.plan.exercises.enumerated()), id: \.element.id) { index, planned in
                        exerciseResult(index: index, planned: planned)
                    }
                    Text("Tap any set to correct its reps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .sheet(item: $editingLog) { log in
            VStack(spacing: 16) {
                RepsStepper(
                    title: "Set \(log.setNumber)",
                    subtitle: log.exerciseName,
                    log: log,
                    engine: engine
                )
                Button("Done") { editingLog = nil }
                    .font(.headline)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(Theme.blue)
            }
            .padding(24)
            .presentationDetents([.height(200)])
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
                FlowingPills(logs: logs) { log in
                    editingLog = log
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

/// − / reps / + for correcting one set.
private struct RepsStepper: View {
    let title: String
    let subtitle: String
    let log: SetLog
    let engine: WorkoutEngine

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            let reps = log.actualReps ?? 0
            Button {
                engine.setReps(reps - 1, for: log)
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
                engine.setReps(reps + 1, for: log)
            } label: {
                Image(systemName: "plus")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
        }
        .animation(.snappy, value: log.actualReps)
    }
}

/// One pill per set, wrapping onto new lines. Rep-based sets are tappable to correct.
private struct FlowingPills: View {
    let logs: [SetLog]
    let onEdit: (SetLog) -> Void

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(logs) { log in
                let editable = !log.wasSkipped && log.actualReps != nil
                Button {
                    onEdit(log)
                } label: {
                    HStack(spacing: 4) {
                        Text(log.resultText)
                        if editable {
                            Image(systemName: "pencil")
                                .font(.caption2)
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        log.wasSkipped ? AnyShapeStyle(.background) : AnyShapeStyle(Theme.green.opacity(0.2)),
                        in: Capsule()
                    )
                    .foregroundStyle(log.wasSkipped ? Color.secondary : Theme.green)
                }
                .buttonStyle(.plain)
                .disabled(!editable)
            }
        }
    }
}

/// Lays children out left to right, wrapping to a new line when the row is full.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
