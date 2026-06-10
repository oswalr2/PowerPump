import Foundation

enum RecipeGoal: String, CaseIterable, Codable {
    case muscleGain  = "Muscle Gain"
    case weightLoss  = "Weight Loss"
    case maintenance = "Maintenance"
}

struct Ingredient: Codable, Identifiable {
    var id: UUID = .init()
    var amount: String
    var name: String
}

struct Recipe: Identifiable, Codable {
    var id: String
    var name: String
    var goal: RecipeGoal
    var emoji: String
    var prepMinutes: Int
    var servings: Int
    var tags: [String]
    var ingredients: [Ingredient]
    var steps: [String]
    var nutrition: NutritionInfo  // per serving
}
