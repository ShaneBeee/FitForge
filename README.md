# FitForge

A personal home-workout app for iPhone, built with SwiftUI. FitForge builds your workouts around your goal, equipment and ability, reads your weigh-ins straight from Apple Health, and is designed to feel like a polished App Store app, without the subscription.

> Personal project, not published on the App Store.

## Features

**Working now**

- **First-time setup:** goal type and focus areas, starting stats, targets, equipment, ability, schedule (days per week and workout length) and your "why"
- **Apple Health integration:** latest weight, body fat %, height and birthday read automatically (e.g. from a smart scale)
- **Goal timeline estimates** at a healthy, sustainable pace
- **Exercise library:** 64 exercises (compound lifts, arms, shoulders, calves, core and cardio finishers) tagged by movement, muscles, difficulty, equipment, dumbbell weight range and joint cautions
- **Plans for 2–6 days a week:** full body (2–3 days), upper/lower (4), upper/lower plus full body (5), or push/pull/legs (6)
- **Workout length (20/30/45/60 min):** sets how many exercises each workout gets; longer workouts add an extra set on the main lifts and, for fat-loss goals, a short cardio finisher
- **Workout builder:** fills each day from your profile, adapting to your equipment, level and joints; never repeats an exercise within a day and varies them across the week
- **Focus areas (up to 3):** chosen muscles (arms, chest, shoulders, back, abs, glutes, legs) move up in each workout, get added where they fit, and get an extra set from 30 minutes; a belly-fat focus keeps core work in every session and adds a cardio finisher. Each day's first two main lifts always stay, so the plan stays balanced
- **Weekly rotation** mapped onto your chosen workout days
- **Muscle targets:** each day shows which muscle groups it works, and each exercise lists the muscles it trains
- **Guided workout mode:** start set → rest countdown → Ready, with skip set, skip exercise, pause, ±15s rest and a reps adjuster
- **Voice coach:** spoken prompts that duck your music, with a choice of any installed voice (Premium and Enhanced voices supported)
- **Haptics and alerts:** countdown taps for the last 3 seconds, plus a notification when rest ends if the phone is locked
- **Live Activity:** the current exercise, rest countdown and workout progress on the lock screen and in the Dynamic Island
- **Workout saving:** every set is saved as you go, and finished workouts are saved to Apple Health as strength workouts
- **Calories:** estimated from your heart rate when your Apple Watch recorded it during the workout, otherwise from the exercises and sets you did; saved with the workout so it shows in the Fitness app (Health's source priority prevents double counting with the Watch)
- **Effort rating:** a 1–10 "How hard was that?" on the summary screen, saved to Apple Health as the workout's Effort
- **Landscape layout** for the workout screen
- **Progress charts:** weight and body fat history from Apple Health with goal lines, change since start, last-4-weeks change and goal progress; tap and drag to inspect any reading
- **Where you stand:** weight, body fat, visceral fat and BMI shown on colour-coded range bars (healthy weight for your height, ACE body fat categories, the standard smart scale visceral fat rating), each with your goal marked where there is one
- **Weigh-in extras:** quick entry for the smart scale numbers Apple Health doesn't store (visceral fat, muscle mass, skeletal muscle %, BMR, metabolic age), with a weigh-in day prompt on the dashboard, a visceral fat chart, and a body composition card showing change since your first entry
- **Body measurements:** belly, waist, chest, upper arms and more (choose which to track), with a body silhouette that shows exactly where to measure, a reminder every 4 weeks on weigh-in day, and charts with change since your first measurement
- **Body fat, two ways:** the smart scale reading next to a tape-measure estimate (US Navy method)
- **Workouts per week** chart against your weekly target
- **History:** past workouts grouped by week with set-by-set details, missed workouts, make-up and ended-early tags, swipe to delete, and a weigh-in log with changes between readings
- **Missed workouts and make-ups:** a workout not done on its day is marked missed and can be made up later that week; every week starts fresh at the beginning of the rotation
- **Dashboard:** today's workout (or a make-up) with a Start button, plus this week's plan at a glance
- **Interrupted workouts** are tidied up automatically: sets done are kept as "ended early"
- **Training phases (Foundation → Build → Push):** Build unlocks after 12 workouts and Push after 30, plus a 1.5% / 3.5% body fat drop (or consistently hitting the top of your rep ranges for a build-muscle goal). You choose when to start a new phase from the dashboard. Each phase moves every movement up a difficulty level; Push also adds a 4th set on the main lifts and trims rest for fat-loss goals. You can go back a phase from Profile
- **Profile:** everything from setup, with each section (about you, goal, starting point, equipment, ability, schedule) editable in place using the same screens as setup

**Coming next**

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
│   ├── WorkoutSession.swift     Saved workouts and their sets
│   └── TapeMeasurement.swift    Body measurements and measuring spots
├── Services/
│   ├── HealthKitManager.swift   Apple Health permissions, reads and workout saving
│   ├── GoalEstimator.swift      Timeline estimates for targets
│   ├── WorkoutBuilder.swift     Plans for 2–6 days, builds each day, maps the schedule
│   ├── WorkoutEngine.swift      Runs guided workouts (sets, rest, timers, saving)
│   ├── WeekSchedule.swift       Weekly plan: done, missed, today, make-ups
│   ├── PhaseProgress.swift      Progress toward unlocking the next training phase
│   ├── TapeBodyFat.swift        Tape-measure body fat estimate (US Navy method)
│   ├── CalorieEstimator.swift   Workout calories from heart rate, or from the work done
│   ├── WorkoutLiveActivity.swift Starts, updates and ends the lock screen Live Activity
│   └── VoiceCoach.swift         Spoken prompts and voice selection
├── Shared/
│   └── WorkoutActivityAttributes.swift  Live Activity data, shared with the widget extension
├── Theme/
│   └── Theme.swift              Colours and card styling
└── Views/
    ├── RootView.swift           Setup vs. main tabs
    ├── Onboarding/              First-time setup flow
    ├── Dashboard/               Home screen
    ├── Workout/                 Workout list, guided mode, timer ring and summary
    ├── Progress/                Charts, range cards, body composition and weigh-in extras entry
    ├── History/                 Past workouts, workout details and weigh-ins
    ├── Measurements/            Body silhouette, measurement entry and progress
    ├── Profile/                 Profile, section editors and voice picker
    └── Shared/                  Reusable components
```

## Running it

1. Open `FitForge.xcodeproj` in Xcode.
2. Under **Signing & Capabilities**, choose your team (a free Personal Team works).
3. Select your iPhone as the run destination and press **Run**.

With a free Apple developer account the app expires after 7 days; just run it from Xcode again. Your data stays on the phone as long as the app isn't deleted.
