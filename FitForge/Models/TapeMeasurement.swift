import Foundation
import SwiftData

/// A place on the body to measure with a tape.
enum MeasureSite: String, CaseIterable, Identifiable, Codable {
    case belly, waist, chest, shoulders, upperArmLeft, upperArmRight, hips, thigh, calf, neck

    var id: String { rawValue }

    /// Tracked by default for new profiles.
    static let defaultTracked: [MeasureSite] = [.belly, .waist, .chest, .upperArmLeft, .upperArmRight]

    var title: String {
        switch self {
        case .belly: "Belly"
        case .waist: "Waist"
        case .chest: "Chest"
        case .shoulders: "Shoulders"
        case .upperArmLeft: "Left upper arm"
        case .upperArmRight: "Right upper arm"
        case .hips: "Hips"
        case .thigh: "Thigh"
        case .calf: "Calf"
        case .neck: "Neck"
        }
    }

    /// Exactly where and how to measure.
    var instructions: String {
        switch self {
        case .belly:
            "Level with your belly button. Stand relaxed, breathe out normally and don't suck in. Keep the tape level all the way around."
        case .waist:
            "At the narrowest point of your torso, usually a little above the belly button. Relaxed, after a normal breath out."
        case .chest:
            "Around the fullest part of your chest, at nipple level, arms relaxed at your sides. Keep the tape level across your back."
        case .shoulders:
            "Around the widest point of your shoulders, over the top of your arms. Stand tall with your arms relaxed."
        case .upperArmLeft, .upperArmRight:
            "Around the thickest part of the upper arm, halfway between shoulder and elbow. Flex with your fist up, and measure the same way every time."
        case .hips:
            "Around the widest part of your hips and glutes, feet together."
        case .thigh:
            "Around the thickest part of your left thigh, just below the glutes, with weight on both feet."
        case .calf:
            "Around the widest part of your left calf, standing with weight on both feet."
        case .neck:
            "Just below the Adam's apple, with the tape sloping slightly down toward the front. Only needed once, for the tape-measure body fat estimate."
        }
    }

    /// Which way counts as progress, for colouring changes.
    enum Direction { case smaller, bigger, neutral }

    var goodDirection: Direction {
        switch self {
        case .belly, .waist, .hips: .smaller
        case .chest, .shoulders, .upperArmLeft, .upperArmRight: .bigger
        case .thigh, .calf, .neck: .neutral
        }
    }
}

/// One tape measurement at one spot on the body.
@Model
final class TapeMeasurement {
    var date: Date = Date.now
    var siteRaw: String = MeasureSite.belly.rawValue
    var inches: Double = 0

    init(site: MeasureSite, inches: Double, date: Date = .now) {
        self.siteRaw = site.rawValue
        self.inches = inches
        self.date = date
    }

    var site: MeasureSite? { MeasureSite(rawValue: siteRaw) }
}
