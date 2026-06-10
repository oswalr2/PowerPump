import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    // Workout
    @Published var workoutEnabled: Bool       { didSet { save(); scheduleWorkout() } }
    @Published var workoutTime: Date          { didSet { save(); scheduleWorkout() } }

    // Hydration
    @Published var hydrationEnabled: Bool     { didSet { save(); scheduleHydration() } }
    @Published var hydrationEveryHours: Int   { didSet { save(); scheduleHydration() } }

    // Meals
    @Published var mealsEnabled: Bool         { didSet { save(); scheduleMeals() } }
    @Published var breakfastTime: Date        { didSet { save(); scheduleMeals() } }
    @Published var lunchTime: Date            { didSet { save(); scheduleMeals() } }
    @Published var dinnerTime: Date           { didSet { save(); scheduleMeals() } }

    private let ud = UserDefaults.standard

    private init() {
        workoutEnabled     = ud.bool(forKey: "nb_workout_on")
        hydrationEnabled   = ud.bool(forKey: "nb_hydration_on")
        mealsEnabled       = ud.bool(forKey: "nb_meals_on")
        hydrationEveryHours = ud.integer(forKey: "nb_hydration_hours").nonZero(default: 2)

        workoutTime   = ud.date("nb_workout_time")   ?? Self.time(hour: 7,  minute: 0)
        breakfastTime = ud.date("nb_breakfast_time") ?? Self.time(hour: 8,  minute: 0)
        lunchTime     = ud.date("nb_lunch_time")     ?? Self.time(hour: 12, minute: 30)
        dinnerTime    = ud.date("nb_dinner_time")    ?? Self.time(hour: 19, minute: 0)

        checkStatus()
    }

    // MARK: - Permission

    func requestPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted { self.scheduleAll() }
                    completion(granted)
                }
            }
    }

    func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule helpers

    private func scheduleAll() {
        scheduleWorkout()
        scheduleHydration()
        scheduleMeals()
    }

    private func scheduleWorkout() {
        cancel(ids: ["sb.workout"])
        guard workoutEnabled, isAuthorized else { return }
        schedule(
            id: "sb.workout",
            title: "Time to train 💪",
            body: "Your workout is waiting. Let's get it done!",
            time: workoutTime
        )
    }

    private func scheduleHydration() {
        let ids = (0..<12).map { "sb.hydration.\($0)" }
        cancel(ids: ids)
        guard hydrationEnabled, isAuthorized else { return }

        var hour = 8
        var index = 0
        while hour <= 20 && index < 12 {
            var comps = DateComponents()
            comps.hour = hour
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            add(id: "sb.hydration.\(index)",
                title: "Stay hydrated 💧",
                body: "Have you had some water lately? Your body will thank you.",
                trigger: trigger)
            hour += hydrationEveryHours
            index += 1
        }
    }

    private func scheduleMeals() {
        cancel(ids: ["sb.meal.breakfast", "sb.meal.lunch", "sb.meal.dinner"])
        guard mealsEnabled, isAuthorized else { return }

        let meals: [(id: String, title: String, body: String, time: Date)] = [
            ("sb.meal.breakfast", "Good morning! 🌅", "Don't forget to log your breakfast and start the day right.", breakfastTime),
            ("sb.meal.lunch",     "Lunchtime! 🥗",    "Log your lunch to stay on top of your calorie goal.",         lunchTime),
            ("sb.meal.dinner",    "Dinner time! 🍽",  "Log your dinner and finish the day strong.",                  dinnerTime),
        ]
        for meal in meals {
            schedule(id: meal.id, title: meal.title, body: meal.body, time: meal.time)
        }
    }

    // MARK: - UNUserNotificationCenter wrappers

    private func schedule(id: String, title: String, body: String, time: Date) {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.hour   = cal.component(.hour,   from: time)
        comps.minute = cal.component(.minute, from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        add(id: id, title: title, body: body, trigger: trigger)
    }

    private func add(id: String, title: String, body: String, trigger: UNNotificationTrigger) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancel(ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Persistence

    private func save() {
        ud.set(workoutEnabled,       forKey: "nb_workout_on")
        ud.set(hydrationEnabled,     forKey: "nb_hydration_on")
        ud.set(mealsEnabled,         forKey: "nb_meals_on")
        ud.set(hydrationEveryHours,  forKey: "nb_hydration_hours")
        ud.setDate(workoutTime,      forKey: "nb_workout_time")
        ud.setDate(breakfastTime,    forKey: "nb_breakfast_time")
        ud.setDate(lunchTime,        forKey: "nb_lunch_time")
        ud.setDate(dinnerTime,       forKey: "nb_dinner_time")
    }

    private static func time(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now
    }
}

// MARK: - UserDefaults helpers

private extension UserDefaults {
    func date(_ key: String) -> Date? {
        object(forKey: key) as? Date
    }
    func setDate(_ date: Date, forKey key: String) {
        set(date, forKey: key)
    }
}

private extension Int {
    func nonZero(default val: Int) -> Int { self == 0 ? val : self }
}
