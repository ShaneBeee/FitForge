import Foundation
import SwiftData
import Observation

/// Holds everything entered during first-time setup.
/// Nothing is saved to the database until the user taps Finish.
@Observable
final class OnboardingDraft {

    enum Step: Int, CaseIterable {
        case welcome, goal, starting, targets, equipment, ability, schedule, why

        var canSkip: Bool { self != .welcome && self != .why }
    }

    var step: Step = .welcome
    /// Direction of the last move, used for the slide animation.
    var movingForward = true

    // Welcome
    var name = ""

    // Goal
    private(set) var goalType: GoalType = .both
    private(set) var focusAreas: Set<FocusArea> = []

    // Starting point
    var currentWeightLbs: Double?
    var currentBodyFatPercent: Double?
    var heightTotalInches = 68
    var birthDate = Calendar.current.date(byAdding: .year, value: -35, to: .now) ?? .now
    var activityLevel: ActivityLevel = .mostlySitting
    var experience: Experience = .new
    var bodyFatRanges: BodyFatRanges?
    private(set) var weighInDateFromHealth: Date?
    private var didPrefill = false

    // Targets
    var targetWeightLbs: Double?
    var targetBodyFatPercent: Double?

    // Equipment
    var selectedEquipment: Set<EquipmentKind> = []
    var equipmentWeights: [EquipmentKind: Double] = [:]

    // Ability
    var abilityTiers: [AbilityQuestion: Int] = [:]
    var jointCautions: Set<JointCaution> = []

    // Schedule
    var workoutWeekdays: Set<Int> = [2, 4, 6]   // Mon, Wed, Fri
    private(set) var daysPerWeek = 3
    var workoutMinutes = 20
    var weighInWeekday = 1                       // Sunday
    var restSeconds = GoalType.both.defaultRestSeconds
    private var restWasCustomized = false

    // Why
    var why = ""

    init() {}

    /// Starts a draft from an existing profile, for editing one section of it.
    convenience init(editing profile: UserProfile) {
        self.init()
        didPrefill = true   // never overwrite saved answers with Health data while editing

        name = profile.name
        why = profile.why

        goalType = profile.goalType
        focusAreas = Set(profile.focusAreas)
        targetWeightLbs = profile.targetWeightLbs
        targetBodyFatPercent = profile.targetBodyFatPercent

        currentWeightLbs = profile.startWeightLbs
        currentBodyFatPercent = profile.startBodyFatPercent
        if let height = profile.heightInches { heightTotalInches = Int(height.rounded()) }
        if let birthDate = profile.birthDate { self.birthDate = birthDate }
        activityLevel = profile.activityLevel
        experience = profile.experience
        bodyFatRanges = profile.bodyFatRanges

        for item in profile.equipment ?? [] {
            selectedEquipment.insert(item.kind)
            if let weight = item.weightLbs { equipmentWeights[item.kind] = weight }
        }

        for question in AbilityQuestion.allCases {
            abilityTiers[question] = profile.tier(for: question)
        }
        jointCautions = profile.jointCautions

        workoutWeekdays = Set(profile.workoutWeekdays)
        daysPerWeek = max(2, profile.workoutWeekdays.count)
        workoutMinutes = profile.workoutMinutes
        weighInWeekday = profile.weighInWeekday
        restSeconds = profile.restSeconds
        restWasCustomized = profile.restSeconds != profile.goalType.defaultRestSeconds
    }

    // MARK: - Derived

    var heightFeet: Int {
        get { heightTotalInches / 12 }
        set { heightTotalInches = newValue * 12 + heightTotalInches % 12 }
    }

    var heightInchesPart: Int {
        get { heightTotalInches % 12 }
        set { heightTotalInches = heightFeet * 12 + newValue }
    }

    var progress: Double {
        Double(step.rawValue + 1) / Double(Step.allCases.count)
    }

    var canContinue: Bool {
        switch step {
        case .schedule: workoutWeekdays.count == daysPerWeek
        default: true
        }
    }

    var isLastStep: Bool { step == Step.allCases.last }

    // MARK: - Actions

    func setGoal(_ goal: GoalType) {
        goalType = goal
        if !restWasCustomized { restSeconds = goal.defaultRestSeconds }
    }

    /// Adds or removes a focus area (up to 3).
    func toggleFocus(_ area: FocusArea) {
        if focusAreas.contains(area) {
            focusAreas.remove(area)
        } else if focusAreas.count < FocusArea.maxSelections {
            focusAreas.insert(area)
        }
    }

    func setRest(_ seconds: Int) {
        restSeconds = seconds
        restWasCustomized = true
    }

    func toggleEquipment(_ kind: EquipmentKind) {
        if selectedEquipment.contains(kind) {
            selectedEquipment.remove(kind)
        } else {
            selectedEquipment.insert(kind)
        }
    }

    func toggleWorkoutDay(_ weekday: Int) {
        if workoutWeekdays.contains(weekday) {
            workoutWeekdays.remove(weekday)
        } else if workoutWeekdays.count < daysPerWeek {
            workoutWeekdays.insert(weekday)
        }
    }

    /// Changes how many days a week, and suggests a fresh spread of days to match.
    func setDaysPerWeek(_ count: Int) {
        guard count != daysPerWeek else { return }
        daysPerWeek = count
        workoutWeekdays = WorkoutPlans.suggestedWeekdays(forDaysPerWeek: count)
    }

    func next() {
        guard let nextStep = Step(rawValue: step.rawValue + 1) else { return }
        movingForward = true
        step = nextStep
    }

    func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        movingForward = false
        step = previous
    }

    /// Fills the starting point from Apple Health, once.
    func prefill(from health: HealthKitManager) {
        guard !didPrefill else { return }
        didPrefill = true

        if let weight = health.latestWeight {
            currentWeightLbs = (weight.value * 10).rounded() / 10
            weighInDateFromHealth = weight.date
        }
        if let bodyFat = health.latestBodyFat {
            currentBodyFatPercent = (bodyFat.value * 10).rounded() / 10
        }
        if let height = health.latestHeight {
            heightTotalInches = Int(height.value.rounded())
        }
        if let birthDate = health.birthDate {
            self.birthDate = birthDate
        }
    }

    // MARK: - Save

    /// Writes one edited section back to an existing profile.
    func apply(_ section: ProfileSection, to profile: UserProfile, in context: ModelContext) {
        switch section {
        case .about:
            profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.why = why.trimmingCharacters(in: .whitespacesAndNewlines)

        case .goal:
            profile.goalType = goalType
            profile.focusAreas = FocusArea.allCases.filter { focusAreas.contains($0) }
            profile.targetWeightLbs = targetWeightLbs
            profile.targetBodyFatPercent = targetBodyFatPercent

        case .starting:
            profile.startWeightLbs = currentWeightLbs
            profile.startBodyFatPercent = currentBodyFatPercent
            profile.heightInches = Double(heightTotalInches)
            profile.birthDate = birthDate
            profile.activityLevel = activityLevel
            profile.experience = experience
            profile.bodyFatRanges = bodyFatRanges

        case .equipment:
            for item in profile.equipment ?? [] {
                context.delete(item)
            }
            for kind in EquipmentKind.allCases where selectedEquipment.contains(kind) {
                let item = EquipmentItem(kind: kind, weightLbs: kind.hasWeight ? equipmentWeights[kind] : nil)
                context.insert(item)
                item.profile = profile
            }

        case .ability:
            for question in AbilityQuestion.allCases {
                profile.setTier(abilityTiers[question] ?? 0, for: question)
            }
            profile.jointCautions = jointCautions

        case .schedule:
            profile.workoutWeekdays = workoutWeekdays.sorted()
            profile.workoutMinutes = workoutMinutes
            profile.weighInWeekday = weighInWeekday
            profile.restSeconds = restSeconds
        }
        try? context.save()
    }

    /// Creates the profile, equipment and starting weigh-in.
    func save(in context: ModelContext) {
        let profile = UserProfile()
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.birthDate = birthDate
        profile.heightInches = Double(heightTotalInches)

        profile.goalType = goalType
        profile.focusAreas = FocusArea.allCases.filter { focusAreas.contains($0) }
        profile.targetWeightLbs = targetWeightLbs
        profile.targetBodyFatPercent = targetBodyFatPercent
        profile.why = why.trimmingCharacters(in: .whitespacesAndNewlines)

        profile.startDate = .now
        profile.startWeightLbs = currentWeightLbs
        profile.startBodyFatPercent = currentBodyFatPercent
        profile.activityLevel = activityLevel
        profile.experience = experience
        profile.bodyFatRanges = bodyFatRanges
        profile.jointCautions = jointCautions
        for question in AbilityQuestion.allCases {
            profile.setTier(abilityTiers[question] ?? 0, for: question)
        }

        profile.workoutWeekdays = workoutWeekdays.sorted()
        profile.workoutMinutes = workoutMinutes
        profile.weighInWeekday = weighInWeekday
        profile.restSeconds = restSeconds

        context.insert(profile)

        for kind in EquipmentKind.allCases where selectedEquipment.contains(kind) {
            let item = EquipmentItem(kind: kind, weightLbs: kind.hasWeight ? equipmentWeights[kind] : nil)
            context.insert(item)
            item.profile = profile
        }

        saveStartingMeasurement(in: context)

        profile.hasCompletedSetup = true
        try? context.save()
    }

    private func saveStartingMeasurement(in context: ModelContext) {
        guard currentWeightLbs != nil || currentBodyFatPercent != nil else { return }
        let date = weighInDateFromHealth ?? .now

        // Don't duplicate a weigh-in that's already stored (e.g. if setup is run again).
        let existing = (try? context.fetch(FetchDescriptor<BodyMeasurement>())) ?? []
        guard !existing.contains(where: { abs($0.date.timeIntervalSince(date)) < 60 }) else { return }

        let measurement = BodyMeasurement(date: date, source: weighInDateFromHealth == nil ? .manual : .health)
        measurement.weightLbs = currentWeightLbs
        measurement.bodyFatPercent = currentBodyFatPercent
        context.insert(measurement)
    }
}
