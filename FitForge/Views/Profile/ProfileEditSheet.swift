import SwiftUI
import SwiftData
import UIKit

/// The editable parts of the profile.
enum ProfileSection: String, Identifiable {
    case about, goal, starting, equipment, ability, schedule

    var id: String { rawValue }

    var title: String {
        switch self {
        case .about: "About you"
        case .goal: "Goal"
        case .starting: "Starting point"
        case .equipment: "Equipment"
        case .ability: "Ability"
        case .schedule: "Schedule"
        }
    }
}

/// Edits one profile section using the same screens as first-time setup.
struct ProfileEditSheet: View {
    let section: ProfileSection
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var draft: OnboardingDraft

    init(section: ProfileSection, profile: UserProfile) {
        self.section = section
        self.profile = profile
        _draft = State(initialValue: OnboardingDraft(editing: profile))
    }

    private var canSave: Bool {
        section != .schedule || draft.workoutWeekdays.count == draft.daysPerWeek
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding()
                    .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit \(section.title.lowercased())")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.apply(section, to: profile, in: context)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .interactiveDismissDisabled()
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .about:
            aboutEditor
        case .goal:
            VStack(spacing: 32) {
                GoalStep(draft: draft)
                TargetsStep(draft: draft)
            }
        case .starting:
            StartingPointStep(draft: draft)
        case .equipment:
            EquipmentStep(draft: draft)
        case .ability:
            AbilityStep(draft: draft)
        case .schedule:
            ScheduleStep(draft: draft)
        }
    }

    private var aboutEditor: some View {
        VStack(alignment: .leading, spacing: 20) {
            FormCard {
                Text("Name")
                    .font(.headline)
                TextField("First name", text: $draft.name)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                    .font(.title3)
                    .padding(12)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            WhyStep(draft: draft)
        }
    }
}
