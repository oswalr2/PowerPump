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
    /// When the active session started. Used to compute moving time from a
    /// reference Date instead of timer ticks, so background freezes don't
    /// cause the clock to drift.
    private var sessionStartedAt: Date?
    /// Accumulated paused duration in seconds.
    private var pausedAccum: TimeInterval = 0
    /// When the current pause began (nil if not paused).
    private var pauseStartedAt: Date?

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
        sessionStartedAt = session.startedAt
        pausedAccum = 0
        pauseStartedAt = nil
        activeSession = session
        isPaused = false
        location.startTracking()
        startTicker()
    }

    func pause() {
        guard activeSession != nil, !isPaused else { return }
        syncMovingSeconds()           // commit elapsed time before freezing the clock
        isPaused = true
        pauseStartedAt = .now
    }

    func resume() {
        guard activeSession != nil, isPaused else { return }
        if let pStart = pauseStartedAt {
            pausedAccum += Date().timeIntervalSince(pStart)
        }
        pauseStartedAt = nil
        isPaused = false
    }

    func finish() -> RunSession? {
        guard var session = activeSession else { return nil }
        syncMovingSeconds()
        stopTicker()
        location.stopTracking()
        session.endedAt = .now
        // Snapshot the latest moving time and route into the returned struct.
        session.movingSeconds = activeSession?.movingSeconds ?? session.movingSeconds
        // Persist + sync to Health, but only if we got somewhere meaningful.
        // A 5-second misfire shouldn't pollute history.
        if session.movingSeconds > 10 && session.distanceMeters > 20 {
            history.insert(session, at: 0)
            saveHistory()
            HealthKitService.shared.saveRun(session)
        }
        activeSession = nil
        isPaused = false
        sessionStartedAt = nil
        pauseStartedAt = nil
        pausedAccum = 0
        return session
    }

    func discard() {
        stopTicker()
        location.stopTracking()
        activeSession = nil
        isPaused = false
        sessionStartedAt = nil
        pauseStartedAt = nil
        pausedAccum = 0
    }

    // MARK: - Time tracking (date-based, survives background)

    /// Recomputes movingSeconds from the absolute timestamps. This is correct
    /// even after iOS suspended the app for minutes: when we come back, the
    /// elapsed time is whatever Date()-startedAt-pausedAccum yields.
    private func syncMovingSeconds() {
        guard var session = activeSession, let start = sessionStartedAt else { return }
        let now = Date()
        var pause = pausedAccum
        if isPaused, let pStart = pauseStartedAt {
            pause += now.timeIntervalSince(pStart)
        }
        session.movingSeconds = max(0, now.timeIntervalSince(start) - pause)
        activeSession = session
    }

    private func startTicker() {
        ticker?.invalidate()
        // The timer keeps the UI fresh while in foreground; in background iOS
        // suspends it but syncMovingSeconds() will catch up the next time a
        // location update or willEnterForeground arrives.
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.syncMovingSeconds() }
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    // MARK: - Location handling

    private func handle(location new: CLLocation) {
        guard !isPaused, var session = activeSession else { return }

        // Always update moving time on a location event so the clock keeps
        // advancing even when the foreground Timer is suspended.
        syncMovingSeconds()
        if let refreshed = activeSession { session = refreshed }

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
