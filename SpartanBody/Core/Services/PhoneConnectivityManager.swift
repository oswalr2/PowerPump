import Foundation
import WatchConnectivity
import WidgetKit

final class PhoneConnectivityManager: NSObject {
    static let shared = PhoneConnectivityManager()

    private let groupID = "group.com.oswaldo.spartanbody"

    override private init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // Call this whenever any data changes (food log, workout, steps, water)
    func syncToWatch() {
        Task { @MainActor in
            let ctx = self.buildContext()
            self.writeToAppGroup(ctx)
            WidgetCenter.shared.reloadAllTimelines()
            guard WCSession.default.activationState == .activated,
                  WCSession.default.isWatchAppInstalled else { return }
            try? WCSession.default.updateApplicationContext(ctx)
        }
    }

    // MARK: - Context builder

    @MainActor
    private func buildContext() -> [String: Any] {
        let foodLog  = FoodLogStore.shared
        let workouts = WorkoutStore.shared
        let health   = HealthKitService.shared
        let profile  = UserProfile.shared

        var ctx: [String: Any] = [
            "calories":        Int(foodLog.todayCalories),
            "calorieTarget":   profile.dailyCalorieTarget,
            "protein":         foodLog.todayProtein,
            "proteinTarget":   profile.dailyProteinTarget,
            "steps":           health.stepsToday,
            "streak":          workouts.currentStreak,
            "hasActiveWorkout": workouts.activeSession != nil,
        ]

        if let session = workouts.activeSession {
            ctx["workoutName"]    = session.name
            ctx["currentExercise"] = session.exercises.first
                .flatMap { ex -> String? in ex.exerciseID } ?? ""
        }

        return ctx
    }

    // MARK: - App Groups (for complications)

    private func writeToAppGroup(_ ctx: [String: Any]) {
        let defaults = UserDefaults(suiteName: groupID)
        defaults?.set(ctx["calories"]      as? Int ?? 0,    forKey: "watch_calories")
        defaults?.set(ctx["calorieTarget"] as? Int ?? 2000, forKey: "watch_calorieTarget")
        defaults?.set(ctx["streak"]        as? Int ?? 0,    forKey: "watch_streak")
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        if state == .activated { syncToWatch() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    // Watch requests a context refresh
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        if message["request"] as? String == "context" {
            Task { @MainActor in replyHandler(self.buildContext()) }
        }
    }

    // Watch finished a workout (live message)
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        handleWatchPayload(message)
    }

    // Watch finished a workout while the phone was unreachable (queued transfer)
    func session(_ session: WCSession,
                 didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleWatchPayload(userInfo)
    }

    private func handleWatchPayload(_ payload: [String: Any]) {
        guard payload["action"] as? String == "workoutFinished" else { return }
        let duration = payload["duration"] as? Int ?? 0
        let sets     = payload["sets"]     as? Int ?? 0
        DispatchQueue.main.async {
            WorkoutStore.shared.recordWatchWorkout(durationSeconds: duration, sets: sets)
        }
    }
}
