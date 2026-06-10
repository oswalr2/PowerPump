import Foundation

final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    @Published private(set) var weightEntries: [WeightEntry] = []

    private init() { load() }

    // MARK: - Mutations

    func addEntry(weightKg: Double, date: Date = .now) {
        let cal = Calendar.current
        weightEntries.removeAll { cal.isDate($0.date, inSameDayAs: date) }
        weightEntries.append(WeightEntry(date: date, weightKg: weightKg))
        weightEntries.sort { $0.date < $1.date }
        save()
    }

    // MARK: - Queries

    func entries(days: Int) -> [WeightEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now)!
        return weightEntries.filter { $0.date >= cutoff }
    }

    var latestWeight: Double? { weightEntries.last?.weightKg }

    var weightChange: Double? {
        guard weightEntries.count >= 2 else { return nil }
        return weightEntries.last!.weightKg - weightEntries[weightEntries.count - 2].weightKg
    }

    // MARK: - Persistence

    private func save() {
        if let d = try? JSONEncoder().encode(weightEntries) {
            UserDefaults.standard.set(d, forKey: "sb_weight_entries")
        }
    }

    private func load() {
        guard let d = UserDefaults.standard.data(forKey: "sb_weight_entries"),
              let v = try? JSONDecoder().decode([WeightEntry].self, from: d) else { return }
        weightEntries = v
    }
}
