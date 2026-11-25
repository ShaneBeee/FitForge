import Foundation
import SwiftData

// CloudKit-ready rules followed in every model:
//  - every property has a default value or is optional
//  - no @Attribute(.unique)
//  - relationships are optional
// This lets us switch on iCloud sync later without a migration.

@Model
final class UserProfile {
    var name: String = ""
    var birthDate: Date? = nil
    var heightInches: Double? = nil

    // Goals
    var goalTypeRaw: String = GoalType.both.rawValue
    var targetWeightLbs: Double? = nil
    var targetBodyFatPercent: Double? = nil
    var why: String = ""
    /// Up to 3 FocusArea raw values.
    var focusAreasRaw: [String] = []

    // Starting point (baseline for progress)
    var startDate: Date = Date.now
    var startWeightLbs: Double? = nil
    var startBodyFatPercent: Double? = nil
    var activityLevelRaw: String = ActivityLevel.mostlySitting.rawValue
    var experienceRaw: String = Experience.new.rawValue
    var jointCautionsRaw: [String] = []
    /// "male", "female" or "" (not chosen yet) — only used to pick body fat ranges.
    var bodyFatRangesRaw: String = ""

    // Ability answers — tier 0…3 for each AbilityQuestion
    var pushUpTier: Int = 0
    var plankTier: Int = 0
    var squatTier: Int = 0

    // Schedule — Calendar weekday numbers (1 = Sunday … 7 = Saturday)
    var workoutWeekdays: [Int] = [2, 4, 6]   // Mon, Wed, Fri — the count sets the plan (2–6 days)
    var weighInWeekday: Int = 1              // Sunday
    var restSeconds: Int = 60
    /// Target workout length in minutes (20, 30, 45 or 60).
    var workoutMinutes: Int = 20

    /// Which tape measurements to track (MeasureSite raw values). Empty means the defaults.
    var trackedSitesRaw: [String] = []

    var hasCompletedSetup: Bool = false

    /// Current training phase (TrainingPhase raw value) and when it started.
    var phaseRaw: Int = 1
    var phaseStartedDate: Date? = nil

    /// Movements moved up a level after their exercises got too easy (MovementPattern raw values;
    /// a pattern listed twice is two levels up).
    var levelBoostsRaw: [String] = []
    /// "Not yet" answers to a harder-exercise offer: "exerciseID|seconds since 1970".
    var graduationSnoozesRaw: [String] = []

    @Relationship(deleteRule: .cascade, inverse: \EquipmentItem.profile)
    var equipment: [EquipmentItem]? = []

    init() {}

    // MARK: - Typed accessors

    var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw) ?? .both }
        set { goalTypeRaw = newValue.rawValue }
    }

    var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRaw) ?? .mostlySitting }
        set { activityLevelRaw = newValue.rawValue }
    }

    var experience: Experience {
        get { Experience(rawValue: experienceRaw) ?? .new }
        set { experienceRaw = newValue.rawValue }
    }

    var jointCautions: Set<JointCaution> {
        get { Set(jointCautionsRaw.compactMap(JointCaution.init(rawValue:))) }
        set { jointCautionsRaw = newValue.map(\.rawValue).sorted() }
    }

    var bodyFatRanges: BodyFatRanges? {
        get { BodyFatRanges(rawValue: bodyFatRangesRaw) }
        set { bodyFatRangesRaw = newValue?.rawValue ?? "" }
    }

    var phase: TrainingPhase {
        get { TrainingPhase(rawValue: phaseRaw) ?? .foundation }
        set { phaseRaw = newValue.rawValue }
    }

    /// Focus areas in a consistent order.
    var focusAreas: [FocusArea] {
        get { FocusArea.allCases.filter { focusAreasRaw.contains($0.rawValue) } }
        set { focusAreasRaw = newValue.map(\.rawValue) }
    }

    /// Tracked measurement sites in a consistent order (the defaults if none are chosen).
    var trackedSites: [MeasureSite] {
        get {
            let sites = MeasureSite.allCases.filter { trackedSitesRaw.contains($0.rawValue) }
            return sites.isEmpty ? MeasureSite.defaultTracked : sites
        }
        set { trackedSitesRaw = newValue.map(\.rawValue) }
    }

    // MARK: - Moving up a level

    /// Extra levels this movement has been moved up.
    func levelBoost(for pattern: MovementPattern) -> Int {
        levelBoostsRaw.filter { $0 == pattern.rawValue }.count
    }

    func moveUpLevel(for pattern: MovementPattern) {
        levelBoostsRaw.append(pattern.rawValue)
    }

    /// How long a "Not yet" lasts before the offer can come back.
    static let graduationSnoozeDays = 14

    func isGraduationSnoozed(_ exerciseID: String, now: Date = .now) -> Bool {
        graduationSnoozesRaw.contains { entry in
            let parts = entry.split(separator: "|")
            guard parts.count == 2, parts[0] == exerciseID, let seconds = Double(parts[1]) else { return false }
            let snoozedAt = Date(timeIntervalSince1970: seconds)
            return now.timeIntervalSince(snoozedAt) < Double(Self.graduationSnoozeDays) * 86_400
        }
    }

    func snoozeGraduation(_ exerciseID: String, now: Date = .now) {
        graduationSnoozesRaw.removeAll { $0.hasPrefix(exerciseID + "|") }
        graduationSnoozesRaw.append("\(exerciseID)|\(Int(now.timeIntervalSince1970))")
    }

    func tier(for question: AbilityQuestion) -> Int {
        switch question {
        case .pushUps: pushUpTier
        case .plank: plankTier
        case .squats: squatTier
        }
    }

    func setTier(_ tier: Int, for question: AbilityQuestion) {
        switch question {
        case .pushUps: pushUpTier = tier
        case .plank: plankTier = tier
        case .squats: squatTier = tier
        }
    }
}
