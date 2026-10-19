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
    let latitude:  Double
    let longitude: Double
    let timestamp: Date

    /// Derived, not stored: a stored UUID per GPS fix was a third of the
    /// size of every saved route. Older saves still carry it; it's ignored.
    var id: String { "\(timestamp.timeIntervalSinceReferenceDate):\(latitude):\(longitude)" }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension Array where Element == RunRoutePoint {
    /// The route with the points that add nothing to the drawn line removed
    /// (Douglas-Peucker, `tolerance` in metres). Saved routes are only drawn
    /// on a map; distance and pace were measured on the full route.
    func simplified(tolerance: Double = 3) -> [RunRoutePoint] {
        guard count > 2 else { return self }
        // Metres on a local flat projection; plenty accurate for a run.
        let lat0 = self[0].latitude * .pi / 180
        let xy = map { p -> (x: Double, y: Double) in
            (p.longitude * 111_320 * cos(lat0), p.latitude * 110_540)
        }
        var keep = [Bool](repeating: false, count: count)
        keep[0] = true
        keep[count - 1] = true
        var stack = [(0, count - 1)]
        while let (a, b) = stack.popLast() {
            guard b > a + 1 else { continue }
            let (ax, ay) = xy[a], (bx, by) = xy[b]
            let dx = bx - ax, dy = by - ay
            let len = (dx * dx + dy * dy).squareRoot()
            var farthest = a, maxDist = 0.0
            for i in (a + 1)..<b {
                let (px, py) = xy[i]
                let d = len > 0
                    ? abs(dy * px - dx * py + bx * ay - by * ax) / len
                    : ((px - ax) * (px - ax) + (py - ay) * (py - ay)).squareRoot()
                if d > maxDist { maxDist = d; farthest = i }
            }
            if maxDist > tolerance {
                keep[farthest] = true
                stack.append((a, farthest))
                stack.append((farthest, b))
            }
        }
        return indices.filter { keep[$0] }.map { self[$0] }
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
