import Foundation
import CoreLocation
import Combine

@MainActor
final class RunStore: ObservableObject {
    static let shared = RunStore()

    @Published private(set) var activeSession: RunSession?
    @Published private(set) var isPaused = false
    @Published private(set) var history: [RunSession] = []

    private let location = LocationService.shared
    private var subscriptions: Set<AnyCancellable> = []
    private var ticker: Timer?
    private var lastTick: Date?

    private init() {
        loadHistory()
        location.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loc in self?.handle(location: loc) }
            .store(in: &subscriptions)
    }

    // MARK: - Lifecycle

    func start(activity: RunActivityType) {
        guard activeSession == nil else { return }
        var session = RunSession(activity: activity)
        session.startedAt = .now
        activeSession = session
        isPaused = false
        lastTick = .now
        location.startTracking()
        startTicker()
    }

    func pause() {
        guard activeSession != nil, !isPaused else { return }
        isPaused = true
        flushTick()
        stopTicker()
    }

    func resume() {
        guard activeSession != nil, isPaused else { return }
        isPaused = false
        lastTick = .now
        startTicker()
    }

    func finish() -> RunSession? {
        guard var session = activeSession else { return nil }
        flushTick()
        stopTicker()
        location.stopTracking()
        session.endedAt = .now
        // Persist + sync to Health, but only if we got somewhere meaningful.
        // A 5-second misfire shouldn't pollute history.
        if session.movingSeconds > 10 && session.distanceMeters > 20 {
            history.insert(session, at: 0)
            saveHistory()
            HealthKitService.shared.saveRun(session)
        }
        activeSession = nil
        isPaused = false
        return session
    }

    func discard() {
        flushTick()
        stopTicker()
        location.stopTracking()
        activeSession = nil
        isPaused = false
    }

    // MARK: - Ticker (moving time)

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.flushTick() }
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func flushTick() {
        guard !isPaused, var session = activeSession, let last = lastTick else { return }
        let now = Date()
        session.movingSeconds += now.timeIntervalSince(last)
        activeSession = session
        lastTick = now
    }

    // MARK: - Location handling

    private func handle(location new: CLLocation) {
        guard !isPaused, var session = activeSession else { return }

        let point = RunRoutePoint(
            latitude:  new.coordinate.latitude,
            longitude: new.coordinate.longitude,
            timestamp: new.timestamp
        )

        if let last = session.route.last {
            let lastLoc = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let delta = new.distance(from: lastLoc)
            // Drop tiny GPS jitter (< 3 m) so a stationary user doesn't
            // accumulate phantom distance, but accept anything plausibly real.
            if delta > 3 && delta < 200 {
                session.distanceMeters += delta
            } else if delta >= 200 {
                // 200m+ jump is almost certainly a GPS glitch; skip it.
                return
            }
        }

        session.route.append(point)
        activeSession = session
    }

    // MARK: - History persistence

    private let historyKey = "sb_run_history"

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([RunSession].self, from: data) else { return }
        history = decoded
    }

    func delete(_ session: RunSession) {
        history.removeAll { $0.id == session.id }
        saveHistory()
    }
}
