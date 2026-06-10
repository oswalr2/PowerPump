import SwiftUI

@main
struct SpartanBodyApp: App {
    @ObservedObject private var theme    = ThemeManager.shared
    @ObservedObject private var language = LanguageManager.shared

    init() {
        _ = PhoneConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(language.selectedCode)
                .preferredColorScheme(theme.current.colorScheme)
                .environmentObject(theme)
                .environment(\.locale, language.locale)
        }
    }
}
