import Foundation

/// Body fat estimated from a tape measure, using the US Navy method.
/// A completely different approach from a smart scale, so it makes a good cross-check.
enum TapeBodyFat {

    /// What's needed to calculate it.
    static func requiredSites(for ranges: BodyFatRanges) -> [MeasureSite] {
        switch ranges {
        case .male: [.neck, .belly]
        case .female: [.neck, .waist, .hips]
        }
    }

    /// Estimated body fat % from measurements in inches, or nil if something is missing or invalid.
    static func estimate(
        ranges: BodyFatRanges,
        heightInches: Double,
        neck: Double?,
        belly: Double?,
        waist: Double?,
        hips: Double?
    ) -> Double? {
        guard heightInches > 0, let neck else { return nil }

        let result: Double
        switch ranges {
        case .male:
            // Men: abdomen measured at the belly button.
            guard let belly, belly - neck > 0 else { return nil }
            result = 86.010 * log10(belly - neck) - 70.041 * log10(heightInches) + 36.76
        case .female:
            guard let waist, let hips, waist + hips - neck > 0 else { return nil }
            result = 163.205 * log10(waist + hips - neck) - 97.684 * log10(heightInches) - 78.387
        }

        // Ignore results that can't be right (e.g. a typo in a measurement).
        return (2...60).contains(result) ? result : nil
    }
}
