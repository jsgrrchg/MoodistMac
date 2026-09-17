import SwiftUI
import MoodistKit

struct RootView: View {
    @EnvironmentObject private var store: SoundStore
    @EnvironmentObject private var model: IOSAppModel
    @State private var playerDetent: PresentationDetent = .large
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage(PersistenceService.appLanguageKey) private var language = "system"

    var body: some View {
        ZStack {
        TabView {
            Tab(L10n.sounds, systemImage: "waveform") {
                NavigationStack { SoundBrowser().toolbar { settingsButton }.safeAreaInset(edge: .bottom) { playerInset } }
            }
            Tab(L10n.mixes, systemImage: "square.stack") {
                NavigationStack { MixBrowser().toolbar { settingsButton }.safeAreaInset(edge: .bottom) { playerInset } }
            }
            Tab(T("library", "Library"), systemImage: "books.vertical") {
                NavigationStack { LibraryView().toolbar { settingsButton }.safeAreaInset(edge: .bottom) { playerInset } }
            }
        }
        .id(language)
        }
        .sheet(item: $model.presentedSheet, onDismiss: { playerDetent = .large }) { destination in
            switch destination {
            case .player:
                NavigationStack { PlayerView() }
                    .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.medium, .large], selection: $playerDetent)
                    .presentationDragIndicator(.visible)
            case .settings:
                NavigationStack { SettingsView() }
            }
        }
        .alert(T("playback_error", "Unable to play audio"), isPresented: Binding(get: { store.playbackError != nil }, set: { if !$0 { store.playbackError = nil } })) {
            Button(L10n.close) { store.playbackError = nil }
        } message: { Text(store.playbackError ?? "") }
    }
    private var playerInset: some View {
        MiniPlayer()
            .padding(.vertical, 4)
            .modifier(PlayerSurfaceStyle())
            .padding(.horizontal).padding(.bottom, 8)
    }
    @ToolbarContentBuilder private var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu(L10n.playbackMenu, systemImage: "ellipsis.circle") {
                Button(L10n.shuffle, systemImage: "shuffle") { store.shuffle() }.keyboardShortcut("s")
                Button(L10n.unselectAll, systemImage: "xmark.circle") { store.unselectAll() }.keyboardShortcut("u")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(L10n.options, systemImage: "gearshape") { model.presentedSheet = .settings }.keyboardShortcut(",").accessibilityIdentifier("open-settings")
        }
    }
}

struct MiniPlayer: View {
    @EnvironmentObject private var store: SoundStore
    @EnvironmentObject private var model: IOSAppModel
    var body: some View {
        HStack(spacing: 12) {
            Button { model.presentedSheet = .player } label: {
                HStack {
                    SoundSymbol(name: store.displayedMixIconName ?? "waveform").frame(width: 24, height: 24)
                    Text(store.displayedMixName ?? (store.hasSelection ? L10n.currentlyPlaying : T("choose_sounds", "Choose your sounds")))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("open-player")
            Button { store.togglePlay() } label: {
                Image(systemName: store.isPlaying ? "pause.fill" : "play.fill").frame(width: 44, height: 44).contentShape(Rectangle())
            }
                .accessibilityLabel(store.isPlaying ? L10n.pause : L10n.play).disabled(!store.hasSelection).keyboardShortcut("r")
            Group {
                Button { store.playNextRandomMix() } label: {
                    Image(systemName: "forward.end.fill").frame(width: 44, height: 44).contentShape(Rectangle())
                }
                    .accessibilityLabel(L10n.nextMix).keyboardShortcut("n")
            }
        }
        .padding(.horizontal)
    }
}
