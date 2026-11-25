import SwiftUI
import SwiftData

/// On the workout summary: "Bodyweight Squat is getting easy. Ready for something harder?"
/// Try it moves that movement up a level (harder exercises from the next workout on);
/// Not yet asks again in two weeks if it's still easy.
struct GraduationCard: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Query private var sessions: [WorkoutSession]
    /// Answered offers, hidden for the rest of this summary.
    @State private var answered: [String: Bool] = [:]

    private var offers: [ExerciseProgression.Graduation] {
        ExerciseProgression.graduations(for: profile, history: sessions)
    }

    var body: some View {
        // Show answered offers too, with their result, until the summary closes.
        let visible = offers.filter { answered[$0.id] == nil } + answeredOffers
        if !visible.isEmpty {
            VStack(spacing: 12) {
                ForEach(visible) { offer in
                    card(offer)
                }
            }
            .animation(.snappy, value: answered)
        }
    }

    /// Offers already answered stay visible (with a confirmation) instead of vanishing.
    @State private var answeredOffers: [ExerciseProgression.Graduation] = []

    private func card(_ offer: ExerciseProgression.Graduation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Ready for something harder?", systemImage: "arrow.up.forward.circle.fill")
                .font(.headline)
                .foregroundStyle(Theme.green)

            Text("\(offer.from.name) is getting easy. \(offer.reason)")
                .font(.subheadline)

            if let accepted = answered[offer.id] {
                Label(
                    accepted
                        ? "Done. From your next workout, \(offer.pattern.areaTitle.lowercased()) exercises move up a level, starting with harder ones like \(offer.to.name)."
                        : "No problem. FitForge will ask again in \(UserProfile.graduationSnoozeDays) days if it's still easy.",
                    systemImage: accepted ? "checkmark.circle.fill" : "clock"
                )
                .font(.caption)
                .foregroundStyle(accepted ? Theme.green : .secondary)
            } else {
                Text("Next up: **\(offer.to.name)**. \(offer.to.summary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button {
                        answer(offer, accept: true)
                    } label: {
                        Text("Try it")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(Theme.green)

                    Button {
                        answer(offer, accept: false)
                    } label: {
                        Text("Not yet")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(Theme.blue)
                }
            }
        }
        .cardStyle()
    }

    private func answer(_ offer: ExerciseProgression.Graduation, accept: Bool) {
        if accept {
            profile.moveUpLevel(for: offer.pattern)
        } else {
            profile.snoozeGraduation(offer.from.id)
        }
        try? context.save()
        answeredOffers.append(offer)
        answered[offer.id] = accept
    }
}
