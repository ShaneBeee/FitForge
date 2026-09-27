import SwiftUI
import SwiftData
import UIKit

/// Quick entry for the smart scale numbers Apple Health doesn't store.
struct WeighInExtrasSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]

    @State private var date = Date.now
    @State private var visceralFat: Double?
    @State private var muscleMass: Double?
    @State private var skeletalMuscle: Double?
    @State private var bmr: Double?
    @State private var metabolicAge: Double?
    @State private var didLoad = false

    /// A weigh-in already saved for the chosen day, if any.
    private var existing: BodyMeasurement? {
        measurements.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    /// The most recent earlier entry with extras, shown as a hint.
    private var previous: BodyMeasurement? {
        measurements.first {
            !Calendar.current.isDate($0.date, inSameDayAs: date) && $0.date < date && $0.hasExtras
        }
    }

    private var hasAnyValue: Bool {
        [visceralFat, muscleMass, skeletalMuscle, bmr, metabolicAge].contains { $0 != nil }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Open your smart scale's app and copy these from your latest weigh-in. Weight and body fat come in from Apple Health automatically. Everything here is optional — fill in whatever your scale measures.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    FormCard {
                        DatePicker("Weigh-in date", selection: $date, in: ...Date.now, displayedComponents: .date)
                    }

                    FormCard {
                        row("Visceral fat", unit: "", value: $visceralFat, last: previous?.visceralFat, digits: 0)
                        Divider()
                        row("Muscle mass", unit: "lb", value: $muscleMass, last: previous?.muscleMassLbs)
                        Divider()
                        row("Skeletal muscle", unit: "%", value: $skeletalMuscle, last: previous?.skeletalMusclePercent)
                        Divider()
                        row("BMR", unit: "kcal", value: $bmr, last: previous?.bmrKcal, digits: 0)
                        Divider()
                        row("Metabolic age", unit: "yrs", value: $metabolicAge, last: previous?.metabolicAge.map(Double.init), digits: 0)
                    }

                    Text("Visceral fat is the fat stored deep around your organs, mostly in your belly. Most smart scales rate it on a scale where 1–9 is standard.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Weigh-in extras")
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
            .onAppear {
                guard !didLoad else { return }
                didLoad = true
                loadExisting()
            }
            .onChange(of: date) { loadExisting() }
        }
    }

    private func row(_ title: String, unit: String, value: Binding<Double?>, last: Double?, digits: Int = 1) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NumberEntryRow(title: title, unit: unit, value: value)
            if let last {
                Text("Last time: \(last.formatted(.number.precision(.fractionLength(digits)))) \(unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Fills the fields if extras were already entered for this day.
    private func loadExisting() {
        visceralFat = existing?.visceralFat
        muscleMass = existing?.muscleMassLbs
        skeletalMuscle = existing?.skeletalMusclePercent
        bmr = existing?.bmrKcal
        metabolicAge = existing?.metabolicAge.map(Double.init)
    }

    /// Adds the extras to that day's weigh-in, or creates a new one.
    private func save() {
        let measurement: BodyMeasurement
        if let existing {
            measurement = existing
        } else {
            measurement = BodyMeasurement(date: date, source: .manual)
            context.insert(measurement)
        }
        measurement.visceralFat = visceralFat
        measurement.muscleMassLbs = muscleMass
        measurement.skeletalMusclePercent = skeletalMuscle
        measurement.bmrKcal = bmr
        measurement.metabolicAge = metabolicAge.map { Int($0.rounded()) }
        try? context.save()
    }
}

extension BodyMeasurement {
    /// Whether any of the Renpho-only extras were entered.
    var hasExtras: Bool {
        visceralFat != nil || muscleMassLbs != nil || skeletalMusclePercent != nil || bmrKcal != nil || metabolicAge != nil
    }
}
