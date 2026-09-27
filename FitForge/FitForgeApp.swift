import SwiftUI
import SwiftData

@main
struct FitForgeApp: App {
    @State private var health = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(health)
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
