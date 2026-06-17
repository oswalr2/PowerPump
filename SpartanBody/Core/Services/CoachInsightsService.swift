import Foundation
import SwiftUI

// Generates personalized, data-driven feedback the coach surfaces on the
// dashboard. Reads from the same stores the user is already filling in.
@MainActor
enum CoachInsightsService {

    // MARK: - Weekly recap (Mondays)

    struct WeeklyRecap {
        let weekRange: String              // "9–15 Jun"
        let workoutsDone: Int
        let workoutsPlanned: Int           // best guess based on goal
        let avgDailyCalories: Int
        let calorieTarget: Int
        let avgWater: Double               // glasses/day average
        let weightChange: Double?          // kg, nil if not enough data
        let highlight: String              // one-liner about the user's win
    }

    static func weeklyRecap() -> WeeklyRecap {
        let cal = Calendar.current
        let now = Date()
        // Last 7 full days (today inclusive).
        guard let weekStart = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now))
        else { return placeholder }

        let workouts = WorkoutStore.shared.history.filter {
            $0.startedAt >= weekStart && $0.finishedAt != nil
        }.count

        let daily = FoodLogStore.shared.dailyCalories(lastDays: 7)
        let logged = daily.filter { $0.calories > 0 }
        let avgCal = logged.isEmpty ? 0
            : Int(logged.reduce(0) { $0 + $1.calories } / Double(logged.count))

        let waterGlasses: [Int] = (0..<7).compactMap { offset in
            guard let d = cal.date(byAdding: .day, value: -offset, to: now) else { return nil }
            let key = "sb_water_\(Self.dateKey(for: d))"
            let g = UserDefaults.standard.integer(forKey: key)
            return g > 0 ? g : nil
        }
        let avgWater = waterGlasses.isEmpty ? 0
            : Double(waterGlasses.reduce(0, +)) / Double(waterGlasses.count)

        let entries = ProgressStore.shared.entries(days: 14).sorted { $0.date < $1.date }
        let weightDelta: Double? = {
            guard entries.count >= 2 else { return nil }
            return entries.last!.weightKg - entries.first!.weightKg
        }()

        return WeeklyRecap(
            weekRange:        rangeString(from: weekStart, to: now),
            workoutsDone:     workouts,
            workoutsPlanned:  plannedWorkouts(for: UserProfile.shared.goal),
            avgDailyCalories: avgCal,
            calorieTarget:    UserProfile.shared.dailyCalorieTarget,
            avgWater:         avgWater,
            weightChange:     weightDelta,
            highlight:        pickHighlight(
                                workouts: workouts,
                                streak: WorkoutStore.shared.currentStreak,
                                avgCal: avgCal,
                                target: UserProfile.shared.dailyCalorieTarget,
                                avgWater: avgWater,
                                weightDelta: weightDelta)
        )
    }

    // MARK: - Alerts (proactive, one at a time)

    struct CoachAlert: Identifiable {
        let id = UUID()
        let icon: String
        let tint: AlertTint
        let title: String
        let body:  String
    }
    enum AlertTint { case info, warn, success }

    // Returns at most one alert — the most relevant — to avoid notification fatigue.
    static func currentAlert() -> CoachAlert? {
        let foodLog  = FoodLogStore.shared
        let workouts = WorkoutStore.shared
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        // 1. Three days without logging food
        let last3Days = (0..<3).compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }
        let loggedDays = last3Days.filter { foodLog.totalCalories(for: $0) > 0 }.count
        if loggedDays == 0 {
            return CoachAlert(
                icon: "fork.knife.circle",
                tint: .warn,
                title: localized("alert.noFood.title"),
                body:  localized("alert.noFood.body"))
        }

        // 2. No workout this week, and weekend coming
        let weekStart = cal.date(byAdding: .day, value: -6, to: today) ?? today
        let workoutsThisWeek = workouts.history.filter {
            $0.startedAt >= weekStart && $0.finishedAt != nil
        }.count
        if workoutsThisWeek == 0 && workouts.history.count > 0 {
            return CoachAlert(
                icon: "dumbbell",
                tint: .warn,
                title: localized("alert.noWorkout.title"),
                body:  localized("alert.noWorkout.body"))
        }

        // 3. Streak milestone reached
        let streak = workouts.currentStreak
        if streak == 7 || streak == 30 || streak == 100 {
            return CoachAlert(
                icon: "flame.fill",
                tint: .success,
                title: String(format: localized("alert.streak.title"), streak),
                body:  localized("alert.streak.body"))
        }

        // 4. Weight stuck for 2+ weeks
        let entries = ProgressStore.shared.entries(days: 21).sorted { $0.date < $1.date }
        if entries.count >= 3 {
            let recent = entries.suffix(3)
            let weights = recent.map(\.weightKg)
            let span = (weights.max() ?? 0) - (weights.min() ?? 0)
            if span < 0.5 {
                return CoachAlert(
                    icon: "chart.line.flattrend.xyaxis",
                    tint: .info,
                    title: localized("alert.plateau.title"),
                    body:  localized("alert.plateau.body"))
            }
        }

        // 5. Crushing it — way over expected workout pace
        let plannedPerWeek = plannedWorkouts(for: UserProfile.shared.goal)
        if workoutsThisWeek >= plannedPerWeek + 1 {
            return CoachAlert(
                icon: "bolt.fill",
                tint: .success,
                title: localized("alert.onFire.title"),
                body:  String(format: localized("alert.onFire.body"), workoutsThisWeek))
        }

        return nil
    }

    // MARK: - Helpers

    private static let placeholder = WeeklyRecap(
        weekRange: "", workoutsDone: 0, workoutsPlanned: 4,
        avgDailyCalories: 0, calorieTarget: 2000, avgWater: 0,
        weightChange: nil, highlight: "")

    private static func plannedWorkouts(for goal: FitnessGoal) -> Int {
        switch goal {
        case .gainMuscle: return 5
        case .loseWeight: return 4
        case .stayFit:    return 3
        }
    }

    private static func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private static func rangeString(from: Date, to: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: LanguageManager.shared.selectedCode)
        f.setLocalizedDateFormatFromTemplate("d MMM")
        return "\(f.string(from: from)) – \(f.string(from: to))"
    }

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // Picks the most positive true statement to lead the recap.
    private static func pickHighlight(workouts: Int, streak: Int,
                                      avgCal: Int, target: Int,
                                      avgWater: Double,
                                      weightDelta: Double?) -> String {
        if streak >= 7 {
            return String(format: localized("recap.highlight.streak"), streak)
        }
        if let delta = weightDelta, delta < -0.3 {
            return String(format: localized("recap.highlight.lostWeight"), abs(delta))
        }
        if let delta = weightDelta, delta > 0.3 {
            return String(format: localized("recap.highlight.gainedWeight"), delta)
        }
        if avgWater >= 7 {
            return localized("recap.highlight.water")
        }
        if workouts >= 3 {
            return String(format: localized("recap.highlight.workouts"), workouts)
        }
        if avgCal > 0 && abs(avgCal - target) < target / 10 {
            return localized("recap.highlight.calories")
        }
        return localized("recap.highlight.keepGoing")
    }
}
