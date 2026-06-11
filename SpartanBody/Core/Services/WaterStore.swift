import Foundation

final class WaterStore: ObservableObject {
    static let shared = WaterStore()

    @Published private(set) var todayGlasses: Int = 0

    private init() {
        load()
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged, object: nil, queue: .main
        ) { [weak self] _ in
            self?.load()
        }
    }

    func set(_ glasses: Int) {
        todayGlasses = max(0, min(8, glasses))
        UserDefaults.standard.set(todayGlasses, forKey: todayKey)
        HealthKitService.shared.saveWater(glasses: todayGlasses)
    }

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var todayKey: String {
        "sb_water_\(Self.keyFormatter.string(from: .now))"
    }

    private func load() {
        todayGlasses = UserDefaults.standard.integer(forKey: todayKey)
    }
}
