import Foundation

final class FoodLogStore: ObservableObject {
    static let shared = FoodLogStore()

    @Published private(set) var todayEntries: [LoggedFood] = []

    private var allLogs: [String: [LoggedFood]] = [:]
    private var loadedDayKey = ""

    private init() {
        load()
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged, object: nil, queue: .main
        ) { [weak self] _ in
            self?.rolloverIfNeeded()
        }
    }

    // MARK: - Today key

    private var todayKey: String { dateKey(for: .now) }

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func dateKey(for date: Date) -> String {
        Self.keyFormatter.string(from: date)
    }

    // Reload today's entries when the calendar day changes while the app is alive,
    // so yesterday's meals don't leak into the new day.
    private func rolloverIfNeeded() {
        guard loadedDayKey != todayKey else { return }
        loadedDayKey = todayKey
        todayEntries = allLogs[todayKey] ?? []
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
        rolloverIfNeeded()
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
        rolloverIfNeeded()
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
        loadedDayKey = todayKey
        todayEntries = allLogs[todayKey] ?? []
    }
}
