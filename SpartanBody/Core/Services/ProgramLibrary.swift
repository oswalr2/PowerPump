import SwiftUI

struct BuiltinProgram: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let estimatedMinutes: Int
    let muscleGroups: String
    let template: WorkoutTemplate
}

struct ProgramLibrary {

    static let all: [BuiltinProgram] = [pushDay, pullDay, legsDay, fullBody, upperBody, coreCardio]

    static let pushDay = BuiltinProgram(
        id: "prog_push",
        name: "Push Day",
        subtitle: "Chest · Shoulders · Triceps",
        icon: "arrow.up.circle.fill",
        color: .sbAccent,
        estimatedMinutes: 50,
        muscleGroups: "Chest, Shoulders, Triceps",
        template: WorkoutTemplate(
            id: UUID(),
            name: "Push Day",
            exercises: [
                TemplateExercise(exerciseID: "bench_press",          sets: 4, targetReps: "8",  targetWeight: 60),
                TemplateExercise(exerciseID: "incline_dumbbell_press",sets: 3, targetReps: "10", targetWeight: 20),
                TemplateExercise(exerciseID: "overhead_press",        sets: 3, targetReps: "10", targetWeight: 40),
                TemplateExercise(exerciseID: "lateral_raise",         sets: 3, targetReps: "12", targetWeight: 10),
                TemplateExercise(exerciseID: "tricep_dip",            sets: 3, targetReps: "12", targetWeight: 0),
                TemplateExercise(exerciseID: "skull_crusher",         sets: 3, targetReps: "12", targetWeight: 20),
            ],
            createdAt: .distantPast
        )
    )

    static let pullDay = BuiltinProgram(
        id: "prog_pull",
        name: "Pull Day",
        subtitle: "Back · Biceps",
        icon: "arrow.down.circle.fill",
        color: .sbGreen,
        estimatedMinutes: 50,
        muscleGroups: "Back, Biceps",
        template: WorkoutTemplate(
            id: UUID(),
            name: "Pull Day",
            exercises: [
                TemplateExercise(exerciseID: "pull_up",       sets: 4, targetReps: "8",  targetWeight: 0),
                TemplateExercise(exerciseID: "lat_pulldown",  sets: 3, targetReps: "10", targetWeight: 50),
                TemplateExercise(exerciseID: "barbell_row",   sets: 4, targetReps: "8",  targetWeight: 60),
                TemplateExercise(exerciseID: "dumbbell_row",  sets: 3, targetReps: "10", targetWeight: 24),
                TemplateExercise(exerciseID: "barbell_curl",  sets: 3, targetReps: "12", targetWeight: 30),
                TemplateExercise(exerciseID: "hammer_curl",   sets: 3, targetReps: "12", targetWeight: 14),
            ],
            createdAt: .distantPast
        )
    )

    static let legsDay = BuiltinProgram(
        id: "prog_legs",
        name: "Leg Day",
        subtitle: "Quads · Hamstrings · Glutes",
        icon: "figure.run",
        color: Color(hex: "#C084FC"),
        estimatedMinutes: 55,
        muscleGroups: "Quads, Hamstrings, Glutes",
        template: WorkoutTemplate(
            id: UUID(),
            name: "Leg Day",
            exercises: [
                TemplateExercise(exerciseID: "squat",              sets: 4, targetReps: "8",  targetWeight: 80),
                TemplateExercise(exerciseID: "romanian_deadlift",  sets: 3, targetReps: "10", targetWeight: 60),
                TemplateExercise(exerciseID: "walking_lunge",      sets: 3, targetReps: "12", targetWeight: 20),
                TemplateExercise(exerciseID: "hip_thrust",         sets: 3, targetReps: "12", targetWeight: 60),
                TemplateExercise(exerciseID: "glute_bridge",       sets: 3, targetReps: "15", targetWeight: 0),
            ],
            createdAt: .distantPast
        )
    )

    static let fullBody = BuiltinProgram(
        id: "prog_fullbody",
        name: "Full Body",
        subtitle: "All muscle groups",
        icon: "figure.strengthtraining.traditional",
        color: Color(hex: "#FFD700"),
        estimatedMinutes: 60,
        muscleGroups: "Full Body",
        template: WorkoutTemplate(
            id: UUID(),
            name: "Full Body",
            exercises: [
                TemplateExercise(exerciseID: "squat",         sets: 4, targetReps: "6",  targetWeight: 80),
                TemplateExercise(exerciseID: "bench_press",   sets: 4, targetReps: "6",  targetWeight: 60),
                TemplateExercise(exerciseID: "deadlift",      sets: 3, targetReps: "5",  targetWeight: 100),
                TemplateExercise(exerciseID: "overhead_press",sets: 3, targetReps: "8",  targetWeight: 40),
                TemplateExercise(exerciseID: "barbell_row",   sets: 3, targetReps: "8",  targetWeight: 60),
            ],
            createdAt: .distantPast
        )
    )

    static let upperBody = BuiltinProgram(
        id: "prog_upper",
        name: "Upper Body",
        subtitle: "Chest · Back · Shoulders · Arms",
        icon: "figure.arms.open",
        color: Color(hex: "#FF6B35"),
        estimatedMinutes: 55,
        muscleGroups: "Chest, Back, Shoulders, Arms",
        template: WorkoutTemplate(
            id: UUID(),
            name: "Upper Body",
            exercises: [
                TemplateExercise(exerciseID: "bench_press",   sets: 4, targetReps: "8",  targetWeight: 60),
                TemplateExercise(exerciseID: "pull_up",       sets: 4, targetReps: "8",  targetWeight: 0),
                TemplateExercise(exerciseID: "overhead_press",sets: 3, targetReps: "10", targetWeight: 40),
                TemplateExercise(exerciseID: "barbell_row",   sets: 3, targetReps: "10", targetWeight: 60),
                TemplateExercise(exerciseID: "barbell_curl",  sets: 3, targetReps: "12", targetWeight: 30),
                TemplateExercise(exerciseID: "tricep_dip",    sets: 3, targetReps: "12", targetWeight: 0),
            ],
            createdAt: .distantPast
        )
    )

    static let coreCardio = BuiltinProgram(
        id: "prog_core",
        name: "Core & Cardio",
        subtitle: "Abs · Stability · Conditioning",
        icon: "bolt.heart.fill",
        color: Color(hex: "#FF375F"),
        estimatedMinutes: 30,
        muscleGroups: "Core, Full Body",
        template: WorkoutTemplate(
            id: UUID(),
            name: "Core & Cardio",
            exercises: [
                TemplateExercise(exerciseID: "plank",            sets: 4, targetReps: "60", targetWeight: 0),
                TemplateExercise(exerciseID: "crunch",           sets: 3, targetReps: "20", targetWeight: 0),
                TemplateExercise(exerciseID: "russian_twist",    sets: 3, targetReps: "20", targetWeight: 0),
                TemplateExercise(exerciseID: "leg_raise",        sets: 3, targetReps: "15", targetWeight: 0),
                TemplateExercise(exerciseID: "mountain_climber", sets: 3, targetReps: "30", targetWeight: 0),
                TemplateExercise(exerciseID: "jump_rope",        sets: 3, targetReps: "60", targetWeight: 0),
            ],
            createdAt: .distantPast
        )
    )
}
