import Foundation

struct ScannedFoodItem: Identifiable, Codable {
    var id       = UUID()
    var name:    String
    var grams:   Double
    var calories: Int
    var protein: Double
    var carbs:   Double
    var fat:     Double

    var nutritionInfo: NutritionInfo {
        NutritionInfo(calories: Double(calories), protein: protein, carbs: carbs, fat: fat)
    }
}

struct FoodScanResponse: Codable {
    var items:         [ScannedFoodItem]
    var totalCalories: Int
    var totalProtein:  Double
    var totalCarbs:    Double
    var totalFat:      Double
}
