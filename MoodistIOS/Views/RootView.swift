import SwiftUI
import MoodistKit

struct RootView: View {
    @EnvironmentObject private var store: SoundStore
    @State private var playerPresented = false
    @State private var settingsPresented = false

    var body: some View {
        TabView {
            Tab(L10n.sounds, systemImage: "waveform") {
                NavigationStack { Text(L10n.sounds).navigationTitle(L10n.sounds).toolbar { settingsButton } }
            }
            Tab(L10n.mixes, systemImage: "square.stack") {
                NavigationStack { Text(L10n.mixes).navigationTitle(L10n.mixes).toolbar { settingsButton } }
            }
            Tab(T("library", "Library"), systemImage: "books.vertical") {
                NavigationStack { Text(L10n.favorites).navigationTitle(T("library", "Library")).toolbar { settingsButton } }
            }
        }
        .tabViewBottomAccessory { MiniPlayer { playerPresented = true } }
        .sheet(isPresented: $playerPresented) {
            NavigationStack { Text(store.displayedMixName ?? L10n.currentlyPlaying).navigationTitle(T("player", "Player")) }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $settingsPresented) {
            NavigationStack { Text(L10n.options).navigationTitle(L10n.options) }
        }
        .alert(T("playback_error", "Unable to play audio"), isPresented: Binding(get: { store.playbackError != nil }, set: { if !$0 { store.playbackError = nil } })) {
            Button(L10n.close) { store.playbackError = nil }
        } message: { Text(store.playbackError ?? "") }
    }
    @ToolbarContentBuilder private var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(L10n.options, systemImage: "gearshape") { settingsPresented = true }
        }
    }
}

struct MiniPlayer: View {
    @EnvironmentObject private var store: SoundStore
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    let open: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Button(action: open) {
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
            Button(store.isPlaying ? L10n.pause : L10n.play, systemImage: store.isPlaying ? "pause.fill" : "play.fill") { store.togglePlay() }
                .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44).disabled(!store.hasSelection)
            if placement != .inline {
                Button(L10n.nextMix, systemImage: "forward.end.fill") { store.playNextRandomMix() }
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(.horizontal)
    }
}
