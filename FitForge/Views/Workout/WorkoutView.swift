import SwiftUI

/// Shows today's workout (or the next one on a rest day), with Day A/B/C browsable.
struct WorkoutView: View {
    let profile: UserProfile

    @State private var selectedDay: WorkoutDay = .a
    @State private var detail: PlannedExercise?
    @State private var didSetInitialDay = false

    private var week: [PlannedWorkout] { WorkoutBuilder.buildWeek(for: profile) }
    private var todaysDay: WorkoutDay? { WorkoutSchedule.workoutDay(on: .now, for: profile) }
    private var next: (date: Date, day: WorkoutDay)? { WorkoutSchedule.nextWorkout(after: .now, for: profile) }

    private var selectedWorkout: PlannedWorkout? {
        week.first { $0.day == selectedDay }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    todayCard

                    Picker("Workout", selection: $selectedDay) {
                        ForEach(WorkoutDay.allCases) { day in
                            Text(day.title).tag(day)
                        }
                    }
                    .pickerStyle(.segmented)

                    if let workout = selectedWorkout {
                        workoutHeader(workout)

                        ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, planned in
                            Button {
                                detail = planned
                            } label: {
                                ExerciseRow(number: index + 1, planned: planned)
                            }
                            .buttonStyle(.plain)
                        }

                        Label("Guided mode — sets, rest timers and the Ready button — is coming next.", systemImage: "sparkles")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .animation(.snappy, value: selectedDay)
            }
            .navigationTitle("Workout")
            .sheet(item: $detail) { planned in
                ExerciseDetailView(planned: planned)
            }
            .onAppear {
                guard !didSetInitialDay else { return }
                didSetInitialDay = true
                selectedDay = todaysDay ?? next?.day ?? .a
            }
        }
    }

    // MARK: - Pieces

    private var todayCard: some View {
        HStack(spacing: 14) {
            Image(systemName: todaysDay == nil ? "moon.zzz.fill" : "flame.fill")
                .font(.title)
                .foregroundStyle(Theme.gradient)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                if let todaysDay {
                    Text("Today")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(todaysDay.title) is on the schedule")
                        .font(.headline)
                } else {
                    Text("Rest day")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if let next {
                        Text("Next up: \(next.day.title) on \(next.date.formatted(.dateTime.weekday(.wide)))")
                            .font(.headline)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    private func workoutHeader(_ workout: PlannedWorkout) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.day.focus)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.blue)
            Text("\(workout.exercises.count) exercises · about \(workout.estimatedMinutes) min")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
}

/// One exercise in the workout list.
struct ExerciseRow: View {
    let number: Int
    let planned: PlannedExercise

    var body: some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Theme.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(planned.exercise.name)
                    .font(.headline)
                Text(planned.prescription)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    tag(planned.exercise.pattern.title, systemImage: planned.exercise.pattern.systemImage)
                    ForEach(EquipmentKind.allCases.filter { planned.exercise.equipment.contains($0) }) { kind in
                        tag(kind.title, systemImage: kind.systemImage)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .cardStyle()
        .contentShape(Rectangle())
    }

    private func tag(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.background, in: Capsule())
            .foregroundStyle(.secondary)
    }
}
