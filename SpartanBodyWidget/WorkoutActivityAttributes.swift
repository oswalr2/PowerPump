import Foundation
#if canImport(ActivityKit)
import ActivityKit

// Shared between the app (starts/updates the activity) and the widget
// extension (renders it in the Dynamic Island and on the Lock Screen).
@available(iOS 16.1, *)
struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var setsDone: Int
        var totalSets: Int
        var exerciseCount: Int
        var restEndDate: Date?
    }

    var workoutName: String
    var startedAt: Date
}
#endif
