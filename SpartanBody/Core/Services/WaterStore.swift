import Foundation

final class WaterStore: ObservableObject {
    static let shared = WaterStore()

    @Published private(set) var todayGlasses: Int = 0

    private init() { load() }

    func set(_ glasses: Int) {
        todayGlasses = max(0, min(8, glasses))
        UserDefaults.standard.set(todayGlasses, forKey: todayKey)
        HealthKitService.shared.saveWater(glasses: todayGlasses)
    }

    private var todayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "sb_water_\(f.string(from: .now))"
    }

    private func load() {
        todayGlasses = UserDefaults.standard.integer(forKey: todayKey)
    }
}
