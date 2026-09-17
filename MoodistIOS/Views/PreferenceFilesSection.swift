import SwiftUI
import MoodistKit

struct PreferenceFilesSection: View {
    @EnvironmentObject private var store: SoundStore
    @State private var importing = false
    @State private var exporting = false
    @State private var confirmImport = false
    @State private var pending: ExportedPreferences?
    @State private var document = PreferencesDocument(data: Data())
    @State private var sharedFile: SharedPreferenceFile?
    @State private var message: String?
    var body: some View {
        Section {
            Button(L10n.importPreferences, systemImage: "square.and.arrow.down") { importing = true }
            Button(L10n.exportPreferences, systemImage: "square.and.arrow.up") {
                perform { document = PreferencesDocument(data: try PreferencesCodec.encode(store.exportedPreferences())); exporting = true }
            }
            Button(T("share_preferences", "Share preferences"), systemImage: "square.and.arrow.up.on.square") {
                perform {
                    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
                    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                    let url = folder.appendingPathComponent("Moodist preferences.json")
                    do { try PreferencesCodec.encode(store.exportedPreferences()).write(to: url, options: .atomic) }
                    catch { try? FileManager.default.removeItem(at: folder); throw error }
                    sharedFile = SharedPreferenceFile(url: url)
                }
            }
        } header: { Text(T("preference_files", "Preference files")) }
        footer: { Text(T("files_hint", "Files contain custom mixes and favorites. Import replaces these collections; playback settings and recent history are not included.")) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            perform {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                var readError: NSError?
                var payload: Result<ExportedPreferences, Error>?
                NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &readError) { coordinated in
                    payload = Result {
                        let size = try coordinated.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                        guard size <= 16 * 1024 * 1024 else { throw CocoaError(.fileReadTooLarge) }
                        return try PreferencesCodec.decode(Data(contentsOf: coordinated))
                    }
                }
                if let readError { throw readError }
                guard let payload else { throw CocoaError(.fileReadUnknown) }
                pending = try payload.get()
                confirmImport = true
            }
        }
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "Moodist preferences") { result in
            perform { _ = try result.get(); message = T("export_complete", "Preferences exported.") }
        }
        .sheet(item: $sharedFile) { PreferenceShareSheet(file: $0) }
        .confirmationDialog(L10n.importPreferences, isPresented: $confirmImport, titleVisibility: .visible) {
            Button(T("replace_collections", "Replace mixes and favorites"), role: .destructive) {
                if let pending, store.applyImportedPreferences(pending) { store.flushPersistence() }
                pending = nil
            }
            Button(L10n.cancel, role: .cancel) { pending = nil }
        } message: { Text(T("import_warning", "This replaces your saved mixes and favorites with the file’s contents. Export a copy first if you want to keep them.")) }
        .alert(T("preference_files", "Preference files"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button(L10n.close) { message = nil }
        } message: { Text(message ?? "") }
    }
    private func perform(_ action: () throws -> Void) {
        do { try action() }
        catch {
            let ns = error as NSError
            if ns.domain == NSCocoaErrorDomain && ns.code == NSUserCancelledError { return }
            if case PreferencesCodec.Failure.unsupportedVersion = error { message = T("future_file", "This preference file was created by a newer version of Moodist.") }
            else { message = "\(T("file_error", "The file could not be read or saved. Your existing data was kept."))\n\(error.localizedDescription)" }
        }
    }
}
