import Foundation
import Combine

enum FitnessGoal: String, CaseIterable, Codable {
    case loseWeight  = "Lose Weight"
    case gainMuscle  = "Gain Muscle"
    case stayFit     = "Stay Fit"

    var icon: String {
        switch self {
        case .loseWeight: return "flame.fill"
        case .gainMuscle: return "bolt.fill"
        case .stayFit:    return "heart.fill"
        }
    }

    var description: String {
        switch self {
        case .loseWeight: return "Burn fat with cardio & calorie deficit"
        case .gainMuscle: return "Build strength with progressive overload"
        case .stayFit:    return "Maintain health & energy levels"
        }
    }

    var dailyCalorieAdjustment: Int {
        switch self {
        case .loseWeight: return -500
        case .gainMuscle: return +300
        case .stayFit:    return 0
        }
    }
}

enum BiologicalSex: String, CaseIterable, Codable {
    case male   = "Male"
    case female = "Female"

    var icon: String {
        switch self {
        case .male:   return "figure.stand"
        case .female: return "figure.stand.dress"
        }
    }

    // Mifflin-St Jeor constant: +5 for males, −161 for females.
    var bmrConstant: Double {
        switch self {
        case .male:   return 5
        case .female: return -161
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary   = "Sedentary"
    case light       = "Lightly Active"
    case moderate    = "Moderately Active"
    case active      = "Very Active"

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light:     return 1.375
        case .moderate:  return 1.55
        case .active:    return 1.725
        }
    }
}

@MainActor
final class UserProfile: ObservableObject {
    static let shared = UserProfile()

    @Published var name: String        { didSet { save() } }
    @Published var age: Int            { didSet { save() } }
    @Published var sex: BiologicalSex  { didSet { save() } }
    @Published var weightKg: Double    { didSet { save() } }
    @Published var targetWeightKg: Double { didSet { save() } }
    @Published var heightCm: Double    { didSet { save() } }
    @Published var goal: FitnessGoal   { didSet { save() } }
    @Published var activityLevel: ActivityLevel { didSet { save() } }
    @Published var onboardingDone: Bool { didSet { save() } }

    private let key = "spartanbody_profile"

    private init() {
        if let data = UserDefaults.standard.data(forKey: "spartanbody_profile"),
           let saved = try? JSONDecoder().decode(ProfileData.self, from: data) {
            name          = saved.name
            age           = saved.age
            sex           = saved.sex ?? .male
            weightKg      = saved.weightKg
            targetWeightKg = saved.targetWeightKg ?? saved.weightKg
            heightCm      = saved.heightCm
            goal          = saved.goal
            activityLevel = saved.activityLevel
            onboardingDone = saved.onboardingDone
        } else {
            name          = ""
            age           = 25
            sex           = .male
            weightKg      = 75
            targetWeightKg = 75
            heightCm      = 175
            goal          = .gainMuscle
            activityLevel = .moderate
            onboardingDone = false
        }
    }

    // BMR via Mifflin-St Jeor (sex-specific constant)
    var bmr: Double {
        10 * weightKg + 6.25 * heightCm - 5 * Double(age) + sex.bmrConstant
    }

    var dailyCalorieTarget: Int {
        Int(bmr * activityLevel.multiplier) + goal.dailyCalorieAdjustment
    }

    var dailyProteinTarget: Int {
        switch goal {
        case .gainMuscle: return Int(weightKg * 2.0)
        case .loseWeight: return Int(weightKg * 1.8)
        case .stayFit:    return Int(weightKg * 1.5)
        }
    }

    var bmi: Double {
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }

    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    private func save() {
        let data = ProfileData(name: name, age: age, sex: sex, weightKg: weightKg,
                               targetWeightKg: targetWeightKg,
                               heightCm: heightCm, goal: goal,
                               activityLevel: activityLevel, onboardingDone: onboardingDone)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}

private struct ProfileData: Codable {
    var name: String
    var age: Int
    var sex: BiologicalSex? = nil       // Optional for backward compatibility
    var weightKg: Double
    var targetWeightKg: Double? = nil   // Optional for backward compatibility
    var heightCm: Double
    var goal: FitnessGoal
    var activityLevel: ActivityLevel
    var onboardingDone: Bool
}
