import SwiftUI
import SwiftData

@main
struct FitForgeApp: App {
    @State private var health = HealthKitManager()
    /// Created at launch so it's ready to catch the Watch's mirrored workout session.
    @State private var watch = WatchWorkoutLink()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(health)
                .environment(watch)
        }
        .modelContainer(for: [
            UserProfile.self,
            EquipmentItem.self,
            BodyMeasurement.self,
            WorkoutSession.self,
            SetLog.self,
            TapeMeasurement.self
        ])
    }
}
