import SwiftUI

struct WelcomeStep: View {
    @Bindable var draft: OnboardingDraft
    @Environment(HealthKitManager.self) private var health

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            StepHeader(
                title: "Welcome to FitForge",
                subtitle: "A few quick questions and your workouts will be built around you. Everything can be changed later.",
                systemImage: "bolt.heart.fill"
            )

            FormCard {
                Text("What should we call you?")
                    .font(.headline)
                TextField("First name", text: $draft.name)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                    .font(.title3)
                    .padding(12)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            healthCard
        }
    }

    @ViewBuilder
    private var healthCard: some View {
        if health.isAvailable {
            FormCard {
                Label("Apple Health", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.green)

                if health.needsAuthorization {
                    Text("Connect Apple Health so FitForge can fill in your stats and pick up weigh-ins from your scale automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        Task { await health.requestAuthorization() }
                    } label: {
                        Text("Connect Apple Health")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.green)
                } else {
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
