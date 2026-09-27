import SwiftUI
import SwiftData

enum ProgressRange: String, CaseIterable, Identifiable {
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"

    var id: String { rawValue }

    var startDate: Date {
        let calendar = Calendar.current
        let now = Date.now
        return switch self {
        case .month: calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths: calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths: calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .year: calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all: calendar.date(byAdding: .year, value: -10, to: now) ?? now
        }
    }
}

/// The Progress tab: weight, body fat and visceral fat charts, where you stand,
/// body composition, and workouts per week.
struct ProgressScreen: View {
    let profile: UserProfile

    @Environment(HealthKitManager.self) private var health
    @Query(sort: \WorkoutSession.startDate) private var sessions: [WorkoutSession]
    @Query(sort: \BodyMeasurement.date) private var measurements: [BodyMeasurement]
    @Query(sort: \TapeMeasurement.date) private var tapeEntries: [TapeMeasurement]

    @State private var range: ProgressRange = .threeMonths
    @State private var weights: [HealthKitManager.Reading] = []
    @State private var bodyFats: [HealthKitManager.Reading] = []
    @State private var hasLoaded = false
    @State private var showExtrasEntry = false
    @State private var showMeasurementsEntry = false

    /// Weigh-ins that have smart scale extras, oldest first.
    private var extras: [BodyMeasurement] {
        measurements.filter(\.hasExtras)
    }

    /// Visceral fat readings within the chosen range.
    private var visceralReadings: [HealthKitManager.Reading] {
        measurements
            .filter { $0.date >= range.startDate }
            .compactMap { measurement in
                measurement.visceralFat.map { HealthKitManager.Reading(value: $0, date: measurement.date) }
            }
    }

    private var age: Int? {
        profile.birthDate.flatMap { Calendar.current.dateComponents([.year], from: $0, to: .now).year }
    }

    /// For "All", start the charts at the first reading instead of 10 years ago.
    private var domainStart: Date {
        guard range == .all else { return range.startDate }
        let firstDates = [weights.first?.date, bodyFats.first?.date, sessions.first?.startDate].compactMap { $0 }
        return firstDates.min() ?? range.startDate
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Time range", selection: $range) {
                        ForEach(ProgressRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    if health.needsAuthorization && health.hasCheckedAuthorization {
                        connectCard
                    }

                    MetricChartCard(
                        title: "Weight",
                        systemImage: "scalemass.fill",
                        unit: "lb",
                        readings: weights,
                        start: profile.startWeightLbs,
                        goal: profile.targetWeightLbs,
                        tint: Theme.blue,
                        domainStart: domainStart
                    )

                    MetricChartCard(
                        title: "Body fat",
                        systemImage: "percent",
                        unit: "%",
                        readings: bodyFats,
                        start: profile.startBodyFatPercent,
                        goal: profile.targetBodyFatPercent,
                        tint: Theme.green,
                        domainStart: domainStart
                    )

                    if extras.contains(where: { $0.visceralFat != nil }) {
                        MetricChartCard(
                            title: "Visceral fat",
                            systemImage: "target",
                            unit: "",
                            readings: visceralReadings,
                            start: extras.first(where: { $0.visceralFat != nil })?.visceralFat,
                            goal: nil,
                            tint: Theme.teal,
                            domainStart: domainStart,
                            fractionDigits: 0
                        )
                    }

                    whereYouStand

                    TapeBodyFatCard(
                        profile: profile,
                        entries: tapeEntries,
                        scaleBodyFat: bodyFats.last?.value ?? health.latestBodyFat?.value
                    ) {
                        showMeasurementsEntry = true
                    }

                    MeasurementsSection(
                        profile: profile,
                        entries: tapeEntries,
                        domainStart: domainStart
                    ) {
                        showMeasurementsEntry = true
                    }

                    BodyCompositionCard(measurements: extras, age: age) {
                        showExtrasEntry = true
                    }

                    WorkoutsPerWeekCard(
                        sessions: sessions,
                        target: profile.workoutWeekdays.count,
                        domainStart: domainStart
                    )
                }
                .padding()
                .animation(.snappy, value: range)
                .opacity(hasLoaded ? 1 : 0.5)
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showMeasurementsEntry = true
                        } label: {
                            Label("Log measurements", systemImage: "ruler")
                        }
                        Button {
                            showExtrasEntry = true
                        } label: {
                            Label("Log scale extras", systemImage: "scalemass")
                        }
                    } label: {
                        Label("Log", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showExtrasEntry) {
                WeighInExtrasSheet()
            }
            .sheet(isPresented: $showMeasurementsEntry) {
                MeasurementsSheet(profile: profile)
            }
            .refreshable { await load() }
            .task(id: range) { await load() }
        }
    }

    @ViewBuilder
    private var whereYouStand: some View {
        let weight = weights.last?.value ?? health.latestWeight?.value
        let bodyFat = bodyFats.last?.value ?? health.latestBodyFat?.value
        let height = profile.heightInches ?? 0

        if weight != nil || bodyFat != nil {
            Text("Where you stand")
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        }

        if let weight, height > 0 {
            WeightRangeCard(weightLbs: weight, heightInches: height, goalLbs: profile.targetWeightLbs)
        }

        if let bodyFat {
            BodyFatRangeCard(profile: profile, bodyFatPercent: bodyFat, goalPercent: profile.targetBodyFatPercent)
        }

        if let visceral = extras.last(where: { $0.visceralFat != nil })?.visceralFat {
            VisceralFatRangeCard(rating: visceral)
        }

        if let weight, height > 0 {
            BMICard(weightLbs: weight, heightInches: height, goalWeightLbs: profile.targetWeightLbs)
        }
    }

    private var connectCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Connect Apple Health to see your charts", systemImage: "heart.fill")
                .font(.headline)
                .foregroundStyle(Theme.green)
            Button("Connect") {
                Task {
                    await health.requestAuthorization()
                    await load()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.green)
        }
        .cardStyle()
    }

    private func load() async {
        if !health.hasCheckedAuthorization {
            await health.checkAuthorization()
        }
        let start = range.startDate
        weights = await health.weightHistory(since: start)
        bodyFats = await health.bodyFatHistory(since: start)
        hasLoaded = true
    }
}
