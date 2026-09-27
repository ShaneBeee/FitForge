import SwiftUI

/// FitForge look: clean, light, blues and greens, no red.
enum Theme {
    static let blue = Color(red: 0.15, green: 0.45, blue: 0.95)
    static let green = Color(red: 0.12, green: 0.70, blue: 0.52)
    static let teal = Color(red: 0.10, green: 0.62, blue: 0.75)

    static let gradient = LinearGradient(
        colors: [blue, green],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardCornerRadius: CGFloat = 20
}

extension View {
    /// Standard rounded card background used across the app.
    func cardStyle() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
    }
}
