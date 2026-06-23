import Foundation

enum BarcodeLookupError: LocalizedError {
    case notFound
    case network

    var errorDescription: String? {
        switch self {
        case .notFound:
            return NSLocalizedString("Product not found. Try searching by name.", comment: "")
        case .network:
            return NSLocalizedString("No connection. Check your internet and try again.", comment: "")
        }
    }
}

// Looks up packaged products by barcode in Open Food Facts (free, ~3M products).
// Results are cached on-device so repeat scans work offline.
final class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    private init() { loadCache() }

    private var cache: [String: FoodItem] = [:]
    private let cacheKey = "sb_barcode_cache"
    private let cacheLimit = 300

    func lookup(barcode: String) async throws -> FoodItem {
        if let cached = cache[barcode] { return cached }

        let lang = String(LanguageManager.shared.selectedCode.prefix(2))
        let fields = "product_name,product_name_\(lang),brands,nutriments"
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=\(fields)") else {
            throw BarcodeLookupError.network
        }

        var request = URLRequest(url: url)
        request.setValue("PowerPump-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            throw BarcodeLookupError.network
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["status"] as? Int == 1,
              let product = json["product"] as? [String: Any],
              let nutriments = product["nutriments"] as? [String: Any],
              let kcal = doubleValue(nutriments["energy-kcal_100g"]) else {
            throw BarcodeLookupError.notFound
        }

        let localizedName = nonEmpty(product["product_name_\(lang)"] as? String)
        let baseName      = nonEmpty(product["product_name"] as? String)
        let brand = (product["brands"] as? String)?
            .components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces)

        var name = localizedName ?? baseName ?? NSLocalizedString("Scanned product", comment: "")
        if let brand, !brand.isEmpty, !name.localizedCaseInsensitiveContains(brand) {
            name = "\(name) (\(brand))"
        }

        let item = FoodItem(
            id: "barcode_\(barcode)",
            name: name,
            category: .other,
            per100g: NutritionInfo(
                calories: kcal,
                protein:  doubleValue(nutriments["proteins_100g"]) ?? 0,
                carbs:    doubleValue(nutriments["carbohydrates_100g"]) ?? 0,
                fat:      doubleValue(nutriments["fat_100g"]) ?? 0
            )
        )

        cache[barcode] = item
        saveCache()
        return item
    }

    // MARK: - Helpers

    private func nonEmpty(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespaces), !s.isEmpty else { return nil }
        return s
    }

    private func doubleValue(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int    { return Double(i) }
        if let s = any as? String { return Double(s) }
        return nil
    }

    // MARK: - Cache

    private func loadCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([String: FoodItem].self, from: data) {
            cache = decoded
        }
    }

    private func saveCache() {
        if cache.count > cacheLimit {
            // Drop arbitrary overflow — repeat scans will simply re-fetch.
            cache = Dictionary(uniqueKeysWithValues: Array(cache.suffix(cacheLimit)))
        }
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
