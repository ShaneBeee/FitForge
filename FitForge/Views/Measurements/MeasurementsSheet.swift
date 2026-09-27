import SwiftUI
import SwiftData
import UIKit

/// Log tape measurements, with the body silhouette showing exactly where each one goes.
struct MeasurementsSheet: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TapeMeasurement.date, order: .reverse) private var entries: [TapeMeasurement]

    @State private var date = Date.now
    @State private var values: [MeasureSite: Double] = [:]
    @State private var selected: MeasureSite?
    @State private var showSitePicker = false

    private var isFemale: Bool { profile.bodyFatRanges == .female }

    /// The sites shown in the form: tracked ones, plus neck once if it's never been measured.
    private var sites: [MeasureSite] {
        var sites = profile.trackedSites
        if !sites.contains(.neck) && !entries.contains(where: { $0.site == .neck }) {
            sites.append(.neck)
        }
        return sites
    }

    private var hasAnyValue: Bool { !values.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    guide

                    FormCard {
                        DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                    }

                    FormCard {
                        ForEach(Array(sites.enumerated()), id: \.element) { index, site in
                            if index > 0 { Divider() }
                            siteRow(site)
                        }
                    }

                    Button {
                        showSitePicker = true
                    } label: {
                        Label("Choose which measurements to track", systemImage: "slider.horizontal.3")
                            .font(.subheadline.weight(.semibold))
                    }

                    tips
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasAnyValue)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showSitePicker) {
                TrackedSitesPicker(profile: profile)
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                if selected == nil { selected = sites.first }
            }
        }
    }

    // MARK: - Guide

    private var guide: some View {
        HStack(alignment: .top, spacing: 16) {
            BodySilhouette(
                highlight: selected,
                isFemale: isFemale,
                tappableSites: sites
            ) { site in
                selected = site
            }
            .frame(height: 260)

            VStack(alignment: .leading, spacing: 8) {
                if let selected {
                    Text(selected.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.green)
                    Text(selected.instructions)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if selected == .upperArmLeft || selected == .upperArmRight || selected == .thigh || selected == .calf {
                        Text("The figure faces you, so your left side is on the right of the drawing.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Text("Tap a measurement to see where it goes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.snappy, value: selected)
        }
        .cardStyle()
    }

    // MARK: - Rows

    private func siteRow(_ site: MeasureSite) -> some View {
        let last = entries.first { $0.site == site && !Calendar.current.isDate($0.date, inSameDayAs: date) }

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Circle()
                    .fill(selected == site ? Theme.green : Color.clear)
                    .frame(width: 8, height: 8)
                NumberEntryRow(title: site.title, unit: "in", value: binding(for: site))
            }
            if let last {
                Text("Last: \(last.inches.formatted(.number.precision(.fractionLength(0...2)))) in on \(last.date.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 16)
            } else if site == .neck && !profile.trackedSites.contains(.neck) {
                Text("One time only — used for the tape-measure body fat estimate.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 16)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { selected = site })
    }

    private func binding(for site: MeasureSite) -> Binding<Double?> {
        Binding(
            get: { values[site] },
            set: { values[site] = $0 }
        )
    }

    private var tips: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("For consistent numbers")
                .font(.subheadline.weight(.semibold))
            Text("Measure in the morning, before eating and not right after a workout. Use the same tape each time, snug but not squeezing the skin. Every 2–4 weeks is plenty — measurements change slowly.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Save

    private func save() {
        for (site, inches) in values where inches > 0 {
            // Replace an entry for the same spot on the same day, if there is one.
            for existing in entries where existing.site == site && Calendar.current.isDate(existing.date, inSameDayAs: date) {
                context.delete(existing)
            }
            context.insert(TapeMeasurement(site: site, inches: inches, date: date))
        }
        try? context.save()
    }
}

/// Toggle which measurements show up in the form and on Progress.
struct TrackedSitesPicker: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(MeasureSite.allCases) { site in
                        Button {
                            toggle(site)
                        } label: {
                            HStack {
                                Text(site.title)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if profile.trackedSites.contains(site) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.blue)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } footer: {
                    Text("At least one must stay on.")
                }
            }
            .navigationTitle("Track measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func toggle(_ site: MeasureSite) {
        var sites = profile.trackedSites
        if let index = sites.firstIndex(of: site) {
            guard sites.count > 1 else { return }
            sites.remove(at: index)
        } else {
            sites.append(site)
        }
        profile.trackedSites = sites
        try? context.save()
    }
}
