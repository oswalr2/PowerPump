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

        if let activity = Activity<WorkoutActivityAttributes>.activities.first {
            Task { await activity.update(using: state) }
        } else {
            let attributes = WorkoutActivityAttributes(
                workoutName: session.name,
                startedAt:   session.startedAt
            )
            _ = try? Activity.request(attributes: attributes, contentState: state)
        }
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
