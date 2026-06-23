import Foundation
import CoreLocation

enum RunActivityType: String, Codable, CaseIterable {
    case run    = "Run"
    case walk   = "Walk"
    case hike   = "Hike"

    var icon: String {
        switch self {
        case .run:  return "figure.run"
        case .walk: return "figure.walk"
        case .hike: return "figure.hiking"
        }
    }

    // ≈ kcal per minute, used when computing burn for the saved workout.
    var kcalPerMinute: Double {
        switch self {
        case .run:  return 11
        case .walk: return 4
        case .hike: return 6
        }
    }
}

struct RunRoutePoint: Codable, Identifiable, Hashable {
    var id = UUID()
    let latitude:  Double
    let longitude: Double
    let timestamp: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct RunSession: Identifiable, Codable {
    let id: UUID
    var activity: RunActivityType
    var startedAt: Date
    var endedAt: Date?
    var route: [RunRoutePoint]
    /// Total moving time in seconds, excluding paused intervals.
    var movingSeconds: TimeInterval
    /// Total distance in meters along the GPS route.
    var distanceMeters: Double

    init(activity: RunActivityType = .run) {
        self.id = UUID()
        self.activity = activity
        self.startedAt = Date()
        self.endedAt = nil
        self.route = []
        self.movingSeconds = 0
        self.distanceMeters = 0
    }

    var distanceKm: Double { distanceMeters / 1000 }

    /// Average pace in seconds per kilometre (running convention).
    var paceSecondsPerKm: Double {
        guard distanceKm > 0 else { return 0 }
        return movingSeconds / distanceKm
    }

    var calories: Int {
        Int(movingSeconds / 60 * activity.kcalPerMinute)
    }
}
