import SwiftUI

/// App language and theme chosen in Profile (same choices as the Android app), kept in UserDefaults.
@MainActor
final class Prefs: ObservableObject {
    static let shared = Prefs()

    enum Language: String, CaseIterable { case system, uz, ru, en }
    enum Theme: String, CaseIterable { case system, light, dark }

    @Published var language: Language {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "language"); Prefs.code = Prefs.resolve(language) }
    }
    @Published var theme: Theme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "theme") }
    }

    /// "uz" | "ru" | "en": the language the UI is shown in (also sent as Accept-Language). Read from any thread.
    nonisolated(unsafe) static var code = "uz"

    private init() {
        let lang = Language(rawValue: UserDefaults.standard.string(forKey: "language") ?? "") ?? .system
        language = lang
        theme = Theme(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "") ?? .system
        Prefs.code = Prefs.resolve(lang)
    }

    /// The phone's language when it is Russian or English, otherwise Uzbek.
    private static func resolve(_ language: Language) -> String {
        if language != .system { return language.rawValue }
        for id in Locale.preferredLanguages {
            let code = String(id.prefix(2))
            if ["uz", "ru", "en"].contains(code) { return code }
        }
        return "uz"
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func languageName(_ l: Language) -> String {
        switch l {
        case .system: return tr("lang_system")
        case .uz: return "O'zbekcha"
        case .ru: return "Русский"
        case .en: return "English"
        }
    }

    func themeName(_ t: Theme) -> String {
        switch t {
        case .system: return tr("theme_system")
        case .light: return tr("theme_light")
        case .dark: return tr("theme_dark")
        }
    }
}

/// A UI string in the current app language; `%1$d` / `%1$s` style arguments as in the Android resources.
func tr(_ key: String, _ args: CVarArg...) -> String {
    guard let entry = stringsTable[key] else { return key }
    let text: String
    switch Prefs.code {
    case "ru": text = entry.ru
    case "en": text = entry.en
    default: text = entry.uz
    }
    guard !args.isEmpty else { return text }
    // Android uses %s for strings; Swift's String(format:) needs %@.
    return String(format: text.replacingOccurrences(of: "$s", with: "$@"), arguments: args)
}
