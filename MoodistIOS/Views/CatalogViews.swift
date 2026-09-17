import SwiftUI
import MoodistKit

struct SoundBrowser: View {
    @EnvironmentObject private var store: SoundStore
    @EnvironmentObject private var model: IOSAppModel
    @SceneStorage("MoodistIOS.soundSearch") private var query = ""
    @State private var collapsed = Set<String>()
    @State private var initialized = false
    @State private var anchor: String?
    @State private var anchors: [String: String] = [:]
    private var context: String { "ios.sounds.\(query.lowercased())" }
    private func visible(_ category: SoundCategory) -> [Sound] {
        category.sounds.filter {
            query.isEmpty || L10n.soundLabel($0.id).localizedStandardContains(query)
                || L10n.categoryTitle(category.id).localizedStandardContains(query)
        }
    }
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(SoundsData.categories) { category in
                    let sounds = visible(category)
                    if !sounds.isEmpty {
                        CategoryHeader(title: L10n.categoryTitle(category.id), collapsed: collapsed.contains(category.id)) {
                            if !collapsed.insert(category.id).inserted { collapsed.remove(category.id) }
                        }.id("category-\(category.id)")
                        if !collapsed.contains(category.id) || !query.isEmpty {
                            ForEach(sounds) { sound in
                                SoundCell(sound: sound).padding(.horizontal).padding(.vertical, 6).id(sound.id)
                                Divider().padding(.leading)
                            }
                        }
                    }
                }
                if SoundsData.categories.allSatisfy({ visible($0).isEmpty }) {
                    ContentUnavailableView.search(text: query)
                }
            }.scrollTargetLayout()
        }
        .scrollPosition(id: $anchor)
        .searchable(text: $query, prompt: L10n.searchPlaceholder)
        .navigationTitle(L10n.sounds)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(collapsed.isEmpty ? L10n.collapseAllCategories : L10n.expandAllCategories, systemImage: collapsed.isEmpty ? "rectangle.compress.vertical" : "rectangle.expand.vertical") {
                    collapsed = collapsed.isEmpty ? Set(SoundsData.categories.map(\.id)) : []
                }
            }
        }
        .onAppear {
            guard !initialized else { return }
            initialized = true
            if model.defaults.bool(forKey: PersistenceService.collapseCategoriesOnColdOpenKey) { collapsed = Set(SoundsData.categories.map(\.id)) }
            anchors = PreferencesRepository(defaults: model.defaults).loadScrollAnchorIds()
            anchor = anchors[context]
        }
        .onChange(of: anchor) { _, id in
            guard let id else { return }
            anchors = PreferencesRepository(defaults: model.defaults).loadScrollAnchorIds()
            anchors[context] = id
            PreferencesRepository(defaults: model.defaults).saveScrollAnchorIds(anchors)
        }
        .onChange(of: query) { _, _ in anchor = anchors[context] }
    }
}

struct CategoryHeader: View {
    let title: String
    let collapsed: Bool
    let toggle: () -> Void
    var body: some View {
        Button(action: toggle) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Image(systemName: collapsed ? "chevron.down" : "chevron.up")
            }.padding().frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(collapsed ? L10n.stateCollapsed : L10n.stateExpanded)
    }
}

struct SoundCell: View {
    @EnvironmentObject private var store: SoundStore
    @EnvironmentObject private var model: IOSAppModel
    let sound: Sound
    @State private var createPresented = false
    var body: some View {
        HStack(spacing: 12) {
            Button {
                if store.sounds[sound.id]?.isSelected == true { store.unselect(sound.id) } else { store.select(sound.id) }
            } label: {
                HStack(spacing: 12) {
                    SoundSymbol(name: sound.iconName).frame(width: 24, height: 24).foregroundStyle(.secondary)
                    Text(L10n.soundLabel(sound.id)).frame(maxWidth: .infinity, alignment: .leading)
                    if store.sounds[sound.id]?.isSelected == true { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
                }.frame(minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityIdentifier("sound-\(sound.id)")
                .accessibilityValue(store.sounds[sound.id]?.isSelected == true ? L10n.stateSelected : L10n.stateNotSelected)
            Button { store.toggleFavorite(sound.id) } label: {
                Image(systemName: store.sounds[sound.id]?.isFavorite == true ? "star.fill" : "star")
                    .frame(width: 44, height: 44)
            }.buttonStyle(.borderless).accessibilityLabel("\(L10n.favorites): \(L10n.soundLabel(sound.id))")
                .accessibilityValue(store.sounds[sound.id]?.isFavorite == true ? L10n.stateSelected : L10n.stateNotSelected)
        }
        .contextMenu {
            Menu(L10n.addToMix) {
                ForEach(store.presets) { preset in
                    Button(preset.name) { store.addSound(sound.id, toPreset: preset.id) }
                }
            }.disabled(store.presets.isEmpty)
            Button(L10n.createNewMix) {
                store.unselectAll(); store.select(sound.id); createPresented = true
            }
        }
        .sheet(isPresented: $createPresented) { CustomMixEditor() }
    }
}

struct MixBrowser: View {
    @EnvironmentObject private var store: SoundStore
    @EnvironmentObject private var model: IOSAppModel
    @State private var collapsed = Set<String>()
    @State private var initialized = false
    @State private var anchor: String?
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(MixesData.categories) { category in
                    let mixes = category.id == "custom" ? store.presets.map { $0.toMix() } : category.mixes
                    CategoryHeader(title: L10n.mixCategoryTitle(category.id), collapsed: collapsed.contains(category.id)) {
                        if !collapsed.insert(category.id).inserted { collapsed.remove(category.id) }
                    }.id("category-\(category.id)")
                    if !collapsed.contains(category.id) {
                        if mixes.isEmpty { Text(T("no_custom_mixes", "Save your first mix from the player.")).foregroundStyle(.secondary).padding() }
                        ForEach(mixes) { mix in
                            MixCell(mix: mix).padding(.horizontal).padding(.vertical, 6).id(mix.id)
                            Divider().padding(.leading)
                        }
                    }
                }
            }.scrollTargetLayout()
        }
        .scrollPosition(id: $anchor)
        .navigationTitle(L10n.mixes)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(collapsed.isEmpty ? L10n.collapseAllCategories : L10n.expandAllCategories, systemImage: "rectangle.compress.vertical") {
                    collapsed = collapsed.isEmpty ? Set(MixesData.categories.map(\.id)) : []
                }
            }
        }
        .onAppear {
            guard !initialized else { return }; initialized = true
            if model.defaults.bool(forKey: PersistenceService.collapseCategoriesOnColdOpenKey) { collapsed = Set(MixesData.categories.map(\.id)) }
            anchor = PreferencesRepository(defaults: model.defaults).loadScrollAnchorIds()["ios.mixes"]
        }
        .onChange(of: anchor) { _, id in
            guard let id else { return }
            var saved = PreferencesRepository(defaults: model.defaults).loadScrollAnchorIds(); saved["ios.mixes"] = id
            PreferencesRepository(defaults: model.defaults).saveScrollAnchorIds(saved)
        }
    }
}

struct MixCell: View {
    @EnvironmentObject private var store: SoundStore
    @EnvironmentObject private var model: IOSAppModel
    let mix: Mix
    @State private var editing = false
    @State private var deleting = false
    private var name: String { store.presetsById[mix.id]?.name ?? L10n.mixName(mix.id) }
    var body: some View {
        HStack {
            Button { store.applyMix(mix) } label: {
                HStack(spacing: 12) {
                    SoundSymbol(name: mix.iconName).frame(width: 24, height: 24)
                    VStack(alignment: .leading) {
                        Text(name)
                        Text(L10n.countSounds(mix.soundIds.count)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if store.displayedMixId == mix.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
                }.frame(minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityIdentifier("mix-\(mix.id)")
            Button { store.toggleFavoriteMix(id: mix.id) } label: {
                Image(systemName: store.favoriteMixIds.contains(mix.id) ? "star.fill" : "star").frame(width: 44, height: 44)
            }.buttonStyle(.borderless).accessibilityLabel("\(L10n.favorites): \(name)")
                .accessibilityValue(store.favoriteMixIds.contains(mix.id) ? L10n.stateSelected : L10n.stateNotSelected)
        }
        .contextMenu {
            if store.presetsById[mix.id] != nil {
                Button(L10n.editMix, systemImage: "pencil") { editing = true }
                Button(L10n.presetDelete, systemImage: "trash", role: .destructive) { deleting = true }
            }
        }
        .sheet(isPresented: $editing) { CustomMixEditor(presetID: mix.id) }
        .confirmationDialog(L10n.presetDelete, isPresented: $deleting, titleVisibility: .visible) {
            Button(L10n.presetDelete, role: .destructive) { store.deletePreset(id: mix.id) }
            Button(L10n.cancel, role: .cancel) {}
        } message: { Text(name) }
    }
}
