import SwiftUI
import SwiftData

/// Shows first-time setup until a profile exists, then the main tabs.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @State private var isRestoring = false
    @State private var restoreMessage: RestoreMessage?

    private var profile: UserProfile? {
        profiles.first(where: \.hasCompletedSetup)
    }

    var body: some View {
        Group {
            if isRestoring {
                ProgressView("Restoring your backup…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let profile {
                MainTabView(profile: profile)
                    .id(profile.persistentModelID)
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: profile == nil)
        .environment(\.restoreBackup) { file in startRestore(file) }
        .alert(
            restoreMessage?.title ?? "",
            isPresented: Binding(get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } }),
            presenting: restoreMessage
        ) { _ in
            Button("OK") {}
        } message: { message in
            Text(message.text)
        }
    }

    /// Takes every screen away first, so nothing is showing the old data while it's replaced.
    private func startRestore(_ file: BackupFile) {
        isRestoring = true
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            do {
                let safetyCopy = try BackupService.restore(file, into: context)
                var text = "FitForge now has your backup from \(file.createdAt.formatted(date: .abbreviated, time: .shortened)): \(file.summary)."
                if let safetyCopy {
                    text += "\n\nWhat was in the app before was saved to \(safetyCopy)."
                }
                if !BackupService.hasFolder {
                    text += "\n\nChoose a backup folder in Profile › Backup so automatic backups keep going."
                } else {
                    BackupService.autoBackup(context)
                }
                restoreMessage = RestoreMessage(title: "Backup restored", text: text)
            } catch {
                restoreMessage = RestoreMessage(title: "Couldn't restore", text: error.localizedDescription)
            }
            isRestoring = false
        }
    }
}

private struct RestoreMessage: Identifiable {
    let id = UUID()
    let title: String
    let text: String
}

/// The app's main tab bar.
struct MainTabView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(HealthKitManager.self) private var health
    @Environment(\.scenePhase) private var scenePhase

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
            // Send any effort ratings that were waiting for the Watch's workout to reach Health.
            await EffortSync.retryPending(in: context, health: health)
            BackupService.autoBackup(context)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await EffortSync.retryPending(in: context, health: health) }
            } else if phase == .background {
                BackupService.autoBackup(context)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(HealthKitManager())
        .modelContainer(for: [UserProfile.self, EquipmentItem.self, BodyMeasurement.self], inMemory: true)
}
