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

/// The Progress tab, in four parts: your goals (weight and body fat progress), the Body card
/// (one chart with chips for every body metric), measurements, and workouts per week.
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
    /// The Body card's chart. Starts on Weight each time the app opens.
    @State private var bodyMetricID = BodyMetric.weight.id

    private var bodyMetric: Binding<BodyMetric> {
        Binding(
            get: { BodyMetric(id: bodyMetricID) ?? .weight },
            set: { bodyMetricID = $0.id }
        )
    }

    /// Weigh-ins that have smart scale extras, oldest first.
    private var extras: [BodyMeasurement] {
        measurements.filter(\.hasExtras)
    }

    private var latestWeight: Double? {
        weights.last?.value ?? health.latestWeight?.value
    }

    private var latestBodyFat: Double? {
        bodyFats.last?.value ?? health.latestBodyFat?.value
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
            ScrollViewReader { proxy in
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

                        if profile.targetWeightLbs != nil || profile.targetBodyFatPercent != nil {
                            GoalsCard(
                                weight: latestWeight,
                                startWeight: profile.startWeightLbs,
                                goalWeight: profile.targetWeightLbs,
                                bodyFat: latestBodyFat,
                                startBodyFat: profile.startBodyFatPercent,
                                goalBodyFat: profile.targetBodyFatPercent
                            ) { metric in
                                // Show that metric in the Body chart and bring the chart into view.
                                withAnimation(.snappy) {
                                    bodyMetricID = metric.id
                                    proxy.scrollTo("body", anchor: .top)
                                }
                            }
                        }

                        BodyTrendsCard(
                            profile: profile,
                            weights: weights,
                            bodyFats: bodyFats,
                            latestWeight: latestWeight,
                            latestBodyFat: latestBodyFat,
                            extras: extras,
                            tapeEntries: tapeEntries,
                            age: age,
                            rangeStart: range.startDate,
                            domainStart: domainStart,
                            selection: bodyMetric,
                            onAddMeasurements: { showMeasurementsEntry = true },
                            onAddExtras: { showExtrasEntry = true }
                        )
                        .id("body")

                        MeasurementsSection(
                            profile: profile,
                            entries: tapeEntries,
                            domainStart: domainStart
                        ) {
                            showMeasurementsEntry = true
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
