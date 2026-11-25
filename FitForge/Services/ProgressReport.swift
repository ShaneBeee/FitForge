import Foundation
import SwiftData

/// How far back a progress report goes.
enum ReportRange: String, CaseIterable, Identifiable {
    case fourWeeks, threeMonths, sixMonths, year, all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fourWeeks: "4 wk"
        case .threeMonths: "3 mo"
        case .sixMonths: "6 mo"
        case .year: "1 yr"
        case .all: "All"
        }
    }

    var longTitle: String {
        switch self {
        case .fourWeeks: "Last 4 weeks"
        case .threeMonths: "Last 3 months"
        case .sixMonths: "Last 6 months"
        case .year: "Last year"
        case .all: "Everything since you started"
        }
    }

    /// Start of the range ("All" is worked out from the data instead).
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date.now
        return switch self {
        case .fourWeeks: calendar.date(byAdding: .day, value: -28, to: now) ?? now
        case .threeMonths: calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths: calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .year: calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all: .distantPast
        }
    }
}

/// Everything a report is built from.
struct ProgressReportInput {
    let profile: UserProfile
    /// All saved workouts.
    let sessions: [WorkoutSession]
    /// All weigh-ins with smart scale extras, oldest first.
    let measurements: [BodyMeasurement]
    /// All tape measurements, oldest first.
    let tape: [TapeMeasurement]
    /// Weight and body fat from Apple Health, oldest first (one per day).
    let weights: [HealthKitManager.Reading]
    let bodyFats: [HealthKitManager.Reading]
    let range: ReportRange
    let includeName: Bool
    /// Summarize Health weigh-ins from before FitForge, by year, for context.
    let includeEarlierHistory: Bool
    /// Anything else the reader should know (e.g. "Started creatine Nov 12").
    let notes: String
}

/// Builds the "Progress report" PDF: goals, body, consistency, workouts and strength progress,
/// with a ready-made question at the top for an AI assistant.
@MainActor
enum ProgressReport {
    typealias Block = ReportPDFWriter.Block
    typealias Table = ReportPDFWriter.Table

    /// Writes the PDF to a temporary file and returns its location (ready for the share sheet).
    static func makePDF(_ input: ProgressReportInput) throws -> URL {
        // Today's date in the phone's own time zone (plain .iso8601 would use UTC and could say tomorrow).
        let stamp = Date.now.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
        let url = FileManager.default.temporaryDirectory
            .appending(path: "FitForge Progress Report \(stamp).pdf")
        let writer = ReportPDFWriter(footer: "FitForge progress report · \(day(.now))")
        try writer.write(blocks(for: input), title: "FitForge Progress Report", to: url)
        return url
    }

    static let aiPrompt = """
        I'm sharing a progress report from FitForge, the home-workout app I use. Please review it and tell me:
        1. How am I doing toward my goals?
        2. Is my rate of progress realistic and healthy?
        3. Am I training hard enough and consistently enough?
        4. What should I change or focus on next?
        Be honest and specific, and point to the numbers in the report.
        """

    // MARK: - Report

    static func blocks(for input: ProgressReportInput) -> [Block] {
        let profile = input.profile
        // "All" means since starting FitForge. Older Health weigh-ins go in their own summary instead.
        let earliest = ([profile.startDate] + input.sessions.map(\.startDate)).min() ?? profile.startDate
        let start = input.range == .all ? earliest : input.range.startDate

        var subtitle: [String] = []
        if input.includeName, !profile.name.trimmingCharacters(in: .whitespaces).isEmpty {
            subtitle.append(profile.name)
        }
        subtitle.append("\(input.range.longTitle): \(day(start)) – \(day(.now))")

        var blocks: [Block] = [
            .title("FitForge Progress Report", subtitle: subtitle.joined(separator: " · ")),
            .box(aiPrompt),
        ]
        let notes = input.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notes.isEmpty {
            blocks.append(.heading("Notes from me"))
            blocks.append(.paragraph(notes))
        }
        blocks += aboutSection(profile)
        blocks += bodySection(input, start: start)
        if input.includeEarlierHistory {
            blocks += earlierHistorySection(input)
        }
        blocks += scaleSection(input, start: start)
        blocks += measurementsSection(input, start: start)
        blocks += consistencySection(input, start: start)
        blocks += strengthSection(input, start: start)
        blocks.append(.heading("About this data"))
        blocks.append(.note("""
            Weight and body fat come from Apple Health (a smart scale). Smart scale body composition numbers \
            (muscle, water, visceral fat and so on) are estimates and can swing with hydration. Reps are what I \
            entered after each set; FitForge suggests heavier weights when every set reaches the top of its rep range. \
            Effort is my own 1–10 rating after each workout. Workouts are home workouts with the equipment listed above.
            """))
        return blocks
    }

    // MARK: - About me and my plan

    private static func aboutSection(_ profile: UserProfile) -> [Block] {
        var rows: [[String]] = []
        if let birthDate = profile.birthDate,
           let age = Calendar.current.dateComponents([.year], from: birthDate, to: .now).year {
            rows.append(["Age", "\(age)"])
        }
        if let ranges = profile.bodyFatRanges {
            rows.append(["Sex (for body fat ranges)", ranges.title])
        }
        if let height = profile.heightInches {
            let inches = Int(height.rounded())
            rows.append(["Height", "\(inches / 12)′\(inches % 12)″"])
        }
        rows.append(["Main goal", goalText(profile.goalType)])
        if let target = profile.targetWeightLbs {
            rows.append(["Weight goal", "\(profile.startWeightLbs.map { "From \(lb($0)) → " } ?? "")\(lb(target))"])
        }
        if let target = profile.targetBodyFatPercent {
            rows.append(["Body fat goal", "\(profile.startBodyFatPercent.map { "From \(pct($0)) → " } ?? "")\(pct(target))"])
        }
        if !profile.focusAreas.isEmpty {
            rows.append(["Focus areas", profile.focusAreas.map(\.title).joined(separator: ", ")])
        }
        let days = profile.workoutWeekdays.sorted().map(Weekday.shortName).joined(separator: ", ")
        rows.append(["Workouts", "\(profile.workoutWeekdays.count) a week (\(days)), about \(profile.workoutMinutes) min each, \(profile.restSeconds) sec rest between sets"])
        rows.append(["Weigh-in day", Weekday.name(profile.weighInWeekday)])
        let phaseSince = profile.phaseStartedDate.map { " since \(day($0))" } ?? ""
        rows.append(["Training phase", "\(profile.phase.title)\(phaseSince) — \(profile.phase.tagline)"])
        rows.append(["Experience", profile.experience.title])
        rows.append(["Daily activity", "\(profile.activityLevel.title) (\(profile.activityLevel.detail.lowercased()))"])
        let ability = AbilityQuestion.allCases.map { question in
            let options = question.options
            let tier = min(max(profile.tier(for: question), 0), options.count - 1)
            return "\(question.shortName) \(options[tier])"
        }
        rows.append(["Ability at setup", ability.joined(separator: "; ")])
        let cautions = profile.jointCautions.map(\.title).sorted()
        rows.append(["Joint cautions", cautions.isEmpty ? "None" : cautions.joined(separator: ", ")])

        // In the order of the equipment list, lightest weights first.
        let kindOrder = EquipmentKind.allCases
        let equipment = (profile.equipment ?? []).sorted { lhs, rhs in
            let left = kindOrder.firstIndex(of: lhs.kind) ?? 0
            let right = kindOrder.firstIndex(of: rhs.kind) ?? 0
            return left != right ? left < right : (lhs.weightLbs ?? 0) < (rhs.weightLbs ?? 0)
        }
        let inUse = equipment.filter(\.isInUse).map(\.displayName)
        let notYet = equipment.filter { !$0.isInUse }.map { $0.kind == .bench ? $0.benchType.title : $0.kind.title }
        rows.append(["Equipment", inUse.isEmpty ? "Bodyweight only" : inUse.joined(separator: "; ")])
        if !notYet.isEmpty {
            rows.append(["Owned, not used yet", notYet.joined(separator: "; ")])
        }
        rows.append(["Using FitForge since", day(profile.startDate)])

        return [
            .heading("About me and my plan"),
            .table(Table(headers: [], widths: [1, 3], rows: rows)),
        ]
    }

    // MARK: - Body

    private static func bodySection(_ input: ProgressReportInput, start: Date) -> [Block] {
        let profile = input.profile
        var blocks: [Block] = [.heading("Body")]

        var summary: [[String]] = []
        if let latest = input.weights.last {
            summary.append([
                "Weight (lb)",
                profile.startWeightLbs.map(num) ?? "—",
                num(latest.value),
                profile.startWeightLbs.map { signed(latest.value - $0) } ?? "—",
                profile.targetWeightLbs.map(num) ?? "—",
            ])
        }
        if let latest = input.bodyFats.last {
            summary.append([
                "Body fat (%)",
                profile.startBodyFatPercent.map(num) ?? "—",
                num(latest.value),
                profile.startBodyFatPercent.map { signed(latest.value - $0) } ?? "—",
                profile.targetBodyFatPercent.map(num) ?? "—",
            ])
        }
        if summary.isEmpty {
            blocks.append(.paragraph("No weigh-ins found in Apple Health."))
            return blocks
        }
        blocks.append(.table(Table(
            headers: ["", "At start (\(day(profile.startDate)))", "Latest", "Change", "Target"],
            widths: [1.3, 1.6, 1, 1, 1],
            rows: summary,
            rightAligned: [1, 2, 3, 4]
        )))

        // Average rate of change over the report period.
        let inRange = input.weights.filter { $0.date >= start }
        if let first = inRange.first, let last = inRange.last, last.date > first.date {
            let weeks = last.date.timeIntervalSince(first.date) / (7 * 86_400)
            if weeks >= 1 {
                let rate = (last.value - first.value) / weeks
                blocks.append(.paragraph("Over this period: \(signed(last.value - first.value)) lb in \(Int(weeks.rounded())) weeks, an average of \(signed(rate)) lb per week."))
            }
        }

        // Every weigh-in in the period, merged by day.
        var byDay: [Date: (date: Date, weight: Double?, bodyFat: Double?)] = [:]
        for reading in input.weights where reading.date >= start {
            let key = Calendar.current.startOfDay(for: reading.date)
            byDay[key] = (reading.date, reading.value, byDay[key]?.bodyFat)
        }
        for reading in input.bodyFats where reading.date >= start {
            let key = Calendar.current.startOfDay(for: reading.date)
            byDay[key] = (byDay[key]?.date ?? reading.date, byDay[key]?.weight, reading.value)
        }
        let rows = byDay.values.sorted { $0.date < $1.date }.map { entry -> [String] in
            let visceral = input.measurements.first {
                Calendar.current.isDate($0.date, inSameDayAs: entry.date) && $0.visceralFat != nil
            }?.visceralFat
            return [day(entry.date), entry.weight.map(num) ?? "—", entry.bodyFat.map(num) ?? "—", visceral.map(whole) ?? "—"]
        }
        if !rows.isEmpty {
            blocks.append(.paragraph("Weigh-ins in this period:"))
            blocks.append(.table(Table(
                headers: ["Date", "Weight (lb)", "Body fat (%)", "Visceral fat"],
                widths: [1.4, 1, 1, 1],
                rows: rows,
                rightAligned: [1, 2, 3]
            )))
        }
        return blocks
    }

    // MARK: - Earlier history

    /// Weigh-ins from before FitForge, summarized by year, so the reader has the longer story
    /// without it mixing into the "since I started" numbers.
    private static func earlierHistorySection(_ input: ProgressReportInput) -> [Block] {
        let cutoff = input.profile.startDate
        let earlier = input.weights.filter { $0.date < cutoff }
        guard let lowest = earlier.min(by: { $0.value < $1.value }),
              let highest = earlier.max(by: { $0.value < $1.value }),
              let last = earlier.last else { return [] }
        let earlierFats = input.bodyFats.filter { $0.date < cutoff }
        let calendar = Calendar.current

        func average(_ values: [Double]) -> Double { values.reduce(0, +) / Double(max(values.count, 1)) }

        let byYear = Dictionary(grouping: earlier) { calendar.component(.year, from: $0.date) }
        let rows = byYear.keys.sorted().map { year -> [String] in
            let weights = byYear[year]?.map(\.value) ?? []
            let fats = earlierFats.filter { calendar.component(.year, from: $0.date) == year }.map(\.value)
            return [
                "\(year)",
                "\(weights.count)",
                num(average(weights)),
                weights.min().map(num) ?? "—",
                weights.max().map(num) ?? "—",
                fats.isEmpty ? "—" : num(average(fats)),
            ]
        }

        return [
            .heading("Earlier history (before FitForge)"),
            .paragraph("Weigh-ins in Apple Health from before I started FitForge, for context. Lowest: \(lb(lowest.value)) on \(day(lowest.date)). Highest: \(lb(highest.value)) on \(day(highest.date)). Last before starting: \(lb(last.value)) on \(day(last.date))."),
            .table(Table(
                headers: ["Year", "Weigh-ins", "Average (lb)", "Lowest", "Highest", "Avg body fat (%)"],
                widths: [0.8, 0.9, 1, 0.9, 0.9, 1.2],
                rows: rows,
                rightAligned: [1, 2, 3, 4, 5]
            )),
            .note("Very old readings may include the odd mis-weigh (or someone else on the scale)."),
        ]
    }

    // MARK: - Smart scale extras

    private static func scaleSection(_ input: ProgressReportInput, start: Date) -> [Block] {
        let inRange = input.measurements.filter { $0.date >= start }
        var rows: [[String]] = []

        func addRow(_ title: String, unit: String, digits: Int, _ value: (BodyMeasurement) -> Double?) {
            let readings = inRange.compactMap { measurement in value(measurement).map { (measurement.date, $0) } }
            guard let first = readings.first, let last = readings.last else { return }
            let format = { (number: Double) in number.formatted(.number.precision(.fractionLength(digits))) }
            rows.append([
                unit.isEmpty ? title : "\(title) (\(unit))",
                "\(format(first.1)) on \(day(first.0))",
                readings.count > 1 ? "\(format(last.1)) on \(day(last.0))" : "—",
                readings.count > 1 ? signed(last.1 - first.1, digits: digits) : "—",
            ])
        }

        addRow("Visceral fat rating", unit: "", digits: 0) { $0.visceralFat }
        for metric in CompositionMetric.allCases {
            addRow(metric.title, unit: metric.unit, digits: metric.digits) { metric.value($0) }
        }
        guard !rows.isEmpty else { return [] }

        return [
            .heading("Smart scale body composition"),
            .table(Table(
                headers: ["Measurement", "First in period", "Latest", "Change"],
                widths: [1.6, 1.5, 1.5, 0.8],
                rows: rows,
                rightAligned: [3]
            )),
        ]
    }

    // MARK: - Tape measurements

    private static func measurementsSection(_ input: ProgressReportInput, start: Date) -> [Block] {
        let inRange = input.tape.filter { $0.date >= start }
        var rows: [[String]] = []
        for site in MeasureSite.allCases {
            let entries = inRange.filter { $0.site == site }
            guard let first = entries.first, let last = entries.last else { continue }
            rows.append([
                site.title,
                "\(num(first.inches)) on \(day(first.date))",
                entries.count > 1 ? "\(num(last.inches)) on \(day(last.date))" : "—",
                entries.count > 1 ? signed(last.inches - first.inches) : "—",
            ])
        }
        guard !rows.isEmpty else { return [] }
        return [
            .heading("Tape measurements (inches)"),
            .table(Table(
                headers: ["Spot", "First in period", "Latest", "Change"],
                widths: [1.4, 1.5, 1.5, 0.8],
                rows: rows,
                rightAligned: [3]
            )),
        ]
    }

    // MARK: - Consistency and workouts

    private static func consistencySection(_ input: ProgressReportInput, start: Date) -> [Block] {
        let profile = input.profile
        let calendar = Calendar.current
        let now = Date.now
        let sessions = workouts(in: input, from: start)

        // Week by week: workouts done vs. the days scheduled (counted from when you started).
        var weekRows: [[String]] = []
        var totalPlanned = 0
        var weekStart = calendar.dateInterval(of: .weekOfYear, for: start)?.start ?? start
        let countFrom = calendar.startOfDay(for: max(start, profile.startDate))
        while weekStart <= now {
            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { break }
            var planned = 0
            var dayCursor = max(weekStart, countFrom)
            while dayCursor < weekEnd, dayCursor <= now {
                if profile.workoutWeekdays.contains(calendar.component(.weekday, from: dayCursor)) { planned += 1 }
                guard let next = calendar.date(byAdding: .day, value: 1, to: dayCursor) else { break }
                dayCursor = next
            }
            let done = sessions.filter { $0.startDate >= weekStart && $0.startDate < weekEnd }
            if planned > 0 || !done.isEmpty {
                let sets = done.flatMap { $0.sets ?? [] }
                weekRows.append([
                    "Week of \(day(weekStart))",
                    "\(done.count)",
                    "\(planned)",
                    "\(sets.filter { !$0.wasSkipped }.count)",
                    "\(sets.filter(\.wasSkipped).count)",
                ])
            }
            totalPlanned += planned
            weekStart = weekEnd
        }

        var blocks: [Block] = [.heading("Consistency")]
        let endedEarly = sessions.filter { $0.status == .endedEarly }.count
        let makeUps = sessions.filter { WeekSchedule.isMakeUp($0, profile: profile) }.count
        var summary = "\(sessions.count) workout\(sessions.count == 1 ? "" : "s") done out of \(totalPlanned) scheduled in this period"
        if endedEarly > 0 { summary += ", \(endedEarly) ended early" }
        if makeUps > 0 { summary += ", \(makeUps) done as make-ups on another day" }
        summary += ". (Scheduled days use my current schedule.)"
        blocks.append(.paragraph(summary))
        if !weekRows.isEmpty {
            blocks.append(.table(Table(
                headers: ["Week", "Workouts", "Scheduled", "Sets done", "Sets skipped"],
                widths: [1.6, 1, 1, 1, 1],
                rows: weekRows,
                rightAligned: [1, 2, 3, 4]
            )))
        }

        guard !sessions.isEmpty else { return blocks }

        // Each workout.
        let efforts = sessions.compactMap(\.effort)
        let calories = sessions.compactMap(\.activeCalories)
        var averages: [String] = []
        if !efforts.isEmpty {
            averages.append("average effort \(num(Double(efforts.reduce(0, +)) / Double(efforts.count)))/10")
        }
        if !calories.isEmpty {
            averages.append("average \(whole(calories.reduce(0, +) / Double(calories.count))) active calories per workout")
        }
        blocks.append(.heading("Workouts"))
        if !averages.isEmpty {
            let sentence = averages.joined(separator: ", ")
            blocks.append(.paragraph(sentence.prefix(1).uppercased() + String(sentence.dropFirst()) + "."))
        }
        let rows = sessions.map { session -> [String] in
            let sets = session.sets ?? []
            let minutes = session.endDate.map { whole($0.timeIntervalSince(session.startDate) / 60) } ?? "—"
            var notes: [String] = []
            if WeekSchedule.isMakeUp(session, profile: profile) { notes.append("Make-up") }
            if session.status == .endedEarly { notes.append("Ended early") }
            if session.calorieMethod == .watch { notes.append("Apple Watch") }
            return [
                day(session.startDate),
                session.day.title,
                minutes,
                "\(sets.filter { !$0.wasSkipped }.count)/\(sets.count)",
                session.activeCalories.map(whole) ?? "—",
                session.averageHeartRate.map(whole) ?? "—",
                session.effort.map { "\($0)/10" } ?? "—",
                notes.joined(separator: ", "),
            ]
        }
        blocks.append(.table(Table(
            headers: ["Date", "Workout", "Min", "Sets", "Cal", "Avg HR", "Effort", "Notes"],
            widths: [1.3, 0.9, 0.5, 0.6, 0.6, 0.7, 0.7, 1.4],
            rows: rows,
            rightAligned: [2, 3, 4, 5, 6]
        )))
        return blocks
    }

    // MARK: - Strength progress

    private static func strengthSection(_ input: ProgressReportInput, start: Date) -> [Block] {
        let sessions = workouts(in: input, from: start)
        let sets = sessions.flatMap { session in (session.sets ?? []).map { (session, $0) } }
        let byExercise = Dictionary(grouping: sets.filter { !$0.1.wasSkipped }, by: { $0.1.exerciseID })
        guard !byExercise.isEmpty else { return [] }

        struct Row {
            let name: String
            let sessions: Int
            let first: String
            let latest: String
            let atTop: String
        }

        let rows: [Row] = byExercise.values.compactMap { entries in
            let bySession = Dictionary(grouping: entries, by: { $0.0.persistentModelID })
            let ordered = bySession.values.sorted { $0[0].0.startDate < $1[0].0.startDate }
            guard let firstSets = ordered.first?.map(\.1), let lastSets = ordered.last?.map(\.1),
                  let name = entries.first?.1.exerciseName else { return nil }
            let allSets = entries.map(\.1)
            let topCount = allSets.filter(\.hitTarget).count
            return Row(
                name: name,
                sessions: ordered.count,
                first: "\(bestSet(firstSets)) (\(day(ordered.first![0].0.startDate)))",
                latest: ordered.count > 1 ? "\(bestSet(lastSets)) (\(day(ordered.last![0].0.startDate)))" : "—",
                atTop: "\(topCount) of \(allSets.count)"
            )
        }
        .sorted { $0.sessions != $1.sessions ? $0.sessions > $1.sessions : $0.name < $1.name }

        var blocks: [Block] = [
            .heading("Strength progress by exercise"),
            .note("Best set from the first and latest workout in this period. \"Sets at top\" counts sets that reached the top of the target rep range (or the full time)."),
            .table(Table(
                headers: ["Exercise", "Workouts", "First", "Latest", "Sets at top"],
                widths: [1.6, 0.7, 1.7, 1.7, 0.8],
                rows: rows.map { [$0.name, "\($0.sessions)", $0.first, $0.latest, $0.atTop] },
                rightAligned: [1, 4]
            )),
        ]

        let outgrown = WeightProgression.outgrown(for: input.profile, history: input.sessions)
        if !outgrown.isEmpty {
            let list = outgrown
                .map { "\($0.exercise.name) at \(EquipmentItem.format($0.weight)) lb" }
                .sorted()
                .joined(separator: "; ")
            blocks.append(.paragraph("Outgrown (top of the rep range with my heaviest weight two workouts in a row, so I'm doing slow 3-second lowering until I get heavier weights): \(list)."))
        }
        return blocks
    }

    // MARK: - Helpers

    /// Finished workouts in the period, oldest first.
    private static func workouts(in input: ProgressReportInput, from start: Date) -> [WorkoutSession] {
        input.sessions
            .filter { $0.startDate >= start && $0.status != .inProgress }
            .sorted { $0.startDate < $1.startDate }
    }

    /// The heaviest, then most reps (or longest), set — e.g. "12 reps @ 20 lb".
    private static func bestSet(_ sets: [SetLog]) -> String {
        let best = sets.max { lhs, rhs in
            let left = (lhs.weightLbs ?? 0, lhs.actualReps ?? lhs.actualSeconds ?? 0)
            let right = (rhs.weightLbs ?? 0, rhs.actualReps ?? rhs.actualSeconds ?? 0)
            return left < right
        }
        return best?.resultText ?? "—"
    }

    private static func goalText(_ goal: GoalType) -> String {
        switch goal {
        case .loseFat: "Lose fat"
        case .buildMuscle: "Build muscle"
        case .both: "Lose fat and build muscle at the same time"
        }
    }

    private static func day(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private static func num(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    private static func whole(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    private static func lb(_ value: Double) -> String { "\(num(value)) lb" }
    private static func pct(_ value: Double) -> String { "\(num(value))%" }

    private static func signed(_ value: Double, digits: Int = 1) -> String {
        let text = abs(value).formatted(.number.precision(.fractionLength(digits)))
        if abs(value) < 0.05 { return "±0" }
        return (value > 0 ? "+" : "−") + text
    }
}

private extension AbilityQuestion {
    var shortName: String {
        switch self {
        case .pushUps: "push-ups"
        case .plank: "plank"
        case .squats: "squats"
        }
    }
}
