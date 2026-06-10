import SwiftUI

// How completion is verified each day
enum ChallengeCheckType: String, Codable {
    case manual          // user taps "Check In"
    case workoutLogged   // auto: completed a workout today
    case allMealsLogged  // auto: logged 3+ meals today
    case proteinGoalMet  // auto: hit protein target
    case withinCalories  // auto: within calorie goal
    case waterGoalMet    // auto: 8 glasses
}

enum ChallengeCategory: String, CaseIterable, Codable {
    case workout    = "Workout"
    case nutrition  = "Nutrition"
    case water      = "Hydration"
    case lifestyle  = "Lifestyle"
}

struct ChallengeDefinition: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let category: ChallengeCategory
    let durationDays: Int
    let checkType: ChallengeCheckType
    let dailyGoalDescription: String
}

struct ActiveChallenge: Identifiable, Codable {
    var id           = UUID()
    var challengeID: String
    var startDate:   Date
    var completedDayKeys: [String] = []   // "yyyy-MM-dd"

    var definition: ChallengeDefinition? { ChallengeLibrary.find(id: challengeID) }
    var totalDays:  Int    { definition?.durationDays ?? 7 }
    var progress:   Double { Double(completedDayKeys.count) / Double(totalDays) }
    var isFinished: Bool   { completedDayKeys.count >= totalDays }

    func isDayComplete(_ date: Date) -> Bool {
        completedDayKeys.contains(dayKey(date))
    }

    mutating func markToday() {
        let key = dayKey(.now)
        if !completedDayKeys.contains(key) { completedDayKeys.append(key) }
    }

    private func dayKey(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
