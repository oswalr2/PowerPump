import Foundation
import MapKit
import CoreLocation

// MARK: - Models

/// A single turn instruction along a generated route, tagged with where it
/// happens so we can fire the voice cue when the runner gets close.
struct RouteManeuver: Identifiable {
    let id = UUID()
    let instruction: String                 // localized by MapKit to device locale
    let coordinate: CLLocationCoordinate2D   // where the turn happens
    let distanceFromStart: Double            // metres along the route
}

/// A ready-to-run loop the AI planner produced: the full path plus the
/// A (start) / B (halfway) / C (finish) stage markers and turn-by-turn steps.
struct PlannedRoute: Identifiable {
    let id = UUID()
    let coordinates: [CLLocationCoordinate2D]
    let maneuvers: [RouteManeuver]
    let totalDistance: Double                // metres

    var startCoord: CLLocationCoordinate2D { coordinates.first ?? kCLLocationCoordinate2DInvalid }
    var endCoord:   CLLocationCoordinate2D { coordinates.last  ?? kCLLocationCoordinate2DInvalid }

    /// Coordinate at ~50 % of the route length — the "Stage B" pin.
    var midCoord: CLLocationCoordinate2D {
        guard coordinates.count > 1 else { return startCoord }
        let target = totalDistance / 2
        var cum = 0.0
        for i in 1..<coordinates.count {
            let a = CLLocation(latitude: coordinates[i-1].latitude, longitude: coordinates[i-1].longitude)
            let b = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let d = a.distance(from: b)
            if cum + d >= target { return coordinates[i] }
            cum += d
        }
        return coordinates[coordinates.count / 2]
    }

    var distanceKm: Double { totalDistance / 1000 }
}

enum RouteGenError: Error { case noRoute, noLocation }

// MARK: - Generator

/// Builds a circular walking/running loop from the user's current position
/// using Apple Maps directions (MKDirections). Free and unlimited — no AI
/// API cost. Places waypoints around a circle and stitches the legs, scaling
/// the radius across a few attempts until the total length lands near the
/// requested distance.
@MainActor
final class RouteGenerator: ObservableObject {
    static let shared = RouteGenerator()

    @Published var isGenerating = false

    private init() {}

    func generateLoop(from start: CLLocationCoordinate2D,
                      targetMeters: Double,
                      seed: Int) async throws -> PlannedRoute {
        isGenerating = true
        defer { isGenerating = false }

        let waypointCount = 3
        // Rotate the loop per seed so "Regenerate" gives a genuinely different
        // path each time.
        let startBearing = Double((seed * 47) % 360) + 15
        // First radius guess: road routing inflates the straight-line polygon
        // by ~1.3×, and the 3-waypoint loop perimeter ≈ 7·r straight-line.
        var radius = targetMeters / 7.0

        var best: PlannedRoute?

        for _ in 0..<3 {
            let waypoints = (0..<waypointCount).map { i -> CLLocationCoordinate2D in
                let bearing = startBearing + Double(i) * (360.0 / Double(waypointCount))
                return Self.destination(from: start, bearingDegrees: bearing, distanceMeters: radius)
            }
            let legPoints = [start] + waypoints + [start]

            var coords: [CLLocationCoordinate2D] = []
            var maneuvers: [RouteManeuver] = []
            var cumulative = 0.0

            for i in 0..<(legPoints.count - 1) {
                let mkRoute = try await Self.walkingRoute(from: legPoints[i], to: legPoints[i + 1])
                let legCoords = mkRoute.polyline.coordinates

                for step in mkRoute.steps {
                    let text = step.instructions.trimmingCharacters(in: .whitespaces)
                    if !text.isEmpty, let c = step.polyline.coordinates.first {
                        maneuvers.append(RouteManeuver(instruction: text,
                                                       coordinate: c,
                                                       distanceFromStart: cumulative))
                    }
                    cumulative += step.distance
                }

                if coords.isEmpty {
                    coords.append(contentsOf: legCoords)
                } else {
                    coords.append(contentsOf: legCoords.dropFirst())
                }
                // Small breather so MapKit doesn't throttle the burst of requests.
                try? await Task.sleep(nanoseconds: 120_000_000)
            }

            let total = Self.polylineLength(coords)
            let route = PlannedRoute(coordinates: coords, maneuvers: maneuvers, totalDistance: total)
            best = route

            // Close enough? Stop early.
            if abs(total - targetMeters) / targetMeters < 0.12 { break }
            // Otherwise scale the radius toward the target and try again.
            radius *= max(0.4, min(2.2, targetMeters / max(total, 1)))
        }

        guard let result = best, result.coordinates.count >= 2 else { throw RouteGenError.noRoute }
        return result
    }

    // MARK: - MapKit helpers

    private static func walkingRoute(from: CLLocationCoordinate2D,
                                     to: CLLocationCoordinate2D) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .walking
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        guard let route = response.routes.first else { throw RouteGenError.noRoute }
        return route
    }

    // MARK: - Geometry

    /// Point at a bearing + distance from an origin (spherical earth).
    static func destination(from origin: CLLocationCoordinate2D,
                            bearingDegrees: Double,
                            distanceMeters: Double) -> CLLocationCoordinate2D {
        let R = 6_371_000.0
        let bearing = bearingDegrees * .pi / 180
        let lat1 = origin.latitude * .pi / 180
        let lon1 = origin.longitude * .pi / 180
        let dr = distanceMeters / R
        let lat2 = asin(sin(lat1) * cos(dr) + cos(lat1) * sin(dr) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(dr) * cos(lat1),
                                cos(dr) - sin(lat1) * sin(lat2))
        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi,
                                      longitude: lon2 * 180 / .pi)
    }

    static func polylineLength(_ coords: [CLLocationCoordinate2D]) -> Double {
        guard coords.count > 1 else { return 0 }
        var total = 0.0
        for i in 1..<coords.count {
            let a = CLLocation(latitude: coords[i-1].latitude, longitude: coords[i-1].longitude)
            let b = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
            total += a.distance(from: b)
        }
        return total
    }
}

// MARK: - MKPolyline coordinate extraction

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
