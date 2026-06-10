import SwiftUI

enum AppTheme: String, CaseIterable {
    case dark  = "Dark"
    case light = "Light"

    var colorScheme: ColorScheme {
        self == .dark ? .dark : .light
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var current: AppTheme {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "sb_theme") }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "sb_theme") ?? ""
        current = AppTheme(rawValue: saved) ?? .dark
    }
}
