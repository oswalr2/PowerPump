import Foundation
import Combine

/// Tracks the user's progress through each running program: which days are
/// done, what's unlocked next, and how to mark sessions complete.
@MainActor
final class RunProgramStore: ObservableObject {
    static let shared = RunProgramStore()

    /// Map of programId -> set of completed day numbers (1-based, across the
    /// whole program: week 1 day 1 = 1, week 1 day 3 = 3, week 2 day 1 = 4…).
    @Published private(set) var completed: [String: Set<Int>] = [:]

    private let key = "sb_program_progress"

    private init() {
        load()
    }

    // MARK: - Queries

    func completedCount(for program: RunningProgram) -> Int {
        completed[program.id]?.count ?? 0
    }

    /// 1-based global day number (across all weeks) for a given week/day.
    func globalDay(in program: RunningProgram, weekNumber: Int, dayNumber: Int) -> Int {
        (weekNumber - 1) * program.daysPerWeek + dayNumber
    }

    func isCompleted(_ globalDay: Int, in program: RunningProgram) -> Bool {
        completed[program.id]?.contains(globalDay) ?? false
    }

    /// A day is unlocked if it's the next one after the last completed day.
    /// The very first day is always unlocked.
    func nextUnlockedDay(in program: RunningProgram) -> Int {
        let done = completed[program.id] ?? []
        if done.isEmpty { return 1 }
        return (done.max() ?? 0) + 1
    }

    func isUnlocked(_ globalDay: Int, in program: RunningProgram) -> Bool {
        if isCompleted(globalDay, in: program) { return true }
        return globalDay <= nextUnlockedDay(in: program)
    }

    func progress(in program: RunningProgram) -> Double {
        guard program.totalDays > 0 else { return 0 }
        return Double(completedCount(for: program)) / Double(program.totalDays)
    }

    // MARK: - Mutations

    func markComplete(_ globalDay: Int, in program: RunningProgram) {
        var set = completed[program.id] ?? []
        set.insert(globalDay)
        completed[program.id] = set
        save()
    }

    func reset(_ program: RunningProgram) {
        completed[program.id] = []
        save()
    }

    // MARK: - Persistence

    private func save() {
        // Convert sets to arrays for JSON.
        let dict = completed.mapValues { Array($0).sorted() }
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let dict = try? JSONDecoder().decode([String: [Int]].self, from: data) else { return }
        completed = dict.mapValues { Set($0) }
    }
}
