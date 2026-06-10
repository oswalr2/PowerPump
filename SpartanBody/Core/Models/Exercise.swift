import Foundation

enum MuscleGroup: String, CaseIterable, Codable {
    case fullBody   = "Full Body"
    case chest      = "Chest"
    case back       = "Back"
    case shoulders  = "Shoulders"
    case arms       = "Arms"
    case core       = "Core"
    case legs       = "Legs"
    case glutes     = "Glutes"
    case cardio     = "Cardio"

    var icon: String {
        switch self {
        case .fullBody:  return "figure.strengthtraining.functional"
        case .chest:     return "heart.fill"
        case .back:      return "arrow.up.and.down.circle.fill"
        case .shoulders: return "arrow.left.and.right.circle.fill"
        case .arms:      return "figure.arms.open"
        case .core:      return "bolt.fill"
        case .legs:      return "figure.walk.circle.fill"
        case .glutes:    return "circle.fill"
        case .cardio:    return "flame.fill"
        }
    }
}

enum Equipment: String, Codable {
    case barbell     = "Barbell"
    case dumbbell    = "Dumbbell"
    case cable       = "Cable"
    case machine     = "Machine"
    case bodyweight  = "Bodyweight"
    case kettlebell  = "Kettlebell"
    case resistanceBand = "Resistance Band"
    case pullupBar   = "Pull-up Bar"

    var icon: String {
        switch self {
        case .barbell:        return "dumbbell.fill"
        case .dumbbell:       return "dumbbell.fill"
        case .cable:          return "arrow.up.and.down"
        case .machine:        return "gearshape.fill"
        case .bodyweight:     return "figure.strengthtraining.functional"
        case .kettlebell:     return "circle.fill"
        case .resistanceBand: return "link"
        case .pullupBar:      return "arrow.up.circle.fill"
        }
    }
}

enum ExerciseLocation: String, Codable {
    case gym  = "Gym"
    case home = "Home"
    case both = "Both"
}

enum Difficulty: String, Codable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"

    var color: String {
        switch self {
        case .beginner:     return "sbGreen"
        case .intermediate: return "sbAccent"
        case .advanced:     return "sbRed"
        }
    }
}

struct Exercise: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: MuscleGroup
    let equipment: Equipment
    let location: ExerciseLocation
    let difficulty: Difficulty
    let primaryMuscle: String
    let secondaryMuscles: [String]
    let setup: String
    let steps: [String]
    let tips: [String]
    let defaultSets: Int
    let defaultReps: String

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Exercise, rhs: Exercise) -> Bool { lhs.id == rhs.id }
}

struct WorkoutSet: Identifiable, Codable {
    let id: UUID
    var reps: Int
    var weightKg: Double
    var completed: Bool

    init(reps: Int = 10, weightKg: Double = 0, completed: Bool = false) {
        self.id = UUID()
        self.reps = reps
        self.weightKg = weightKg
        self.completed = completed
    }
}

struct ExerciseLog: Identifiable, Codable {
    let id: UUID
    let exerciseId: String
    let date: Date
    var sets: [WorkoutSet]

    init(exerciseId: String, sets: [WorkoutSet] = []) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.date = Date()
        self.sets = sets
    }
}
