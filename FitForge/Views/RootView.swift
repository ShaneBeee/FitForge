import SwiftUI
import SwiftData

/// Shows first-time setup until a profile exists, then the main tabs.
struct RootView: View {
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? {
        profiles.first(where: \.hasCompletedSetup)
    }

    var body: some View {
        Group {
            if let profile {
                MainTabView(profile: profile)
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: profile == nil)
    }
}

/// The app's main tab bar.
struct MainTabView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house.fill") {
                DashboardView(profile: profile)
            }

            Tab("Workout", systemImage: "figure.strengthtraining.traditional") {
                WorkoutView(profile: profile)
            }

            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis") {
                ProgressScreen(profile: profile)
            }

            Tab("History", systemImage: "calendar") {
                HistoryScreen(profile: profile)
            }

            Tab("Profile", systemImage: "person.crop.circle") {
                ProfileView(profile: profile)
            }
        }
        .tint(Theme.blue)
        .task {
            // Tidy up any workout that was interrupted by the app closing.
            WorkoutSession.finalizeUnfinished(in: context)
        }
    }
}

#Preview {
    RootView()
        .environment(HealthKitManager())
        .modelContainer(for: [UserProfile.self, EquipmentItem.self, BodyMeasurement.self], inMemory: true)
}
