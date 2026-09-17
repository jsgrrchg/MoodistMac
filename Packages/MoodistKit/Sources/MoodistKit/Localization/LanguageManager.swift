//
//  LanguageManager.swift
//  MoodistMac
//

import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case spanish = "es"
    case portuguese = "pt-BR"

    public var id: String { rawValue }
}

public enum LanguageManager {
    public static let appleLanguagesKey = "AppleLanguages"

    public static func language(for rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .system
    }

    public static func applyPersistedLanguage() {
        let rawValue =
            UserDefaults.standard.string(forKey: PersistenceService.appLanguageKey)
            ?? AppLanguage.system.rawValue
        apply(language(for: rawValue))
    }

    public static func apply(_ language: AppLanguage) {
        switch language {
        case .system:
            UserDefaults.standard.removeObject(forKey: appleLanguagesKey)
        case .english, .spanish, .portuguese:
            // AppleLanguages is scoped to this app's defaults domain here.
            UserDefaults.standard.set([language.rawValue], forKey: appleLanguagesKey)
        }
    }
}
