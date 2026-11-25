import Foundation
import SwiftData

/// Attaches effort ratings that couldn't be sent to Apple Health right after a workout.
///
/// When the Apple Watch records a workout, the Watch saves it to Health, and it can take a while
/// to sync over to the iPhone. If the phone couldn't find it in time to attach your effort,
/// the workout is marked as waiting, and this tries again each time the app opens.
enum EffortSync {
    /// Stop trying after this long (e.g. if the workout was deleted from Health).
    private static let giveUpAfter: TimeInterval = 7 * 86_400

    @MainActor
    static func retryPending(in context: ModelContext, health: HealthKitManager) async {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.effortPendingHealth }
        )
        guard let pending = try? context.fetch(descriptor), !pending.isEmpty else { return }

        if !health.hasCheckedAuthorization {
            await health.checkAuthorization()
        }

        for session in pending {
            guard let effort = session.effort, let end = session.endDate else {
                session.effortPendingHealth = false
                continue
            }
            if let workout = await health.strengthWorkout(near: session.startDate, end: end) {
                do {
                    try await health.saveEffort(effort, for: workout)
                    session.effortPendingHealth = false
                } catch {
                    // Leave it waiting; try again next time.
                }
            } else if Date.now.timeIntervalSince(end) > giveUpAfter {
                session.effortPendingHealth = false
            }
        }
        try? context.save()
    }
}
