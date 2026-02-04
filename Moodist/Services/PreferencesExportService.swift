//
//  PreferencesExportService.swift
//  MoodistMac
//
//  Presenta NSSavePanel y escribe las preferencias exportadas a un archivo JSON.
//

import Foundation
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif

enum PreferencesExportService {
    /// Presenta el panel de guardado y escribe las preferencias en el archivo elegido.
    /// - Returns: true si el usuario guardó correctamente, false si canceló o hubo error.
    @MainActor
    static func presentExportPanel(presets: [Preset], favoriteMixIds: [String], favoriteSoundIds: [String]) -> Bool {
        let payload = ExportedPreferences(
            version: ExportedPreferences.currentVersion,
            exportDate: ExportedPreferences.exportDateString(),
            presets: presets,
            favoriteMixIds: favoriteMixIds,
            favoriteSoundIds: favoriteSoundIds
        )
        guard let data = try? JSONEncoder().encode(payload) else { return false }
#if canImport(AppKit)
        let panel = NSSavePanel()
        panel.title = L10n.exportPreferences
        panel.nameFieldStringValue = suggestedFilename()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        do {
            try data.write(to: url)
            return true
        } catch {
            let alert = NSAlert()
            alert.messageText = L10n.exportFailed
            alert.informativeText = L10n.exportFailedMessage
            alert.alertStyle = .warning
            alert.addButton(withTitle: L10n.close)
            alert.runModal()
            return false
        }
#else
        return false
#endif
    }

    private static func suggestedFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        return "Moodist preferences \(dateStr).json"
    }
}
