# FitForge

A personal home-workout app for iPhone, built with SwiftUI. FitForge builds your workouts around your goal, equipment and ability, reads your weigh-ins straight from Apple Health, and is designed to feel like a polished App Store app, without the subscription.

> Personal project, not published on the App Store.

## Features

**Working now**

- **First-time setup:** goal type, starting stats, targets, equipment, ability, schedule and your "why"
- **Apple Health integration:** latest weight, body fat %, height and birthday read automatically (e.g. from a Renpho scale)
- **Goal timeline estimates** at a healthy, sustainable pace
- **Exercise library:** 42 exercises tagged by movement, difficulty, equipment, dumbbell weight range and joint cautions
- **Workout builder:** fills Day A/B/C from your profile, adapting to your equipment, level and joints without repeating exercises across the week
- **A → B → C rotation** mapped onto your chosen workout days
- **Guided workout mode:** start set → rest countdown → Ready, with skip set, skip exercise, pause, ±15s rest and a reps adjuster
- **Voice coach:** spoken prompts that duck your music, with a choice of any installed voice (Premium and Enhanced voices supported)
- **Haptics and alerts:** countdown taps for the last 3 seconds, plus a notification when rest ends if the phone is locked
- **Workout saving:** every set is saved as you go, and finished workouts are saved to Apple Health as strength workouts
- **Landscape layout** for the workout screen
- **Profile** summary of everything entered during setup

**Coming next**

- Workout history, missed workouts and make-ups
- Progress charts (Swift Charts)
- Lock screen Live Activity for rest timers
- Foundation → Build → Push phases
- Import from the original FitForge web app

**Later**

- Apple Watch companion (heart rate, timer and controls on the wrist)
- Apple TV / AirPlay big-screen workout view
- iCloud sync, iPad and Mac

## Tech

| Area | Choice |
|------|--------|
| UI | SwiftUI |
| Data | SwiftData (models follow CloudKit rules so iCloud sync can be turned on later) |
| Health | HealthKit |
| Minimum OS | iOS 27 |
| IDE | Xcode 27 |

## Project structure

```
FitForge/
├── FitForgeApp.swift            App entry point
├── Models/
│   ├── UserProfile.swift        Profile, goals, ability and schedule
│   ├── EquipmentItem.swift      Owned equipment (with weights)
│   ├── BodyMeasurement.swift    Weigh-ins
│   ├── ProfileOptions.swift     Goal, activity, equipment and other option enums
│   ├── Exercise.swift           Exercise type, movement patterns, difficulty
│   ├── ExerciseLibrary.swift    The built-in exercise library
│   └── WorkoutSession.swift     Saved workouts and their sets
├── Services/
│   ├── HealthKitManager.swift   Apple Health permissions, reads and workout saving
│   ├── GoalEstimator.swift      Timeline estimates for targets
│   ├── WorkoutBuilder.swift     Builds Day A/B/C and maps the schedule
│   ├── WorkoutEngine.swift      Runs guided workouts (sets, rest, timers, saving)
│   └── VoiceCoach.swift         Spoken prompts and voice selection
├── Theme/
│   └── Theme.swift              Colours and card styling
└── Views/
    ├── RootView.swift           Setup vs. main tabs
    ├── Onboarding/              First-time setup flow
    ├── Dashboard/               Home screen
    ├── Workout/                 Workout list, guided mode, timer ring and summary
    ├── Profile/                 Profile summary and voice picker
    └── Shared/                  Reusable components
```

## Running it

1. Open `FitForge.xcodeproj` in Xcode.
2. Under **Signing & Capabilities**, choose your team (a free Personal Team works).
3. Select your iPhone as the run destination and press **Run**.

With a free Apple developer account the app expires after 7 days; just run it from Xcode again. Your data stays on the phone as long as the app isn't deleted.
