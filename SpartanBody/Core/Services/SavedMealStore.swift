import Foundation

// A reusable combo ("my usual breakfast") logged with one tap.
struct SavedMeal: Identifiable, Codable {
    var id: UUID = .init()
    var name: String
    var items: [SavedMealItem]

    var totalCalories: Double {
        items.reduce(0) { $0 + $1.item.nutrition(grams: $1.grams).calories }
    }
}

struct SavedMealItem: Codable {
    var item: FoodItem
    var grams: Double
}

final class SavedMealStore: ObservableObject {
    static let shared = SavedMealStore()

    @Published private(set) var meals: [SavedMeal] = []

    private let key = "sb_saved_meals"

    private init() { load() }

    // Snapshot the given logged entries as a reusable meal.
    func save(name: String, entries: [LoggedFood]) {
        let items = entries.filter { $0.grams > 0 }.map { e in
            SavedMealItem(item: FoodLogStore.shared.foodItem(from: e), grams: e.grams)
        }
        guard !items.isEmpty else { return }
        meals.insert(SavedMeal(name: name, items: items), at: 0)
        persist()
    }

    func remove(_ meal: SavedMeal) {
        meals.removeAll { $0.id == meal.id }
        persist()
    }

    // Log every item of the combo to the given meal in one shot.
    func log(_ meal: SavedMeal, to mealType: MealType) {
        for i in meal.items {
            FoodLogStore.shared.add(i.item, grams: i.grams, meal: mealType)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(meals) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([SavedMeal].self, from: data) {
            meals = decoded
        }
    }
}
