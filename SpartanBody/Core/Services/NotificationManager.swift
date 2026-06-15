import Foundation
import UserNotifications

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    // Toggling any reminder on auto-requests permission, so the user doesn't
    // have to find a hidden button — the toggle itself triggers the system prompt.
    private func ensureAuthorized(then onAuthorized: @escaping () -> Void) {
        if isAuthorized { onAuthorized(); return }
        requestPermission { granted in
            if granted { onAuthorized() }
        }
    }

    // Workout
    @Published var workoutEnabled: Bool       { didSet { save(); if workoutEnabled { ensureAuthorized { self.scheduleWorkout() } } else { scheduleWorkout() } } }
    @Published var workoutTime: Date          { didSet { save(); scheduleWorkout() } }

    // Hydration
    @Published var hydrationEnabled: Bool     { didSet { save(); if hydrationEnabled { ensureAuthorized { self.scheduleHydration() } } else { scheduleHydration() } } }
    @Published var hydrationEveryHours: Int   { didSet { save(); scheduleHydration() } }

    // Meals
    @Published var mealsEnabled: Bool         { didSet { save(); if mealsEnabled { ensureAuthorized { self.scheduleMeals() } } else { scheduleMeals() } } }
    @Published var breakfastTime: Date        { didSet { save(); scheduleMeals() } }
    @Published var lunchTime: Date            { didSet { save(); scheduleMeals() } }
    @Published var dinnerTime: Date           { didSet { save(); scheduleMeals() } }

    // Sleep
    @Published var sleepEnabled: Bool         { didSet { save(); if sleepEnabled { ensureAuthorized { self.scheduleSleep() } } else { scheduleSleep() } } }
    @Published var sleepTime: Date            { didSet { save(); scheduleSleep() } }

    private let ud = UserDefaults.standard

    private override init() {
        workoutEnabled     = ud.bool(forKey: "nb_workout_on")
        hydrationEnabled   = ud.bool(forKey: "nb_hydration_on")
        mealsEnabled       = ud.bool(forKey: "nb_meals_on")
        sleepEnabled       = ud.bool(forKey: "nb_sleep_on")
        hydrationEveryHours = ud.integer(forKey: "nb_hydration_hours").nonZero(default: 2)

        workoutTime   = ud.date("nb_workout_time")   ?? Self.time(hour: 7,  minute: 0)
        breakfastTime = ud.date("nb_breakfast_time") ?? Self.time(hour: 8,  minute: 0)
        lunchTime     = ud.date("nb_lunch_time")     ?? Self.time(hour: 12, minute: 30)
        dinnerTime    = ud.date("nb_dinner_time")    ?? Self.time(hour: 19, minute: 0)
        sleepTime     = ud.date("nb_sleep_time")     ?? Self.time(hour: 22, minute: 30)

        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkStatus()
    }

    // Show banners even when the app is in the foreground (otherwise iOS
    // delivers them silently, which looks like "the reminders don't work").
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - Permission

    func requestPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    // Reschedule whatever toggles are currently on, now that
                    // we actually have permission.
                    if granted { self.scheduleAll() }
                    completion(granted)
                }
            }
    }

    // Re-syncs reminders whenever the app comes back to foreground — covers the
    // case where the user changes permission from iOS Settings while the app is
    // backgrounded.
    func refreshIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authorized = settings.authorizationStatus == .authorized
            DispatchQueue.main.async {
                let wasAuthorized = self.isAuthorized
                self.isAuthorized = authorized
                if authorized && !wasAuthorized { self.scheduleAll() }
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
        scheduleSleep()
    }

    private func scheduleWorkout() {
        cancel(ids: ["sb.workout"])
        guard workoutEnabled, isAuthorized else { return }
        schedule(
            id: "sb.workout",
            title: NSLocalizedString("notif.workout.title", comment: ""),
            body:  NSLocalizedString("notif.workout.body",  comment: ""),
            time: workoutTime
        )
    }

    private func scheduleSleep() {
        cancel(ids: ["sb.sleep"])
        guard sleepEnabled, isAuthorized else { return }
        schedule(
            id: "sb.sleep",
            title: NSLocalizedString("notif.sleep.title", comment: ""),
            body:  NSLocalizedString("notif.sleep.body",  comment: ""),
            time: sleepTime
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
                title: NSLocalizedString("notif.water.title", comment: ""),
                body:  NSLocalizedString("notif.water.body",  comment: ""),
                trigger: trigger)
            hour += hydrationEveryHours
            index += 1
        }
    }

    private func scheduleMeals() {
        cancel(ids: ["sb.meal.breakfast", "sb.meal.lunch", "sb.meal.dinner"])
        guard mealsEnabled, isAuthorized else { return }

        let meals: [(id: String, title: String, body: String, time: Date)] = [
            ("sb.meal.breakfast",
             NSLocalizedString("notif.breakfast.title", comment: ""),
             NSLocalizedString("notif.breakfast.body",  comment: ""), breakfastTime),
            ("sb.meal.lunch",
             NSLocalizedString("notif.lunch.title", comment: ""),
             NSLocalizedString("notif.lunch.body",  comment: ""), lunchTime),
            ("sb.meal.dinner",
             NSLocalizedString("notif.dinner.title", comment: ""),
             NSLocalizedString("notif.dinner.body",  comment: ""), dinnerTime),
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
        ud.set(sleepEnabled,         forKey: "nb_sleep_on")
        ud.set(hydrationEveryHours,  forKey: "nb_hydration_hours")
        ud.setDate(workoutTime,      forKey: "nb_workout_time")
        ud.setDate(breakfastTime,    forKey: "nb_breakfast_time")
        ud.setDate(lunchTime,        forKey: "nb_lunch_time")
        ud.setDate(dinnerTime,       forKey: "nb_dinner_time")
        ud.setDate(sleepTime,        forKey: "nb_sleep_time")
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
