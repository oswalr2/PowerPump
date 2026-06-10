import Foundation

final class FoodLogStore: ObservableObject {
    static let shared = FoodLogStore()

    @Published private(set) var todayEntries: [LoggedFood] = []

    private var allLogs: [String: [LoggedFood]] = [:]

    private init() { load() }

    // MARK: - Today key

    private var todayKey: String { dateKey(for: .now) }

    private func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    // MARK: - Computed totals for today

    var todayCalories: Double { todayEntries.reduce(0) { $0 + $1.nutrition.calories } }
    var todayProtein:  Double { todayEntries.reduce(0) { $0 + $1.nutrition.protein } }
    var todayCarbs:    Double { todayEntries.reduce(0) { $0 + $1.nutrition.carbs } }
    var todayFat:      Double { todayEntries.reduce(0) { $0 + $1.nutrition.fat } }

    func entries(for meal: MealType) -> [LoggedFood] {
        todayEntries.filter { $0.meal == meal }
    }

    func calories(for meal: MealType) -> Double {
        entries(for: meal).reduce(0) { $0 + $1.nutrition.calories }
    }

    // Historical queries (for Progress charts)
    func totalCalories(for date: Date) -> Double {
        (allLogs[dateKey(for: date)] ?? []).reduce(0) { $0 + $1.nutrition.calories }
    }

    func dailyCalories(lastDays days: Int) -> [(date: Date, calories: Double)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<days).map { offset -> (date: Date, calories: Double) in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            return (date: date, calories: totalCalories(for: date))
        }.reversed()
    }

    struct DailyMacros {
        let date: Date
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
    }

    func weeklyMacros() -> [DailyMacros] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<7).map { offset -> DailyMacros in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let entries = allLogs[dateKey(for: date)] ?? []
            return DailyMacros(
                date:     date,
                calories: entries.reduce(0) { $0 + $1.nutrition.calories },
                protein:  entries.reduce(0) { $0 + $1.nutrition.protein },
                carbs:    entries.reduce(0) { $0 + $1.nutrition.carbs },
                fat:      entries.reduce(0) { $0 + $1.nutrition.fat }
            )
        }.reversed()
    }

    // MARK: - Mutations

    func add(_ item: FoodItem, grams: Double, meal: MealType) {
        let n = item.nutrition(grams: grams)
        let entry = LoggedFood(
            foodID:    item.id,
            foodName:  item.name,
            grams:     grams,
            meal:      meal,
            nutrition: n
        )
        todayEntries.append(entry)
        allLogs[todayKey] = todayEntries
        save()
        HealthKitService.shared.saveMealEntry(
            calories: n.calories, protein: n.protein, carbs: n.carbs, fat: n.fat)
    }

    func remove(_ entry: LoggedFood) {
        todayEntries.removeAll { $0.id == entry.id }
        allLogs[todayKey] = todayEntries
        save()
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(allLogs) {
            UserDefaults.standard.set(data, forKey: "sb_food_logs")
        }
        PhoneConnectivityManager.shared.syncToWatch()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: "sb_food_logs"),
           let decoded = try? JSONDecoder().decode([String: [LoggedFood]].self, from: data) {
            allLogs = decoded
        }
        todayEntries = allLogs[todayKey] ?? []
    }
}
