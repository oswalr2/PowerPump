import SwiftUI

struct ChallengeLibrary {

    static let all: [ChallengeDefinition] = [
        // ── Workout ──────────────────────────────────────────────────────
        ChallengeDefinition(
            id: "c_warrior7",
            name: "7-Day Warrior",
            subtitle: "Complete a workout every day",
            icon: "dumbbell.fill",
            color: .sbAccent,
            category: .workout,
            durationDays: 7,
            checkType: .workoutLogged,
            dailyGoalDescription: "Complete any workout today"
        ),
        ChallengeDefinition(
            id: "c_pushup30",
            name: "Push-up Power",
            subtitle: "30 push-ups a day for 7 days",
            icon: "figure.strengthtraining.traditional",
            color: Color(hex: "#FF6B35"),
            category: .workout,
            durationDays: 7,
            checkType: .manual,
            dailyGoalDescription: "Do 30 push-ups today and check in"
        ),
        ChallengeDefinition(
            id: "c_plank5",
            name: "Plank Challenge",
            subtitle: "60-second plank every day for 5 days",
            icon: "figure.core.training",
            color: Color(hex: "#C084FC"),
            category: .workout,
            durationDays: 5,
            checkType: .manual,
            dailyGoalDescription: "Hold a 60-second plank and check in"
        ),
        ChallengeDefinition(
            id: "c_warrior30",
            name: "Iron Month",
            subtitle: "Work out every day for 30 days",
            icon: "crown.fill",
            color: Color(hex: "#FFD700"),
            category: .workout,
            durationDays: 30,
            checkType: .workoutLogged,
            dailyGoalDescription: "Complete any workout today"
        ),
        // ── Nutrition ────────────────────────────────────────────────────
        ChallengeDefinition(
            id: "c_protein7",
            name: "Protein Week",
            subtitle: "Hit your protein goal every day",
            icon: "chart.bar.fill",
            color: .sbGreen,
            category: .nutrition,
            durationDays: 7,
            checkType: .proteinGoalMet,
            dailyGoalDescription: "Reach your daily protein target"
        ),
        ChallengeDefinition(
            id: "c_track5",
            name: "Track Everything",
            subtitle: "Log all 3 meals for 5 days",
            icon: "fork.knife",
            color: Color(hex: "#FF9F0A"),
            category: .nutrition,
            durationDays: 5,
            checkType: .allMealsLogged,
            dailyGoalDescription: "Log breakfast, lunch and dinner"
        ),
        ChallengeDefinition(
            id: "c_calories7",
            name: "Calorie Control",
            subtitle: "Stay within your calorie goal for 7 days",
            icon: "flame.fill",
            color: Color(hex: "#FF375F"),
            category: .nutrition,
            durationDays: 7,
            checkType: .withinCalories,
            dailyGoalDescription: "Stay within your daily calorie goal"
        ),
        // ── Hydration ────────────────────────────────────────────────────
        ChallengeDefinition(
            id: "c_water5",
            name: "Hydration Hero",
            subtitle: "Drink 8 glasses every day for 5 days",
            icon: "drop.fill",
            color: Color(hex: "#0EA5E9"),
            category: .water,
            durationDays: 5,
            checkType: .waterGoalMet,
            dailyGoalDescription: "Drink 8 glasses of water today"
        ),
    ]

    static func find(id: String) -> ChallengeDefinition? {
        all.first { $0.id == id }
    }

    static func available(excluding active: [ActiveChallenge]) -> [ChallengeDefinition] {
        let activeIDs = Set(active.map(\.challengeID))
        return all.filter { !activeIDs.contains($0.id) }
    }
}
