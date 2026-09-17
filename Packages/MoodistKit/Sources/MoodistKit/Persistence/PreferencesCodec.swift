import Foundation

public enum PreferencesCodec {
    public enum Failure: Error { case unsupportedVersion(Int) }
    public static func decode(_ data: Data) throws -> ExportedPreferences {
        let payload = try JSONDecoder().decode(ExportedPreferences.self, from: data)
        guard payload.version == ExportedPreferences.currentVersion else {
            throw Failure.unsupportedVersion(payload.version)
        }
        return payload
    }
    public static func encode(_ payload: ExportedPreferences) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }
}
