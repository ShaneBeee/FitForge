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

    var hasCompletedSetup: Bool = false

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
