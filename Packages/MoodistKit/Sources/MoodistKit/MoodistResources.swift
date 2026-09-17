import Foundation

public enum MoodistResources {
    public static let bundle = Bundle.module
    public static func soundURL(_ sound: Sound) -> URL? {
        bundle.url(forResource: sound.fileName, withExtension: nil, subdirectory: "sounds/\(sound.categoryFolder)")
    }
    public static func localizedString(_ key: String, fallback: String, language: String? = nil) -> String {
        let selected = language ?? UserDefaults.standard.string(forKey: PersistenceService.appLanguageKey) ?? "system"
        let code = selected == "system" ? Bundle.preferredLocalizations(from: ["en", "es", "pt-BR"]).first ?? "en" : selected
        let localized = bundle.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:)) ?? bundle
        return localized.localizedString(forKey: key, value: fallback, table: nil)
    }
}
