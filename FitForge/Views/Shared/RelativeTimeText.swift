import SwiftUI

/// "49 seconds ago", "2 minutes ago", "yesterday"… that stays current on its own.
struct RelativeTimeText: View {
    let date: Date

    var body: some View {
        // Re-render every 15 seconds so the wording never goes stale while the screen is open.
        TimelineView(.periodic(from: .now, by: 15)) { _ in
            Text(date.formatted(.relative(presentation: .named, unitsStyle: .wide)))
        }
    }
}
