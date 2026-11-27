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
- **Live Activity:** the current exercise, rest countdown and workout progress on the lock screen and in the Dynamic Island; switches to "Rest's up" the moment rest ends, even while the app is asleep
- **Workout saving:** every set is saved as you go, and finished workouts are saved to Apple Health as strength workouts
- **Calories:** estimated from the exercises and sets you did, blended with a heart-rate estimate when your Apple Watch recorded enough heart rate during the workout (heart-rate formulas alone run high for strength training); saved with the workout so it shows in the Fitness app (Health's source priority prevents double counting with the Watch)
- **Effort rating:** a 1–10 "How hard was that?" on the summary screen, saved to Apple Health as the workout's Effort. When the Apple Watch recorded the workout, the phone waits up to about two minutes for it to sync to Health; if it still isn't there, the rating is sent the next time the app opens (History shows "Effort waiting to sync" until then)
- **Equipment list:** 15 types in four groups (weights, bodyweight helpers, bands, cardio): dumbbells, kettlebell, medicine/slam ball, chair, bench, step/box, pull-up bar, dip station, push-up handles, suspension trainer, ab wheel, stability ball, resistance band, mini bands and jump rope, each unlocking its own exercises. Any item can be switched out of workouts ("Use in workouts") while staying on your list
- **Bench types:** flat, adjustable, or adjustable with decline. Any bench adds dumbbell bench press, flyes and bench leg raises; adjustable adds incline press, incline flyes, chest-supported rows, seated dumbbell press and incline curls; decline adds decline press and decline crunches. What to get next suggests upgrading a flat bench, with the exercises it would add
- **Dip station:** standalone, wall-mounted or on a bench's uprights. Adds dip support holds, feet-assisted dips, negative dips, knee raises on the bars and full parallel bar dips (dips are skipped with a shoulder caution)
- **Multiple weights:** dumbbells and kettlebells can be fixed weights (tap every pair you own, 5–100 lb) or adjustable (enter the lightest and heaviest setting)
- **Suggested weights:** each weighted exercise shows which pair to use (heaviest for legs and hips, middle for presses and rows, lightest for small muscles), changeable mid-workout; the weight is saved with every set
- **Progression:** when every set of an exercise reached the top of its rep range, the next workout suggests the next weight up ("Try 20 lb")
- **Outgrown weights:** hitting the top of the range with your heaviest weight two workouts in a row marks the exercise as outgrown; it switches to slow 3-second lowering and 10–15 reps (shown on screen and spoken by the coach) until heavier weights are added
- **Body composition charts:** smart scale extras (muscle mass, fat-free mass, skeletal muscle, subcutaneous fat, body water, protein, bone mass, BMR, metabolic age, plus visceral fat) can be logged on weigh-in day and charted in the Progress tab's Body card; "See all scale readings" shows the latest of each with the change since your first entry
- **What to get next** (Profile → Equipment): which heavier weights you need and for which exercises, then the equipment that would add the most exercises for your level and focus areas, with rough Canadian prices
- **Focus area limit by workout length:** 3 focus areas for 20–30 minute workouts, 4 at 45, 5 at 60; if there are ever more than fit, they take turns across the week. The picker notes areas that are already a main lift in every workout (e.g. glutes and legs on the 3-day plan)
- **Apple Watch app:** starting a workout on the iPhone launches FitForge on the Watch, which runs a real workout session and streams live heart rate and calories to the phone's workout screen. The Watch saves the workout to Apple Health with Apple-measured calories and heart rate (no phone estimate or duplicate workout)
- **Apple Watch controls:** the current exercise, set and rest countdown on the wrist, with Start set / Done / Skip rest, skip set, skip exercise, pause and ±15s rest, all kept in sync with the iPhone; a wrist tap when rest is up
- **Landscape layout** for the workout screen: the timer ring on the left sized to fit the screen, with Up next, the reps adjuster and rest buttons on the right
- **Progress tab, in four parts:**
  - **Your goals:** weight and body fat side by side, each with the current value, change since start, a progress bar and how much is left; tap one to show it in the Body chart
  - **Body:** one chart with chips for weight, body fat, visceral fat and every smart scale extra (opens on weight). Each shows goal lines, change since start and over the last 4 weeks, and tap-and-drag to inspect any reading. Under the chart: where you stand on a colour-coded range bar (healthy weight for your height, ACE body fat categories, the standard visceral fat rating, and Renpho's standard ranges for muscle mass, skeletal muscle, subcutaneous fat, body water, protein, bone mass and metabolic age), a short explanation of what each number means, BMI under weight, and body fat two ways (smart scale vs. a US Navy tape-measure estimate) under body fat
  - **Measurements:** chips to pick a spot, its chart, and the latest of each with change since your first measurement (tap a row to chart it)
  - **Workouts per week** against your weekly target
  - **Progress report:** a PDF for the last 4 weeks, 3 months, 6 months, year or everything, made to share with an AI assistant (Claude, ChatGPT, Gemini…) or save to Files. A ready-made question sits at the top (how am I doing, is my progress realistic, am I pushing hard enough, what should I change), followed by real-number tables: goals and plan, weigh-ins and rate of change, smart scale readings, tape measurements, workouts done vs scheduled each week, every workout (time, sets, calories, heart rate, effort) and strength progress per exercise. Optional extras: a yearly summary of older Apple Health weigh-ins from before FitForge (kept separate from the "since I started" numbers), and a notes box for anything the numbers don't show (e.g. "started creatine"). Name is left off unless you choose to include it. It's a report, not a backup
- **Weigh-in extras:** quick entry for the smart scale numbers Apple Health doesn't store (visceral fat, muscle mass, skeletal muscle %, BMR, metabolic age), with a weigh-in day prompt on the dashboard
- **Body measurements:** belly, waist, chest, upper arms and more (choose which to track), with a body silhouette that shows exactly where to measure and a reminder every 4 weeks on weigh-in day
- **History:** past workouts grouped by week with set-by-set details, missed workouts, make-up and ended-early tags, swipe to delete, and a weigh-in log with changes between readings
- **Missed workouts and make-ups:** a workout not done on its day is marked missed and can be made up later that week; every week starts fresh at the beginning of the rotation
- **Dashboard:** today's workout (or a make-up) with a Start button, plus this week's plan at a glance
- **Interrupted workouts** are tidied up automatically: sets done are kept as "ended early"
- **Training phases (Foundation → Build → Push):** Build unlocks after 12 workouts and Push after 30, plus either a 1.5% / 3.5% body fat drop or hitting the top of your rep ranges on 70% of sets over your last 6 workouts (the rep ranges alone for a build-muscle goal), so slow fat loss doesn't hold back training you've outgrown. You choose when to start a new phase from the dashboard. Each phase moves every movement up a difficulty level; Push also adds a 4th set on the main lifts and trims rest for fat-loss goals. You can go back a phase from Profile
- **Longer holds:** planks and other timed holds go up 10 seconds after you complete every set two workouts in a row, up to a minute
- **Ready for something harder?** When a bodyweight exercise is at the top of its range every set two workouts in a row (or a hold reaches a full minute twice), the workout summary offers the next level, preferring exercises that use weights you own (e.g. Bodyweight Squat → Goblet Squat). Try it moves that movement up a level from the next workout; Not yet asks again in two weeks
- **Profile:** everything from setup, with each section (about you, goal, starting point, equipment, ability, schedule) editable in place using the same screens as setup
- **Backup and restore** (Profile → Backup): pick a folder once (ideally in iCloud Drive) and FitForge backs up everything (profile, equipment, workouts and sets, weigh-ins, scale extras, tape measurements, phase and level progress) every time you leave the app: one JSON file per day, keeping the last 30 days. Back up now and Save a copy somewhere else are there too. Restoring replaces everything in the app after saving a "Before Restore" copy of what was there, so a wrong restore can be undone. Setup's first screen has Restore from a backup, for a new phone or a reinstall

**Coming next**

- Polish from real-world use

**Later**

- Apple TV / AirPlay big-screen workout view
- iCloud sync, iPad and Mac (needs the paid Apple Developer Program, which would also allow installing the Watch app on a Watch Xcode can't connect to)

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
│   ├── BackupFile.swift         The backup file format (everything the app stores)
│   ├── BackupService.swift      Automatic backups to a chosen folder, and restoring
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
    ├── Progress/                Goals and Body cards, charts, range bars, scale readings and weigh-in extras entry
    ├── History/                 Past workouts, workout details and weigh-ins
    ├── Measurements/            Body silhouette, measurement entry and progress
    ├── Profile/                 Profile, section editors, voice picker and backup
    └── Shared/                  Reusable components
```

## Running it

1. Open `FitForge.xcodeproj` in Xcode.
2. Under **Signing & Capabilities**, choose your team (a free Personal Team works).
3. Select your iPhone as the run destination and press **Run**.

With a free Apple developer account the app expires after 7 days; just run it from Xcode again. Your data stays on the phone as long as the app isn't deleted, and with a backup folder chosen (Profile → Backup) it's also copied to iCloud Drive every time you leave the app.
