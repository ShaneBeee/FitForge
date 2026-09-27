import SwiftUI

struct StartingPointStep: View {
    @Bindable var draft: OnboardingDraft
    @Environment(HealthKitManager.self) private var health

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: "Where you're starting",
                subtitle: "Filled in from Apple Health where possible. Adjust anything that looks off.",
                systemImage: "figure.stand"
            )

            FormCard {
                NumberEntryRow(title: "Weight", unit: "lb", value: $draft.currentWeightLbs)
                Divider()
                NumberEntryRow(title: "Body fat", unit: "%", value: $draft.currentBodyFatPercent)
                Divider()
                heightRow
                Divider()
                DatePicker("Birthday", selection: $draft.birthDate, in: ...Date.now, displayedComponents: .date)
                    .padding(.vertical, 4)

                if draft.weighInDateFromHealth != nil {
                    Label("From your latest Apple Health weigh-in", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }

            SectionLabel("How active is your day?")
            ForEach(ActivityLevel.allCases) { level in
                OptionCard(
                    title: level.title,
                    detail: level.detail,
                    systemImage: level.systemImage,
                    isSelected: draft.activityLevel == level
                ) {
                    draft.activityLevel = level
                }
            }

            SectionLabel("Workout experience")
            HStack(spacing: 8) {
                ForEach(Experience.allCases) { level in
                    ChipButton(title: level.title, isSelected: draft.experience == level) {
                        draft.experience = level
                    }
                }
            }
        }
        .task {
            await health.refresh()
            draft.prefill(from: health)
        }
    }

    private var heightRow: some View {
        HStack {
            Text("Height")
            Spacer()
            Picker("Feet", selection: $draft.heightFeet) {
                ForEach(3...7, id: \.self) { Text("\($0) ft").tag($0) }
            }
            .labelsHidden()
            Picker("Inches", selection: $draft.heightInchesPart) {
                ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
            }
            .labelsHidden()
        }
    }
}
