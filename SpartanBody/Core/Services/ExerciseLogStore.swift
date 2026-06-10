import Foundation
import Combine

@MainActor
final class ExerciseLogStore: ObservableObject {
    static let shared = ExerciseLogStore()

    @Published private(set) var allLogs: [ExerciseLog] = []

    private let key = "spartanbody_exercise_logs"

    private init() { load() }

    func logs(for exerciseId: String) -> [ExerciseLog] {
        allLogs.filter { $0.exerciseId == exerciseId }
            .sorted { $0.date > $1.date }
    }

    func save(_ log: ExerciseLog) {
        allLogs.append(log)
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ExerciseLog].self, from: data) else { return }
        allLogs = decoded
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(allLogs) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
