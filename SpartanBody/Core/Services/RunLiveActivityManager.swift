import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

// Drives the run/walk/hike Live Activity (Dynamic Island + Lock Screen).
// Called from RunStore on start/pause/resume/finish/discard and on every
// location update so distance and pace stay in sync while the app is in
// background.
final class RunLiveActivityManager {
    static let shared = RunLiveActivityManager()
    private init() {}

    /// Leftover activities are being ended before this run's is requested.
    private var replacing = false

    func sync(session: RunSession?, isPaused: Bool) {
        guard #available(iOS 16.1, *) else { return }
        if let session {
            updateOrStart(session: session, isPaused: isPaused)
        } else {
            endAll()
        }
    }

    @available(iOS 16.1, *)
    private func updateOrStart(session: RunSession, isPaused: Bool) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = RunActivityAttributes.ContentState(
            distanceMeters:   session.distanceMeters,
            movingSeconds:    session.movingSeconds,
            paceSecondsPerKm: session.paceSecondsPerKm,
            calories:         session.calories,
            isPaused:         isPaused,
            clockStart:       isPaused ? nil : Date().addingTimeInterval(-session.movingSeconds)
        )

        // Only this run's own activity is reused. Taking whatever came first
        // revived one left over from an earlier run or a crash, with its old
        // start time and type on the Lock Screen.
        let all = Activity<RunActivityAttributes>.activities
        if let current = all.first(where: { Self.belongs($0.attributes, to: session) }) {
            Task { await current.update(using: state) }
            for stale in all where stale.id != current.id {
                Task { await stale.end(dismissalPolicy: .immediate) }
            }
            return
        }
        guard !replacing else { return }
        replacing = true
        let attributes = RunActivityAttributes(
            activityRaw: session.activity.rawValue,
            startedAt:   session.startedAt
        )
        Task { @MainActor in
            // End the leftovers first so two never show at once.
            for stale in all { await stale.end(dismissalPolicy: .immediate) }
            _ = try? Activity.request(attributes: attributes, contentState: state)
            self.replacing = false
        }
    }

    @available(iOS 16.1, *)
    private static func belongs(_ attributes: RunActivityAttributes, to session: RunSession) -> Bool {
        attributes.activityRaw == session.activity.rawValue
            && abs(attributes.startedAt.timeIntervalSince(session.startedAt)) < 1
    }

    @available(iOS 16.1, *)
    private func endAll() {
        Task {
            for activity in Activity<RunActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
}
