import Foundation

// MARK: - Interval

/// A single chunk of activity inside a session. The user goes through them
/// in order; voice coach announces each transition.
enum IntervalKind: String, Codable, CaseIterable {
    case warmup
    case walk
    case briskWalk      // brisk walk
    case jog
    case run
    case fastRun
    case sprint
    case cooldown
    case rest

    /// Localized announcement key for the voice coach.
    var voiceKey: String {
        switch self {
        case .warmup:    return "voice.warmup"
        case .walk:      return "voice.walk"
        case .briskWalk: return "voice.briskWalk"
        case .jog:       return "voice.jog"
        case .run:       return "voice.run"
        case .fastRun:   return "voice.fastRun"
        case .sprint:    return "voice.sprint"
        case .cooldown:  return "voice.cooldown"
        case .rest:      return "voice.rest"
        }
    }

    /// User-facing label key for the UI ("Walk", "Jog", etc.)
    var labelKey: String {
        switch self {
        case .warmup:    return "Warm Up"
        case .walk:      return "Walk"
        case .briskWalk: return "Brisk Walk"
        case .jog:       return "Jog"
        case .run:       return "Run"
        case .fastRun:   return "Fast Run"
        case .sprint:    return "Sprint"
        case .cooldown:  return "Cool Down"
        case .rest:      return "Rest"
        }
    }

    var icon: String {
        switch self {
        case .warmup, .cooldown: return "figure.cooldown"
        case .walk, .briskWalk:  return "figure.walk"
        case .jog:               return "figure.run"
        case .run, .fastRun:     return "figure.run"
        case .sprint:            return "bolt.fill"
        case .rest:              return "pause.circle"
        }
    }

    /// Rough kcal/min used to estimate the session's burn before it actually runs.
    var kcalPerMinute: Double {
        switch self {
        case .warmup, .cooldown, .rest: return 3.5
        case .walk:       return 4
        case .briskWalk:  return 5
        case .jog:        return 8
        case .run:        return 11
        case .fastRun:    return 13
        case .sprint:     return 16
        }
    }
}

struct ProgramInterval: Codable, Identifiable, Hashable {
    var id = UUID()
    let kind: IntervalKind
    /// Seconds.
    let duration: Int
}

// MARK: - Day / Week / Phase

struct ProgramDay: Codable, Identifiable, Hashable {
    var id = UUID()
    let dayNumber: Int
    let intervals: [ProgramInterval]

    var totalSeconds: Int { intervals.reduce(0) { $0 + $1.duration } }
    var totalMinutes: Int { Int(round(Double(totalSeconds) / 60)) }
    var formattedDuration: String {
        String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
    var estimatedKcal: Int {
        let kcal = intervals.reduce(0.0) { acc, i in
            acc + (Double(i.duration) / 60.0 * i.kind.kcalPerMinute)
        }
        return Int(kcal)
    }
}

struct ProgramWeek: Codable, Identifiable, Hashable {
    var id = UUID()
    let weekNumber: Int
    let days: [ProgramDay]
}

struct ProgramPhase: Codable, Identifiable, Hashable {
    var id = UUID()
    let weekStart: Int
    let weekEnd: Int
    /// Localization key for the phase title (e.g. "Calorie Burner").
    let titleKey: String
    /// Localization key for the phase description.
    let bodyKey: String
    /// SF Symbol shown next to the phase title.
    let icon: String
}

// MARK: - Program

enum ProgramLevel: Int, Codable {
    case veryEasy = 1, easy = 2, medium = 3, hard = 4
}

struct RunningProgram: Identifiable, Codable, Hashable {
    /// Stable identifier used to persist progress per program.
    let id: String
    /// Localization keys for the strings users see.
    let nameKey: String
    let subtitleKey: String       // short tag line under the name
    let headerImageName: String   // asset image name for the hero image

    let weeks: [ProgramWeek]
    let phases: [ProgramPhase]
    /// Bullet points displayed in the Introducción tab.
    let goalKeys: [String]
    /// Badge tags ("Low impact", "Beginner friendly").
    let badgeKeys: [String]

    let endurance: ProgramLevel
    let speed:     ProgramLevel

    var totalWeeks: Int { weeks.count }
    var daysPerWeek: Int { weeks.first?.days.count ?? 0 }
    var totalDays: Int { weeks.reduce(0) { $0 + $1.days.count } }

    /// Range of session durations across the program, e.g. "22-66 min".
    var durationRangeText: String {
        let allMins = weeks.flatMap { $0.days.map(\.totalMinutes) }
        guard let lo = allMins.min(), let hi = allMins.max() else { return "--" }
        return lo == hi ? "\(lo) min" : "\(lo)-\(hi) min"
    }
}
