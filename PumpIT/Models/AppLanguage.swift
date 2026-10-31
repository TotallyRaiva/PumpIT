//
//  AppLanguage.swift
//  PumpIT
//

import Foundation

public enum AppLanguage: String, CaseIterable, Codable, Identifiable, Sendable {
    case english = "en"
    case german = "de"

    public static let storageKey = "app_language"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .german: return "Deutsch"
        }
    }

    public var locale: Locale {
        Locale(identifier: rawValue)
    }

    /// Reads the currently active language from UserDefaults (defaulting to device language if German, otherwise English).
    public static var current: AppLanguage {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let lang = AppLanguage(rawValue: raw) {
            return lang
        }
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.lowercased().hasPrefix("de") ? .german : .english
    }
}

public enum L10n {
    public static func tr(_ en: String, _ de: String, lang: AppLanguage = .current) -> String {
        switch lang {
        case .english: return en
        case .german: return de
        }
    }
}
