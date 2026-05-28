import Foundation

extension SoundStore {
    // Toggles a sound favorite and synchronizes the persisted favorite order.
    func toggleFavorite(_ id: String) {
        guard var item = sounds[id] else { return }
        item.isFavorite.toggle()
        sounds[id] = item
        if item.isFavorite {
            if !favoriteSoundIds.contains(id) { favoriteSoundIds.append(id) }
        } else {
            favoriteSoundIds.removeAll { $0 == id }
        }
    }

    /// Adds or removes a mix favorite by ID.
    func toggleFavoriteMix(id: String) {
        if favoriteMixIds.contains(id) {
            favoriteMixIds.removeAll { $0 == id }
        } else {
            favoriteMixIds.append(id)
        }
    }

    // Inserts at the front and trims to the configured recent mixes limit.
    func addToRecentMixes(mixId: String) {
        var ids = recentMixIds
        ids.removeAll { $0 == mixId }
        ids.insert(mixId, at: 0)
        let limit = PersistenceService.loadMaxRecentMixesCount()
        recentMixIds = Array(ids.prefix(limit))
    }

    // Inserts at the front and trims to the configured recent sounds limit.
    func addToRecentSounds(soundId: String) {
        var ids = recentSoundIds
        ids.removeAll { $0 == soundId }
        ids.insert(soundId, at: 0)
        let limit = PersistenceService.loadMaxRecentSoundsCount()
        recentSoundIds = Array(ids.prefix(limit))
    }

    /// Trims recent mixes to the limit configured in Options.
    func trimRecentMixIdsToLimit() {
        let limit = PersistenceService.loadMaxRecentMixesCount()
        if recentMixIds.count > limit {
            recentMixIds = Array(recentMixIds.prefix(limit))
        }
    }

    /// Trims recent sounds to the limit configured in Options.
    func trimRecentSoundIdsToLimit() {
        let limit = PersistenceService.loadMaxRecentSoundsCount()
        if recentSoundIds.count > limit {
            recentSoundIds = Array(recentSoundIds.prefix(limit))
        }
    }
}
