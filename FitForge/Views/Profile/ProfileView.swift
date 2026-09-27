import SwiftUI
import SwiftData

/// Read-only summary of the profile for now. Editing comes in a later step.
struct ProfileView: View {
    @Environment(\.modelContext) private var context
    let profile: UserProfile
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section("Goal") {
                    LabeledContent("Main goal", value: profile.goalType.title)
                    LabeledContent("Target weight", value: format(profile.targetWeightLbs, unit: "lb"))
                    LabeledContent("Target body fat", value: format(profile.targetBodyFatPercent, unit: "%"))
                    if !profile.why.isEmpty {
                        Text("“\(profile.why)”")
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Starting point") {
                    LabeledContent("Started", value: profile.startDate.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("Weight", value: format(profile.startWeightLbs, unit: "lb"))
                    LabeledContent("Body fat", value: format(profile.startBodyFatPercent, unit: "%"))
                    LabeledContent("Height", value: heightText)
                    if let birthDate = profile.birthDate {
                        LabeledContent("Age", value: "\(age(from: birthDate))")
                    }
                    LabeledContent("Activity", value: profile.activityLevel.title)
                    LabeledContent("Experience", value: profile.experience.title)
                }

                Section("Equipment") {
                    Label("Bodyweight", systemImage: "figure.stand")
                    ForEach(profile.equipment ?? []) { item in
                        Label(item.displayName, systemImage: item.kind.systemImage)
                    }
                }

                Section("Ability") {
                    ForEach(AbilityQuestion.allCases) { question in
                        LabeledContent(label(for: question), value: question.options[profile.tier(for: question)])
                    }
                    LabeledContent(
                        "Joints to protect",
                        value: profile.jointCautions.isEmpty ? "None" : profile.jointCautions.map(\.title).sorted().joined(separator: ", ")
                    )
                }

                Section("Schedule") {
                    LabeledContent("Workout days", value: profile.workoutWeekdays.map { Weekday.shortName($0) }.joined(separator: ", "))
                    LabeledContent("Weigh-in day", value: Weekday.name(profile.weighInWeekday))
                    LabeledContent("Rest between sets", value: "\(profile.restSeconds)s")
                }

                Section {
                    Button("Run setup again") { confirmReset = true }
                        .foregroundStyle(Theme.teal)
                } footer: {
                    Text("Editing each section right here is coming soon. For now, running setup again replaces your profile. Your weigh-in history is kept.")
                }
            }
            .navigationTitle(profile.name.isEmpty ? "Profile" : profile.name)
            .confirmationDialog("Run setup again?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Run setup again") { resetProfile() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your profile, goals and equipment will be replaced when you finish setup.")
            }
        }
    }

    // MARK: - Helpers

    private var heightText: String {
        guard let inches = profile.heightInches else { return "—" }
        let total = Int(inches.rounded())
        return "\(total / 12)′ \(total % 12)″"
    }

    private func format(_ value: Double?, unit: String) -> String {
        guard let value else { return "—" }
        return "\(value.formatted(.number.precision(.fractionLength(0...1)))) \(unit)"
    }

    private func age(from birthDate: Date) -> Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 0
    }

    private func label(for question: AbilityQuestion) -> String {
        switch question {
        case .pushUps: "Push-ups"
        case .plank: "Plank"
        case .squats: "Squats"
        }
    }

    private func resetProfile() {
        withAnimation {
            context.delete(profile)
            try? context.save()
        }
    }
}
