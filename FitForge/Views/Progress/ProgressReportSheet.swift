import SwiftUI
import SwiftData

/// Creates the progress report PDF and hands it to the share sheet (an AI app, Files, Messages…).
struct ProgressReportSheet: View {
    let profile: UserProfile

    @Environment(HealthKitManager.self) private var health
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSession.startDate) private var sessions: [WorkoutSession]
    @Query(sort: \BodyMeasurement.date) private var measurements: [BodyMeasurement]
    @Query(sort: \TapeMeasurement.date) private var tapeEntries: [TapeMeasurement]

    @State private var range: ReportRange = .threeMonths
    @State private var includeName = false
    @State private var includeEarlierHistory = true
    @State private var notes = ""
    @State private var isCreating = false
    @State private var reportURL: URL?
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("A PDF of your goals, weigh-ins, measurements, workouts and strength progress, with a ready-made question at the top. Share it with an AI assistant like Claude or ChatGPT for honest feedback, or save it to Files.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    FormCard {
                        Text("Time range")
                            .font(.headline)
                        Picker("Time range", selection: $range) {
                            ForEach(ReportRange.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text(range.longTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Toggle(isOn: $includeName) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Include my name")
                                    .font(.subheadline.weight(.semibold))
                                Text("Off by default, since the report may be shared.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(Theme.green)

                        Divider()

                        Toggle(isOn: $includeEarlierHistory) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Include earlier history")
                                    .font(.subheadline.weight(.semibold))
                                Text("A yearly summary of Apple Health weigh-ins from before FitForge, for context.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(Theme.green)
                    }

                    FormCard {
                        Text("Notes for the AI")
                            .font(.headline)
                        Text("Optional. Anything the numbers don't show, like \"Started creatine Nov 12\" or \"Ate badly over the holidays\".")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(3...8)
                            .textFieldStyle(.roundedBorder)
                    }

                    if let reportURL {
                        ShareLink(item: reportURL) {
                            Label("Share or save report", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(Theme.green)

                        Text("Ready. Tap above and pick Claude, ChatGPT or another app, or Save to Files.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Button {
                            Task { await create() }
                        } label: {
                            Group {
                                if isCreating {
                                    ProgressView()
                                } else {
                                    Label("Create report", systemImage: "doc.richtext")
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(Theme.blue)
                        .disabled(isCreating)
                    }

                    if let errorText {
                        Text(errorText)
                            .font(.caption)
                            .foregroundStyle(Theme.teal)
                    }

                    Label("This is a report to read and share, not a backup. FitForge can't restore your data from it.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Progress report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            // A changed setting means a new report is needed.
            .onChange(of: range) { reportURL = nil }
            .onChange(of: includeName) { reportURL = nil }
            .onChange(of: includeEarlierHistory) { reportURL = nil }
            .onChange(of: notes) { reportURL = nil }
        }
    }

    private func create() async {
        isCreating = true
        errorText = nil
        defer { isCreating = false }

        // From the start (for "at start → latest"), or further back for "All".
        let fetchStart = min(range.startDate, profile.startDate).addingTimeInterval(-30 * 86_400)
        let since = includeEarlierHistory
            ? (Calendar.current.date(byAdding: .year, value: -10, to: .now) ?? fetchStart)
            : fetchStart
        let weights = await health.weightHistory(since: since)
        let bodyFats = await health.bodyFatHistory(since: since)

        let input = ProgressReportInput(
            profile: profile,
            sessions: sessions,
            measurements: measurements.filter(\.hasExtras),
            tape: tapeEntries,
            weights: weights,
            bodyFats: bodyFats,
            range: range,
            includeName: includeName,
            includeEarlierHistory: includeEarlierHistory,
            notes: notes
        )
        do {
            reportURL = try ProgressReport.makePDF(input)
        } catch {
            errorText = "Couldn't create the report: \(error.localizedDescription)"
        }
    }
}
