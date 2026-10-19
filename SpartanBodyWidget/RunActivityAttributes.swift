import Foundation
#if canImport(ActivityKit)
import ActivityKit

// Shared between the app (RunLiveActivityManager updates it) and the widget
// extension (RunLiveActivity renders the Dynamic Island / Lock Screen).
@available(iOS 16.1, *)
struct RunActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var distanceMeters: Double
        var movingSeconds: TimeInterval
        /// Seconds per kilometre. 0 while distance is still negligible.
        var paceSecondsPerKm: Double
        var calories: Int
        var isPaused: Bool
        /// When the clock would have read 0:00 counting only moving time.
        /// Lets the Lock Screen tick by itself between GPS fixes; nil while
        /// paused, when the time shown stays still.
        var clockStart: Date? = nil
    }

    /// "Run" / "Walk" / "Hike" — matches RunActivityType.rawValue.
    var activityRaw: String
    var startedAt: Date
}
#endif
