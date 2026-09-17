import SwiftUI
import MoodistKit

struct LibraryView: View {
    @EnvironmentObject private var store: SoundStore
    private func mix(_ id: String) -> Mix? { store.presetsById[id]?.toMix() ?? MixesData.allMixesById[id] }
    var body: some View {
        List {
            Section(L10n.sidebarFavorites) {
                if store.orderedFavoriteSoundIds.isEmpty { Text(L10n.sidebarFavoritesEmpty).foregroundStyle(.secondary) }
                ForEach(store.orderedFavoriteSoundIds, id: \.self) { id in
                    if let sound = SoundsData.allSoundsById[id] {
                        SoundCell(sound: sound)
                            .accessibilityAction(named: T("move_up", "Move up")) { moveSound(id, delta: -1) }
                            .accessibilityAction(named: T("move_down", "Move down")) { moveSound(id, delta: 1) }
                    }
                }.onMove { source, destination in
                    var ids = store.orderedFavoriteSoundIds
                    ids.move(fromOffsets: source, toOffset: destination)
                    store.favoriteSoundIds = ids
                }
            }
            Section(L10n.sidebarFavoriteMixes) {
                if store.favoriteMixIds.isEmpty { Text(L10n.sidebarFavoriteMixesEmpty).foregroundStyle(.secondary) }
                ForEach(store.favoriteMixIds, id: \.self) { id in
                    if let mix = mix(id) {
                        MixCell(mix: mix)
                            .accessibilityAction(named: T("move_up", "Move up")) { moveMix(id, delta: -1) }
                            .accessibilityAction(named: T("move_down", "Move down")) { moveMix(id, delta: 1) }
                    }
                }.onMove { store.favoriteMixIds.move(fromOffsets: $0, toOffset: $1) }
            }
            Section(L10n.customMix) {
                if store.presets.isEmpty { Text(T("no_custom_mixes", "Save your first mix from the player.")).foregroundStyle(.secondary) }
                ForEach(store.presets) { MixCell(mix: $0.toMix()) }
            }
            Section(L10n.sidebarRecentMixes) {
                if store.recentMixIds.isEmpty { Text(L10n.sidebarRecentMixesEmpty).foregroundStyle(.secondary) }
                ForEach(store.recentMixIds, id: \.self) { id in
                    if let mix = mix(id) { MixCell(mix: mix) }
                }
            }
            Section(L10n.sidebarRecentSounds) {
                if store.recentSoundIds.isEmpty { Text(L10n.sidebarRecentSoundsEmpty).foregroundStyle(.secondary) }
                ForEach(store.recentSoundIds, id: \.self) { id in
                    if let sound = SoundsData.allSoundsById[id] { SoundCell(sound: sound) }
                }
            }
        }
        .navigationTitle(T("library", "Library"))
        .toolbar { ToolbarItem(placement: .topBarLeading) { EditButton() } }
    }
    private func moveSound(_ id: String, delta: Int) {
        var ids = store.orderedFavoriteSoundIds
        guard let index = ids.firstIndex(of: id), ids.indices.contains(index + delta) else { return }
        ids.swapAt(index, index + delta); store.favoriteSoundIds = ids
    }
    private func moveMix(_ id: String, delta: Int) {
        guard let index = store.favoriteMixIds.firstIndex(of: id), store.favoriteMixIds.indices.contains(index + delta) else { return }
        store.favoriteMixIds.swapAt(index, index + delta)
    }
}
