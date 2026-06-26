import Foundation
import HealthKit

/// A trackable sport activity. Drives the Sports catalog UI and the
/// generic session tracker.  Each activity maps to a HealthKit
/// workout type so finished sessions sync into Apple Health.
struct SportActivity: Identifiable, Hashable {
    let id: String                  // stable id for persistence
    let nameKey: String             // localised label key
    let icon: String                // SF Symbol
    let category: SportCategory
    let usesGPS: Bool               // true → show map + track distance
    let healthKitType: UInt         // HKWorkoutActivityType.rawValue
    let kcalPerMinute: Double

    var hkType: HKWorkoutActivityType {
        HKWorkoutActivityType(rawValue: healthKitType) ?? .other
    }
}

enum SportCategory: String, CaseIterable, Identifiable {
    case outdoor = "Outdoor"
    case indoor  = "Indoor"
    case water   = "Water"
    case team    = "Team & Racquet"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .outdoor: return "sun.max.fill"
        case .indoor:  return "house.fill"
        case .water:   return "drop.fill"
        case .team:    return "person.3.fill"
        }
    }
}

/// Static catalog. We pick activities that the typical user might track from
/// a phone or pair with an Apple Watch later.
enum SportLibrary {
    static let all: [SportActivity] = [
        // Outdoor — usually GPS
        SportActivity(id: "cycling", nameKey: "sport.cycling",
                      icon: "bicycle", category: .outdoor, usesGPS: true,
                      healthKitType: HKWorkoutActivityType.cycling.rawValue,
                      kcalPerMinute: 8),
        SportActivity(id: "hiking", nameKey: "sport.hiking",
                      icon: "figure.hiking", category: .outdoor, usesGPS: true,
                      healthKitType: HKWorkoutActivityType.hiking.rawValue,
                      kcalPerMinute: 6),
        SportActivity(id: "skating", nameKey: "sport.skating",
                      icon: "figure.skating", category: .outdoor, usesGPS: true,
                      healthKitType: HKWorkoutActivityType.skatingSports.rawValue,
                      kcalPerMinute: 7),
        SportActivity(id: "skiing", nameKey: "sport.skiing",
                      icon: "figure.skiing.downhill", category: .outdoor, usesGPS: true,
                      healthKitType: HKWorkoutActivityType.downhillSkiing.rawValue,
                      kcalPerMinute: 8),
        SportActivity(id: "snowboarding", nameKey: "sport.snowboarding",
                      icon: "figure.snowboarding", category: .outdoor, usesGPS: true,
                      healthKitType: HKWorkoutActivityType.snowboarding.rawValue,
                      kcalPerMinute: 7),
        SportActivity(id: "climbing", nameKey: "sport.climbing",
                      icon: "figure.climbing", category: .outdoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.climbing.rawValue,
                      kcalPerMinute: 9),
        SportActivity(id: "golf", nameKey: "sport.golf",
                      icon: "figure.golf", category: .outdoor, usesGPS: true,
                      healthKitType: HKWorkoutActivityType.golf.rawValue,
                      kcalPerMinute: 4),

        // Indoor / gym
        SportActivity(id: "stationary_bike", nameKey: "sport.stationaryBike",
                      icon: "figure.indoor.cycle", category: .indoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.cycling.rawValue,
                      kcalPerMinute: 8),
        SportActivity(id: "elliptical", nameKey: "sport.elliptical",
                      icon: "figure.elliptical", category: .indoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.elliptical.rawValue,
                      kcalPerMinute: 7),
        SportActivity(id: "treadmill", nameKey: "sport.treadmill",
                      icon: "figure.run.treadmill", category: .indoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.running.rawValue,
                      kcalPerMinute: 10),
        SportActivity(id: "stair_stepper", nameKey: "sport.stairStepper",
                      icon: "figure.stair.stepper", category: .indoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.stairClimbing.rawValue,
                      kcalPerMinute: 8),
        SportActivity(id: "yoga", nameKey: "sport.yoga",
                      icon: "figure.yoga", category: .indoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.yoga.rawValue,
                      kcalPerMinute: 3),
        SportActivity(id: "pilates", nameKey: "sport.pilates",
                      icon: "figure.pilates", category: .indoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.pilates.rawValue,
                      kcalPerMinute: 4),
        SportActivity(id: "dance", nameKey: "sport.dance",
                      icon: "figure.dance", category: .indoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.socialDance.rawValue,
                      kcalPerMinute: 6),
        SportActivity(id: "boxing", nameKey: "sport.boxing",
                      icon: "figure.boxing", category: .indoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.boxing.rawValue,
                      kcalPerMinute: 11),
        SportActivity(id: "martial_arts", nameKey: "sport.martialArts",
                      icon: "figure.martial.arts", category: .indoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.martialArts.rawValue,
                      kcalPerMinute: 10),
        SportActivity(id: "hiit", nameKey: "sport.hiit",
                      icon: "figure.highintensity.intervaltraining", category: .indoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.highIntensityIntervalTraining.rawValue,
                      kcalPerMinute: 12),
        SportActivity(id: "rowing", nameKey: "sport.rowing",
                      icon: "figure.rower", category: .indoor, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.rowing.rawValue,
                      kcalPerMinute: 9),

        // Water sports
        SportActivity(id: "swimming", nameKey: "sport.swimming",
                      icon: "figure.pool.swim", category: .water, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.swimming.rawValue,
                      kcalPerMinute: 9),
        SportActivity(id: "open_water_swim", nameKey: "sport.openWaterSwim",
                      icon: "figure.open.water.swim", category: .water, usesGPS: true,
                      healthKitType: HKWorkoutActivityType.swimming.rawValue,
                      kcalPerMinute: 10),
        SportActivity(id: "surfing", nameKey: "sport.surfing",
                      icon: "figure.surfing", category: .water, usesGPS: true,
                      healthKitType: HKWorkoutActivityType.surfingSports.rawValue,
                      kcalPerMinute: 6),
        SportActivity(id: "diving", nameKey: "sport.diving",
                      icon: "drop.fill", category: .water, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.waterSports.rawValue,
                      kcalPerMinute: 6),
        SportActivity(id: "paddleboard", nameKey: "sport.paddleboard",
                      icon: "figure.surfing", category: .water, usesGPS: true,
                      healthKitType: HKWorkoutActivityType.paddleSports.rawValue,
                      kcalPerMinute: 6),
        SportActivity(id: "kayaking", nameKey: "sport.kayaking",
                      icon: "oar.2.crossed", category: .water, usesGPS: true,
                      healthKitType: HKWorkoutActivityType.paddleSports.rawValue,
                      kcalPerMinute: 7),

        // Team & racquet sports
        SportActivity(id: "tennis", nameKey: "sport.tennis",
                      icon: "figure.tennis", category: .team, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.tennis.rawValue,
                      kcalPerMinute: 8),
        SportActivity(id: "soccer", nameKey: "sport.soccer",
                      icon: "figure.soccer", category: .team, usesGPS: true,
                      healthKitType: HKWorkoutActivityType.soccer.rawValue,
                      kcalPerMinute: 9),
        SportActivity(id: "basketball", nameKey: "sport.basketball",
                      icon: "figure.basketball", category: .team, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.basketball.rawValue,
                      kcalPerMinute: 9),
        SportActivity(id: "volleyball", nameKey: "sport.volleyball",
                      icon: "figure.volleyball", category: .team, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.volleyball.rawValue,
                      kcalPerMinute: 6),
        SportActivity(id: "baseball", nameKey: "sport.baseball",
                      icon: "figure.baseball", category: .team, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.baseball.rawValue,
                      kcalPerMinute: 5),
        SportActivity(id: "padel", nameKey: "sport.padel",
                      icon: "figure.tennis", category: .team, usesGPS: false,
                      healthKitType: HKWorkoutActivityType.racquetball.rawValue,
                      kcalPerMinute: 8),
    ]

    static func byCategory(_ cat: SportCategory) -> [SportActivity] {
        all.filter { $0.category == cat }
    }
}
