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
        var changed = false
        for i in active.indices {
            let def = active[i].definition
            guard let def else { continue }
            guard !active[i].isDayComplete(.now) else { continue }

            switch def.checkType {
            case .workoutLogged:
                let cal = Calendar.current
                if WorkoutStore.shared.history.contains(where: {
                    cal.isDateInToday($0.startedAt)
                }) {
                    active[i].markToday(); changed = true
                }
            case .allMealsLogged:
                let store = FoodLogStore.shared
                let mealsLogged = Set(store.todayEntries.map(\.meal.rawValue)).count
                if mealsLogged >= 3 {
                    active[i].markToday(); changed = true
                }
            case .proteinGoalMet:
                let goal = Double(UserProfile.shared.dailyProteinTarget)
                if FoodLogStore.shared.todayProtein >= goal {
                    active[i].markToday(); changed = true
                }
            case .withinCalories:
                let goal = Double(UserProfile.shared.dailyCalorieTarget)
                let consumed = FoodLogStore.shared.todayCalories
                if consumed > 0 && consumed <= goal {
                    active[i].markToday(); changed = true
                }
            case .waterGoalMet:
                if WaterStore.shared.todayGlasses >= 8 {
                    active[i].markToday(); changed = true
                }
            case .manual:
                break
            }

            if changed { promoteIfFinished(i) }
        }
        if changed { save() }
    }

    // MARK: - Helpers

    private func autoMarkIfPossible(_ c: inout ActiveChallenge) {
        guard let def = c.definition else { return }
        switch def.checkType {
        case .workoutLogged:
            let cal = Calendar.current
            if WorkoutStore.shared.history.contains(where: { cal.isDateInToday($0.startedAt) }) {
                c.markToday()
            }
        default: break
        }
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
