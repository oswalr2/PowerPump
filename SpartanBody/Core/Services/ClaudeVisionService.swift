import Foundation
import UIKit

enum ScanError: LocalizedError {
    case weeklyLimitReached
    case imageEncodingFailed
    case networkError(String)
    case parsingFailed
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .weeklyLimitReached:  return "You've used your free scan for this week. Come back next week!"
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

    // MARK: - User ID (stable per install, sent to the proxy for rate limiting)

    private var userID: String {
        if let id = UserDefaults.standard.string(forKey: "sb_user_id") { return id }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: "sb_user_id")
        return id
    }

    // MARK: - Weekly limit (UI only — the proxy is the source of truth)

    var scansUsedThisWeek: Int {
        UserDefaults.standard.integer(forKey: weekKey())
    }

    var scansRemaining: Int { max(0, Config.weeklyScanLimit - scansUsedThisWeek) }
    var isLimitReached: Bool { scansUsedThisWeek >= Config.weeklyScanLimit }

    private func incrementScanCount() {
        UserDefaults.standard.set(scansUsedThisWeek + 1, forKey: weekKey())
    }

    private func markLimitReached() {
        UserDefaults.standard.set(Config.weeklyScanLimit, forKey: weekKey())
    }

    private func weekKey() -> String {
        let cal = Calendar(identifier: .iso8601)
        let c = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return String(format: "sb_scan_%04d-W%02d", c.yearForWeekOfYear ?? 0, c.weekOfYear ?? 0)
    }

    // MARK: - Main API call (via Cloudflare Worker proxy)

    func analyzeFood(image: UIImage) async throws -> FoodScanResponse {
        guard !isLimitReached else { throw ScanError.weeklyLimitReached }

        guard let compressed = compress(image) else {
            throw ScanError.imageEncodingFailed
        }

        guard let url = URL(string: Config.scanProxyURL) else {
            throw ScanError.networkError("Invalid proxy URL")
        }

        let requestBody: [String: Any] = [
            "user_id":  userID,
            "image":    compressed.base64EncodedString(),
            "language": LanguageManager.shared.languageNameForAI,
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            if http.statusCode == 429 {
                markLimitReached()
                throw ScanError.weeklyLimitReached
            }
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?
                          .description ?? "HTTP \(http.statusCode)"
            throw ScanError.apiError(msg)
        }

        // Parse Claude's response envelope (forwarded verbatim by the proxy)
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
