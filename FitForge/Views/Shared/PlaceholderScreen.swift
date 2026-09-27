import SwiftUI

/// Temporary stand-in for tabs that haven't been built yet.
struct PlaceholderScreen: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
                .navigationTitle(title)
        }
    }
}

#Preview {
    PlaceholderScreen(title: "Progress", systemImage: "chart.line.uptrend.xyaxis", message: "Charts are coming soon.")
}
