//
//  LanguageManager.swift
//  MoodistMac
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }
}

enum LanguageManager {
    static let appleLanguagesKey = "AppleLanguages"

    static func language(for rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .system
    }

    static func applyPersistedLanguage() {
        let rawValue =
            UserDefaults.standard.string(forKey: PersistenceService.appLanguageKey)
            ?? AppLanguage.system.rawValue
        apply(language(for: rawValue))
    }

    static func apply(_ language: AppLanguage) {
        switch language {
        case .system:
            UserDefaults.standard.removeObject(forKey: appleLanguagesKey)
        case .english, .spanish:
            // AppleLanguages is scoped to this app's defaults domain here.
            UserDefaults.standard.set([language.rawValue], forKey: appleLanguagesKey)
        }
    }
}
