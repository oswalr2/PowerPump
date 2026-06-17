import Foundation
import SwiftUI
import ObjectiveC

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    struct Language: Identifiable {
        let id: String
        let nativeName: String
        let flag: String
    }

    static let available: [Language] = [
        Language(id: "en",    nativeName: "English",            flag: "🇬🇧"),
        Language(id: "es",    nativeName: "Español",            flag: "🇪🇸"),
        Language(id: "it",    nativeName: "Italiano",           flag: "🇮🇹"),
        Language(id: "pt-BR", nativeName: "Português (Brasil)", flag: "🇧🇷"),
        Language(id: "fr",    nativeName: "Français",           flag: "🇫🇷"),
    ]

    @Published var selectedCode: String

    var locale: Locale { Locale(identifier: selectedCode) }

    var currentLanguage: Language {
        Self.available.first { $0.id == selectedCode } ?? Self.available[0]
    }

    // Plain English name used in Claude API prompts
    var languageNameForAI: String {
        switch selectedCode {
        case "es":    return "Spanish"
        case "it":    return "Italian"
        case "pt-BR": return "Brazilian Portuguese"
        case "fr":    return "French"
        default:      return "English"
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "sb_language")
        if let saved, Self.available.map(\.id).contains(saved) {
            selectedCode = saved
        } else {
            selectedCode = Self.detectDeviceLanguage()
            UserDefaults.standard.set(selectedCode, forKey: "sb_language")
        }
        UserDefaults.standard.set([selectedCode], forKey: "AppleLanguages")
        // Install the bundle override so SwiftUI's Text("...") routes through
        // the selected language's lproj even when the OS language differs.
        Bundle.activateLanguageOverride()
        Bundle.setLanguage(selectedCode)
    }

    private static func detectDeviceLanguage() -> String {
        let supported = Self.available.map(\.id)
        for preferred in Locale.preferredLanguages {
            let locale = Locale(identifier: preferred)
            let lang   = locale.language.languageCode?.identifier ?? ""
            let region = locale.region?.identifier ?? ""
            if lang == "pt" && region == "BR" && supported.contains("pt-BR") { return "pt-BR" }
            if supported.contains(lang) { return lang }
        }
        return "en"
    }

    func select(_ code: String) {
        guard selectedCode != code else { return }
        selectedCode = code
        UserDefaults.standard.set(code, forKey: "sb_language")
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        // Live switch — no app restart needed.
        Bundle.setLanguage(code)
        objectWillChange.send()
        // Force any SwiftUI view that doesn't observe LanguageManager directly
        // to redraw (date pickers, Text(verbatim:), etc.).
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("sb.languageDidChange")
}

// MARK: - Bundle override (so NSLocalizedString and Text("...") follow
// LanguageManager regardless of the system language).

private var sbBundleKey: UInt8 = 0

extension Bundle {
    static func activateLanguageOverride() {
        guard self !== SBLanguageBundle.self else { return }
        object_setClass(Bundle.main, SBLanguageBundle.self)
    }

    static func setLanguage(_ language: String) {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            objc_setAssociatedObject(Bundle.main, &sbBundleKey, nil, .OBJC_ASSOCIATION_RETAIN)
            return
        }
        objc_setAssociatedObject(Bundle.main, &sbBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN)
    }
}

private final class SBLanguageBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let override = objc_getAssociatedObject(self, &sbBundleKey) as? Bundle {
            return override.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}
