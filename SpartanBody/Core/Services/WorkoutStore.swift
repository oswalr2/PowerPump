import Foundation

final class WorkoutStore: ObservableObject {
    static let shared = WorkoutStore()

    @Published var templates: [WorkoutTemplate] = []
    @Published var history: [WorkoutSession] = []
    @Published var activeSession: WorkoutSession?

    private init() { load() }

    // MARK: - Session lifecycle

    func startEmpty(name: String = "Workout") {
        activeSession = WorkoutSession(name: name, exercises: [])
    }

    func start(template: WorkoutTemplate) {
        let exercises = template.exercises.map { te -> SessionExercise in
            let sets = (1...max(1, te.sets)).map { i in
                SessionSet(setNumber: i,
                           weight: te.targetWeight,
                           reps: Int(te.targetReps) ?? 10)
            }
            return SessionExercise(exerciseID: te.exerciseID, sets: sets)
        }
        activeSession = WorkoutSession(name: template.name, exercises: exercises)
    }

    func finish() {
        guard var session = activeSession else { return }
        session.finishedAt = .now
        history.insert(session, at: 0)
        activeSession = nil
        save()
        HealthKitService.shared.saveWorkout(session)
    }

    func cancel() { activeSession = nil }

    // MARK: - Exercise / set mutation

    func addExercise(_ exerciseID: String) {
        guard activeSession != nil else { return }
        let ex = SessionExercise(exerciseID: exerciseID,
                                 sets: [SessionSet(setNumber: 1, weight: 0, reps: 10)])
        activeSession?.exercises.append(ex)
    }

    func removeExercise(at index: Int) {
        activeSession?.exercises.remove(at: index)
    }

    func addSet(to exerciseIndex: Int) {
        guard let session = activeSession,
              exerciseIndex < session.exercises.count else { return }
        let ex = session.exercises[exerciseIndex]
        let newSet = SessionSet(setNumber: ex.sets.count + 1,
                                weight: ex.sets.last?.weight ?? 0,
                                reps:   ex.sets.last?.reps   ?? 10)
        activeSession?.exercises[exerciseIndex].sets.append(newSet)
    }

    func removeSet(exerciseIndex: Int, setIndex: Int) {
        activeSession?.exercises[exerciseIndex].sets.remove(at: setIndex)
        for i in 0..<(activeSession?.exercises[exerciseIndex].sets.count ?? 0) {
            activeSession?.exercises[exerciseIndex].sets[i].setNumber = i + 1
        }
    }

    // Returns new completed state
    func toggleSet(exerciseIndex: Int, setIndex: Int) -> Bool {
        guard activeSession != nil else { return false }
        let current = activeSession?.exercises[exerciseIndex].sets[setIndex].completed ?? false
        activeSession?.exercises[exerciseIndex].sets[setIndex].completed = !current
        return !current
    }

    func updateWeight(_ weight: Double, exerciseIndex: Int, setIndex: Int) {
        activeSession?.exercises[exerciseIndex].sets[setIndex].weight = weight
    }

    func updateReps(_ reps: Int, exerciseIndex: Int, setIndex: Int) {
        activeSession?.exercises[exerciseIndex].sets[setIndex].reps = reps
    }

    // MARK: - Templates

    func saveAsTemplate(name: String) {
        guard let session = activeSession else { return }
        let exercises = session.exercises.map { se in
            TemplateExercise(exerciseID: se.exerciseID,
                             sets: se.sets.count,
                             targetReps: "\(se.sets.first?.reps ?? 10)",
                             targetWeight: se.sets.first?.weight ?? 0)
        }
        templates.insert(WorkoutTemplate(name: name, exercises: exercises), at: 0)
        save()
    }

    func deleteTemplate(_ template: WorkoutTemplate) {
        templates.removeAll { $0.id == template.id }
        save()
    }

    func deleteHistory(_ session: WorkoutSession) {
        history.removeAll { $0.id == session.id }
        save()
    }

    // MARK: - Calories burned

    var todayCaloriesBurned: Int {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: .now)
        let todaySessions = history.filter {
            cal.startOfDay(for: $0.startedAt) == todayStart && $0.finishedAt != nil
        }
        let totalMinutes = todaySessions.reduce(0.0) { $0 + $1.duration / 60 }
        return Int(totalMinutes * 6)   // ~6 kcal/min for strength training
    }

    // MARK: - Streak

    var currentStreak: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let days = Set(history.map { cal.startOfDay(for: $0.startedAt) })
        guard !days.isEmpty else { return 0 }

        var start = today
        if !days.contains(today) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) else { return 0 }
            start = yesterday
        }

        var streak = 0
        var checking = start
        while days.contains(checking) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checking) else { break }
            checking = prev
        }
        return streak
    }

    var longestStreak: Int {
        let cal = Calendar.current
        let days = Set(history.map { cal.startOfDay(for: $0.startedAt) }).sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1, current = 1
        for i in 1..<days.count {
            if let expected = cal.date(byAdding: .day, value: 1, to: days[i - 1]),
               expected == days[i] {
                current += 1
                if current > longest { longest = current }
            } else {
                current = 1
            }
        }
        return longest
    }

    // MARK: - Personal Records

    func personalRecord(for exerciseID: String) -> SessionSet? {
        history.flatMap(\.exercises)
            .filter { $0.exerciseID == exerciseID }
            .flatMap(\.sets)
            .filter(\.completed)
            .max { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }
    }

    func isNewRecord(exerciseID: String, weight: Double, reps: Int) -> Bool {
        let newVolume = weight * Double(reps)
        guard let pr = personalRecord(for: exerciseID) else { return newVolume > 0 }
        return newVolume > pr.weight * Double(pr.reps)
    }

    // MARK: - Achievements

    func unlockedAchievements(foodLogHasEntries: Bool, weightLogged: Bool) -> [Achievement] {
        Achievement.allCases.filter { a in
            switch a {
            case .firstWorkout: return history.count >= 1
            case .streak3:      return currentStreak >= 3
            case .streak7:      return currentStreak >= 7
            case .streak30:     return currentStreak >= 30
            case .workouts10:   return history.count >= 10
            case .workouts25:   return history.count >= 25
            case .firstMeal:    return foodLogHasEntries
            case .firstWeight:  return weightLogged
            }
        }
    }

    // MARK: - Persistence

    func save() {
        if let d = try? JSONEncoder().encode(templates) { UserDefaults.standard.set(d, forKey: "sb_templates") }
        if let d = try? JSONEncoder().encode(history)   { UserDefaults.standard.set(d, forKey: "sb_history") }
        PhoneConnectivityManager.shared.syncToWatch()
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: "sb_templates"),
           let v = try? JSONDecoder().decode([WorkoutTemplate].self, from: d) { templates = v }
        if let d = UserDefaults.standard.data(forKey: "sb_history"),
           let v = try? JSONDecoder().decode([WorkoutSession].self, from: d) { history = v }
    }
}
