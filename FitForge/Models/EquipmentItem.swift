import Foundation
import SwiftData

@Model
final class EquipmentItem {
    var kindRaw: String = EquipmentKind.dumbbells.rawValue
    /// Weight in lb for dumbbells/kettlebells (per dumbbell). Nil for everything else.
    var weightLbs: Double? = nil
    var isPair: Bool = true
    var addedDate: Date = Date.now

    var profile: UserProfile?

    init(kind: EquipmentKind, weightLbs: Double? = nil, isPair: Bool = true) {
        self.kindRaw = kind.rawValue
        self.weightLbs = weightLbs
        self.isPair = isPair
    }

    var kind: EquipmentKind {
        get { EquipmentKind(rawValue: kindRaw) ?? .dumbbells }
        set { kindRaw = newValue.rawValue }
    }

    /// e.g. "Dumbbells · 25 lb pair" or "Sturdy chair"
    var displayName: String {
        guard kind.hasWeight, let weightLbs else { return kind.title }
        let weight = weightLbs.formatted(.number.precision(.fractionLength(0...1)))
        return "\(kind.title) · \(weight) lb\(isPair && kind == .dumbbells ? " pair" : "")"
    }
}
