import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // Dashboard data (received from iPhone)
    @Published var calories: Int = 0
    @Published var calorieTarget: Int = 2000
    @Published var protein: Double = 0
    @Published var proteinTarget: Int = 150
    @Published var steps: Int = 0
    @Published var streak: Int = 0

    // Workout data (received from iPhone)
    @Published var hasActiveWorkout: Bool = false
    @Published var activeWorkoutName: String = ""
    @Published var currentExercise: String = ""

    override private init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func requestContextFromPhone() async {
        guard WCSession.default.activationState == .activated else { return }
        WCSession.default.sendMessage(["request": "context"], replyHandler: { [weak self] reply in
            self?.applyContext(reply)
        }, errorHandler: nil)
    }

    func sendWorkoutFinished(duration: Int, sets: Int) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage([
            "action":   "workoutFinished",
            "duration": duration,
            "sets":     sets
        ], replyHandler: nil, errorHandler: nil)
    }

    private func applyContext(_ ctx: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.calories          = ctx["calories"]        as? Int    ?? self.calories
            self.calorieTarget     = ctx["calorieTarget"]   as? Int    ?? self.calorieTarget
            self.protein           = ctx["protein"]         as? Double ?? self.protein
            self.proteinTarget     = ctx["proteinTarget"]   as? Int    ?? self.proteinTarget
            self.steps             = ctx["steps"]           as? Int    ?? self.steps
            self.streak            = ctx["streak"]          as? Int    ?? self.streak
            self.hasActiveWorkout  = ctx["hasActiveWorkout"] as? Bool  ?? false
            self.activeWorkoutName = ctx["workoutName"]     as? String ?? ""
            self.currentExercise   = ctx["currentExercise"] as? String ?? ""
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {}

    func session(_ session: WCSession,
                 didReceiveApplicationContext context: [String: Any]) {
        applyContext(context)
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        applyContext(message)
    }
}
