import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

// Drives the workout Live Activity (Dynamic Island + Lock Screen).
// Called from WorkoutStore on every active-session change and from
// ActiveWorkoutView when the rest timer starts/stops.
final class WorkoutLiveActivityManager {
    static let shared = WorkoutLiveActivityManager()
    private init() {}

    private var restEndDate: Date?
    /// Leftover activities are being ended before this workout's is requested.
    private var replacing = false

    func sync(session: WorkoutSession?) {
        guard #available(iOS 16.1, *) else { return }
        if let session {
            updateOrStart(session: session)
        } else {
            restEndDate = nil
            endAll()
        }
    }

    func startRest(seconds: Int, session: WorkoutSession?) {
        restEndDate = Date().addingTimeInterval(Double(seconds))
        sync(session: session)
    }

    func endRest(session: WorkoutSession?) {
        restEndDate = nil
        sync(session: session)
    }

    // MARK: - ActivityKit

    @available(iOS 16.1, *)
    private func updateOrStart(session: WorkoutSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let allSets = session.exercises.flatMap(\.sets)
        let state = WorkoutActivityAttributes.ContentState(
            setsDone:      allSets.filter(\.completed).count,
            totalSets:     allSets.count,
            exerciseCount: session.exercises.count,
            restEndDate:   restEndDate
        )

        // Only this workout's own activity is reused, never one left over
        // from an earlier workout or a crash.
        let all = Activity<WorkoutActivityAttributes>.activities
        if let current = all.first(where: { Self.belongs($0.attributes, to: session) }) {
            Task { await current.update(using: state) }
            for stale in all where stale.id != current.id {
                Task { await stale.end(dismissalPolicy: .immediate) }
            }
            return
        }
        guard !replacing else { return }
        replacing = true
        let attributes = WorkoutActivityAttributes(
            workoutName: session.name,
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
    private static func belongs(_ attributes: WorkoutActivityAttributes, to session: WorkoutSession) -> Bool {
        attributes.workoutName == session.name
            && abs(attributes.startedAt.timeIntervalSince(session.startedAt)) < 1
    }

    @available(iOS 16.1, *)
    private func endAll() {
        Task {
            for activity in Activity<WorkoutActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
}
