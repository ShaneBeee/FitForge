import Foundation
import HealthKit
import Observation

/// Everything FitForge reads from and writes to Apple Health.
@Observable
final class HealthKitManager {

    struct Reading: Equatable {
        let value: Double
        let date: Date
    }

    private let store = HKHealthStore()

    /// False on devices without Health (e.g. Mac).
    let isAvailable = HKHealthStore.isHealthDataAvailable()

    /// True until the user has been shown the Health permission sheet.
    private(set) var needsAuthorization = true
    private(set) var hasCheckedAuthorization = false

    private(set) var latestWeight: Reading?        // lb
    private(set) var latestBodyFat: Reading?       // percent, e.g. 21.4
    private(set) var latestHeight: Reading?        // inches
    private(set) var birthDate: Date?
    private(set) var isLoading = false
    private(set) var lastError: String?

    // MARK: - Types

    private var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.bodyMass),
            HKQuantityType(.bodyFatPercentage),
            HKQuantityType(.leanBodyMass),
            HKQuantityType(.bodyMassIndex),
            HKQuantityType(.height),
            HKQuantityType(.heartRate),
            HKCharacteristicType(.dateOfBirth),
            HKObjectType.workoutType()
        ]
    }

    private var shareTypes: Set<HKSampleType> {
        [
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned)
        ]
    }

    // MARK: - Authorization

    /// Checks whether the permission sheet still needs to be shown.
    /// (For privacy, iOS never tells apps whether *read* access was granted —
    /// only whether the user has been asked.)
    func checkAuthorization() async {
        guard isAvailable else { return }
        do {
            let status = try await store.statusForAuthorizationRequest(toShare: shareTypes, read: readTypes)
            needsAuthorization = (status == .shouldRequest)
        } catch {
            lastError = error.localizedDescription
        }
        hasCheckedAuthorization = true
    }

    /// Shows the Health permission sheet, then loads the latest data.
    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            needsAuthorization = false
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Reading

    /// Loads the most recent body stats from Health.
    func refresh() async {
        guard isAvailable, !needsAuthorization else { return }
        isLoading = true
        defer { isLoading = false }
        lastError = nil

        latestWeight = await latestSample(.bodyMass, unit: .pound())
        latestBodyFat = await latestSample(.bodyFatPercentage, unit: .percent())
            .map { Reading(value: $0.value * 100, date: $0.date) }   // Health stores 0.214 for 21.4%
        latestHeight = await latestSample(.height, unit: .inch())
        birthDate = readBirthDate()
    }

    private func latestSample(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Reading? {
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(identifier))],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        do {
            guard let sample = try await descriptor.result(for: store).first else { return nil }
            return Reading(value: sample.quantity.doubleValue(for: unit), date: sample.endDate)
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    private func readBirthDate() -> Date? {
        guard let components = try? store.dateOfBirthComponents() else { return nil }
        return Calendar.current.date(from: components)
    }

    // MARK: - History

    /// Weight readings (lb) since a date, oldest first, one per day (the latest that day).
    func weightHistory(since start: Date) async -> [Reading] {
        await history(.bodyMass, unit: .pound(), since: start)
    }

    /// Body fat readings (percent, e.g. 21.4) since a date, oldest first, one per day.
    func bodyFatHistory(since start: Date) async -> [Reading] {
        await history(.bodyFatPercentage, unit: .percent(), since: start)
            .map { Reading(value: $0.value * 100, date: $0.date) }
    }

    private func history(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, since start: Date) async -> [Reading] {
        guard isAvailable, !needsAuthorization else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: nil)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(identifier), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .forward)]
        )
        do {
            let samples = try await descriptor.result(for: store)
            let readings = samples.map { Reading(value: $0.quantity.doubleValue(for: unit), date: $0.endDate) }
            return Self.onePerDay(readings)
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    /// Keeps the last reading of each day, so repeat weigh-ins don't clutter the charts.
    private static func onePerDay(_ readings: [Reading]) -> [Reading] {
        var byDay: [Date: Reading] = [:]
        for reading in readings {
            byDay[Calendar.current.startOfDay(for: reading.date)] = reading
        }
        return byDay.values.sorted { $0.date < $1.date }
    }

    // MARK: - Writing

    /// Saves a finished strength workout to Apple Health.
    func saveStrengthWorkout(start: Date, end: Date) async throws {
        guard isAvailable else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        try await builder.beginCollection(at: start)
        try await builder.endCollection(at: end)
        _ = try await builder.finishWorkout()
    }
}
