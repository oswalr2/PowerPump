import Foundation

final class ChallengeStore: ObservableObject {
    static let shared = ChallengeStore()

    @Published private(set) var active:    [ActiveChallenge] = []
    @Published private(set) var completed: [ActiveChallenge] = []

    private init() {
        load()
        Task { @MainActor in self.autoCheck() }
    }

    // MARK: - Lifecycle

    func start(_ definition: ChallengeDefinition) {
        guard !active.contains(where: { $0.challengeID == definition.id }) else { return }
        var challenge = ActiveChallenge(challengeID: definition.id, startDate: .now)
        autoMarkIfPossible(&challenge)
        active.insert(challenge, at: 0)
        save()
    }

    func checkIn(id: UUID) {
        guard let idx = active.firstIndex(where: { $0.id == id }) else { return }
        HapticManager.success()
        active[idx].markToday()
        promoteIfFinished(idx)
        save()
    }

    func abandon(_ challenge: ActiveChallenge) {
        active.removeAll { $0.id == challenge.id }
        save()
    }

    // MARK: - Auto-check (call on app foreground)

    @MainActor func autoCheck() {
        let cal = Calendar.current
        let now = Date()
        var changed = false
        for i in active.indices {
            guard let def = active[i].definition else { continue }
            if def.checkType == .withinCalories {
                // Judged on a finished day: logging breakfast alone is
                // "within the goal", which used to complete the day at 8 am.
                // Every finished day since the start is checked, not just
                // yesterday, so days the app wasn't opened still count.
                let today = cal.startOfDay(for: now)
                var day = cal.startOfDay(for: active[i].startDate)
                while day < today, !active[i].isFinished {
                    if !active[i].isDayComplete(day), Self.stayedWithinCalories(on: day) {
                        active[i].mark(day); changed = true
                    }
                    guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
                    day = next
                }
                continue
            }
            guard !active[i].isDayComplete(now), Self.isMet(def.checkType, on: now) else { continue }
            active[i].markToday(); changed = true
        }
        // Promote after the loop: removing finished challenges while walking
        // the same array crashed when two challenges were active.
        let finished = active.filter(\.isFinished)
        if !finished.isEmpty {
            active.removeAll(where: \.isFinished)
            completed.insert(contentsOf: finished, at: 0)
            HapticManager.heavy()
        }
        if changed || !finished.isEmpty { save() }
    }

    /// Whether today's goal for an automatic challenge has been reached.
    @MainActor private static func isMet(_ type: ChallengeCheckType, on day: Date) -> Bool {
        let cal = Calendar.current
        switch type {
        case .workoutLogged:
            // Any workout: gym, run or a sport session.
            return WorkoutStore.shared.history.contains { cal.isDate($0.startedAt, inSameDayAs: day) }
                || RunStore.shared.history.contains { cal.isDate($0.startedAt, inSameDayAs: day) }
                || SportSessionStore.shared.history.contains { cal.isDate($0.startedAt, inSameDayAs: day) }
        case .allMealsLogged:
            let meals = Set(FoodLogStore.shared.todayEntries.map(\.meal))
            return meals.contains(.breakfast) && meals.contains(.lunch) && meals.contains(.dinner)
        case .proteinGoalMet:
            // The same target the dashboard shows, which follows the plan.
            let goal = Double(PlanStore.shared.todayTargets(for: UserProfile.shared).protein)
            return FoodLogStore.shared.todayProtein >= goal
        case .waterGoalMet:
            return WaterStore.shared.todayGlasses >= 8
        case .withinCalories, .manual:
            return false
        }
    }

    /// A finished day counts when food was actually logged (at least half
    /// the target) and the total stayed under the target.
    @MainActor private static func stayedWithinCalories(on day: Date) -> Bool {
        let goal = Double(PlanStore.shared.targets(on: day, for: UserProfile.shared).kcal)
        let eaten = FoodLogStore.shared.totalCalories(for: day)
        return eaten >= goal * 0.5 && eaten <= goal * 1.05
    }

    // MARK: - Helpers

    private func autoMarkIfPossible(_ c: inout ActiveChallenge) {
        guard let def = c.definition else { return }
        let met = MainActor.assumeIsolated { Self.isMet(def.checkType, on: Date()) }
        if met { c.markToday() }
    }

    private func promoteIfFinished(_ idx: Int) {
        guard idx < active.count, active[idx].isFinished else { return }
        let finished = active.remove(at: idx)
        completed.insert(finished, at: 0)
        HapticManager.heavy()
    }

    // MARK: - Persistence

    private func save() {
        if let d = try? JSONEncoder().encode(active)    { UserDefaults.standard.set(d, forKey: "sb_challenges_active") }
        if let d = try? JSONEncoder().encode(completed) { UserDefaults.standard.set(d, forKey: "sb_challenges_done") }
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: "sb_challenges_active"),
           let v = try? JSONDecoder().decode([ActiveChallenge].self, from: d) { active = v }
        if let d = UserDefaults.standard.data(forKey: "sb_challenges_done"),
           let v = try? JSONDecoder().decode([ActiveChallenge].self, from: d) { completed = v }
    }
}
