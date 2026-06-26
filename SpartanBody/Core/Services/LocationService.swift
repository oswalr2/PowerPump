import Foundation
import CoreLocation
import Combine

/// Wraps CLLocationManager and publishes a stream of locations while a run is
/// active.  RunStore subscribes to this to extend the route in real time.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    @Published var isTracking = false

    /// Each new location while tracking is published here.
    let locationPublisher = PassthroughSubject<CLLocation, Never>()

    private let manager = CLLocationManager()

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5      // metres between updates
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
        // Only enable background updates if the bundle actually declares
        // "location" in UIBackgroundModes — otherwise CoreLocation throws
        // an NSException and the whole app crashes the moment we try to
        // start a session.  Until we wire the Background Modes capability
        // through Xcode UI, foreground-only tracking is the safe default.
        let bgModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
        if bgModes?.contains("location") == true {
            manager.allowsBackgroundLocationUpdates = true
            if #available(iOS 11.0, *) {
                manager.showsBackgroundLocationIndicator = true
            }
        }
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse
           || authorizationStatus == .authorizedAlways else {
            requestAuthorization()
            return
        }
        manager.startUpdatingLocation()
        isTracking = true
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        isTracking = false
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        // Ignore wildly inaccurate fixes (e.g. cold-start estimates) so the
        // route doesn't zig-zag across the city.
        guard loc.horizontalAccuracy > 0, loc.horizontalAccuracy < 35 else { return }
        DispatchQueue.main.async {
            self.lastLocation = loc
            self.locationPublisher.send(loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Surface auth-style errors silently; transient kCLErrorLocationUnknown
        // happens often early in a run and is not actionable.
    }
}
