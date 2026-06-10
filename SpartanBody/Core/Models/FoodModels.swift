import Foundation

enum FoodCategory: String, CaseIterable, Codable {
    case protein     = "Protein"
    case carbs       = "Carbs"
    case fats        = "Fats"
    case vegetables  = "Vegetables"
    case dairy       = "Dairy"
    case fruits      = "Fruits"
    case other       = "Other"

    var icon: String {
        switch self {
        case .protein:    return "flame.fill"
        case .carbs:      return "leaf.fill"
        case .fats:       return "drop.fill"
        case .vegetables: return "tree.fill"
        case .dairy:      return "cup.and.saucer.fill"
        case .fruits:     return "apple.logo"
        case .other:      return "square.grid.2x2.fill"
        }
    }
}

struct NutritionInfo: Codable, Hashable {
    var calories: Double
    var protein:  Double
    var carbs:    Double
    var fat:      Double

    func scaled(by factor: Double) -> NutritionInfo {
        NutritionInfo(calories: calories * factor,
                      protein:  protein  * factor,
                      carbs:    carbs    * factor,
                      fat:      fat      * factor)
    }
}

struct FoodItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: FoodCategory
    let per100g: NutritionInfo

    func nutrition(grams: Double) -> NutritionInfo {
        per100g.scaled(by: grams / 100)
    }
}

enum MealType: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch     = "Lunch"
    case dinner    = "Dinner"
    case snack     = "Snack"

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch:     return "sun.max.fill"
        case .dinner:    return "moon.fill"
        case .snack:     return "fork.knife"
        }
    }
}

struct LoggedFood: Identifiable, Codable {
    var id:        UUID = .init()
    var foodID:    String
    var foodName:  String
    var grams:     Double
    var meal:      MealType
    var nutrition: NutritionInfo
    var loggedAt:  Date = .now
}
