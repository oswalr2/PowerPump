import Foundation
import SwiftUI

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
    }
}
