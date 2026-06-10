import Foundation
import UIKit

enum AICoachError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:         return "Add your Anthropic API key in the AI Coach screen."
        case .invalidResponse:  return "Couldn't parse the AI response. Please try again."
        case .apiError(let m):  return m
        }
    }
}

struct AICoachService {

    // MARK: - API key

    static var apiKey: String {
        get { UserDefaults.standard.string(forKey: "sb_anthropic_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "sb_anthropic_key") }
    }

    // MARK: - Plan cache (7-day, keyed by profile snapshot)

    static func profileKey(weightKg: Double, heightCm: Double, goal: String,
                           activityLevel: String, dailyCalories: Int) -> String {
        "\(Int(weightKg))-\(Int(heightCm))-\(goal)-\(activityLevel)-\(dailyCalories)"
    }

    static func cachedPlan(for key: String) -> FitnessPlan? {
        guard let data = UserDefaults.standard.data(forKey: "sb_plan_cache"),
              let wrapper = try? JSONDecoder().decode(PlanCache.self, from: data),
              wrapper.profileKey == key,
              Date().timeIntervalSince(wrapper.generatedAt) < 7 * 86400
        else { return nil }
        return wrapper.plan
    }

    private static func storePlan(_ plan: FitnessPlan, for key: String) {
        let wrapper = PlanCache(plan: plan, profileKey: key, generatedAt: Date())
        if let data = try? JSONEncoder().encode(wrapper) {
            UserDefaults.standard.set(data, forKey: "sb_plan_cache")
        }
    }

    static func clearCache() {
        UserDefaults.standard.removeObject(forKey: "sb_plan_cache")
    }

    // MARK: - Plan generation (accepts pre-built prompt to avoid MainActor issues)

    static func generatePlan(prompt: String, image: UIImage?,
                             cacheKey: String? = nil) async throws -> FitnessPlan {
        if image == nil, let key = cacheKey, let cached = cachedPlan(for: key) {
            return cached
        }
        guard !apiKey.isEmpty else { throw AICoachError.noAPIKey }

        let body = buildBody(prompt: prompt, image: image)

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey,             forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?
                .description ?? "HTTP \(http.statusCode)"
            throw AICoachError.apiError(msg)
        }

        let plan = try parsePlan(from: data)
        if let key = cacheKey, image == nil { storePlan(plan, for: key) }
        return plan
    }

    // MARK: - Prompt builder (call from MainActor / view)

    static func buildPrompt(weightKg: Double, heightCm: Double,
                            bmi: Double, bmiCategory: String,
                            goal: String, activityLevel: String,
                            dailyCalories: Int, dailyProtein: Int,
                            extraContext: String, hasPhoto: Bool,
                            language: String = LanguageManager.shared.languageNameForAI) -> String {
        let goalAdvice: String
        switch goal {
        case "Lose Weight":  goalAdvice = "Focus on calorie deficit, cardio and compound movements."
        case "Gain Muscle":  goalAdvice = "Focus on progressive overload, hypertrophy, and high protein."
        default:             goalAdvice = "Focus on balanced training, endurance, and healthy maintenance."
        }

        let dayNames = localizedDayNames(for: language)
        let langInstruction = language == "English" ? "" : """

        ██ LANGUAGE RULE — MANDATORY ██
        The user's language is \(language). You MUST write EVERY single word of your response in \(language).
        This includes: analysis, day names, focus area, every exercise name, every tip, nutrition tips, motivation.
        Do NOT use English anywhere in the JSON. Translate everything.
        Day names to use (in order Mon–Sun): \(dayNames.joined(separator: ", "))
        ████████████████████████████████
        """

        return """
        User profile:
        - Weight: \(Int(weightKg)) kg
        - Height: \(Int(heightCm)) cm
        - BMI: \(String(format: "%.1f", bmi)) (\(bmiCategory))
        - Fitness goal: \(goal)
        - Activity level: \(activityLevel)
        - Daily calorie target: \(dailyCalories) kcal
        - Daily protein target: \(dailyProtein) g
        \(extraContext.isEmpty ? "" : "\nAdditional context: \(extraContext)\n")
        \(hasPhoto ? "A photo of the user's physique is attached — use it to personalise the assessment.\n" : "")
        \(goalAdvice)\(langInstruction)

        Create a highly personalised 7-day fitness & nutrition plan.
        Return ONLY valid JSON — no markdown, no text outside the JSON — in this exact structure:
        {
          "analysis": "2-3 sentences analysing the user and what the plan targets",
          "weeklySchedule": [
            {
              "day": "Monday",
              "type": "workout",
              "focus": "Chest & Triceps",
              "exercises": ["Bench Press 4×8", "Incline DB Press 3×10", "Push-ups 3×15", "Tricep Dips 3×12"]
            },
            {
              "day": "Tuesday",
              "type": "rest",
              "focus": "Active Recovery",
              "exercises": ["20-min walk", "10-min stretching", "Foam roll"]
            }
          ],
          "nutritionPlan": {
            "calories": 2400,
            "protein": 160,
            "carbs": 250,
            "fat": 75,
            "tips": ["Eat protein within 45 min post-workout", "Drink 3 L water daily"]
          },
          "tips": ["Sleep 7-9 hours for optimal recovery", "Track your lifts to ensure progression"],
          "motivation": "One powerful personalised motivational sentence"
        }
        All 7 days must appear. Exercises must include sets×reps or duration.
        Return ONLY the JSON object.
        """
    }

    // MARK: - Day name translations

    private static func localizedDayNames(for language: String) -> [String] {
        switch language {
        case "Spanish":
            return ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        case "Italian":
            return ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]
        case "Brazilian Portuguese":
            return ["Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo"]
        case "French":
            return ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        default:
            return ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        }
    }

    // MARK: - Request body

    private static func buildBody(prompt: String, image: UIImage?) -> [String: Any] {
        var parts: [[String: Any]] = []

        if let img = image, let jpeg = img.jpegData(compressionQuality: 0.7) {
            parts.append([
                "type": "image",
                "source": [
                    "type":       "base64",
                    "media_type": "image/jpeg",
                    "data":       jpeg.base64EncodedString()
                ]
            ])
        }

        parts.append(["type": "text", "text": prompt])

        return [
            "model":      "claude-haiku-4-5-20251001",
            "max_tokens": 2048,
            "messages":   [["role": "user", "content": parts]]
        ]
    }

    // MARK: - Response parser

    private static func parsePlan(from data: Data) throws -> FitnessPlan {
        guard let root    = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (root["content"] as? [[String: Any]])?.first,
              let text    = content["text"] as? String
        else { throw AICoachError.invalidResponse }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonString: String
        if let start = trimmed.firstIndex(of: "{"),
           let end   = trimmed.lastIndex(of: "}") {
            jsonString = String(trimmed[start...end])
        } else {
            jsonString = trimmed
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AICoachError.invalidResponse
        }

        return try JSONDecoder().decode(FitnessPlan.self, from: jsonData)
    }
}

private struct PlanCache: Codable {
    let plan: FitnessPlan
    let profileKey: String
    let generatedAt: Date
}
