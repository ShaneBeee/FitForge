import SwiftUI
import SwiftData

/// Everything about one past workout, set by set.
struct SessionDetailView: View {
    let session: WorkoutSession
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    /// Sets grouped by exercise, in the order they were done.
    private var groups: [(name: String, sets: [SetLog])] {
        let sets = (session.sets ?? []).sorted {
            ($0.exerciseIndex, $0.setNumber) < ($1.exerciseIndex, $1.setNumber)
        }
        var result: [(name: String, sets: [SetLog])] = []
        for set in sets {
            if let index = result.firstIndex(where: { $0.name == set.exerciseName }) {
                result[index].sets.append(set)
            } else {
                result.append((name: set.exerciseName, sets: [set]))
            }
        }
        return result
    }

    private var duration: TimeInterval? {
        session.endDate.map { $0.timeIntervalSince(session.startDate) }
    }

    private var doneCount: Int { (session.sets ?? []).filter { !$0.wasSkipped }.count }
    private var skippedCount: Int { (session.sets ?? []).filter(\.wasSkipped).count }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(session.day.title)
                            .font(.largeTitle.weight(.bold))
                        if WeekSchedule.isMakeUp(session, profile: profile) {
                            tag("Make-up", color: Theme.teal)
                        }
                        if session.status == .endedEarly {
                            tag("Ended early", color: .secondary)
                        }
                    }
                    Text(session.day.focus)
                        .font(.subheadline)
                        .foregroundStyle(Theme.blue)
                    Text(session.startDate.formatted(date: .complete, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                HStack(spacing: 12) {
                    stat("Time", duration.map { Duration.seconds($0).formatted(.time(pattern: .minuteSecond)) } ?? "—")
                    stat("Sets done", "\(doneCount)")
                    stat("Skipped", "\(skippedCount)")
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            ForEach(groups, id: \.name) { group in
                Section(group.name) {
                    ForEach(group.sets) { set in
                        HStack {
                            Text("Set \(set.setNumber)")
                            Spacer()
                            Text(set.resultText)
                                .fontWeight(.semibold)
                                .foregroundStyle(set.wasSkipped ? Color.secondary : Theme.green)
                            if let target = targetText(set) {
                                Text("/ \(target)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .monospacedDigit()
                    }
                }
            }

            Section {
                if let calories = session.activeCalories {
                    LabeledContent("Active calories", value: "About \(Int(calories))")
                    if let method = session.calorieMethod {
                        Text(method.description + (session.averageHeartRate.map { " (average \(Int($0)) bpm)" } ?? "") + ".")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let effort = session.effort {
                    LabeledContent("Effort", value: "\(effort) of 10")
                }

                Label(
                    session.savedToHealth ? "Saved to Apple Health" : "Not saved to Apple Health",
                    systemImage: session.savedToHealth ? "heart.fill" : "heart.slash"
                )
                .foregroundStyle(session.savedToHealth ? Theme.green : .secondary)

                Button("Delete workout") { confirmDelete = true }
                    .foregroundStyle(Theme.teal)
            } footer: {
                if session.savedToHealth {
                    Text("Deleting here doesn't remove the workout from Apple Health. You can delete it there in the Health app.")
                }
            }
        }
        .navigationTitle(session.startDate.formatted(.dateTime.month(.abbreviated).day()))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this workout?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete workout") {
                // Leave the screen first, then delete, so the view never shows a deleted workout.
                dismiss()
                let session = session
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    context.delete(session)
                    try? context.save()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It will be removed from your history and won't count toward this week.")
        }
    }

    private func targetText(_ set: SetLog) -> String? {
        if let low = set.targetRepsLow, let high = set.targetRepsHigh { return "\(low)–\(high)" }
        if let seconds = set.targetSeconds { return "\(seconds) sec" }
        return nil
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: Capsule())
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
