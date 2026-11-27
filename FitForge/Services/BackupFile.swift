import Foundation
import SwiftData

/// Everything FitForge stores, as one JSON file.
///
/// Weigh-ins from Apple Health also live in Health itself, but they're included so a restore
/// brings back the app exactly as it was. Rules for future versions: only ever ADD fields,
/// and make every new field optional, so older backup files keep loading.
struct BackupFile: Codable {
    static let currentVersion = 1

    var version: Int = BackupFile.currentVersion
    var createdAt: Date = .now
    var appVersion: String = ""
    var profiles: [ProfileRecord] = []
    var weighIns: [WeighInRecord] = []
    var tapeMeasurements: [TapeRecord] = []
    var workouts: [WorkoutRecord] = []

    /// e.g. "38 workouts · 22 weigh-ins · 15 tape measurements"
    var summary: String {
        var parts = ["\(workouts.count) workout\(workouts.count == 1 ? "" : "s")"]
        parts.append("\(weighIns.count) weigh-in\(weighIns.count == 1 ? "" : "s")")
        parts.append("\(tapeMeasurements.count) tape measurement\(tapeMeasurements.count == 1 ? "" : "s")")
        return parts.joined(separator: " · ")
    }
}

// MARK: - Records

struct ProfileRecord: Codable {
    var name: String
    var birthDate: Date?
    var heightInches: Double?
    var goalTypeRaw: String
    var targetWeightLbs: Double?
    var targetBodyFatPercent: Double?
    var why: String
    var focusAreasRaw: [String]
    var startDate: Date
    var startWeightLbs: Double?
    var startBodyFatPercent: Double?
    var activityLevelRaw: String
    var experienceRaw: String
    var jointCautionsRaw: [String]
    var bodyFatRangesRaw: String
    var pushUpTier: Int
    var plankTier: Int
    var squatTier: Int
    var workoutWeekdays: [Int]
    var weighInWeekday: Int
    var restSeconds: Int
    var workoutMinutes: Int
    var trackedSitesRaw: [String]
    var hasCompletedSetup: Bool
    var phaseRaw: Int
    var phaseStartedDate: Date?
    var levelBoostsRaw: [String]
    var graduationSnoozesRaw: [String]
    var equipment: [EquipmentRecord]

    init(_ p: UserProfile) {
        name = p.name
        birthDate = p.birthDate
        heightInches = p.heightInches
        goalTypeRaw = p.goalTypeRaw
        targetWeightLbs = p.targetWeightLbs
        targetBodyFatPercent = p.targetBodyFatPercent
        why = p.why
        focusAreasRaw = p.focusAreasRaw
        startDate = p.startDate
        startWeightLbs = p.startWeightLbs
        startBodyFatPercent = p.startBodyFatPercent
        activityLevelRaw = p.activityLevelRaw
        experienceRaw = p.experienceRaw
        jointCautionsRaw = p.jointCautionsRaw
        bodyFatRangesRaw = p.bodyFatRangesRaw
        pushUpTier = p.pushUpTier
        plankTier = p.plankTier
        squatTier = p.squatTier
        workoutWeekdays = p.workoutWeekdays
        weighInWeekday = p.weighInWeekday
        restSeconds = p.restSeconds
        workoutMinutes = p.workoutMinutes
        trackedSitesRaw = p.trackedSitesRaw
        hasCompletedSetup = p.hasCompletedSetup
        phaseRaw = p.phaseRaw
        phaseStartedDate = p.phaseStartedDate
        levelBoostsRaw = p.levelBoostsRaw
        graduationSnoozesRaw = p.graduationSnoozesRaw
        equipment = (p.equipment ?? []).sorted { $0.addedDate < $1.addedDate }.map { EquipmentRecord($0) }
    }

    /// A new profile (with its equipment) inserted into `context`.
    func insert(into context: ModelContext) {
        let p = UserProfile()
        p.name = name
        p.birthDate = birthDate
        p.heightInches = heightInches
        p.goalTypeRaw = goalTypeRaw
        p.targetWeightLbs = targetWeightLbs
        p.targetBodyFatPercent = targetBodyFatPercent
        p.why = why
        p.focusAreasRaw = focusAreasRaw
        p.startDate = startDate
        p.startWeightLbs = startWeightLbs
        p.startBodyFatPercent = startBodyFatPercent
        p.activityLevelRaw = activityLevelRaw
        p.experienceRaw = experienceRaw
        p.jointCautionsRaw = jointCautionsRaw
        p.bodyFatRangesRaw = bodyFatRangesRaw
        p.pushUpTier = pushUpTier
        p.plankTier = plankTier
        p.squatTier = squatTier
        p.workoutWeekdays = workoutWeekdays
        p.weighInWeekday = weighInWeekday
        p.restSeconds = restSeconds
        p.workoutMinutes = workoutMinutes
        p.trackedSitesRaw = trackedSitesRaw
        p.hasCompletedSetup = hasCompletedSetup
        p.phaseRaw = phaseRaw
        p.phaseStartedDate = phaseStartedDate
        p.levelBoostsRaw = levelBoostsRaw
        p.graduationSnoozesRaw = graduationSnoozesRaw
        context.insert(p)

        let items = equipment.map { $0.makeModel() }
        items.forEach { context.insert($0) }
        p.equipment = items
    }
}

struct EquipmentRecord: Codable {
    var kindRaw: String
    var weightLbs: Double?
    var isPair: Bool
    var addedDate: Date
    var isAdjustable: Bool
    var maxWeightLbs: Double?
    var isInUse: Bool
    var benchTypeRaw: String?

    init(_ e: EquipmentItem) {
        kindRaw = e.kindRaw
        weightLbs = e.weightLbs
        isPair = e.isPair
        addedDate = e.addedDate
        isAdjustable = e.isAdjustable
        maxWeightLbs = e.maxWeightLbs
        isInUse = e.isInUse
        benchTypeRaw = e.benchTypeRaw
    }

    func makeModel() -> EquipmentItem {
        let e = EquipmentItem(kind: EquipmentKind(rawValue: kindRaw) ?? .dumbbells, weightLbs: weightLbs, isPair: isPair)
        e.kindRaw = kindRaw
        e.addedDate = addedDate
        e.isAdjustable = isAdjustable
        e.maxWeightLbs = maxWeightLbs
        e.isInUse = isInUse
        e.benchTypeRaw = benchTypeRaw
        return e
    }
}

struct WeighInRecord: Codable {
    var date: Date
    var weightLbs: Double?
    var bodyFatPercent: Double?
    var visceralFat: Double?
    var muscleMassLbs: Double?
    var skeletalMusclePercent: Double?
    var bmrKcal: Double?
    var metabolicAge: Int?
    var fatFreeMassLbs: Double?
    var subcutaneousFatPercent: Double?
    var bodyWaterPercent: Double?
    var boneMassLbs: Double?
    var proteinPercent: Double?
    var sourceRaw: String

    init(_ m: BodyMeasurement) {
        date = m.date
        weightLbs = m.weightLbs
        bodyFatPercent = m.bodyFatPercent
        visceralFat = m.visceralFat
        muscleMassLbs = m.muscleMassLbs
        skeletalMusclePercent = m.skeletalMusclePercent
        bmrKcal = m.bmrKcal
        metabolicAge = m.metabolicAge
        fatFreeMassLbs = m.fatFreeMassLbs
        subcutaneousFatPercent = m.subcutaneousFatPercent
        bodyWaterPercent = m.bodyWaterPercent
        boneMassLbs = m.boneMassLbs
        proteinPercent = m.proteinPercent
        sourceRaw = m.sourceRaw
    }

    func makeModel() -> BodyMeasurement {
        let m = BodyMeasurement(date: date)
        m.weightLbs = weightLbs
        m.bodyFatPercent = bodyFatPercent
        m.visceralFat = visceralFat
        m.muscleMassLbs = muscleMassLbs
        m.skeletalMusclePercent = skeletalMusclePercent
        m.bmrKcal = bmrKcal
        m.metabolicAge = metabolicAge
        m.fatFreeMassLbs = fatFreeMassLbs
        m.subcutaneousFatPercent = subcutaneousFatPercent
        m.bodyWaterPercent = bodyWaterPercent
        m.boneMassLbs = boneMassLbs
        m.proteinPercent = proteinPercent
        m.sourceRaw = sourceRaw
        return m
    }
}

struct TapeRecord: Codable {
    var date: Date
    var siteRaw: String
    var inches: Double

    init(_ t: TapeMeasurement) {
        date = t.date
        siteRaw = t.siteRaw
        inches = t.inches
    }

    func makeModel() -> TapeMeasurement {
        let t = TapeMeasurement(site: MeasureSite(rawValue: siteRaw) ?? .belly, inches: inches, date: date)
        t.siteRaw = siteRaw
        return t
    }
}

struct WorkoutRecord: Codable {
    var startDate: Date
    var endDate: Date?
    var dayRaw: String
    var statusRaw: String
    var savedToHealth: Bool
    var activeCalories: Double?
    var calorieMethodRaw: String
    var averageHeartRate: Double?
    var effort: Int?
    var effortPendingHealth: Bool
    var sets: [SetRecord]

    init(_ s: WorkoutSession) {
        startDate = s.startDate
        endDate = s.endDate
        dayRaw = s.dayRaw
        statusRaw = s.statusRaw
        savedToHealth = s.savedToHealth
        activeCalories = s.activeCalories
        calorieMethodRaw = s.calorieMethodRaw
        averageHeartRate = s.averageHeartRate
        effort = s.effort
        effortPendingHealth = s.effortPendingHealth
        sets = (s.sets ?? [])
            .sorted { ($0.exerciseIndex, $0.setNumber) < ($1.exerciseIndex, $1.setNumber) }
            .map { SetRecord($0) }
    }

    func insert(into context: ModelContext) {
        let s = WorkoutSession(day: WorkoutPlans.day(id: dayRaw), startDate: startDate)
        s.dayRaw = dayRaw
        s.endDate = endDate
        s.statusRaw = statusRaw
        s.savedToHealth = savedToHealth
        s.activeCalories = activeCalories
        s.calorieMethodRaw = calorieMethodRaw
        s.averageHeartRate = averageHeartRate
        s.effort = effort
        s.effortPendingHealth = effortPendingHealth
        context.insert(s)

        let logs = sets.map { $0.makeModel() }
        logs.forEach { context.insert($0) }
        s.sets = logs
    }
}

struct SetRecord: Codable {
    var exerciseID: String
    var exerciseName: String
    var exerciseIndex: Int
    var setNumber: Int
    var targetRepsLow: Int?
    var targetRepsHigh: Int?
    var targetSeconds: Int?
    var actualReps: Int?
    var actualSeconds: Int?
    var wasSkipped: Bool
    var completedAt: Date
    var weightLbs: Double?

    init(_ l: SetLog) {
        exerciseID = l.exerciseID
        exerciseName = l.exerciseName
        exerciseIndex = l.exerciseIndex
        setNumber = l.setNumber
        targetRepsLow = l.targetRepsLow
        targetRepsHigh = l.targetRepsHigh
        targetSeconds = l.targetSeconds
        actualReps = l.actualReps
        actualSeconds = l.actualSeconds
        wasSkipped = l.wasSkipped
        completedAt = l.completedAt
        weightLbs = l.weightLbs
    }

    func makeModel() -> SetLog {
        let l = SetLog(exerciseID: exerciseID, exerciseName: exerciseName, exerciseIndex: exerciseIndex, setNumber: setNumber)
        l.targetRepsLow = targetRepsLow
        l.targetRepsHigh = targetRepsHigh
        l.targetSeconds = targetSeconds
        l.actualReps = actualReps
        l.actualSeconds = actualSeconds
        l.wasSkipped = wasSkipped
        l.completedAt = completedAt
        l.weightLbs = weightLbs
        return l
    }
}
