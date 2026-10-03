import SwiftUI
import WatchKit
import HealthKit

/// Receives the "start a workout" request when the iPhone launches FitForge on the Watch.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Task { await WorkoutManager.shared.start(with: workoutConfiguration) }
    }
}

@main
struct FitForgeWatch_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(WorkoutManager.shared)
        }
    }
}
