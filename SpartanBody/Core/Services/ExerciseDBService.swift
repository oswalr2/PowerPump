import Foundation

// Fetches animated GIF URLs from ExerciseDB (RapidAPI).
// GIF URLs are cached in UserDefaults so each exercise is only fetched once.
struct ExerciseDBService {

    // MARK: - Name mapping: our exercise IDs → ExerciseDB search terms
    private static let nameMap: [String: String] = [
        "bench_press":            "barbell bench press",
        "incline_dumbbell_press": "incline dumbbell press",
        "push_up":                "push up",
        "cable_fly":              "cable crossover",
        "pull_up":                "pull up",
        "lat_pulldown":           "lat pulldown",
        "barbell_row":            "barbell bent over row",
        "dumbbell_row":           "dumbbell one arm row",
        "overhead_press":         "barbell overhead press",
        "lateral_raise":          "dumbbell lateral raise",
        "pike_push_up":           "pike push up",
        "barbell_curl":           "barbell curl",
        "hammer_curl":            "hammer curl",
        "tricep_dip":             "triceps dip",
        "skull_crusher":          "ez bar skullcrusher",
        "squat":                  "barbell squat",
        "goblet_squat":           "dumbbell goblet squat",
        "romanian_deadlift":      "romanian deadlift",
        "walking_lunge":          "dumbbell walking lunge",
        "hip_thrust":             "barbell hip thrust",
        "glute_bridge":           "glute bridge",
        "deadlift":               "barbell deadlift",
        "clean_and_press":        "barbell clean and press",
        "plank":                  "plank",
        "crunch":                 "crunch",
        "russian_twist":          "russian twist",
        "leg_raise":              "hanging leg raise",
        "jump_rope":              "jump rope",
        "mountain_climber":       "mountain climber",
        "box_jump":               "box jump",
    ]

    // MARK: - Public API

    /// Returns cached URL if available; otherwise fetches from ExerciseDB.
    static func gifURL(for exercise: Exercise) async -> URL? {
        let key = apiKey
        guard !key.isEmpty else { return nil }

        // Cache hit
        let cacheKey = "exercisedb_gif_\(exercise.id)"
        if let cached = UserDefaults.standard.string(forKey: cacheKey),
           let url = URL(string: cached) {
            return url
        }

        // Network fetch
        let term = nameMap[exercise.id] ?? exercise.name.lowercased()
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let endpoint = URL(string: "https://exercisedb.p.rapidapi.com/exercises/name/\(encoded)?limit=1")
        else { return nil }

        var req = URLRequest(url: endpoint)
        req.setValue(key, forHTTPHeaderField: "X-RapidAPI-Key")
        req.setValue("exercisedb.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        req.timeoutInterval = 10

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let items = try? JSONDecoder().decode([ExerciseDBItem].self, from: data),
              let gifUrl = items.first?.gifUrl
        else { return nil }

        // Persist to cache
        UserDefaults.standard.set(gifUrl, forKey: cacheKey)
        return URL(string: gifUrl)
    }

    // MARK: - API key (stored in UserDefaults so user can set it in Profile)
    static var apiKey: String {
        get { UserDefaults.standard.string(forKey: "exercisedb_api_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "exercisedb_api_key") }
    }

    static func clearCache() {
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("exercisedb_gif_") }
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}

private struct ExerciseDBItem: Codable {
    let id: String
    let gifUrl: String
}
