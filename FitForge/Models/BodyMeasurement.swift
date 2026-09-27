import Foundation
import SwiftData

/// One weigh-in. Weight and body fat normally come from Apple Health (e.g. a smart scale);
/// the extras that Health has no place for are optional manual entries.
@Model
final class BodyMeasurement {
    var date: Date = Date.now

    // From Apple Health (or imported from the web app)
    var weightLbs: Double? = nil
    var bodyFatPercent: Double? = nil

    // Smart scale extras with no place in Apple Health — optional manual entry
    var visceralFat: Double? = nil
    var muscleMassLbs: Double? = nil
    var skeletalMusclePercent: Double? = nil
    var bmrKcal: Double? = nil
    var metabolicAge: Int? = nil

    var sourceRaw: String = MeasurementSource.manual.rawValue

    init(date: Date = .now, source: MeasurementSource = .manual) {
        self.date = date
        self.sourceRaw = source.rawValue
    }

    var source: MeasurementSource {
        get { MeasurementSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}

enum MeasurementSource: String, Codable {
    case health
    case manual
    case webImport
}
