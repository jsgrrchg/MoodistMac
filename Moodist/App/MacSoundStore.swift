import MoodistKit
import Combine
import Foundation

@MainActor
final class MacSoundStore: SoundStore {
    private var platformSubscriptions = Set<AnyCancellable>()
    @Published var showOptionsPanel = false
    @Published var showSavePresetSheet = false
    @Published var editingPresetId: String?
    @Published var requestSearchFocus = false

    override init(audioService: AudioService, preferences: PreferencesRepository = PreferencesRepository(), now: @escaping () -> Date = Date.init, scheduler: TimerScheduling? = nil) {
        super.init(audioService: audioService, preferences: preferences, now: now, scheduler: scheduler)
        $presets.sink { [weak self] presets in
            guard let self, let id = self.editingPresetId, !presets.contains(where: { $0.id == id }) else { return }
            self.closeSavePresetSheet()
        }.store(in: &platformSubscriptions)
        onTimerScheduled = { _, _ in TimerNotificationManager.shared.requestAuthorizationIfNeeded() }
        onTimerFinished = { TimerNotificationManager.shared.scheduleFinishedNotification(name: $0) }
    }

    func promptSaveCurrentPreset() {
        guard canSaveCustomMix else { return }
        editingPresetId = nil
        showSavePresetSheet = true
    }
    func beginEditingPreset(id: String) {
        guard presetsById[id] != nil else { return }
        editingPresetId = id
        showSavePresetSheet = true
    }
    func closeSavePresetSheet() { showSavePresetSheet = false; editingPresetId = nil }
    func createNewPresetWithSound(_ id: String) {
        guard sounds[id] != nil else { return }
        unselectAll()
        select(id)
        editingPresetId = nil
        showSavePresetSheet = true
    }
    func exportPreferences() -> Bool {
        PreferencesExportService.presentExportPanel(presets: presets, favoriteMixIds: favoriteMixIds, favoriteSoundIds: favoriteSoundIds)
    }
    func importPreferences() -> Bool {
        guard let payload = PreferencesImportService.presentImportPanel() else { return false }
        return applyImportedPreferences(payload)
    }
}
