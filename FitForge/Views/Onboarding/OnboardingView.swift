import SwiftUI
import SwiftData
import UIKit

/// First-time setup. Shown until a profile has been created.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(HealthKitManager.self) private var health
    @State private var draft = OnboardingDraft()
    @State private var finishTrigger = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: draft.progress)
                    .tint(Theme.green)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .animation(.snappy, value: draft.progress)

                ScrollView {
                    stepContent
                        .padding()
                        .padding(.bottom, 24)
                        .id(draft.step)
                        .transition(stepTransition)
                }
                .scrollDismissesKeyboard(.interactively)

                bottomBar
            }
            .animation(.snappy, value: draft.step)
            .toolbar {
                if draft.step.canSkip {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") { draft.next() }
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                        .fontWeight(.semibold)
                }
            }
            .task {
                await health.checkAuthorization()
                await health.refresh()
            }
        }
        .sensoryFeedback(.success, trigger: finishTrigger)
    }

    // MARK: - Pieces

    @ViewBuilder
    private var stepContent: some View {
        switch draft.step {
        case .welcome: WelcomeStep(draft: draft)
        case .goal: GoalStep(draft: draft)
        case .starting: StartingPointStep(draft: draft)
        case .targets: TargetsStep(draft: draft)
        case .equipment: EquipmentStep(draft: draft)
        case .ability: AbilityStep(draft: draft)
        case .schedule: ScheduleStep(draft: draft)
        case .why: WhyStep(draft: draft)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if draft.step != .welcome {
                Button {
                    hideKeyboard()
                    draft.back()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 52, height: 52)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
            }

            Button {
                hideKeyboard()
                if draft.isLastStep {
                    finish()
                } else {
                    draft.next()
                }
            } label: {
                Text(draft.isLastStep ? "Finish" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Theme.blue)
            .disabled(!draft.canContinue)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: draft.movingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .opacity
        )
    }

    // MARK: - Actions

    private func finish() {
        finishTrigger.toggle()
        withAnimation(.snappy) {
            draft.save(in: context)
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    OnboardingView()
        .environment(HealthKitManager())
        .modelContainer(for: [UserProfile.self, EquipmentItem.self, BodyMeasurement.self], inMemory: true)
}
