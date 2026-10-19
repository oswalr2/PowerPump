import Foundation
import CoreLocation

enum RunActivityType: String, Codable, CaseIterable {
    case run    = "Run"
    case walk   = "Walk"
    case hike   = "Hike"

    /// Metres per second above which a jump between two GPS fixes is a
    /// glitch rather than movement (a sprinter peaks around 12 m/s).
    var maxPlausibleSpeed: Double {
        switch self {
        case .run:          return 12
        case .walk, .hike:  return 7
        }
    }

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
    /// 0 (shown as "--") until 100 m are covered: over a few metres the
    /// average is meaningless (e.g. 30 s for 5 m reads as 100'/km).
    var paceSecondsPerKm: Double {
        guard distanceMeters >= 100 else { return 0 }
        return movingSeconds / distanceKm
    }

    var calories: Int {
        Int(movingSeconds / 60 * activity.kcalPerMinute)
    }
}
