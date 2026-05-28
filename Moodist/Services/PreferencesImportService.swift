//
//  PreferencesImportService.swift
//  MoodistMac
//
//  Presents NSOpenPanel, reads exported preferences JSON, and returns the data to apply.
//

import Foundation
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif

enum PreferencesImportService {
    /// Presents the open panel, reads the JSON file, and decodes ExportedPreferences.
    /// - Returns: Imported data when the user chooses a valid file; nil when canceled or on error.
    @MainActor
    static func presentImportPanel() -> ExportedPreferences? {
#if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.title = L10n.importPreferences
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(ExportedPreferences.self, from: data)
            return payload
        } catch {
            let alert = NSAlert()
            alert.messageText = L10n.importFailed
            alert.informativeText = L10n.importFailedMessage
            alert.alertStyle = .warning
            alert.addButton(withTitle: L10n.close)
            alert.runModal()
            return nil
        }
#else
        return nil
#endif
    }
}
