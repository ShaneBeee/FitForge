# FitForge

A personal home-workout app for iPhone, built with SwiftUI. FitForge builds your workouts around your goal, equipment and ability, reads your weigh-ins straight from Apple Health, and is designed to feel like a polished App Store app, without the subscription.

> Personal project, not published on the App Store.

## Features

**Working now**

- **First-time setup:** goal type, starting stats, targets, equipment, ability, schedule (days per week and workout length) and your "why"
- **Apple Health integration:** latest weight, body fat %, height and birthday read automatically (e.g. from a Renpho scale)
- **Goal timeline estimates** at a healthy, sustainable pace
- **Exercise library:** 64 exercises (compound lifts, arms, shoulders, calves, core and cardio finishers) tagged by movement, muscles, difficulty, equipment, dumbbell weight range and joint cautions
- **Plans for 2–6 days a week:** full body (2–3 days), upper/lower (4), upper/lower plus full body (5), or push/pull/legs (6)
- **Workout length (20/30/45/60 min):** sets how many exercises each workout gets; longer workouts add an extra set on the main lifts and, for fat-loss goals, a short cardio finisher
- **Workout builder:** fills each day from your profile, adapting to your equipment, level and joints; never repeats an exercise within a day and varies them across the week
- **Weekly rotation** mapped onto your chosen workout days
- **Muscle targets:** each day shows which muscle groups it works, and each exercise lists the muscles it trains
- **Guided workout mode:** start set → rest countdown → Ready, with skip set, skip exercise, pause, ±15s rest and a reps adjuster
- **Voice coach:** spoken prompts that duck your music, with a choice of any installed voice (Premium and Enhanced voices supported)
- **Haptics and alerts:** countdown taps for the last 3 seconds, plus a notification when rest ends if the phone is locked
- **Workout saving:** every set is saved as you go, and finished workouts are saved to Apple Health as strength workouts
- **Landscape layout** for the workout screen
- **Progress charts:** weight and body fat history from Apple Health with goal lines, change since start, last-4-weeks change and goal progress; tap and drag to inspect any reading
- **Where you stand:** weight, body fat and BMI shown on colour-coded range bars (healthy weight for your height, ACE body fat categories), each with your goal marked
- **Workouts per week** chart against your weekly target
- **History:** past workouts grouped by week with set-by-set details, missed workouts, make-up and ended-early tags, swipe to delete, and a weigh-in log with changes between readings
- **Missed workouts and make-ups:** a workout not done on its day is marked missed and can be made up later that week; every week starts fresh at the beginning of the rotation
- **Dashboard:** today's workout (or a make-up) with a Start button, plus this week's plan at a glance
- **Interrupted workouts** are tidied up automatically: sets done are kept as "ended early"
- **Profile:** everything from setup, with each section (about you, goal, starting point, equipment, ability, schedule) editable in place using the same screens as setup

**Coming next**

- Weigh-in extras (visceral fat and other Renpho metrics) with a visceral fat chart
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
│   ├── Exercise.swift           Exercise type, movement patterns, muscle groups, difficulty
│   ├── ExerciseLibrary.swift    The built-in exercise library
│   └── WorkoutSession.swift     Saved workouts and their sets
├── Services/
│   ├── HealthKitManager.swift   Apple Health permissions, reads and workout saving
│   ├── GoalEstimator.swift      Timeline estimates for targets
│   ├── WorkoutBuilder.swift     Plans for 2–6 days, builds each day, maps the schedule
│   ├── WorkoutEngine.swift      Runs guided workouts (sets, rest, timers, saving)
│   ├── WeekSchedule.swift       Weekly plan: done, missed, today, make-ups
│   └── VoiceCoach.swift         Spoken prompts and voice selection
├── Theme/
│   └── Theme.swift              Colours and card styling
└── Views/
    ├── RootView.swift           Setup vs. main tabs
    ├── Onboarding/              First-time setup flow
    ├── Dashboard/               Home screen
    ├── Workout/                 Workout list, guided mode, timer ring and summary
    ├── Progress/                Weight, body fat, BMI and workout charts
    ├── History/                 Past workouts, workout details and weigh-ins
    ├── Profile/                 Profile, section editors and voice picker
    └── Shared/                  Reusable components
```

## Running it

1. Open `FitForge.xcodeproj` in Xcode.
2. Under **Signing & Capabilities**, choose your team (a free Personal Team works).
3. Select your iPhone as the run destination and press **Run**.

With a free Apple developer account the app expires after 7 days; just run it from Xcode again. Your data stays on the phone as long as the app isn't deleted.
