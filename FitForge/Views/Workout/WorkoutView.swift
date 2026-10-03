import SwiftUI
import SwiftData

/// Shows today's workout (or the next one on a rest day), with every day in the rotation browsable.
struct WorkoutView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Environment(HealthKitManager.self) private var health
    @State private var selectedDayID: String?
    @State private var detail: PlannedExercise?
    @State private var didSetInitialDay = false
    @State private var activeWorkout: WorkoutEngine?
    @Query private var sessions: [WorkoutSession]

    private var week: [PlannedWorkout] { WorkoutBuilder.buildWeek(for: profile) }
    private var schedule: [ScheduledWorkout] { WeekSchedule.week(containing: .now, profile: profile, sessions: sessions) }
    private var todaySlot: ScheduledWorkout? { schedule.first { Calendar.current.isDateInToday($0.date) } }
    private var makeUp: ScheduledWorkout? { schedule.first { $0.status == .missed } }
    private var todaysDay: WorkoutDay? { WorkoutSchedule.workoutDay(on: .now, for: profile) }
    private var next: (date: Date, day: WorkoutDay)? { WorkoutSchedule.nextWorkout(after: .now, for: profile) }

    private var selectedWorkout: PlannedWorkout? {
        week.first { $0.day.id == selectedDayID } ?? week.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    todayCard

                    dayPicker

                    if let workout = selectedWorkout {
                        workoutHeader(workout)

                        Button {
                            activeWorkout = WorkoutEngine(plan: workout, context: context, health: health, profile: profile)
                        } label: {
                            Label("Start \(workout.day.title)", systemImage: "play.fill")
                                .font(.title3.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(Theme.blue)
                        .disabled(workout.exercises.isEmpty)

                        ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, planned in
                            Button {
                                detail = planned
                            } label: {
                                ExerciseRow(number: index + 1, planned: planned)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .animation(.snappy, value: selectedDayID)
            }
            .navigationTitle("Workout")
            .sheet(item: $detail) { planned in
                ExerciseDetailView(planned: planned)
            }
            .fullScreenCover(item: $activeWorkout) { engine in
                GuidedWorkoutView(engine: engine)
            }
            .onAppear {
                guard !didSetInitialDay else { return }
                didSetInitialDay = true
                if let todaySlot, todaySlot.status == .today {
                    selectedDayID = todaySlot.day.id
                } else if let makeUp {
                    selectedDayID = makeUp.day.id
                } else {
                    selectedDayID = (next?.day ?? todaysDay)?.id
                }
            }
        }
    }

    // MARK: - Pieces

    /// Chips for every workout in the rotation (2–6 of them).
    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(week) { workout in
                    let isSelected = workout.day.id == selectedWorkout?.day.id
                    Button {
                        selectedDayID = workout.day.id
                    } label: {
                        Text(workout.day.title)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .background(
                                isSelected ? AnyShapeStyle(Theme.blue) : AnyShapeStyle(.background.secondary),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: isSelected)
                }
            }
        }
    }

    private var todayCard: some View {
        HStack(spacing: 14) {
            Image(systemName: todayIcon)
                .font(.title)
                .foregroundStyle(Theme.gradient)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                if let todaySlot, todaySlot.status == .today {
                    Text("Today")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(todaySlot.day.title) is on the schedule")
                        .font(.headline)
                } else if let makeUp {
                    Text("Make-up available")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(makeUp.day.title) from \(makeUp.date.formatted(.dateTime.weekday(.wide)))")
                        .font(.headline)
                } else if let todaySlot, todaySlot.status == .done {
                    Text("Today")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(todaySlot.day.title) done — nice work")
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

    private var todayIcon: String {
        if let todaySlot, todaySlot.status == .today { return "flame.fill" }
        if makeUp != nil { return "arrow.uturn.backward.circle.fill" }
        if let todaySlot, todaySlot.status == .done { return "checkmark.seal.fill" }
        return "moon.zzz.fill"
    }

    private func workoutHeader(_ workout: PlannedWorkout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.focus)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.blue)
                Text("\(workout.exercises.count) exercises · about \(workout.estimatedMinutes) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            MuscleTargetsCard(muscles: workout.targetedMuscles, subtitle: workout.day.kind.description)
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
                HStack(spacing: 6) {
                    Text(planned.exercise.name)
                        .font(.headline)
                    if planned.isFocus {
                        Label("Focus", systemImage: "scope")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(Theme.green)
                            .background(Theme.green.opacity(0.15), in: Capsule())
                    }
                }
                Text(planned.prescription)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(planned.exercise.muscles.map(\.title).joined(separator: " · "))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.blue)
                if !planned.exercise.equipment.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(EquipmentKind.allCases.filter { planned.exercise.equipment.contains($0) }) { kind in
                            tag(kind.title, systemImage: kind.systemImage)
                        }
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
