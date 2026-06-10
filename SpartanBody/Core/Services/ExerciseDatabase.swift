import Foundation

struct ExerciseDatabase {
    static let all: [Exercise] = chest + back + shoulders + arms + core + legs + glutes + fullBody + cardio

    // MARK: - Free Exercise DB image IDs (yuhonas/free-exercise-db)
    // URL pattern: https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{id}/{0|1}.jpg
    static let imageIDs: [String: String] = [
        "bench_press":            "Barbell_Bench_Press_-_Medium_Grip",
        "incline_dumbbell_press": "Incline_Dumbbell_Press",
        "push_up":                "Pushups",
        "cable_fly":              "Cable_Crossover",
        "pull_up":                "Wide-Grip_Rear_Pull-Up",
        "lat_pulldown":           "Close-Grip_Front_Lat_Pulldown",
        "barbell_row":            "Bent_Over_Barbell_Row",
        "dumbbell_row":           "One-Arm_Dumbbell_Row",
        "overhead_press":         "Barbell_Shoulder_Press",
        "lateral_raise":          "Seated_Side_Lateral_Raise",
        "pike_push_up":           "Hanging_Pike",
        "barbell_curl":           "Barbell_Curl",
        "tricep_dip":             "Bench_Dips",
        "hammer_curl":            "Alternate_Hammer_Curl",
        "skull_crusher":          "EZ-Bar_Skullcrusher",
        "squat":                  "Barbell_Squat",
        "goblet_squat":           "Goblet_Squat",
        "romanian_deadlift":      "Romanian_Deadlift",
        "walking_lunge":          "Barbell_Lunge",
        "hip_thrust":             "Barbell_Hip_Thrust",
        "glute_bridge":           "Barbell_Glute_Bridge",
        "deadlift":               "Barbell_Deadlift",
        "plank":                  "Plank",
        "crunch":                 "Cross-Body_Crunch",
        "russian_twist":          "Cable_Russian_Twists",
        "leg_raise":              "Hanging_Leg_Raise",
        "jump_rope":              "Rope_Jumping",
        "mountain_climber":       "Mountain_Climbers",
        "box_jump":               "Box_Jump_Multiple_Response",
        "clean_and_press":        "Power_Clean",
    ]

    // MARK: - Bundled muscle icon asset names
    static let muscleIconNames: [String: String] = [
        "bench_press":            "muscle_icon_bench_press",
        "incline_dumbbell_press": "muscle_icon_incline_dumbbell_press",
        "push_up":                "muscle_icon_push_up",
        "cable_fly":              "muscle_icon_cable_fly",
        "pull_up":                "muscle_icon_pull_up",
        "lat_pulldown":           "muscle_icon_lat_pulldown",
        "barbell_row":            "muscle_icon_barbell_row",
        "dumbbell_row":           "muscle_icon_dumbbell_row",
        "overhead_press":         "muscle_icon_overhead_press",
        "lateral_raise":          "muscle_icon_lateral_raise",
        "pike_push_up":           "muscle_icon_pike_push_up",
        "barbell_curl":           "muscle_icon_barbell_curl",
        "tricep_dip":             "muscle_icon_tricep_dip",
        "hammer_curl":            "muscle_icon_hammer_curl",
        "skull_crusher":          "muscle_icon_skull_crusher",
        "squat":                  "muscle_icon_squat",
        "goblet_squat":           "muscle_icon_goblet_squat",
        "romanian_deadlift":      "muscle_icon_romanian_deadlift",
        "walking_lunge":          "muscle_icon_walking_lunge",
        "hip_thrust":             "muscle_icon_hip_thrust",
        "glute_bridge":           "muscle_icon_glute_bridge",
        "deadlift":               "muscle_icon_deadlift",
        "plank":                  "muscle_icon_plank",
        "crunch":                 "muscle_icon_crunch",
        "russian_twist":          "muscle_icon_russian_twist",
        "leg_raise":              "muscle_icon_leg_raise",
        "jump_rope":              "muscle_icon_jump_rope",
        "mountain_climber":       "muscle_icon_mountain_climber",
        "box_jump":               "muscle_icon_box_jump",
        "clean_and_press":        "muscle_icon_clean_and_press",
    ]

    static func exercises(for category: MuscleGroup) -> [Exercise] {
        all.filter { $0.category == category }
    }

    static func exercises(for location: ExerciseLocation) -> [Exercise] {
        if location == .both { return all }
        return all.filter { $0.location == location || $0.location == .both }
    }

    // MARK: - Chest
    static let chest: [Exercise] = [
        Exercise(
            id: "bench_press",
            name: "Bench Press",
            category: .chest,
            equipment: .barbell,
            location: .gym,
            difficulty: .intermediate,
            primaryMuscle: "Pectoralis Major",
            secondaryMuscles: ["Anterior Deltoid", "Triceps"],
            setup: "Lie flat on a bench. Grip the bar slightly wider than shoulder-width with palms facing away. Unrack the bar and hold it directly over your chest.",
            steps: [
                "Lower the bar slowly to your mid-chest, keeping elbows at ~45°.",
                "Touch your chest lightly — do not bounce.",
                "Press the bar back up in a slight arc until arms are fully extended.",
                "Keep your feet flat, back slightly arched, and shoulder blades retracted."
            ],
            tips: ["Keep wrists straight throughout", "Don't flare elbows past 45°", "Exhale on the push"],
            defaultSets: 4,
            defaultReps: "8–10"
        ),
        Exercise(
            id: "incline_dumbbell_press",
            name: "Incline Dumbbell Press",
            category: .chest,
            equipment: .dumbbell,
            location: .gym,
            difficulty: .intermediate,
            primaryMuscle: "Upper Pectoralis Major",
            secondaryMuscles: ["Anterior Deltoid", "Triceps"],
            setup: "Set a bench to 30–45°. Sit with a dumbbell on each thigh, then kick them up as you lean back.",
            steps: [
                "Hold dumbbells at chest level, palms facing forward.",
                "Press both dumbbells up until arms are extended, meeting at the top.",
                "Lower slowly back to chest level with control.",
                "Keep core tight and back against the pad."
            ],
            tips: ["Squeeze at the top", "Move both dumbbells symmetrically", "Control the eccentric"],
            defaultSets: 3,
            defaultReps: "10–12"
        ),
        Exercise(
            id: "push_up",
            name: "Push-Up",
            category: .chest,
            equipment: .bodyweight,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Pectoralis Major",
            secondaryMuscles: ["Triceps", "Anterior Deltoid", "Core"],
            setup: "Start in a high plank position with hands slightly wider than shoulder-width, body forming a straight line.",
            steps: [
                "Lower your chest toward the floor by bending your elbows.",
                "Keep elbows at roughly 45° from your torso.",
                "Stop just before chest touches the ground.",
                "Push back up forcefully to the start position."
            ],
            tips: ["Don't let hips sag", "Keep head neutral", "Full range of motion"],
            defaultSets: 3,
            defaultReps: "12–15"
        ),
        Exercise(
            id: "cable_fly",
            name: "Cable Fly",
            category: .chest,
            equipment: .cable,
            location: .gym,
            difficulty: .intermediate,
            primaryMuscle: "Pectoralis Major",
            secondaryMuscles: ["Anterior Deltoid"],
            setup: "Set cable pulleys to chest height. Stand in the center, grab one handle in each hand, and step one foot forward.",
            steps: [
                "With a slight elbow bend, open your arms wide like a hug.",
                "Bring both handles together in front of your chest.",
                "Squeeze the chest at the peak contraction.",
                "Slowly return to the open position with control."
            ],
            tips: ["Keep a slight bend in elbows throughout", "Don't let weight crash back", "Focus on stretch"],
            defaultSets: 3,
            defaultReps: "12–15"
        ),
    ]

    // MARK: - Back
    static let back: [Exercise] = [
        Exercise(
            id: "pull_up",
            name: "Pull-Up",
            category: .back,
            equipment: .pullupBar,
            location: .both,
            difficulty: .intermediate,
            primaryMuscle: "Latissimus Dorsi",
            secondaryMuscles: ["Biceps", "Rear Deltoid", "Rhomboids"],
            setup: "Hang from a pull-up bar with an overhand grip, hands shoulder-width apart or slightly wider.",
            steps: [
                "Engage your lats and pull your chest toward the bar.",
                "Lead with your elbows, driving them down and back.",
                "Get your chin above the bar.",
                "Lower yourself slowly until arms are fully extended."
            ],
            tips: ["Don't swing or kip", "Cross your feet behind you for stability", "Full dead hang at the bottom"],
            defaultSets: 4,
            defaultReps: "6–10"
        ),
        Exercise(
            id: "barbell_row",
            name: "Barbell Row",
            category: .back,
            equipment: .barbell,
            location: .gym,
            difficulty: .intermediate,
            primaryMuscle: "Latissimus Dorsi",
            secondaryMuscles: ["Rhomboids", "Biceps", "Rear Deltoid"],
            setup: "Stand with feet hip-width apart. Hinge at hips until torso is roughly parallel to the floor. Grip barbell with overhand grip.",
            steps: [
                "Row the bar toward your lower chest/upper abdomen.",
                "Drive elbows back and squeeze shoulder blades together.",
                "Hold the contraction for 1 second.",
                "Lower the bar under control back to arm extension."
            ],
            tips: ["Keep back flat — no rounding", "Don't jerk the weight up", "Head neutral"],
            defaultSets: 4,
            defaultReps: "8–10"
        ),
        Exercise(
            id: "lat_pulldown",
            name: "Lat Pulldown",
            category: .back,
            equipment: .cable,
            location: .gym,
            difficulty: .beginner,
            primaryMuscle: "Latissimus Dorsi",
            secondaryMuscles: ["Biceps", "Rear Deltoid"],
            setup: "Sit at a lat pulldown machine. Adjust thigh pad so it holds you in place. Grip the bar wider than shoulder-width.",
            steps: [
                "Lean back slightly and pull the bar down toward your upper chest.",
                "Drive elbows down and back, squeezing lats.",
                "Pause briefly when bar reaches chin level.",
                "Slowly allow the bar to rise back up, fully extending arms."
            ],
            tips: ["Don't pull behind the neck", "Control the return", "Keep chest up"],
            defaultSets: 3,
            defaultReps: "10–12"
        ),
        Exercise(
            id: "dumbbell_row",
            name: "Single-Arm Dumbbell Row",
            category: .back,
            equipment: .dumbbell,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Latissimus Dorsi",
            secondaryMuscles: ["Rhomboids", "Biceps", "Rear Deltoid"],
            setup: "Place one knee and hand on a bench for support. Hold a dumbbell in the opposite hand, arm hanging straight down.",
            steps: [
                "Row the dumbbell up toward your hip, elbow driving back.",
                "Squeeze your lat and rhomboids at the top.",
                "Lower the dumbbell slowly until arm is fully extended.",
                "Complete all reps on one side before switching."
            ],
            tips: ["Don't rotate your torso", "Keep back parallel to floor", "Elbow close to body"],
            defaultSets: 3,
            defaultReps: "10–12 each"
        ),
    ]

    // MARK: - Shoulders
    static let shoulders: [Exercise] = [
        Exercise(
            id: "overhead_press",
            name: "Overhead Press",
            category: .shoulders,
            equipment: .barbell,
            location: .gym,
            difficulty: .intermediate,
            primaryMuscle: "Anterior & Medial Deltoid",
            secondaryMuscles: ["Triceps", "Upper Trapezius"],
            setup: "Stand with feet shoulder-width apart. Hold barbell at collarbone level with overhand grip just outside shoulders.",
            steps: [
                "Press the bar straight up overhead, slightly back once it clears your head.",
                "Lock arms out at the top.",
                "Lower the bar back to collarbone under control.",
                "Keep core braced and avoid arching lower back."
            ],
            tips: ["Don't lean back excessively", "Full lockout at top", "Breathe out on push"],
            defaultSets: 4,
            defaultReps: "6–8"
        ),
        Exercise(
            id: "lateral_raise",
            name: "Lateral Raise",
            category: .shoulders,
            equipment: .dumbbell,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Medial Deltoid",
            secondaryMuscles: ["Anterior Deltoid", "Supraspinatus"],
            setup: "Stand with feet hip-width apart, a dumbbell in each hand at your sides.",
            steps: [
                "With a slight bend in your elbows, raise both arms out to the sides.",
                "Lift until your arms are parallel to the floor.",
                "Pour slightly as if emptying a pitcher at the top.",
                "Lower slowly back to your sides."
            ],
            tips: ["Don't swing or use momentum", "Lead with elbows, not wrists", "Light weight, strict form"],
            defaultSets: 3,
            defaultReps: "12–15"
        ),
        Exercise(
            id: "pike_push_up",
            name: "Pike Push-Up",
            category: .shoulders,
            equipment: .bodyweight,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Anterior Deltoid",
            secondaryMuscles: ["Triceps", "Upper Trapezius"],
            setup: "Start in a downward dog position — hips high, forming an inverted V with your body.",
            steps: [
                "Bend elbows and lower your head toward the floor.",
                "Keep your hips elevated throughout the movement.",
                "Stop just before head touches the ground.",
                "Push back up to the inverted V position."
            ],
            tips: ["Wrists directly under shoulders", "Don't drop hips", "Look toward your feet"],
            defaultSets: 3,
            defaultReps: "10–12"
        ),
    ]

    // MARK: - Arms
    static let arms: [Exercise] = [
        Exercise(
            id: "barbell_curl",
            name: "Barbell Curl",
            category: .arms,
            equipment: .barbell,
            location: .gym,
            difficulty: .beginner,
            primaryMuscle: "Biceps Brachii",
            secondaryMuscles: ["Brachialis", "Forearms"],
            setup: "Stand holding a barbell with an underhand grip, hands shoulder-width apart, arms fully extended.",
            steps: [
                "Curl the bar up toward your chest by bending at the elbows.",
                "Keep upper arms pinned at your sides throughout.",
                "Squeeze biceps hard at the top.",
                "Lower the bar slowly back to full extension."
            ],
            tips: ["No swinging or momentum", "Control the negative", "Full range of motion"],
            defaultSets: 3,
            defaultReps: "10–12"
        ),
        Exercise(
            id: "tricep_dip",
            name: "Tricep Dip",
            category: .arms,
            equipment: .bodyweight,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Triceps Brachii",
            secondaryMuscles: ["Anterior Deltoid", "Chest"],
            setup: "Place hands on the edge of a bench or parallel bars, fingers forward. Extend legs out in front.",
            steps: [
                "Lower your body by bending your elbows behind you.",
                "Go down until upper arms are parallel to the floor.",
                "Press back up to straight arms.",
                "Keep elbows close — don't let them flare wide."
            ],
            tips: ["Lean slightly forward for more tricep focus", "Don't go too deep", "Keep hips close to bench"],
            defaultSets: 3,
            defaultReps: "12–15"
        ),
        Exercise(
            id: "hammer_curl",
            name: "Hammer Curl",
            category: .arms,
            equipment: .dumbbell,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Brachialis",
            secondaryMuscles: ["Biceps Brachii", "Forearms"],
            setup: "Stand holding dumbbells at your sides with a neutral grip (palms facing each other).",
            steps: [
                "Curl both dumbbells up simultaneously, keeping palms neutral.",
                "Keep upper arms stationary at your sides.",
                "Squeeze at the top.",
                "Lower slowly with control."
            ],
            tips: ["Can be done alternating for balance", "Great for forearm development", "Don't let wrists bend"],
            defaultSets: 3,
            defaultReps: "10–12"
        ),
        Exercise(
            id: "skull_crusher",
            name: "Skull Crusher",
            category: .arms,
            equipment: .barbell,
            location: .gym,
            difficulty: .intermediate,
            primaryMuscle: "Triceps Brachii",
            secondaryMuscles: [],
            setup: "Lie flat on a bench. Hold an EZ-bar or barbell with a close grip, arms extended over your chest.",
            steps: [
                "Keeping upper arms stationary, lower the bar toward your forehead.",
                "Bend only at the elbows.",
                "Stop just above your forehead.",
                "Extend back to the start position."
            ],
            tips: ["Don't let elbows flare out", "Use a spotter for heavy weight", "Control the descent"],
            defaultSets: 3,
            defaultReps: "10–12"
        ),
    ]

    // MARK: - Core
    static let core: [Exercise] = [
        Exercise(
            id: "plank",
            name: "Plank",
            category: .core,
            equipment: .bodyweight,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Rectus Abdominis",
            secondaryMuscles: ["Transverse Abdominis", "Obliques", "Glutes"],
            setup: "Start in a forearm plank position — elbows under shoulders, body in a straight line from head to heels.",
            steps: [
                "Brace your core tight as if bracing for a punch.",
                "Squeeze glutes and keep hips level — not raised or dropped.",
                "Hold position, breathing steadily.",
                "Keep neck neutral — look at the floor."
            ],
            tips: ["Don't hold your breath", "Progress by adding time", "Squeeze everything"],
            defaultSets: 3,
            defaultReps: "30–60 sec"
        ),
        Exercise(
            id: "crunch",
            name: "Crunch",
            category: .core,
            equipment: .bodyweight,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Rectus Abdominis",
            secondaryMuscles: ["Hip Flexors"],
            setup: "Lie on your back with knees bent, feet flat on the floor. Place hands behind your head lightly.",
            steps: [
                "Engage your core and curl your shoulders off the floor.",
                "Lift only your upper back — lower back stays down.",
                "Squeeze abs at the top.",
                "Lower back down with control — don't fully relax between reps."
            ],
            tips: ["Don't pull your neck", "Exhale on the way up", "Small, controlled movement"],
            defaultSets: 3,
            defaultReps: "15–20"
        ),
        Exercise(
            id: "russian_twist",
            name: "Russian Twist",
            category: .core,
            equipment: .bodyweight,
            location: .both,
            difficulty: .intermediate,
            primaryMuscle: "Obliques",
            secondaryMuscles: ["Rectus Abdominis", "Hip Flexors"],
            setup: "Sit on the floor, knees bent and feet slightly lifted. Lean back at 45°. Clasp hands or hold a weight in front of you.",
            steps: [
                "Rotate your torso to one side as far as comfortable.",
                "Tap the floor beside your hip.",
                "Rotate to the other side.",
                "Keep core braced and feet elevated throughout."
            ],
            tips: ["Move from your core, not just arms", "Increase difficulty by adding a plate or dumbbell", "Keep chest tall"],
            defaultSets: 3,
            defaultReps: "20 total"
        ),
        Exercise(
            id: "leg_raise",
            name: "Hanging Leg Raise",
            category: .core,
            equipment: .pullupBar,
            location: .gym,
            difficulty: .intermediate,
            primaryMuscle: "Lower Rectus Abdominis",
            secondaryMuscles: ["Hip Flexors", "Obliques"],
            setup: "Hang from a pull-up bar with an overhand grip, arms fully extended.",
            steps: [
                "Brace your core and raise your legs toward your chest.",
                "Keep legs straight or slightly bent.",
                "Bring legs until parallel to the floor (or higher).",
                "Lower slowly — don't let momentum swing your body."
            ],
            tips: ["Avoid swinging", "Exhale as you raise legs", "Tuck for easier version"],
            defaultSets: 3,
            defaultReps: "10–12"
        ),
    ]

    // MARK: - Legs
    static let legs: [Exercise] = [
        Exercise(
            id: "squat",
            name: "Back Squat",
            category: .legs,
            equipment: .barbell,
            location: .gym,
            difficulty: .intermediate,
            primaryMuscle: "Quadriceps",
            secondaryMuscles: ["Glutes", "Hamstrings", "Core"],
            setup: "Position barbell across your upper traps. Stand with feet shoulder-width apart, toes slightly out.",
            steps: [
                "Push your hips back and bend knees to lower down.",
                "Keep chest tall and knees tracking over toes.",
                "Descend until thighs are at least parallel to the floor.",
                "Drive through your heels to return to standing."
            ],
            tips: ["Brace core before each rep", "Don't let knees cave in", "Keep weight in heels"],
            defaultSets: 4,
            defaultReps: "6–8"
        ),
        Exercise(
            id: "goblet_squat",
            name: "Goblet Squat",
            category: .legs,
            equipment: .dumbbell,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Quadriceps",
            secondaryMuscles: ["Glutes", "Core"],
            setup: "Hold a dumbbell or kettlebell vertically at your chest with both hands. Stand with feet shoulder-width apart.",
            steps: [
                "Push knees out and lower into a squat.",
                "Keep the weight against your chest throughout.",
                "Descend until thighs are parallel or lower.",
                "Drive through heels to stand back up."
            ],
            tips: ["Great for beginners learning squat mechanics", "Keep elbows inside knees", "Chest up"],
            defaultSets: 3,
            defaultReps: "12–15"
        ),
        Exercise(
            id: "romanian_deadlift",
            name: "Romanian Deadlift",
            category: .legs,
            equipment: .barbell,
            location: .gym,
            difficulty: .intermediate,
            primaryMuscle: "Hamstrings",
            secondaryMuscles: ["Glutes", "Erector Spinae"],
            setup: "Hold a barbell at hip height with overhand grip, standing with feet hip-width apart.",
            steps: [
                "Hinge at the hips, pushing them back as you lower the bar.",
                "Keep the bar close to your legs — nearly dragging down your shins.",
                "Lower until you feel a stretch in your hamstrings.",
                "Drive hips forward to return to standing."
            ],
            tips: ["Keep back flat throughout", "Bend knees slightly — this isn't a stiff-leg DL", "Feel the hamstring stretch"],
            defaultSets: 3,
            defaultReps: "8–10"
        ),
        Exercise(
            id: "walking_lunge",
            name: "Walking Lunge",
            category: .legs,
            equipment: .dumbbell,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Quadriceps",
            secondaryMuscles: ["Glutes", "Hamstrings", "Core"],
            setup: "Stand upright holding dumbbells at your sides (or bodyweight). Feet together.",
            steps: [
                "Step forward with one leg and lower your back knee toward the floor.",
                "Front thigh should be parallel to the floor.",
                "Push off the front foot and step forward with the opposite leg.",
                "Continue alternating legs for the full rep count."
            ],
            tips: ["Keep torso upright", "Don't let front knee pass toes", "Control each step"],
            defaultSets: 3,
            defaultReps: "10 each leg"
        ),
    ]

    // MARK: - Glutes
    static let glutes: [Exercise] = [
        Exercise(
            id: "hip_thrust",
            name: "Barbell Hip Thrust",
            category: .glutes,
            equipment: .barbell,
            location: .gym,
            difficulty: .intermediate,
            primaryMuscle: "Gluteus Maximus",
            secondaryMuscles: ["Hamstrings", "Core"],
            setup: "Sit on the floor with your upper back against a bench. Roll a barbell over your hips. Plant feet flat, shoulder-width apart.",
            steps: [
                "Brace core and drive through heels to lift your hips.",
                "Push hips up until your body forms a straight line from knees to shoulders.",
                "Squeeze glutes hard at the top.",
                "Lower hips back toward the floor with control."
            ],
            tips: ["Chin tucked — don't hyperextend your neck", "Use a barbell pad for comfort", "Drive through heels, not toes"],
            defaultSets: 4,
            defaultReps: "10–12"
        ),
        Exercise(
            id: "glute_bridge",
            name: "Glute Bridge",
            category: .glutes,
            equipment: .bodyweight,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Gluteus Maximus",
            secondaryMuscles: ["Hamstrings", "Core"],
            setup: "Lie on your back with knees bent and feet flat on the floor, hip-width apart.",
            steps: [
                "Press your feet into the floor and squeeze your glutes.",
                "Lift your hips until your body forms a straight line.",
                "Hold at the top for 1–2 seconds.",
                "Lower back down slowly."
            ],
            tips: ["Keep core braced", "Add resistance band above knees for extra activation", "Don't arch lower back"],
            defaultSets: 3,
            defaultReps: "15–20"
        ),
    ]

    // MARK: - Full Body
    static let fullBody: [Exercise] = [
        Exercise(
            id: "deadlift",
            name: "Deadlift",
            category: .fullBody,
            equipment: .barbell,
            location: .gym,
            difficulty: .advanced,
            primaryMuscle: "Erector Spinae",
            secondaryMuscles: ["Glutes", "Hamstrings", "Quadriceps", "Traps", "Forearms"],
            setup: "Stand with feet hip-width apart, bar over mid-foot. Hinge down and grip bar just outside legs. Hips above knees, chest up, back flat.",
            steps: [
                "Take a deep breath and brace your core.",
                "Push the floor away (don't think 'pull'), driving through your heels.",
                "Keep bar close to your body as you rise — drag it up your shins.",
                "Stand fully upright, locking hips forward at the top.",
                "Hinge back down under control."
            ],
            tips: ["Never round your lower back", "Bar stays over mid-foot throughout", "Big breath before each rep"],
            defaultSets: 4,
            defaultReps: "5"
        ),
        Exercise(
            id: "clean_and_press",
            name: "Clean and Press",
            category: .fullBody,
            equipment: .barbell,
            location: .gym,
            difficulty: .advanced,
            primaryMuscle: "Full Body",
            secondaryMuscles: ["Traps", "Shoulders", "Legs", "Core"],
            setup: "Stand with feet hip-width apart. Bar on the floor, grip just outside legs.",
            steps: [
                "Deadlift the bar to hip height with a fast pull.",
                "Shrug and pull yourself under the bar, catching it at shoulder height.",
                "Stand tall with bar at shoulders.",
                "Press the bar overhead to full lockout."
            ],
            tips: ["Master deadlift and overhead press separately first", "Use wrist wraps if needed", "Speed in the pull"],
            defaultSets: 3,
            defaultReps: "5"
        ),
    ]

    // MARK: - Cardio
    static let cardio: [Exercise] = [
        Exercise(
            id: "jump_rope",
            name: "Jump Rope",
            category: .cardio,
            equipment: .bodyweight,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Calves",
            secondaryMuscles: ["Shoulders", "Core"],
            setup: "Hold rope handles with arms at your sides. Position rope behind you.",
            steps: [
                "Swing the rope over your head.",
                "Jump with both feet as the rope reaches the floor.",
                "Land softly on the balls of your feet.",
                "Maintain a steady rhythm."
            ],
            tips: ["Keep jumps low — just enough to clear rope", "Wrists do the rotation, not arms", "Start slow and build speed"],
            defaultSets: 3,
            defaultReps: "2 min"
        ),
        Exercise(
            id: "mountain_climber",
            name: "Mountain Climber",
            category: .cardio,
            equipment: .bodyweight,
            location: .both,
            difficulty: .beginner,
            primaryMuscle: "Core",
            secondaryMuscles: ["Hip Flexors", "Shoulders", "Legs"],
            setup: "Start in a high push-up position, arms fully extended, body in a straight line.",
            steps: [
                "Drive one knee toward your chest as quickly as possible.",
                "Return that foot and simultaneously drive the other knee in.",
                "Alternate rapidly in a running motion.",
                "Keep hips level and core tight throughout."
            ],
            tips: ["Don't let hips rise up", "Keep shoulders over wrists", "Breathe rhythmically"],
            defaultSets: 3,
            defaultReps: "30 sec"
        ),
        Exercise(
            id: "box_jump",
            name: "Box Jump",
            category: .cardio,
            equipment: .bodyweight,
            location: .gym,
            difficulty: .intermediate,
            primaryMuscle: "Quadriceps",
            secondaryMuscles: ["Glutes", "Calves", "Core"],
            setup: "Stand facing a sturdy box or platform. Feet shoulder-width apart.",
            steps: [
                "Bend knees and swing arms back.",
                "Explode upward and forward, landing softly on top of the box.",
                "Land with both feet flat and knees slightly bent.",
                "Stand tall, then step (not jump) back down."
            ],
            tips: ["Step down instead of jumping to protect knees", "Land softly — think 'quiet'", "Start with a lower box"],
            defaultSets: 3,
            defaultReps: "8"
        ),
    ]
}
