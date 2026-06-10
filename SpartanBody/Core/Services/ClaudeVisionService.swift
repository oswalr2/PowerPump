import Foundation
import UIKit

enum ScanError: LocalizedError {
    case dailyLimitReached
    case imageEncodingFailed
    case networkError(String)
    case parsingFailed
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .dailyLimitReached:   return "You've used all \(Config.dailyScanLimit) daily scans. Come back tomorrow!"
        case .imageEncodingFailed: return "Could not process the image. Try again."
        case .networkError(let m): return "Network error: \(m)"
        case .parsingFailed:       return "Couldn't read the response. Try a clearer photo."
        case .apiError(let m):     return m
        }
    }
}

final class ClaudeVisionService {
    static let shared = ClaudeVisionService()
    private init() {}

    // MARK: - Daily limit

    var scansUsedToday: Int {
        let key = todayKey()
        return UserDefaults.standard.integer(forKey: key)
    }

    var scansRemaining: Int { max(0, Config.dailyScanLimit - scansUsedToday) }
    var isLimitReached: Bool { scansUsedToday >= Config.dailyScanLimit }

    private func incrementScanCount() {
        let key = todayKey()
        UserDefaults.standard.set(scansUsedToday + 1, forKey: key)
    }

    private func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "sb_scan_\(f.string(from: Date()))"
    }

    // MARK: - Main API call

    func analyzeFood(image: UIImage) async throws -> FoodScanResponse {
        guard !isLimitReached else { throw ScanError.dailyLimitReached }

        // Compress: resize to max 1024px, JPEG 0.75
        guard let compressed = compress(image),
              let base64 = compressed.base64EncodedString() as String? else {
            throw ScanError.imageEncodingFailed
        }

        let language = LanguageManager.shared.languageNameForAI
        let prompt = """
        Analyze the food in this image. For EACH food item you can identify, estimate the weight and nutrition.
        Use food names in \(language).
        Respond ONLY with valid JSON — no explanation, no markdown, no code block. Use this exact format:
        {"items":[{"name":"Food Name","grams":150,"calories":200,"protein":15.0,"carbs":20.0,"fat":8.0}],"totalCalories":200,"totalProtein":15.0,"totalCarbs":20.0,"totalFat":8.0}
        If you cannot identify any food, respond: {"items":[],"totalCalories":0,"totalProtein":0,"totalCarbs":0,"totalFat":0}
        """

        let requestBody: [String: Any] = [
            "model": Config.claudeModel,
            "max_tokens": 1024,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": base64
                        ]
                    ],
                    ["type": "text", "text": prompt]
                ]
            ]]
        ]

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw ScanError.networkError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Config.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?
                          .description ?? "HTTP \(http.statusCode)"
            throw ScanError.apiError(msg)
        }

        // Parse Claude's response envelope
        guard let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (envelope["content"] as? [[String: Any]])?.first,
              let text = content["text"] as? String else {
            throw ScanError.parsingFailed
        }

        // Extract JSON from the text (handle any surrounding whitespace)
        return try parseFoodResponse(from: text)
    }

    // MARK: - Helpers

    private func parseFoodResponse(from text: String) throws -> FoodScanResponse {
        // Find the JSON object in the response text
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            throw ScanError.parsingFailed
        }
        let jsonString = String(text[start...end])
        guard let jsonData = jsonString.data(using: .utf8) else { throw ScanError.parsingFailed }

        do {
            let result = try JSONDecoder().decode(FoodScanResponse.self, from: jsonData)
            incrementScanCount()  // only count after a successful parse
            return result
        } catch {
            throw ScanError.parsingFailed
        }
    }

    private func compress(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 512
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.55)
    }
}
