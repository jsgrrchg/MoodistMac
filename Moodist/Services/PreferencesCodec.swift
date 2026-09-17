import Foundation

enum PreferencesCodec {
    enum Failure: Error { case unsupportedVersion(Int) }
    static func decode(_ data: Data) throws -> ExportedPreferences {
        let payload = try JSONDecoder().decode(ExportedPreferences.self, from: data)
        guard payload.version == ExportedPreferences.currentVersion else {
            throw Failure.unsupportedVersion(payload.version)
        }
        return payload
    }
    static func encode(_ payload: ExportedPreferences) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }
}
