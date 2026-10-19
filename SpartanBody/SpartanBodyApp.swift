import SwiftUI

@main
struct SpartanBodyApp: App {
    @ObservedObject private var theme    = ThemeManager.shared
    @ObservedObject private var language = LanguageManager.shared

    init() {
        _ = PhoneConnectivityManager.shared
        // Restores a run that was going when the app was closed.
        _ = RunStore.shared
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
