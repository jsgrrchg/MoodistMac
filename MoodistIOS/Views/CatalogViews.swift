import SwiftUI
import MoodistKit

struct SoundBrowser: View {
    @EnvironmentObject private var store: SoundStore
    @SceneStorage("MoodistIOS.soundSearch") private var query = ""
    @State private var collapsed = Set<String>()
    @State private var initialized = false
    @State private var anchor: String?
    @State private var anchors = PersistenceService.loadScrollAnchorIds()
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
            if UserDefaults.standard.bool(forKey: PersistenceService.collapseCategoriesOnColdOpenKey) { collapsed = Set(SoundsData.categories.map(\.id)) }
            anchor = anchors[context]
        }
        .onChange(of: anchor) { _, id in
            guard let id else { return }
            anchors[context] = id
            PersistenceService.saveScrollAnchorIds(anchors)
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
    let sound: Sound
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
        }
    }
}

struct MixBrowser: View {
    @EnvironmentObject private var store: SoundStore
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
            if UserDefaults.standard.bool(forKey: PersistenceService.collapseCategoriesOnColdOpenKey) { collapsed = Set(MixesData.categories.map(\.id)) }
            anchor = PersistenceService.loadScrollAnchorIds()["ios.mixes"]
        }
        .onChange(of: anchor) { _, id in
            guard let id else { return }
            var saved = PersistenceService.loadScrollAnchorIds(); saved["ios.mixes"] = id
            PersistenceService.saveScrollAnchorIds(saved)
        }
    }
}

struct MixCell: View {
    @EnvironmentObject private var store: SoundStore
    let mix: Mix
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
        }
    }
}
