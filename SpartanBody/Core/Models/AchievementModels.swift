import SwiftUI

enum Achievement: String, CaseIterable, Identifiable {
    case firstWorkout
    case streak3
    case streak7
    case streak30
    case workouts10
    case workouts25
    case firstMeal
    case firstWeight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstWorkout: return "First Step"
        case .streak3:      return "On Fire"
        case .streak7:      return "Week Warrior"
        case .streak30:     return "Iron Will"
        case .workouts10:   return "10 Strong"
        case .workouts25:   return "Spartan"
        case .firstMeal:    return "Fuel Up"
        case .firstWeight:  return "Body Tracker"
        }
    }

    var description: String {
        switch self {
        case .firstWorkout: return "Completed your first workout"
        case .streak3:      return "3 days in a row"
        case .streak7:      return "7-day workout streak"
        case .streak30:     return "30-day workout streak"
        case .workouts10:   return "10 workouts completed"
        case .workouts25:   return "25 workouts completed"
        case .firstMeal:    return "Logged your first meal"
        case .firstWeight:  return "Logged your body weight"
        }
    }

    var icon: String {
        switch self {
        case .firstWorkout: return "figure.run"
        case .streak3:      return "flame.fill"
        case .streak7:      return "bolt.fill"
        case .streak30:     return "crown.fill"
        case .workouts10:   return "dumbbell.fill"
        case .workouts25:   return "shield.fill"
        case .firstMeal:    return "fork.knife"
        case .firstWeight:  return "scalemass.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstWorkout: return .sbAccent
        case .streak3:      return Color.orange
        case .streak7:      return Color.orange
        case .streak30:     return Color(hex: "#FFD700")
        case .workouts10:   return .sbAccent
        case .workouts25:   return Color(hex: "#C084FC")
        case .firstMeal:    return .sbGreen
        case .firstWeight:  return .sbAccent
        }
    }
}
