import Foundation

// Matrix test: generate plans for every combination of goal, activity level,
// sex, body size, sport, sport weekdays, history state and context, and check
// the rules a plan must never break. Failures are grouped by rule.

// MATRIX_DAY_OFFSET shifts "today" so every weekday can be checked.
// MATRIX_DAY_OFFSET shifts "today" so every weekday can be checked.
let now = Date().addingTimeInterval(Double(ProcessInfo.processInfo.environment["MATRIX_DAY_OFFSET"] ?? "0")! * 86_400).addingTimeInterval(Double(ProcessInfo.processInfo.environment["MATRIX_DAY_OFFSET"] ?? "0")! * 86_400)
let day: TimeInterval = 86_400
var failures: [String: [String]] = [:]
var checks = 0
func expect(_ ok: Bool, _ rule: String, _ ctx: @autoclosure () -> String) {
    checks += 1
    if !ok { failures[rule, default: []].append(ctx()) }
}

func session(_ daysAgo: Double, _ lifts: [(String, Double, Int, Int, Bool)]) -> WorkoutSession {
    let t = now.addingTimeInterval(-daysAgo * day)
    return WorkoutSession(name: "S", startedAt: t, finishedAt: t.addingTimeInterval(3600),
        exercises: lifts.map { id, kg, reps, sets, done in
            SessionExercise(exerciseID: id, sets: (1...sets).map {
                SessionSet(setNumber: $0, weight: kg, reps: done ? reps : reps - 2, completed: true)
            })
        })
}

enum History: String, CaseIterable { case fresh, consistent, lowAdherence, comeback, stalled, deloadWeek, cutting }

struct Body { let sex: BiologicalSex; let kg: Double; let cm: Double; let kcal: Int; let protein: Int }
let bodies = [Body(sex: .male, kg: 80, cm: 178, kcal: 2600, protein: 160),
              Body(sex: .female, kg: 52, cm: 160, kcal: 1350, protein: 95),
              Body(sex: .male, kg: 130, cm: 185, kcal: 3200, protein: 230)]

let sports: [String?] = [nil, "bjj", "soccer", "swimming", "yoga", "cycling", "tennis", "boxing", "hiit"]
// Calendar weekdays: 1 = Sunday … 7 = Saturday
let weekdayPatterns: [[Int]] = [[], [2, 4], [2, 4, 6], [3, 5, 7], [2, 3, 4, 5, 6], [1, 2, 3, 4, 5, 6, 7]]
let contexts = ["", "soy vegano", "tengo mala la rodilla", "entreno en casa", "mala la espalda y poco tiempo"]

func inputs(goal: FitnessGoal, level: ActivityLevel, body: Body, sport: String?, weekdays: [Int],
            history: History, context: String, seed: UInt64) -> CoachInputs {
    var sessions: [WorkoutSession] = []
    var planned: Int? = nil
    var block = 1, adj = 0, streak = 0
    var weigh: [WeightEntry] = []
    var cals = Array(repeating: 0.0, count: 7)
    switch history {
    case .fresh: break
    case .consistent:
        sessions = (1...4).map { session(Double($0) * 1.5, [("squat", 100, 5, 5, true), ("bench_press", 70, 5, 5, true)]) }
        planned = 4; block = 2
    case .lowAdherence:
        sessions = [session(3, [("bench_press", 60, 8, 3, true)])]; planned = 4; block = 2
    case .comeback:
        sessions = [session(25, [("squat", 90, 5, 5, true)])]; planned = 3; block = 3
    case .stalled:
        sessions = (1...3).map { session(Double($0) * 2, [("squat", 120, 5, 5, false), ("bench_press", 90, 5, 5, false)]) }
        planned = 3; block = 2
    case .deloadWeek:
        sessions = (1...3).map { session(Double($0) * 2, [("deadlift", 140, 5, 3, true)]) }; planned = 3; block = 4
    case .cutting:
        sessions = (1...3).map { session(Double($0) * 2, [("squat", 80, 8, 4, true)]) }; planned = 3; block = 3
        adj = -300; streak = 3
        weigh = stride(from: 15, through: 0, by: -3).map {
            WeightEntry(date: now.addingTimeInterval(-Double($0) * day), weightKg: body.kg + 0.3 * Double(15 - $0) / 7) }
        cals = Array(repeating: Double(body.kcal - 300), count: 7)
    }
    return CoachInputs(goal: goal, activityLevel: level, sex: body.sex, weightKg: body.kg, heightCm: body.cm,
                       bmi: body.kg / pow(body.cm / 100, 2), bmiCategory: "Normal",
                       baseCalories: body.kcal, protein: body.protein,
                       sportID: sport, sportDaysPerWeek: sport == nil ? 0 : max(weekdays.count, 3),
                       sportWeekdays: sport == nil ? [] : weekdays, extraContext: context,
                       sessions: sessions, weighIns: weigh, dailyCalories: cals, currentStreak: streak,
                       sportSessionsLast7: sport == nil ? 0 : weekdays.count,
                       previousPlannedSessions: planned, blockWeek: block,
                       calorieAdjustment: adj, canAdjustCalories: history != .fresh,
                       now: now, seed: seed)
}

let recipeTags = Dictionary(uniqueKeysWithValues: RecipeDatabase.all.map { ($0.id, $0.tags) })
var plans = 0
var seed: UInt64 = 1

for goal in [FitnessGoal.loseWeight, .gainMuscle, .stayFit] {
for level in ActivityLevel.allCases {
for body in bodies {
for sport in sports {
for wd in (sport == nil ? [[]] : weekdayPatterns) {
for history in History.allCases {
for context in contexts {
    seed &+= 7
    let i = inputs(goal: goal, level: level, body: body, sport: sport, weekdays: wd,
                   history: history, context: context, seed: seed)
    let tag = "\(goal) \(level) \(body.sex)\(Int(body.kg)) \(sport ?? "gym") \(wd) \(history) '\(context)'"
    let d = CoachAnalyzer.analyze(i)
    let p = LocalCoachService.generatePlan(i)
    plans += 1
    let s = p.weeklySchedule

    // ── Structure
    expect(s.count == 7, "7 días", tag)
    expect(Set(s.map(\.day)).count == 7, "nombres de día únicos", tag)
    let gym = s.filter(\.isWorkout)
    expect(gym.count >= 2 && gym.count <= 5, "entre 2 y 5 días de gym", "\(tag) → \(gym.count)")
    expect(!p.analysis.isEmpty && !p.motivation.isEmpty, "textos no vacíos", tag)

    // ── Training rules
    let heavyIdx = s.indices.filter { s[$0].intensity == .heavy }
    expect(!zip(heavyIdx, heavyIdx.dropFirst()).contains { $1 == $0 + 1 }, "nunca dos pesados seguidos", tag)
    let sportIdx = WeeklyPlanner.sportDayIndices(i)
    expect(sportIdx.allSatisfy { s[$0].isSportDay }, "días de deporte marcados", tag)
    expect(heavyIdx.allSatisfy { !sportIdx.contains($0) }, "sin pesado en día de deporte", tag)
    expect(heavyIdx.allSatisfy { !sportIdx.contains(($0 + 1) % 7) }, "sin pesado la víspera de deporte", tag)
    if d.isDeload {
        expect(gym.allSatisfy { $0.intensity == .deload || $0.isSportDay }, "descarga: todo en descarga", tag)
    }
    for g in gym {
        expect(g.exercises.count >= 3, "≥3 ejercicios por sesión", "\(tag) \(g.day): \(g.exercises.count)")
        if g.isSportDay { expect(g.intensity == .light || g.intensity == .deload, "gym en día de deporte = ligero", "\(tag) \(g.day)") }
        let names = g.exercises.map { WeeklyPlanner.exerciseName(of: $0).lowercased() }
        expect(Set(names).count == names.count, "sin ejercicios repetidos en un día", "\(tag) \(g.day): \(g.exercises)")
        for line in g.exercises {
            let name = WeeklyPlanner.exerciseName(of: line)
            expect(ExerciseStrings.table["es"]?[name] != nil || ExerciseStrings.table.values.contains { $0.values.contains(name) },
                   "ejercicio traducido", "\(tag) '\(name)'")
            expect(!name.trimmingCharacters(in: .whitespaces).isEmpty, "ejercicio con nombre", "\(tag) '\(line)'")
            expect(!line.contains("Back Glute") && !line.contains("  "), "sin nombres rotos", "\(tag) '\(line)'")
            if let r = line.range(of: #"· (\d+(\.\d+)?) kg"#, options: .regularExpression) {
                let kg = Double(line[r].filter { "0123456789.".contains($0) }) ?? -1
                expect(kg > 0 && kg < 400, "kilos razonables", "\(tag) '\(line)'")
            }
        }
    }
    // Injuries
    if context.contains("rodilla") {
        expect(!gym.flatMap(\.exercises).contains { $0.hasPrefix("Back Squat") || $0.hasPrefix("Walking Lunge") || $0.hasPrefix("Goblet Squat") },
               "rodilla: sin sentadillas ni zancadas", tag)
    }
    if context.contains("espalda") {
        expect(!gym.flatMap(\.exercises).contains { $0.hasPrefix("Deadlift") || $0.hasPrefix("Back Squat") || $0.hasPrefix("Barbell Row") },
               "espalda: sin peso muerto, sentadilla ni remo con barra", tag)
    }
    if context.contains("poco tiempo") {
        expect(gym.allSatisfy { $0.exercises.count <= 4 || $0.isSportDay }, "poco tiempo: ≤4 ejercicios", tag)
    }

    // ── Diet
    let m = p.weeklyMeals
    expect(m.count == 7, "7 menús", tag)
    let floor = body.sex == .female ? 1200 : 1500
    expect(d.weeklyCalories >= floor, "calorías ≥ mínimo seguro", "\(tag) → \(d.weeklyCalories)")
    let avg = Double(m.compactMap { $0.target?.kcal }.reduce(0, +)) / 7
    // At the safety floor the days below it are lifted, so the week may
    // average a little over the target — never under it.
    let atFloor = m.contains { ($0.target?.kcal ?? 0) <= floor + 5 }
    let drift = (avg - Double(d.weeklyCalories)) / Double(d.weeklyCalories)
    expect(atFloor ? (drift > -0.015 && drift < 0.03) : abs(drift) < 0.015, "media semanal = objetivo", "\(tag) \(Int(avg)) vs \(d.weeklyCalories)")
    expect(m.allSatisfy { ($0.target?.kcal ?? floor) >= floor - 5 }, "ningún día bajo el mínimo seguro", tag)
    for md in m {
        guard let t = md.target, let tot = md.totals, let meals = md.meals else {
            expect(false, "cada día con menú y objetivo", "\(tag) \(md.day)"); continue
        }
        expect(meals.count == 4, "4 comidas al día", "\(tag) \(md.day): \(meals.count)")
        expect(t.kcal >= floor - 150, "ningún día muy por debajo del mínimo", "\(tag) \(md.day) \(t.kcal)")
        expect(abs(Double(tot.kcal - t.kcal)) / Double(t.kcal) < 0.12, "kcal del día ±12%", "\(tag) \(md.day) \(tot.kcal)/\(t.kcal)")
        let pr = Double(tot.protein) / Double(t.protein)
        expect(pr >= 0.80 && pr <= 1.40, "proteína 80–140%", "\(tag) \(md.day) \(tot.protein)/\(t.protein)")
        expect(Double(tot.carbs) / Double(max(t.carbs, 1)) >= 0.55, "carbos ≥55%", "\(tag) \(md.day) \(tot.carbs)/\(t.carbs)")
        expect(meals.allSatisfy { $0.kcal > 0 && $0.protein >= 0 }, "comidas con valores", "\(tag) \(md.day)")
        if let items = meals.first(where: { $0.items != nil })?.items {
            expect(items.allSatisfy { $0.grams > 0 && $0.grams <= 800 }, "gramos razonables", "\(tag) \(items.map(\.grams))")
        }
    }
    let sportCarbs = sportIdx.compactMap { m[$0].target?.carbs }
    let restCarbs = m.filter { $0.intensity == .rest }.compactMap { $0.target?.carbs }
    if let lo = sportCarbs.min(), let hi = restCarbs.max() {
        expect(lo > hi, "más carbos en deporte que en descanso", "\(tag) \(lo) vs \(hi)")
    }
    if context.contains("vegano") {
        let ids = m.flatMap { $0.meals ?? [] }.compactMap(\.recipeID)
        expect(ids.allSatisfy { recipeTags[$0]?.contains("Vegan") == true || recipeTags[$0]?.contains("Vegetarian") == true },
               "vegano: solo recetas vegetales", tag)
        let foods = m.flatMap { $0.meals ?? [] }.flatMap { $0.items ?? [] }.map(\.foodID)
        expect(!foods.contains { ["whey_protein", "greek_yogurt", "cottage_cheese", "milk_skim"].contains($0) },
               "vegano: sin lácteos", tag)
    }

    // ── Persistence
    if let data = try? JSONEncoder().encode(p), let back = try? JSONDecoder().decode(FitnessPlan.self, from: data) {
        expect(back.weeklySchedule.count == 7 && back.weeklyMeals.count == 7, "se guarda y se recupera", tag)
    } else { expect(false, "se guarda y se recupera", tag) }
}}}}}}}

print("Planes generados: \(plans) · comprobaciones: \(checks)")
if failures.isEmpty {
    print("TODO OK — ninguna regla rota")
} else {
    for (rule, cases) in failures.sorted(by: { $0.value.count > $1.value.count }) {
        print("FALLA [\(cases.count)] \(rule)")
        for c in cases.prefix(3) { print("     · \(c)") }
        // breakdown by key facets
        func share(_ f: (String) -> Bool) -> Int { cases.filter(f).count }
        print("     vegano: \(share { $0.contains("vegano") })  female52: \(share { $0.contains("female52") })  male130: \(share { $0.contains("male130") })  male80: \(share { $0.contains("male80") })")
        print("     loseWeight: \(share { $0.hasPrefix("loseWeight") })  gainMuscle: \(share { $0.hasPrefix("gainMuscle") })  stayFit: \(share { $0.hasPrefix("stayFit") })")
        let nonVegan = cases.filter { !$0.contains("vegano") }
        print("     no veganos, ejemplos:"); for c in nonVegan.prefix(4) { print("       · \(c)") }
        // over vs under for ratio rules
        let ratios = cases.compactMap { c -> Double? in
            guard let r = c.range(of: #"(\d+)/(\d+)$"#, options: .regularExpression) else { return nil }
            let parts = c[r].split(separator: "/").compactMap { Double($0) }
            return parts.count == 2 ? parts[0] / parts[1] : nil }
        print("     por debajo: \(ratios.filter { $0 < 1 }.count)  por encima: \(ratios.filter { $0 > 1 }.count)  peor bajo: \(Int((ratios.min() ?? 0) * 100))%  peor alto: \(Int((ratios.max() ?? 0) * 100))%")
    }
}
exit(failures.isEmpty ? 0 : 1)
