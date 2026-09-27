import SwiftUI

/// A simple front-facing body outline with a green "tape" band showing where to measure.
/// Drawn in a 200 × 440 design space and scaled to fit.
struct BodySilhouette: View {
    var highlight: MeasureSite?
    var isFemale = false
    /// Sites that can be tapped on the body to select them.
    var tappableSites: [MeasureSite] = []
    var onSelect: (MeasureSite) -> Void = { _ in }

    private static let designSize = CGSize(width: 200, height: 440)

    var body: some View {
        GeometryReader { geometry in
            let sx = geometry.size.width / Self.designSize.width
            let sy = geometry.size.height / Self.designSize.height

            ZStack {
                // Draw the whole figure in a solid (opaque) colour, then fade it as one piece,
                // so overlapping arms/legs don't show lighter patches.
                ZStack {
                    BodyShape(isFemale: isFemale)
                        .fill(Color.gray)

                    LimbsShape(isFemale: isFemale, part: .arms)
                        .stroke(Color.gray, style: StrokeStyle(lineWidth: (isFemale ? 18 : 22) * sx, lineCap: .round, lineJoin: .round))

                    LimbsShape(isFemale: isFemale, part: .legs)
                        .stroke(Color.gray, style: StrokeStyle(lineWidth: (isFemale ? 30 : 32) * sx, lineCap: .round, lineJoin: .round))
                }
                .compositingGroup()
                .opacity(0.35)

                // Tap targets
                ForEach(tappableSites) { site in
                    let band = Self.band(for: site, isFemale: isFemale)
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .frame(width: (band.x2 - band.x1) * sx, height: 22)
                        .position(x: (band.x1 + band.x2) / 2 * sx, y: band.y * sy)
                        .onTapGesture { onSelect(site) }
                }

                // The tape band
                if let highlight {
                    let band = Self.band(for: highlight, isFemale: isFemale)
                    Capsule()
                        .fill(Theme.green)
                        .frame(width: (band.x2 - band.x1) * sx + 8, height: 6)
                        .shadow(color: Theme.green.opacity(0.7), radius: 5)
                        .position(x: (band.x1 + band.x2) / 2 * sx, y: band.y * sy)
                        .allowsHitTesting(false)
                }
            }
        }
        .aspectRatio(Self.designSize.width / Self.designSize.height, contentMode: .fit)
        .animation(.snappy, value: highlight)
        .accessibilityHidden(true)
    }

    /// Where the tape goes for each site, in design coordinates.
    /// The figure faces you, so the person's left side is on the right of the drawing.
    static func band(for site: MeasureSite, isFemale: Bool) -> (y: CGFloat, x1: CGFloat, x2: CGFloat) {
        switch site {
        case .neck: (70, 86, 114)
        case .shoulders: isFemale ? (99, 42, 158) : (99, 36, 164)
        case .chest: isFemale ? (124, 54, 146) : (124, 50, 150)
        case .waist: isFemale ? (180, 69, 131) : (180, 64, 136)
        case .belly: isFemale ? (200, 66, 134) : (200, 62, 138)
        case .hips: isFemale ? (245, 54, 146) : (245, 58, 142)
        case .upperArmLeft: isFemale ? (130, 136, 158) : (130, 138, 164)
        case .upperArmRight: isFemale ? (130, 42, 64) : (130, 36, 62)
        case .thigh: (292, 100, 134)
        case .calf: (372, 104, 132)
        }
    }
}

/// Head, neck and torso as one filled shape.
private struct BodyShape: Shape {
    let isFemale: Bool

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 200
        let sy = rect.height / 440
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }

        var path = Path()

        // Head
        path.addEllipse(in: CGRect(x: rect.minX + 76 * sx, y: rect.minY + 10 * sy, width: 48 * sx, height: 48 * sy))

        // Neck
        path.addRoundedRect(
            in: CGRect(x: rect.minX + 90 * sx, y: rect.minY + 54 * sy, width: 20 * sx, height: 32 * sy),
            cornerSize: CGSize(width: 6 * sx, height: 6 * sy)
        )

        // Torso outline, clockwise from the left shoulder
        let torso: [CGPoint] = isFemale
            ? [p(64, 86), p(88, 80), p(112, 80), p(136, 86), p(146, 100), p(140, 122), p(136, 150),
               p(128, 185), p(136, 215), p(144, 245), p(138, 268), p(100, 272),
               p(62, 268), p(56, 245), p(64, 215), p(72, 185), p(64, 150), p(60, 122), p(54, 100)]
            : [p(60, 86), p(88, 80), p(112, 80), p(140, 86), p(152, 100), p(146, 122), p(140, 150),
               p(133, 185), p(136, 215), p(140, 245), p(136, 268), p(100, 272),
               p(64, 268), p(60, 245), p(64, 215), p(67, 185), p(60, 150), p(54, 122), p(48, 100)]
        path.addPath(Self.smoothClosedPath(through: torso))

        return path
    }

    /// A smooth closed curve through the points (quadratic curves between midpoints).
    static func smoothClosedPath(through points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 2 else { return path }
        func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }

        path.move(to: mid(points[points.count - 1], points[0]))
        for index in points.indices {
            let current = points[index]
            let next = points[(index + 1) % points.count]
            path.addQuadCurve(to: mid(current, next), control: current)
        }
        path.closeSubpath()
        return path
    }
}

/// Arms or legs, drawn as thick rounded strokes.
private struct LimbsShape: Shape {
    enum Part { case arms, legs }

    let isFemale: Bool
    let part: Part

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 200
        let sy = rect.height / 440
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }

        var path = Path()
        switch part {
        case .arms:
            let inset: CGFloat = isFemale ? 4 : 0
            path.addLines([p(54 + inset, 98), p(44 + inset, 168), p(38 + inset, 240)])
            path.addLines([p(146 - inset, 98), p(156 - inset, 168), p(162 - inset, 240)])
        case .legs:
            path.addLines([p(84, 262), p(82, 345), p(82, 425)])
            path.addLines([p(116, 262), p(118, 345), p(118, 425)])
        }
        return path
    }
}

#Preview {
    HStack {
        BodySilhouette(highlight: .belly)
        BodySilhouette(highlight: .upperArmLeft, isFemale: true)
    }
    .frame(height: 360)
    .padding()
}
