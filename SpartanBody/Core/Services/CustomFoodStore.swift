import Foundation

// User-created foods (label data for products not in any database).
final class CustomFoodStore: ObservableObject {
    static let shared = CustomFoodStore()

    @Published private(set) var foods: [FoodItem] = []

    private let key = "sb_custom_foods"

    private init() { load() }

    @discardableResult
    func add(name: String, caloriesPer100g: Double, protein: Double,
             carbs: Double, fat: Double) -> FoodItem {
        let item = FoodItem(
            id: "custom_\(UUID().uuidString)",
            name: name,
            category: .other,
            per100g: NutritionInfo(calories: caloriesPer100g, protein: protein,
                                   carbs: carbs, fat: fat)
        )
        foods.insert(item, at: 0)
        save()
        return item
    }

    func remove(_ item: FoodItem) {
        foods.removeAll { $0.id == item.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(foods) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([FoodItem].self, from: data) {
            foods = decoded
        }
    }
}
