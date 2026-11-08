import Foundation
import SwiftData

/// One piece of equipment the user owns.
///
/// Weighted gear (dumbbells, kettlebells) is stored as one item per weight — a 10 lb pair and a
/// 15 lb pair are two items — or as a single adjustable item covering a range (e.g. 5–50 lb).
@Model
final class EquipmentItem {
    var kindRaw: String = EquipmentKind.dumbbells.rawValue
    /// Weight in lb (per dumbbell / per kettlebell). For adjustable gear, the lightest setting.
    /// Nil when unknown, or for unweighted equipment.
    var weightLbs: Double? = nil
    var isPair: Bool = true
    var addedDate: Date = Date.now
    /// Adjustable dumbbells/kettlebell: every weight from `weightLbs` to `maxWeightLbs` is available.
    var isAdjustable: Bool = false
    var maxWeightLbs: Double? = nil
    /// Owned but switched off: kept on the list, left out of workouts until turned on.
    var isInUse: Bool = true

    var profile: UserProfile?

    init(kind: EquipmentKind, weightLbs: Double? = nil, isPair: Bool = true) {
        self.kindRaw = kind.rawValue
        self.weightLbs = weightLbs
        self.isPair = isPair
    }

    /// An adjustable item covering a range of weights.
    convenience init(adjustable kind: EquipmentKind, from minimum: Double, to maximum: Double) {
        self.init(kind: kind, weightLbs: min(minimum, maximum))
        isAdjustable = true
        maxWeightLbs = max(minimum, maximum)
    }

    var kind: EquipmentKind {
        get { EquipmentKind(rawValue: kindRaw) ?? .dumbbells }
        set { kindRaw = newValue.rawValue }
    }

    /// Every weight this item can be used at (lb). Adjustable gear counts in 5 lb steps.
    var availableWeights: [Double] {
        guard let weightLbs else { return [] }
        guard isAdjustable, let maxWeightLbs, maxWeightLbs > weightLbs else { return [weightLbs] }
        var weights = Array(stride(from: weightLbs, through: maxWeightLbs, by: 5))
        if let last = weights.last, last < maxWeightLbs { weights.append(maxWeightLbs) }
        return weights
    }

    /// e.g. "Dumbbells · 25 lb pair", "Adjustable dumbbells · 5–50 lb" or "Pull-up bar · not in use yet"
    var displayName: String {
        let suffix = isInUse ? "" : " · not in use yet"
        guard kind.hasWeight, let weightLbs else { return kind.title + suffix }
        let low = Self.format(weightLbs)
        if isAdjustable, let maxWeightLbs {
            return "Adjustable \(kind.title.lowercased()) · \(low)–\(Self.format(maxWeightLbs)) lb" + suffix
        }
        return "\(kind.title) · \(low) lb\(isPair && kind == .dumbbells ? " pair" : "")" + suffix
    }

    static func format(_ weight: Double) -> String {
        weight.formatted(.number.precision(.fractionLength(0...1)))
    }
}

extension UserProfile {
    /// Equipment switched on for workouts.
    var equipmentInUse: [EquipmentItem] {
        (equipment ?? []).filter(\.isInUse)
    }

    /// Every weight available for a kind of equipment, lightest first (e.g. dumbbells: 10, 15, 25).
    func availableWeights(for kind: EquipmentKind) -> [Double] {
        let all = equipmentInUse.filter { $0.kind == kind }.flatMap(\.availableWeights)
        return Array(Set(all)).sorted()
    }

    /// True if the user has this kind of equipment but never said what it weighs.
    func hasUnknownWeight(for kind: EquipmentKind) -> Bool {
        equipmentInUse.contains { $0.kind == kind && $0.weightLbs == nil }
    }
}
