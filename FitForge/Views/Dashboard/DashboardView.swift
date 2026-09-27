import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(HealthKitManager.self) private var health
    let profile: UserProfile

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    greeting

                    if !profile.why.isEmpty {
                        whyCard
                    }

                    if !health.isAvailable {
                        unavailableCard
                    } else if health.needsAuthorization {
                        if health.hasCheckedAuthorization { connectCard }
                    } else {
                        statsSection
                    }

                    if let error = health.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .animation(.default, value: health.needsAuthorization)
            }
            .navigationTitle("FitForge")
            .refreshable { await health.refresh() }
            .task {
                await health.checkAuthorization()
                await health.refresh()
            }
        }
    }

    // MARK: - Sections

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(profile.name.isEmpty ? "Let's get after it." : "Let's get after it, \(profile.name).")
                .font(.title2.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var whyCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.circle.fill")
                .font(.title2)
                .foregroundStyle(Theme.gradient)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your why")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(profile.why)
                    .font(.subheadline.weight(.medium))
            }
        }
        .cardStyle()
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest from Apple Health")
                .font(.headline)

            HStack(spacing: 12) {
                StatTile(
                    title: "Weight",
                    systemImage: "scalemass.fill",
                    value: health.latestWeight.map { format($0.value) },
                    unit: "lb",
                    date: health.latestWeight?.date
                )
                StatTile(
                    title: "Body fat",
                    systemImage: "percent",
                    value: health.latestBodyFat.map { format($0.value) },
                    unit: "%",
                    date: health.latestBodyFat?.date,
                    tint: Theme.green
                )
            }

            if health.latestWeight == nil && health.latestBodyFat == nil && !health.isLoading {
                Text("No weigh-ins found. Make sure Renpho is syncing to Apple Health, and that FitForge is allowed to read Weight and Body Fat Percentage in Settings → Health → Data Access & Devices.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var connectCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.gradient)

            Text("Connect Apple Health")
                .font(.title3.weight(.bold))

            Text("FitForge reads your weigh-ins from Apple Health (including your Renpho scale), so you never have to type them in. Workouts you finish get saved back to Health.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task { await health.requestAuthorization() }
            } label: {
                Text("Connect")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.blue)
        }
        .cardStyle()
    }

    private var unavailableCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Apple Health isn't available", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Theme.teal)
            Text("This device doesn't support Apple Health.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }
}

#Preview {
    DashboardView(profile: UserProfile())
        .environment(HealthKitManager())
        .modelContainer(for: [UserProfile.self, EquipmentItem.self, BodyMeasurement.self], inMemory: true)
}
