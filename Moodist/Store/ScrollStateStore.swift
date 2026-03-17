//
//  ScrollStateStore.swift
//  MoodistMac
//
//  Stores and restores scroll anchors for sounds/mixes contexts.
//

import Foundation

enum ContentSection: String, CaseIterable {
    case sounds
    case mixes
}

@MainActor
final class ScrollStateStore {
    enum Context {
        case sounds
        case mixes
        case soundsSearch
        case mixesSearch
    }
    // Identificador de ancla para el inicio de las listas (usado también como fallback).
    static let scrollTopAnchorId = "mainScrollTop"
    static let persistenceKeySounds = "sounds"
    static let persistenceKeyMixes = "mixes"
    static let persistenceKeySoundsSearch = "soundsSearch"
    static let persistenceKeyMixesSearch = "mixesSearch"

    var soundsScrollAnchorId: String = scrollTopAnchorId
    var mixesScrollAnchorId: String = scrollTopAnchorId
    var soundsSearchScrollAnchorId: String = scrollTopAnchorId
    var mixesSearchScrollAnchorId: String = scrollTopAnchorId

    var suppressSoundsScrollMemoryUpdates = false
    var suppressMixesScrollMemoryUpdates = false
    var didRestoreSounds = false
    var didRestoreMixes = false

    private var persistScrollTask: Task<Void, Never>?
    private var soundsRestoreTask: Task<Void, Never>?
    private var mixesRestoreTask: Task<Void, Never>?
    private var soundsRestoreGeneration = 0
    private var mixesRestoreGeneration = 0

    deinit {
        persistScrollTask?.cancel()
        soundsRestoreTask?.cancel()
        mixesRestoreTask?.cancel()
    }
    // Determina el contexto actual (sounds/mixes + search/no search) para usar el ancla de scroll apropiada.
    func context(for section: ContentSection, searchQuery: String) -> Context {
        let isSearching = !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if section == .mixes {
            return isSearching ? .mixesSearch : .mixes
        }
        return isSearching ? .soundsSearch : .sounds
    }
    // Obtiene el id de ancla de scroll almacenado para el contexto dado.
    func storedScrollAnchorId(for context: Context) -> String {
        switch context {
        case .sounds:
            return soundsScrollAnchorId
        case .mixes:
            return mixesScrollAnchorId
        case .soundsSearch:
            return soundsSearchScrollAnchorId
        case .mixesSearch:
            return mixesSearchScrollAnchorId
        }
    }
    // Almacena el id de ancla de scroll para el contexto dado, para restaurarlo en el futuro.
    func setStoredScrollAnchorId(_ id: String, for context: Context) {
        switch context {
        case .sounds:
            soundsScrollAnchorId = id
        case .mixes:
            mixesScrollAnchorId = id
        case .soundsSearch:
            soundsSearchScrollAnchorId = id
        case .mixesSearch:
            mixesSearchScrollAnchorId = id
        }
    }
    // Determina si un id de ancla de scroll es relevante para el contexto actual, para evitar restaurar posiciones que no correspondan al tipo de contenido mostrado.
    func isRelevantScrollAnchorId(_ id: String, for context: Context) -> Bool {
        if id == Self.scrollTopAnchorId { return true }
        switch context {
        case .sounds:
            return id.hasPrefix("category-")
        case .mixes:
            return id.hasPrefix("mix-category-")
        case .soundsSearch:
            return id.hasPrefix("search-category-")
        case .mixesSearch:
            return id.hasPrefix("mix-search-")
        }
    }
    // Construye un diccionario con los ids de ancla de scroll para persistir, excluyendo los vacíos o irrelevantes.
    func persistedAnchorDictionary() -> [String: String] {
        var dict: [String: String] = [:]
        if !soundsScrollAnchorId.isEmpty { dict[Self.persistenceKeySounds] = soundsScrollAnchorId }
        if !mixesScrollAnchorId.isEmpty { dict[Self.persistenceKeyMixes] = mixesScrollAnchorId }
        if !soundsSearchScrollAnchorId.isEmpty { dict[Self.persistenceKeySoundsSearch] = soundsSearchScrollAnchorId }
        if !mixesSearchScrollAnchorId.isEmpty { dict[Self.persistenceKeyMixesSearch] = mixesSearchScrollAnchorId }
        return dict
    }
    // Carga los ids de ancla de scroll desde un diccionario persistido, aplicándolos a las propiedades correspondientes si son válidos.
    func loadPersistedAnchorDictionary(_ dict: [String: String]) {
        if let v = dict[Self.persistenceKeySounds], !v.isEmpty { soundsScrollAnchorId = v }
        if let v = dict[Self.persistenceKeyMixes], !v.isEmpty { mixesScrollAnchorId = v }
        if let v = dict[Self.persistenceKeySoundsSearch], !v.isEmpty { soundsSearchScrollAnchorId = v }
        if let v = dict[Self.persistenceKeyMixesSearch], !v.isEmpty { mixesSearchScrollAnchorId = v }
    }
    // Programa la persistencia de los ids de ancla de scroll con un pequeño retraso para evitar escrituras excesivas durante el scroll, y cancela cualquier tarea pendiente si se programa una nueva persistencia antes de que se ejecute la anterior.
    func schedulePersistScrollAnchors(_ persist: @escaping ([String: String]) -> Void) {
        persistScrollTask?.cancel()
        persistScrollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            let dict = persistedAnchorDictionary()
            if !dict.isEmpty {
                persist(dict)
            }
        }
    }
    // Programa la restauración del scroll a la posición almacenada para el contexto dado, con la opción de desplazarse primero al inicio para evitar problemas de restauración en listas largas, y cancela cualquier tarea de restauración pendiente para el mismo contexto antes de programar una nueva.
    func scheduleSoundsScrollRestore(
        for context: Context,
        scrollToTopFirst: Bool,
        setPosition: @escaping (String?) -> Void
    ) {
        let rawTargetId = storedScrollAnchorId(for: context)
        let targetId = isRelevantScrollAnchorId(rawTargetId, for: context) ? rawTargetId : Self.scrollTopAnchorId
        soundsRestoreTask?.cancel()
        soundsRestoreGeneration += 1
        let generation = soundsRestoreGeneration
        soundsRestoreTask = Task { @MainActor in
            suppressSoundsScrollMemoryUpdates = true
            defer {
                if soundsRestoreGeneration == generation {
                    suppressSoundsScrollMemoryUpdates = false
                }
            }
            if scrollToTopFirst {
                setPosition(Self.scrollTopAnchorId)
            }
            await Task.yield()
            guard !Task.isCancelled, soundsRestoreGeneration == generation else { return }
            setPosition(targetId)
        }
    }

    func scheduleMixesScrollRestore(
        for context: Context,
        scrollToTopFirst: Bool,
        setPosition: @escaping (String?) -> Void
    ) {
        let rawTargetId = storedScrollAnchorId(for: context)
        let targetId = isRelevantScrollAnchorId(rawTargetId, for: context) ? rawTargetId : Self.scrollTopAnchorId
        mixesRestoreTask?.cancel()
        mixesRestoreGeneration += 1
        let generation = mixesRestoreGeneration
        mixesRestoreTask = Task { @MainActor in
            suppressMixesScrollMemoryUpdates = true
            defer {
                if mixesRestoreGeneration == generation {
                    suppressMixesScrollMemoryUpdates = false
                }
            }
            if scrollToTopFirst {
                setPosition(Self.scrollTopAnchorId)
            }
            await Task.yield()
            guard !Task.isCancelled, mixesRestoreGeneration == generation else { return }
            setPosition(targetId)
        }
    }
}
