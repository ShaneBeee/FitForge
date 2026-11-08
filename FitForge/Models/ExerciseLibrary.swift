import Foundation

/// The built-in exercise library.
/// Order matters a little: when two exercises tie, the earlier one is picked first.
enum ExerciseLibrary {

    static func exercise(id: String) -> Exercise? {
        all.first { $0.id == id }
    }

    static let all: [Exercise] = squat + lunge + hinge + push + pull + core + carry
        + shoulders + biceps + triceps + calves + conditioning + equipmentExtras

    // MARK: - Squat

    static let squat: [Exercise] = [
        Exercise(
            id: "bodyweight-squat", name: "Bodyweight Squat",
            summary: "The foundation of lower-body strength.",
            cues: ["Feet shoulder-width, toes slightly out", "Sit back and down like into a chair", "Push the floor away to stand"],
            pattern: .squat, difficulty: .beginner
        ),
        Exercise(
            id: "chair-sit-to-stand", name: "Chair Sit-to-Stand",
            summary: "A squat with a chair as a safety net and depth guide.",
            cues: ["Sit down slowly — take 3 seconds", "Barely touch the seat", "Stand up without using your hands"],
            pattern: .squat, difficulty: .beginner, equipment: [.chair]
        ),
        Exercise(
            id: "goblet-squat", name: "Goblet Squat",
            summary: "Hold one dumbbell at your chest and squat. Great for posture and depth.",
            cues: ["Hold the dumbbell vertically against your chest", "Elbows point down between your knees", "Keep your chest tall the whole way"],
            pattern: .squat, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 10...70
        ),
        Exercise(
            id: "kettlebell-goblet-squat", name: "Kettlebell Goblet Squat",
            summary: "A goblet squat holding the kettlebell by the horns.",
            cues: ["Hold the bell close to your chest", "Sit between your heels", "Drive up through your whole foot"],
            pattern: .squat, difficulty: .intermediate, equipment: [.kettlebell], weightRange: 10...70
        ),
        Exercise(
            id: "pause-goblet-squat", name: "Pause Goblet Squat",
            summary: "A goblet squat with a 2-second pause at the bottom. Much harder than it sounds.",
            cues: ["Lower under control", "Hold 2 seconds at the bottom — stay tight", "Stand up fast"],
            pattern: .squat, difficulty: .advanced, equipment: [.dumbbells], weightRange: 10...60
        ),
        Exercise(
            id: "squat-jump", name: "Squat Jump",
            summary: "An explosive squat that gets your heart rate up.",
            cues: ["Squat to about half depth", "Jump straight up", "Land softly and go right into the next rep"],
            pattern: .squat, difficulty: .advanced, cautions: [.knees]
        ),
    ]

    // MARK: - Lunge

    static let lunge: [Exercise] = [
        Exercise(
            id: "reverse-lunge", name: "Reverse Lunge",
            summary: "Step back into a lunge. Easier on the knees than stepping forward.",
            cues: ["Step one foot back", "Lower until both knees are about 90°", "Push through the front heel to return"],
            pattern: .lunge, difficulty: .beginner, isUnilateral: true
        ),
        Exercise(
            id: "chair-step-up", name: "Chair Step-Up",
            summary: "Step up onto a sturdy chair, one leg at a time.",
            cues: ["Whole foot on the chair", "Drive through the top leg — don't push off the bottom one", "Step down slowly"],
            pattern: .lunge, difficulty: .beginner, equipment: [.chair], isUnilateral: true
        ),
        Exercise(
            id: "split-squat", name: "Split Squat",
            summary: "A lunge with your feet staying in place.",
            cues: ["Staggered stance, feet hip-width apart", "Drop the back knee straight down", "Keep your torso upright"],
            pattern: .lunge, difficulty: .intermediate, isUnilateral: true
        ),
        Exercise(
            id: "db-reverse-lunge", name: "Dumbbell Reverse Lunge",
            summary: "A reverse lunge holding a dumbbell in each hand.",
            cues: ["Dumbbells at your sides", "Step back and lower with control", "Drive up through the front heel"],
            pattern: .lunge, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 8...40, isUnilateral: true
        ),
        Exercise(
            id: "db-step-up", name: "Dumbbell Step-Up",
            summary: "A chair step-up holding dumbbells.",
            cues: ["Dumbbells at your sides", "Drive through the top leg only", "Control the step down"],
            pattern: .lunge, difficulty: .intermediate, equipment: [.dumbbells, .chair], weightRange: 8...40, isUnilateral: true
        ),
        Exercise(
            id: "bulgarian-split-squat", name: "Bulgarian Split Squat",
            summary: "Back foot up on a chair. One of the best leg exercises there is.",
            cues: ["Top of your back foot on the chair seat", "Front foot far enough forward to sit straight down", "Most of your weight on the front leg"],
            pattern: .lunge, difficulty: .advanced, equipment: [.chair], cautions: [.knees], isUnilateral: true
        ),
        Exercise(
            id: "db-bulgarian-split-squat", name: "Dumbbell Bulgarian Split Squat",
            summary: "A Bulgarian split squat holding dumbbells.",
            cues: ["Dumbbells at your sides", "Lower straight down", "Drive through the front heel"],
            pattern: .lunge, difficulty: .advanced, equipment: [.dumbbells, .chair], weightRange: 8...40, cautions: [.knees], isUnilateral: true
        ),
    ]

    // MARK: - Hinge

    static let hinge: [Exercise] = [
        Exercise(
            id: "glute-bridge", name: "Glute Bridge",
            summary: "Lying on your back, lift your hips. Wakes up the glutes and protects your lower back.",
            cues: ["Feet flat, close to your hips", "Squeeze your glutes to lift", "Pause at the top for a second"],
            pattern: .hinge, difficulty: .beginner, muscleOverride: [.glutes, .hamstrings]
        ),
        Exercise(
            id: "db-glute-bridge", name: "Dumbbell Glute Bridge",
            summary: "A glute bridge with a dumbbell resting on your hips.",
            cues: ["Hold the dumbbell across your hip bones", "Drive through your heels", "Don't arch your lower back at the top"],
            pattern: .hinge, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 10...80, muscleOverride: [.glutes, .hamstrings]
        ),
        Exercise(
            id: "db-romanian-deadlift", name: "Dumbbell Romanian Deadlift",
            summary: "Hinge at the hips with dumbbells. Builds hamstrings, glutes and back strength.",
            cues: ["Soft knees, push your hips back", "Dumbbells slide down your thighs", "Stop when you feel a hamstring stretch, then stand tall"],
            pattern: .hinge, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 10...80, cautions: [.lowerBack]
        ),
        Exercise(
            id: "elevated-glute-bridge", name: "Elevated Glute Bridge",
            summary: "A glute bridge with your feet up on a chair.",
            cues: ["Heels on the edge of the chair seat", "Lift your hips until your body is a straight line", "Lower slowly"],
            pattern: .hinge, difficulty: .intermediate, equipment: [.chair], muscleOverride: [.glutes, .hamstrings]
        ),
        Exercise(
            id: "kettlebell-swing", name: "Kettlebell Swing",
            summary: "An explosive hip hinge that builds power and conditioning.",
            cues: ["Hike the bell back between your legs", "Snap your hips forward", "Let the bell float to chest height"],
            pattern: .hinge, difficulty: .intermediate, equipment: [.kettlebell], weightRange: 15...70, cautions: [.lowerBack]
        ),
        Exercise(
            id: "single-leg-glute-bridge", name: "Single-Leg Glute Bridge",
            summary: "A glute bridge on one leg. Twice the work for each side.",
            cues: ["One foot planted, other leg straight up", "Drive through the planted heel", "Keep your hips level"],
            pattern: .hinge, difficulty: .advanced, isUnilateral: true, muscleOverride: [.glutes, .hamstrings]
        ),
        Exercise(
            id: "single-leg-rdl", name: "Single-Leg Dumbbell RDL",
            summary: "A Romanian deadlift on one leg. Strength and balance in one.",
            cues: ["Dumbbell in the hand opposite your standing leg", "Hinge forward as your back leg lifts", "Keep your hips square to the floor"],
            pattern: .hinge, difficulty: .advanced, equipment: [.dumbbells], weightRange: 8...50, cautions: [.lowerBack], isUnilateral: true
        ),
    ]

    // MARK: - Push

    static let push: [Exercise] = [
        Exercise(
            id: "incline-push-up", name: "Incline Push-Up",
            summary: "A push-up with your hands on a chair. The best way to build up to full push-ups.",
            cues: ["Hands on the edge of the chair seat", "Body in one straight line", "Lower your chest to the chair"],
            pattern: .push, difficulty: .beginner, equipment: [.chair], cautions: [.wrists]
        ),
        Exercise(
            id: "knee-push-up", name: "Knee Push-Up",
            summary: "A push-up from your knees.",
            cues: ["Straight line from knees to head", "Elbows at about 45°", "Chest all the way down"],
            pattern: .push, difficulty: .beginner, cautions: [.wrists]
        ),
        Exercise(
            id: "push-up", name: "Push-Up",
            summary: "The classic. Chest, shoulders, triceps and core all at once.",
            cues: ["Hands just wider than your shoulders", "Squeeze your glutes to keep your body straight", "Chest to the floor, then press away"],
            pattern: .push, difficulty: .intermediate, cautions: [.wrists]
        ),
        Exercise(
            id: "db-floor-press", name: "Dumbbell Floor Press",
            summary: "A bench press lying on the floor. Easy on the shoulders.",
            cues: ["Lie on your back, knees bent", "Lower until your upper arms touch the floor", "Press the dumbbells straight up"],
            pattern: .push, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 10...70
        ),
        Exercise(
            id: "db-bench-press", name: "Dumbbell Bench Press",
            summary: "The dumbbell press on a bench, for a bigger range of motion.",
            cues: ["Feet planted, shoulder blades pinched", "Lower to chest level", "Press up and slightly in"],
            pattern: .push, difficulty: .intermediate, equipment: [.dumbbells, .bench], weightRange: 10...80
        ),
        Exercise(
            id: "db-overhead-press", name: "Dumbbell Overhead Press",
            summary: "Press dumbbells overhead. Builds strong shoulders.",
            cues: ["Dumbbells at shoulder height, palms forward", "Brace your core — don't lean back", "Press straight up"],
            pattern: .push, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 8...40, cautions: [.shoulders], muscleOverride: [.shoulders, .triceps]
        ),
        Exercise(
            id: "decline-push-up", name: "Decline Push-Up",
            summary: "A push-up with your feet on a chair. Harder, with more shoulder work.",
            cues: ["Feet on the chair seat", "Body in one straight line", "Lower with control"],
            pattern: .push, difficulty: .advanced, equipment: [.chair], cautions: [.wrists, .shoulders]
        ),
        Exercise(
            id: "chair-dip", name: "Chair Dip",
            summary: "Dips off the edge of a chair. Targets the triceps.",
            cues: ["Hands on the chair edge, fingers forward", "Lower until elbows are about 90°", "Keep your back close to the chair"],
            pattern: .push, difficulty: .advanced, equipment: [.chair], cautions: [.shoulders], muscleOverride: [.triceps, .chest, .shoulders]
        ),
        Exercise(
            id: "pike-push-up", name: "Pike Push-Up",
            summary: "A push-up with your hips high. A bodyweight shoulder press.",
            cues: ["Hips up, body in an upside-down V", "Lower the top of your head toward the floor", "Press back up"],
            pattern: .push, difficulty: .advanced, cautions: [.wrists, .shoulders], muscleOverride: [.shoulders, .triceps]
        ),
    ]

    // MARK: - Pull

    static let pull: [Exercise] = [
        Exercise(
            id: "band-row", name: "Band Row",
            summary: "A seated or standing row with a resistance band.",
            cues: ["Sit tall with the band around your feet", "Pull your elbows back past your ribs", "Squeeze your shoulder blades together"],
            pattern: .pull, difficulty: .beginner, equipment: [.band]
        ),
        Exercise(
            id: "supported-one-arm-row", name: "Supported One-Arm Row",
            summary: "A dumbbell row with one hand braced on a chair. Protects your lower back.",
            cues: ["One hand and knee on the chair", "Pull the dumbbell to your hip", "Lower all the way down for a stretch"],
            pattern: .pull, difficulty: .beginner, equipment: [.dumbbells, .chair], weightRange: 10...70, isUnilateral: true
        ),
        Exercise(
            id: "prone-y-raise", name: "Prone Y Raise",
            summary: "Lying face down, lift your arms in a Y. Works the upper back with no equipment.",
            cues: ["Arms overhead in a Y, thumbs up", "Lift your arms by squeezing your shoulder blades", "Hold for a second at the top"],
            pattern: .pull, difficulty: .beginner
        ),
        Exercise(
            id: "bent-over-row", name: "Bent-Over Dumbbell Row",
            summary: "Row both dumbbells at once while hinged forward.",
            cues: ["Hinge forward to about 45°, back flat", "Pull the dumbbells to your ribs", "Lower with control"],
            pattern: .pull, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 10...70, cautions: [.lowerBack]
        ),
        Exercise(
            id: "db-reverse-fly", name: "Dumbbell Reverse Fly",
            summary: "Raise light dumbbells out to the sides while bent forward. Great for posture.",
            cues: ["Hinge forward, slight bend in your elbows", "Raise your arms out wide", "Squeeze your shoulder blades at the top"],
            pattern: .pull, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 3...15, muscleOverride: [.upperBack, .shoulders]
        ),
        Exercise(
            id: "pull-up-negative", name: "Pull-Up Negative",
            summary: "Jump to the top of a pull-up and lower yourself slowly. Builds up to full pull-ups.",
            cues: ["Start with your chin over the bar", "Lower yourself over 3–5 seconds", "Reset and repeat"],
            pattern: .pull, difficulty: .intermediate, equipment: [.pullUpBar]
        ),
        Exercise(
            id: "paused-one-arm-row", name: "Paused One-Arm Row",
            summary: "A supported row with a 2-second hold at the top.",
            cues: ["Brace on the chair", "Pull to your hip and hold 2 seconds", "Lower slowly"],
            pattern: .pull, difficulty: .advanced, equipment: [.dumbbells, .chair], weightRange: 10...70, isUnilateral: true
        ),
        Exercise(
            id: "renegade-row", name: "Renegade Row",
            summary: "A row from a push-up position. Back and core together.",
            cues: ["Plank on the dumbbells, feet wide", "Row one dumbbell without twisting your hips", "Alternate sides"],
            pattern: .pull, difficulty: .advanced, equipment: [.dumbbells], weightRange: 8...35, cautions: [.wrists], muscleOverride: [.upperBack, .biceps, .abs]
        ),
        Exercise(
            id: "pull-up", name: "Pull-Up",
            summary: "The king of upper-body pulling.",
            cues: ["Hands just outside shoulder-width", "Pull your chest toward the bar", "Lower all the way down"],
            pattern: .pull, difficulty: .advanced, equipment: [.pullUpBar], cautions: [.shoulders]
        ),
    ]

    // MARK: - Core

    static let core: [Exercise] = [
        Exercise(
            id: "dead-bug", name: "Dead Bug",
            summary: "Lying on your back, extend opposite arm and leg. Builds core control.",
            cues: ["Press your lower back into the floor", "Extend opposite arm and leg slowly", "Breathe out as you extend"],
            pattern: .core, difficulty: .beginner
        ),
        Exercise(
            id: "plank", name: "Plank",
            summary: "Hold a straight body on your forearms.",
            cues: ["Elbows under your shoulders", "Squeeze your glutes and brace your abs", "Don't let your hips sag"],
            pattern: .core, difficulty: .beginner, measure: .time
        ),
        Exercise(
            id: "bird-dog", name: "Bird Dog",
            summary: "On hands and knees, extend opposite arm and leg. Great for the lower back.",
            cues: ["Hands under shoulders, knees under hips", "Reach long, don't lift high", "Keep your hips level"],
            pattern: .core, difficulty: .beginner, isUnilateral: true
        ),
        Exercise(
            id: "side-plank", name: "Side Plank",
            summary: "A plank on your side. Targets the obliques.",
            cues: ["Elbow under your shoulder", "Lift your hips into a straight line", "Stack your feet or stagger them"],
            pattern: .core, difficulty: .intermediate, measure: .time, cautions: [.shoulders], isUnilateral: true
        ),
        Exercise(
            id: "plank-shoulder-tap", name: "Plank Shoulder Tap",
            summary: "From a high plank, tap each shoulder without rocking.",
            cues: ["High plank, feet wide", "Tap the opposite shoulder", "Keep your hips completely still"],
            pattern: .core, difficulty: .intermediate, cautions: [.wrists], muscleOverride: [.abs, .shoulders]
        ),
        Exercise(
            id: "hollow-hold", name: "Hollow Hold",
            summary: "A gymnast's core hold on your back.",
            cues: ["Lower back pressed into the floor", "Arms and legs extended, slightly off the ground", "Bend your knees to make it easier"],
            pattern: .core, difficulty: .intermediate, measure: .time, cautions: [.lowerBack]
        ),
        Exercise(
            id: "decline-plank", name: "Decline Plank",
            summary: "A plank with your feet up on a chair.",
            cues: ["Forearms on the floor, feet on the chair", "Body in one straight line", "Brace hard"],
            pattern: .core, difficulty: .advanced, measure: .time, equipment: [.chair]
        ),
        Exercise(
            id: "reverse-crunch", name: "Reverse Crunch",
            summary: "Lying on your back, curl your knees toward your chest. Targets the lower abs.",
            cues: ["Knees bent at 90°, arms by your sides", "Curl your hips off the floor, bringing knees to chest", "Lower slowly — no swinging"],
            pattern: .core, difficulty: .beginner
        ),
        Exercise(
            id: "bicycle-crunch", name: "Bicycle Crunch",
            summary: "Alternate elbow to opposite knee. Works the abs and obliques.",
            cues: ["Hands lightly behind your head", "Rotate your shoulder toward the opposite knee", "Slow and controlled beats fast"],
            pattern: .core, difficulty: .intermediate, isUnilateral: true
        ),
        Exercise(
            id: "db-russian-twist", name: "Dumbbell Russian Twist",
            summary: "Seated and leaning back, rotate a dumbbell side to side.",
            cues: ["Lean back to about 45°, chest up", "Rotate from your ribs, not just your arms", "Feet down to make it easier"],
            pattern: .core, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 5...30, cautions: [.lowerBack]
        ),
    ]

    // MARK: - Carry

    static let carry: [Exercise] = [
        Exercise(
            id: "farmers-carry", name: "Farmer's Carry",
            summary: "Walk while holding heavy dumbbells. Grip, core and posture all at once.",
            cues: ["Dumbbells at your sides, shoulders back", "Walk tall with short, steady steps", "Don't let the weights swing"],
            pattern: .carry, difficulty: .beginner, measure: .time, equipment: [.dumbbells], weightRange: 15...100
        ),
        Exercise(
            id: "suitcase-carry", name: "Suitcase Carry",
            summary: "A carry with one dumbbell. Your core works hard to keep you upright.",
            cues: ["One dumbbell, one side", "Stay perfectly upright — don't lean", "Switch hands halfway"],
            pattern: .carry, difficulty: .intermediate, measure: .time, equipment: [.dumbbells], weightRange: 15...80
        ),
    ]

    // MARK: - Shoulders

    static let shoulders: [Exercise] = [
        Exercise(
            id: "lateral-raise", name: "Lateral Raise",
            summary: "Raise light dumbbells out to your sides. Builds the side of the shoulders.",
            cues: ["Slight bend in your elbows", "Lead with your elbows, up to shoulder height", "Lower slowly"],
            pattern: .shoulders, difficulty: .beginner, equipment: [.dumbbells], weightRange: 3...20
        ),
        Exercise(
            id: "front-raise", name: "Front Raise",
            summary: "Raise a dumbbell straight out in front to shoulder height.",
            cues: ["Hold one dumbbell with both hands", "Arms nearly straight, lift to eye level", "Don't lean back"],
            pattern: .shoulders, difficulty: .beginner, equipment: [.dumbbells], weightRange: 5...30
        ),
        Exercise(
            id: "arnold-press", name: "Arnold Press",
            summary: "An overhead press that rotates from palms-in to palms-forward.",
            cues: ["Start with dumbbells at your chin, palms facing you", "Rotate your palms out as you press up", "Reverse the rotation on the way down"],
            pattern: .shoulders, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 8...35, cautions: [.shoulders], muscleOverride: [.shoulders, .triceps]
        ),
        Exercise(
            id: "upright-row", name: "Dumbbell Upright Row",
            summary: "Pull dumbbells up along your body to chest height.",
            cues: ["Dumbbells in front of your thighs", "Lead with your elbows, stop at chest height", "Keep the dumbbells close to your body"],
            pattern: .shoulders, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 10...40, cautions: [.shoulders], muscleOverride: [.shoulders, .upperBack]
        ),
        Exercise(
            id: "plank-to-down-dog", name: "Plank to Down Dog",
            summary: "Move from a high plank into an upside-down V and back. Shoulders and core, no equipment.",
            cues: ["Start in a high plank", "Push your hips up and back into a V", "Flow back to plank with control"],
            pattern: .shoulders, difficulty: .beginner, cautions: [.wrists], muscleOverride: [.shoulders, .abs]
        ),
    ]

    // MARK: - Biceps

    static let biceps: [Exercise] = [
        Exercise(
            id: "hammer-curl", name: "Hammer Curl",
            summary: "A curl with palms facing each other. Works biceps and forearms.",
            cues: ["Palms face your body", "Keep your elbows pinned to your sides", "Lower all the way down"],
            pattern: .biceps, difficulty: .beginner, equipment: [.dumbbells], weightRange: 8...45, muscleOverride: [.biceps, .grip]
        ),
        Exercise(
            id: "db-curl", name: "Dumbbell Curl",
            summary: "The classic biceps curl.",
            cues: ["Palms forward, elbows at your sides", "Curl up without swinging", "Squeeze at the top, lower slowly"],
            pattern: .biceps, difficulty: .beginner, equipment: [.dumbbells], weightRange: 8...40
        ),
        Exercise(
            id: "band-curl", name: "Band Curl",
            summary: "A biceps curl with a resistance band under your feet.",
            cues: ["Stand on the band, handles at your sides", "Curl up, elbows still", "Control the band on the way down"],
            pattern: .biceps, difficulty: .beginner, equipment: [.band]
        ),
        Exercise(
            id: "concentration-curl", name: "Concentration Curl",
            summary: "A seated one-arm curl with your elbow braced on your thigh.",
            cues: ["Sit on the chair, elbow against your inner thigh", "Curl up slowly", "Pause at the top"],
            pattern: .biceps, difficulty: .intermediate, equipment: [.dumbbells, .chair], weightRange: 8...40, isUnilateral: true
        ),
    ]

    // MARK: - Triceps

    static let triceps: [Exercise] = [
        Exercise(
            id: "bench-dip-bent", name: "Bent-Knee Chair Dip",
            summary: "An easier chair dip with your knees bent.",
            cues: ["Hands on the chair edge, knees bent at 90°", "Lower until elbows are about 90°", "Press back up through your palms"],
            pattern: .triceps, difficulty: .beginner, equipment: [.chair], cautions: [.shoulders]
        ),
        Exercise(
            id: "overhead-triceps-extension", name: "Overhead Triceps Extension",
            summary: "Hold one dumbbell overhead with both hands and lower it behind your head.",
            cues: ["Hold the dumbbell by one end, arms overhead", "Elbows point forward, lower behind your head", "Press back up"],
            pattern: .triceps, difficulty: .beginner, equipment: [.dumbbells], weightRange: 10...50, cautions: [.shoulders]
        ),
        Exercise(
            id: "close-grip-push-up", name: "Close-Grip Push-Up",
            summary: "A push-up with your hands under your shoulders. Shifts the work to your triceps.",
            cues: ["Hands directly under your shoulders", "Elbows brush your sides", "Chest to the floor"],
            pattern: .triceps, difficulty: .intermediate, cautions: [.wrists], muscleOverride: [.triceps, .chest]
        ),
        Exercise(
            id: "db-floor-skull-crusher", name: "Dumbbell Skull Crusher",
            summary: "Lying on the floor, lower dumbbells toward your forehead by bending only your elbows.",
            cues: ["Arms straight up, palms facing each other", "Bend only at the elbows", "Press back up"],
            pattern: .triceps, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 8...35
        ),
    ]

    // MARK: - Calves

    static let calves: [Exercise] = [
        Exercise(
            id: "calf-raise", name: "Standing Calf Raise",
            summary: "Rise up onto your toes. Hold a chair for balance if you need to.",
            cues: ["Feet hip-width apart", "Rise as high as you can", "Lower slowly all the way down"],
            pattern: .calves, difficulty: .beginner
        ),
        Exercise(
            id: "db-calf-raise", name: "Dumbbell Calf Raise",
            summary: "A calf raise holding dumbbells.",
            cues: ["Dumbbells at your sides", "Pause for a second at the top", "Full stretch at the bottom"],
            pattern: .calves, difficulty: .intermediate, equipment: [.dumbbells], weightRange: 10...100
        ),
        Exercise(
            id: "single-leg-calf-raise", name: "Single-Leg Calf Raise",
            summary: "A calf raise on one foot, holding the chair for balance.",
            cues: ["Hold the chair lightly", "All your weight on one foot", "Slow up, slower down"],
            pattern: .calves, difficulty: .advanced, equipment: [.chair], isUnilateral: true
        ),
    ]

    // MARK: - Conditioning (finishers)

    static let conditioning: [Exercise] = [
        Exercise(
            id: "jumping-jacks", name: "Jumping Jacks",
            summary: "A classic to get your heart rate up.",
            cues: ["Stay light on your feet", "Arms all the way overhead", "Step instead of jump to make it easier"],
            pattern: .conditioning, difficulty: .beginner, measure: .time, muscleOverride: [.calves, .shoulders]
        ),
        Exercise(
            id: "mountain-climbers", name: "Mountain Climbers",
            summary: "Drive your knees toward your chest from a high plank.",
            cues: ["Hands under shoulders, hips level", "Drive one knee in, then switch fast", "Keep your core tight"],
            pattern: .conditioning, difficulty: .intermediate, measure: .time, cautions: [.wrists], muscleOverride: [.abs, .shoulders]
        ),
        Exercise(
            id: "burpees", name: "Burpees",
            summary: "Squat, plank, back up and jump. The all-in-one conditioner.",
            cues: ["Squat and place your hands down", "Jump or step your feet back to a plank", "Return and jump up"],
            pattern: .conditioning, difficulty: .advanced, measure: .time, cautions: [.knees, .wrists], muscleOverride: [.quads, .chest, .abs]
        ),
    ]

    // MARK: - Extra equipment

    /// Exercises for the pull-up bar and the extra equipment types. Listed last, so when
    /// they tie with a core exercise the familiar one is picked first.
    static let equipmentExtras: [Exercise] = [
        // Pull-up bar
        Exercise(
            id: "dead-hang", name: "Dead Hang",
            summary: "Simply hang from the bar. Builds grip and shoulder strength, and the first step toward pull-ups.",
            cues: ["Overhand grip, hands shoulder-width", "Let your body hang long and relaxed", "Breathe slowly and hold on"],
            pattern: .pull, difficulty: .beginner, measure: .time, equipment: [.pullUpBar],
            muscleOverride: [.grip, .upperBack, .shoulders]
        ),
        Exercise(
            id: "scapular-pull-up", name: "Scapular Pull-Up",
            summary: "From a hang, pull your shoulder blades down without bending your arms. Teaches the start of every pull-up.",
            cues: ["Start from a dead hang", "Pull your shoulders down away from your ears", "Arms stay straight — it's a small movement"],
            pattern: .pull, difficulty: .beginner, equipment: [.pullUpBar], muscleOverride: [.upperBack, .grip]
        ),
        Exercise(
            id: "band-assisted-pull-up", name: "Band-Assisted Pull-Up",
            summary: "A full pull-up with a band under your foot or knee taking some of your weight.",
            cues: ["Loop the band over the bar, foot or knee in the bottom", "Pull your chest toward the bar", "Lower slowly to a full hang"],
            pattern: .pull, difficulty: .intermediate, equipment: [.pullUpBar, .band]
        ),
        Exercise(
            id: "chin-up", name: "Chin-Up",
            summary: "A pull-up with palms facing you. A little easier than a pull-up, with more biceps.",
            cues: ["Palms facing you, shoulder-width", "Pull until your chin clears the bar", "Lower all the way down with control"],
            pattern: .pull, difficulty: .advanced, equipment: [.pullUpBar], muscleOverride: [.upperBack, .biceps, .grip]
        ),
        Exercise(
            id: "hanging-knee-raise", name: "Hanging Knee Raise",
            summary: "Hang from the bar and lift your knees toward your chest. A great lower-abs exercise.",
            cues: ["Hang with shoulders active, not shrugged", "Curl your knees up toward your chest", "Lower slowly — no swinging"],
            pattern: .core, difficulty: .intermediate, equipment: [.pullUpBar], muscleOverride: [.abs, .grip]
        ),
        Exercise(
            id: "hanging-leg-raise", name: "Hanging Leg Raise",
            summary: "Like the knee raise, but with straight legs. One of the toughest ab exercises.",
            cues: ["Hang still before each rep", "Lift straight legs to hip height or higher", "Lower under control"],
            pattern: .core, difficulty: .advanced, equipment: [.pullUpBar], muscleOverride: [.abs, .grip]
        ),

        // Step or box
        Exercise(
            id: "box-step-up", name: "Step-Up",
            summary: "Step up onto a step or box, one leg at a time. Simple and great for the legs and glutes.",
            cues: ["Whole foot on the step", "Push through the top leg, not the bottom one", "Step down slowly"],
            pattern: .lunge, difficulty: .beginner, equipment: [.step], isUnilateral: true
        ),
        Exercise(
            id: "decline-push-up", name: "Decline Push-Up",
            summary: "A push-up with your feet up on a step. Shifts the work toward your upper chest and shoulders.",
            cues: ["Feet on the step, hands on the floor", "Body in one straight line", "Lower your chest between your hands"],
            pattern: .push, difficulty: .advanced, equipment: [.step], cautions: [.wrists]
        ),
        Exercise(
            id: "deficit-calf-raise", name: "Step Calf Raise",
            summary: "Calf raises with your heels hanging off a step, for a bigger stretch and more range.",
            cues: ["Balls of your feet on the edge", "Let your heels sink below the step", "Rise up high and pause"],
            pattern: .calves, difficulty: .intermediate, equipment: [.step]
        ),

        // Push-up handles
        Exercise(
            id: "handle-push-up", name: "Push-Up on Handles",
            summary: "Push-ups gripping handles. Your wrists stay straight, and you can go a little deeper.",
            cues: ["Grip the handles under your shoulders", "Lower until your chest is between your hands", "Press back up, body in one line"],
            pattern: .push, difficulty: .intermediate, equipment: [.pushUpHandles]
        ),
        Exercise(
            id: "tuck-l-sit", name: "Tuck L-Sit Hold",
            summary: "Press up on the handles and hold your knees tucked off the floor. Tough on the core and triceps.",
            cues: ["Hands on the handles beside your hips", "Press down and lift your hips", "Tuck your knees and hold"],
            pattern: .core, difficulty: .advanced, measure: .time, equipment: [.pushUpHandles],
            muscleOverride: [.abs, .triceps, .shoulders]
        ),

        // Suspension trainer
        Exercise(
            id: "suspension-row", name: "Suspension Row",
            summary: "Lean back holding the straps and pull yourself up. Walk your feet forward to make it harder.",
            cues: ["Body straight like a plank", "Pull your chest to your hands", "Squeeze your shoulder blades together"],
            pattern: .pull, difficulty: .beginner, equipment: [.suspensionTrainer]
        ),
        Exercise(
            id: "suspension-squat", name: "Suspension Squat",
            summary: "Hold the straps for balance while you squat deeper than you could on your own.",
            cues: ["Hold the straps with light arms", "Sit back and down", "Use the straps only as much as you need"],
            pattern: .squat, difficulty: .beginner, equipment: [.suspensionTrainer]
        ),
        Exercise(
            id: "suspension-curl", name: "Suspension Biceps Curl",
            summary: "Lean back with palms up and curl yourself toward your hands.",
            cues: ["Palms up, elbows pointing forward", "Curl your hands toward your forehead", "Lower slowly"],
            pattern: .biceps, difficulty: .intermediate, equipment: [.suspensionTrainer]
        ),
        Exercise(
            id: "suspension-push-up", name: "Suspension Push-Up",
            summary: "Push-ups with your hands in the straps. The wobble makes your chest and core work much harder.",
            cues: ["Hands in the straps under your shoulders", "Keep the straps from flaring out", "Body in one straight line"],
            pattern: .push, difficulty: .advanced, equipment: [.suspensionTrainer], cautions: [.shoulders]
        ),

        // Ab wheel
        Exercise(
            id: "kneeling-ab-rollout", name: "Kneeling Ab Wheel Rollout",
            summary: "Roll the wheel out from your knees and pull it back. One of the best core exercises there is.",
            cues: ["Start on your knees, wheel under your shoulders", "Roll out only as far as you can keep your back flat", "Pull back with your abs"],
            pattern: .core, difficulty: .intermediate, equipment: [.abWheel], cautions: [.lowerBack]
        ),

        // Stability ball
        Exercise(
            id: "ball-crunch", name: "Stability Ball Crunch",
            summary: "Crunches on the ball, for a bigger range than on the floor.",
            cues: ["Ball under your lower back, feet wide", "Curl up, ribs toward hips", "Lower back over the ball"],
            pattern: .core, difficulty: .beginner, equipment: [.stabilityBall]
        ),
        Exercise(
            id: "ball-hamstring-curl", name: "Stability Ball Hamstring Curl",
            summary: "Lying on your back with heels on the ball, lift your hips and roll the ball in.",
            cues: ["Heels on the ball, hips up", "Curl the ball toward you", "Roll it out slowly, hips stay up"],
            pattern: .hinge, difficulty: .intermediate, equipment: [.stabilityBall], muscleOverride: [.hamstrings, .glutes]
        ),
        Exercise(
            id: "stir-the-pot", name: "Stir the Pot",
            summary: "A plank with your forearms on the ball, drawing small circles. Brutal for the core.",
            cues: ["Forearms on the ball, body in a plank", "Draw small circles with your elbows", "Don't let your hips sag"],
            pattern: .core, difficulty: .advanced, measure: .time, equipment: [.stabilityBall], cautions: [.shoulders]
        ),

        // Mini bands
        Exercise(
            id: "banded-glute-bridge", name: "Banded Glute Bridge",
            summary: "A glute bridge with a band above your knees. Push your knees out against it all the way up.",
            cues: ["Band just above your knees", "Press your knees out against the band", "Squeeze your glutes at the top"],
            pattern: .hinge, difficulty: .beginner, equipment: [.miniBands], muscleOverride: [.glutes, .hamstrings]
        ),
        Exercise(
            id: "lateral-band-walk", name: "Lateral Band Walk",
            summary: "Step sideways with a band around your legs. Wakes up the side of your glutes.",
            cues: ["Band above the knees or at the ankles", "Stay in a half squat", "Step wide and slow, keep tension on the band"],
            pattern: .lunge, difficulty: .beginner, equipment: [.miniBands], isUnilateral: true, muscleOverride: [.glutes]
        ),

        // Medicine or slam ball
        Exercise(
            id: "med-ball-russian-twist", name: "Medicine Ball Russian Twist",
            summary: "Sit leaning back and rotate the ball from side to side.",
            cues: ["Lean back with a long, flat back", "Turn your shoulders, not just your arms", "Feet down to make it easier"],
            pattern: .core, difficulty: .intermediate, equipment: [.medicineBall], cautions: [.lowerBack]
        ),
        Exercise(
            id: "ball-slam", name: "Ball Slam",
            summary: "Lift the ball overhead and slam it down as hard as you can. A great way to burn energy fast.",
            cues: ["Reach the ball high overhead", "Slam it down in front of your feet", "Squat to pick it up, and go again"],
            pattern: .conditioning, difficulty: .intermediate, measure: .time, equipment: [.medicineBall],
            muscleOverride: [.abs, .shoulders, .upperBack]
        ),

        // Jump rope
        Exercise(
            id: "jump-rope", name: "Jump Rope",
            summary: "Skipping rope. Quick, light bounces on the balls of your feet.",
            cues: ["Small jumps, just clear the rope", "Turn the rope with your wrists", "Land softly"],
            pattern: .conditioning, difficulty: .intermediate, measure: .time, equipment: [.jumpRope],
            cautions: [.knees], muscleOverride: [.calves, .quads]
        ),
    ]
}
