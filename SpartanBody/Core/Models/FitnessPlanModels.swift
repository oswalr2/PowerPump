import Foundation

struct FitnessPlan: Codable {
    var analysis:       String
    var weeklySchedule: [DayPlan]
    var nutritionPlan:  AINutritionPlan
    var tips:           [String]
    var motivation:     String
    var weeklyMeals:    [DayMeals] = []
}

// Suggested menu for one day (recipe names — localized at render time).
struct DayMeals: Codable, Identifiable {
    var id: String { day }
    var day:       String
    var breakfast: String
    var lunch:     String
    var dinner:    String
}

struct DayPlan: Codable, Identifiable {
    var id: String { day }
    var day:       String   // "Monday", "Tuesday", …
    var type:      String   // "workout" | "rest"
    var focus:     String   // "Chest & Triceps", "Active Recovery", …
    var exercises: [String] // ["Bench Press 4×8", "Push-ups 3×15", …]

    var isWorkout: Bool { type.lowercased() == "workout" }
}

struct AINutritionPlan: Codable {
    var calories: Int
    var protein:  Int
    var carbs:    Int
    var fat:      Int
    var tips:     [String]
}
