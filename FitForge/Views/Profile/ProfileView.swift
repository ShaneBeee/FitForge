import SwiftUI
import SwiftData
import AVFoundation

/// The Profile tab: everything from setup, with each section editable.
struct ProfileView: View {
    @Environment(\.modelContext) private var context
    let profile: UserProfile
    @State private var confirmReset = false
    @State private var editing: ProfileSection?
    /// Watched so the voice name refreshes after picking a new one.
    @AppStorage(VoiceCoach.voiceDefaultsKey) private var voiceID = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Name", value: profile.name.isEmpty ? "—" : profile.name)
                    if profile.why.isEmpty {
                        LabeledContent("Your why", value: "Not set")
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your why")
                            Text("“\(profile.why)”")
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    header(.about)
                }

                Section {
                    LabeledContent("Main goal", value: profile.goalType.title)
                    LabeledContent("Target weight", value: format(profile.targetWeightLbs, unit: "lb"))
                    LabeledContent("Target body fat", value: format(profile.targetBodyFatPercent, unit: "%"))
                } header: {
                    header(.goal)
                }

                Section {
                    LabeledContent("Started", value: profile.startDate.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("Weight", value: format(profile.startWeightLbs, unit: "lb"))
                    LabeledContent("Body fat", value: format(profile.startBodyFatPercent, unit: "%"))
                    LabeledContent("Height", value: heightText)
                    if let birthDate = profile.birthDate {
                        LabeledContent("Age", value: "\(age(from: birthDate))")
                    }
                    LabeledContent("Activity", value: profile.activityLevel.title)
                    LabeledContent("Experience", value: profile.experience.title)
                    LabeledContent("Body fat ranges", value: profile.bodyFatRanges?.title ?? "Not set")
                } header: {
                    header(.starting)
                }

                Section {
                    Label("Bodyweight", systemImage: "figure.stand")
                    ForEach(sortedEquipment) { item in
                        Label(item.displayName, systemImage: item.kind.systemImage)
                    }
                } header: {
                    header(.equipment)
                } footer: {
                    Text("Your workouts update automatically when your equipment changes.")
                }

                Section {
                    ForEach(AbilityQuestion.allCases) { question in
                        LabeledContent(label(for: question), value: question.options[min(profile.tier(for: question), question.options.count - 1)])
                    }
                    LabeledContent(
                        "Joints to protect",
                        value: profile.jointCautions.isEmpty ? "None" : profile.jointCautions.map(\.title).sorted().joined(separator: ", ")
                    )
                } header: {
                    header(.ability)
                }

                Section {
                    LabeledContent("Plan", value: "\(profile.workoutWeekdays.count) days a week · \(profile.workoutMinutes) min")
                    LabeledContent("Workout days", value: WorkoutSchedule.orderedWorkoutDays(for: profile).map { Weekday.shortName($0) }.joined(separator: ", "))
                    LabeledContent("Weigh-in day", value: Weekday.name(profile.weighInWeekday))
                    LabeledContent("Rest between sets", value: "\(profile.restSeconds)s")
                } header: {
                    header(.schedule)
                } footer: {
                    Text(WorkoutPlans.planDescription(forDaysPerWeek: profile.workoutWeekdays.count))
                }

                Section("Coach") {
                    NavigationLink {
                        VoicePickerView()
                    } label: {
                        LabeledContent("Voice", value: voiceID.isEmpty
                            ? "Automatic (\(VoiceCoach.bestAvailableVoice()?.name ?? "Default"))"
                            : (VoiceCoach.selectedVoice?.name ?? "Default"))
                    }
                }

                Section {
                    Button("Run setup again") { confirmReset = true }
                        .foregroundStyle(Theme.teal)
                } footer: {
                    Text("Starts first-time setup from scratch and replaces your profile. Your workout and weigh-in history is kept.")
                }
            }
            .navigationTitle(profile.name.isEmpty ? "Profile" : profile.name)
            .sheet(item: $editing) { section in
                ProfileEditSheet(section: section, profile: profile)
            }
            .confirmationDialog("Run setup again?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Run setup again") { resetProfile() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your profile, goals and equipment will be replaced when you finish setup.")
            }
        }
    }

    // MARK: - Pieces

    private func header(_ section: ProfileSection) -> some View {
        HStack {
            Text(section.title)
            Spacer()
            Button("Edit") { editing = section }
                .font(.subheadline.weight(.semibold))
                .textCase(nil)
                .foregroundStyle(Theme.blue)
        }
    }

    private var sortedEquipment: [EquipmentItem] {
        let order = EquipmentKind.allCases
        return (profile.equipment ?? []).sorted {
            (order.firstIndex(of: $0.kind) ?? 0) < (order.firstIndex(of: $1.kind) ?? 0)
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
