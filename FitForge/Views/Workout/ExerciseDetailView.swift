import SwiftUI

/// Full details for one exercise: what it is, how to do it, and what it needs.
struct ExerciseDetailView: View {
    let planned: PlannedExercise
    @Environment(\.dismiss) private var dismiss

    private var exercise: Exercise { planned.exercise }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: exercise.pattern.systemImage)
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.gradient)
                        Text(exercise.name)
                            .font(.largeTitle.weight(.bold))
                        Text(exercise.summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        infoTile(title: "Target", value: planned.prescription)
                        infoTile(title: "Rest", value: "\(planned.restSeconds)s")
                    }

                    FormCard {
                        Text("How to do it")
                            .font(.headline)
                        ForEach(Array(exercise.cues.enumerated()), id: \.offset) { index, cue in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Theme.blue, in: Circle())
                                Text(cue)
                                    .font(.body)
                            }
                        }
                    }

                    FormCard {
                        LabeledContent("Works", value: exercise.muscles.map(\.title).joined(separator: ", "))
                        Divider()
                        LabeledContent("Movement", value: exercise.pattern.title)
                        Divider()
                        LabeledContent("Level", value: exercise.difficulty.title)
                        Divider()
                        LabeledContent("Equipment", value: equipmentText)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var equipmentText: String {
        let names = EquipmentKind.allCases.filter { exercise.equipment.contains($0) }.map(\.title)
        return names.isEmpty ? "Bodyweight" : names.joined(separator: ", ")
    }

    private func infoTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .cardStyle()
    }
}
