import Foundation
import Combine

/// Persisted record of a finished sport session. Sport-specific so it can
/// live separately from running's RunStore (different fields, but same idea).
struct SportSessionRecord: Codable, Identifiable {
    var id = UUID()
    let sportId: String         // SportActivity.id
    let startedAt: Date
    let endedAt: Date
    /// Seconds the session was actually active (excludes pauses).
    let movingSeconds: TimeInterval
    /// Meters (0 for non-GPS sports).
    let distanceMeters: Double
    let calories: Int
    /// Route points captured during the session (empty for indoor sports).
    /// Stored so a past session can be reopened and visualised on a map.
    var route: [RunRoutePoint] = []

    var distanceKm: Double { distanceMeters / 1000 }
}

@MainActor
final class SportSessionStore: ObservableObject {
    static let shared = SportSessionStore()

    @Published private(set) var history: [SportSessionRecord] = []

    private let key = "sb_sport_sessions"

    private init() { load() }

    func add(_ record: SportSessionRecord) {
        history.insert(record, at: 0)
        save()
    }

    func delete(_ record: SportSessionRecord) {
        history.removeAll { $0.id == record.id }
        save()
    }

    // MARK: - Per-sport queries

    func sessions(for sportId: String) -> [SportSessionRecord] {
        history.filter { $0.sportId == sportId }
    }

    func totalSessions(for sportId: String) -> Int {
        sessions(for: sportId).count
    }

    func totalSeconds(for sportId: String) -> TimeInterval {
        sessions(for: sportId).reduce(0) { $0 + $1.movingSeconds }
    }

    func totalDistance(for sportId: String) -> Double {
        sessions(for: sportId).reduce(0) { $0 + $1.distanceMeters }
    }

    func totalCalories(for sportId: String) -> Int {
        sessions(for: sportId).reduce(0) { $0 + $1.calories }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SportSessionRecord].self, from: data) else { return }
        history = decoded
    }
}
