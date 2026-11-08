import SwiftUI

struct EquipmentStep: View {
    @Bindable var draft: OnboardingDraft

    /// Kinds where the heavier weights (55 lb and up) are showing.
    @State private var showingHeavier: Set<EquipmentKind> = []

    private static let standardWeights: [Double] = Array(stride(from: 5.0, through: 50.0, by: 5.0))
    private static let heavierWeights: [Double] = Array(stride(from: 55.0, through: 100.0, by: 5.0))
    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StepHeader(
                title: "What equipment do you have?",
                subtitle: "Bodyweight is always included. Workouts adapt to whatever you pick, and you can change this anytime.",
                systemImage: "dumbbell.fill"
            )

            ForEach(EquipmentCategory.allCases) { category in
                Text(category.title)
                    .font(.title3.weight(.bold))
                    .padding(.top, 8)

                ForEach(category.kinds) { kind in
                    VStack(spacing: 8) {
                        OptionCard(
                            title: kind.title,
                            detail: kind.detail,
                            systemImage: kind.systemImage,
                            isSelected: draft.selectedEquipment.contains(kind)
                        ) {
                            draft.toggleEquipment(kind)
                        }

                        if draft.selectedEquipment.contains(kind) {
                            VStack(spacing: 8) {
                                inUseCard(for: kind)
                                if kind.hasWeight {
                                    weightsCard(for: kind)
                                }
                            }
                            .padding(.leading, 24)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
            }

            Text("No need to list a yoga mat — floor exercises assume you've got something comfortable to lie on.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .animation(.snappy, value: draft.selectedEquipment)
        .animation(.snappy, value: draft.adjustableKinds)
        .animation(.snappy, value: draft.notInUse)
        .animation(.snappy, value: showingHeavier)
    }

    // MARK: - In use

    private func inUseCard(for kind: EquipmentKind) -> some View {
        FormCard {
            Toggle(isOn: Binding(
                get: { !draft.notInUse.contains(kind) },
                set: { draft.setInUse($0, for: kind) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use in workouts")
                        .font(.subheadline.weight(.semibold))
                    Text(draft.notInUse.contains(kind)
                         ? "Saved as owned, but left out of workouts for now."
                         : "Workouts include exercises for it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Theme.green)
        }
    }

    // MARK: - Weights

    private func weightsCard(for kind: EquipmentKind) -> some View {
        FormCard {
            Picker("Type", selection: adjustableBinding(for: kind)) {
                Text("Fixed weights").tag(false)
                Text("Adjustable").tag(true)
            }
            .pickerStyle(.segmented)

            if draft.adjustableKinds.contains(kind) {
                Text("Enter the lightest and heaviest settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                NumberEntryRow(title: "Lightest", unit: "lb", value: rangeBinding(for: kind, \.adjustableMin))
                Divider()
                NumberEntryRow(title: "Heaviest", unit: "lb", value: rangeBinding(for: kind, \.adjustableMax))
            } else {
                Text(kind == .dumbbells ? "Tap every pair you have (weight per dumbbell)." : "Tap every weight you have.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(visibleWeights(for: kind), id: \.self) { weight in
                        ChipButton(
                            title: EquipmentItem.format(weight),
                            isSelected: draft.fixedWeights[kind]?.contains(weight) == true
                        ) {
                            draft.toggleWeight(weight, for: kind)
                        }
                    }
                }

                Button(showingHeavier.contains(kind) ? "Show fewer" : "More (55–100 lb)") {
                    if showingHeavier.contains(kind) {
                        showingHeavier.remove(kind)
                    } else {
                        showingHeavier.insert(kind)
                    }
                }
                .font(.subheadline.weight(.semibold))

                if let weights = draft.fixedWeights[kind], !weights.isEmpty {
                    Text("Selected: " + weights.sorted().map(EquipmentItem.format).joined(separator: ", ") + " lb")
                        .font(.caption)
                        .foregroundStyle(Theme.blue)
                }
            }
        }
    }

    /// 5–50 lb, plus the heavier ones when expanded (or when one of them is already selected).
    private func visibleWeights(for kind: EquipmentKind) -> [Double] {
        let selectedHeavy = (draft.fixedWeights[kind] ?? []).filter { $0 > 50 }
        if showingHeavier.contains(kind) {
            return Self.standardWeights + Self.heavierWeights
        }
        return Self.standardWeights + Self.heavierWeights.filter { selectedHeavy.contains($0) }
    }

    private func adjustableBinding(for kind: EquipmentKind) -> Binding<Bool> {
        Binding(
            get: { draft.adjustableKinds.contains(kind) },
            set: { draft.setAdjustable($0, for: kind) }
        )
    }

    private func rangeBinding(
        for kind: EquipmentKind,
        _ keyPath: ReferenceWritableKeyPath<OnboardingDraft, [EquipmentKind: Double]>
    ) -> Binding<Double?> {
        Binding(
            get: { draft[keyPath: keyPath][kind] },
            set: { draft[keyPath: keyPath][kind] = $0 }
        )
    }
}
