import SwiftUI

struct EquipmentStep: View {
    @Bindable var draft: OnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StepHeader(
                title: "What equipment do you have?",
                subtitle: "Bodyweight is always included. Workouts adapt to whatever you pick, and you can change this anytime.",
                systemImage: "dumbbell.fill"
            )

            ForEach(EquipmentKind.allCases) { kind in
                VStack(spacing: 8) {
                    OptionCard(
                        title: kind.title,
                        detail: kind.detail,
                        systemImage: kind.systemImage,
                        isSelected: draft.selectedEquipment.contains(kind)
                    ) {
                        draft.toggleEquipment(kind)
                    }

                    if kind.hasWeight && draft.selectedEquipment.contains(kind) {
                        FormCard {
                            NumberEntryRow(
                                title: kind == .dumbbells ? "Weight per dumbbell" : "Weight",
                                unit: "lb",
                                value: weightBinding(for: kind)
                            )
                        }
                        .padding(.leading, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }

            Text("No need to list a yoga mat — floor exercises assume you've got something comfortable to lie on.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .animation(.snappy, value: draft.selectedEquipment)
    }

    private func weightBinding(for kind: EquipmentKind) -> Binding<Double?> {
        Binding(
            get: { draft.equipmentWeights[kind] },
            set: { draft.equipmentWeights[kind] = $0 }
        )
    }
}
