import Foundation

extension SoundStore {
    // Alterna favorito de sonido y sincroniza el orden persistido de favoritos.
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

    /// Añade o quita un mix de favoritos por su id.
    func toggleFavoriteMix(id: String) {
        if favoriteMixIds.contains(id) {
            favoriteMixIds.removeAll { $0 == id }
        } else {
            favoriteMixIds.append(id)
        }
    }

    // Inserta al inicio y recorta al límite configurado para recientes de mixes.
    func addToRecentMixes(mixId: String) {
        var ids = recentMixIds
        ids.removeAll { $0 == mixId }
        ids.insert(mixId, at: 0)
        let limit = PersistenceService.loadMaxRecentMixesCount()
        recentMixIds = Array(ids.prefix(limit))
    }

    // Inserta al inicio y recorta al límite configurado para recientes de sonidos.
    func addToRecentSounds(soundId: String) {
        var ids = recentSoundIds
        ids.removeAll { $0 == soundId }
        ids.insert(soundId, at: 0)
        let limit = PersistenceService.loadMaxRecentSoundsCount()
        recentSoundIds = Array(ids.prefix(limit))
    }

    /// Recorta la lista de mixes recientes al límite configurado en Opciones (p. ej. al reducir el máximo).
    func trimRecentMixIdsToLimit() {
        let limit = PersistenceService.loadMaxRecentMixesCount()
        if recentMixIds.count > limit {
            recentMixIds = Array(recentMixIds.prefix(limit))
        }
    }

    /// Recorta la lista de sonidos recientes al límite configurado en Opciones.
    func trimRecentSoundIdsToLimit() {
        let limit = PersistenceService.loadMaxRecentSoundsCount()
        if recentSoundIds.count > limit {
            recentSoundIds = Array(recentSoundIds.prefix(limit))
        }
    }
}
