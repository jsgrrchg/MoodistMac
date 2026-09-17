import SwiftUI
import MoodistKit

struct PlayerView: View {
    @EnvironmentObject private var store: SoundStore
    @State private var savePresented = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    SoundSymbol(name: store.displayedMixIconName ?? "waveform").frame(width: 56, height: 56).foregroundStyle(.tint)
                    Text(store.displayedMixName ?? L10n.currentlyPlaying).font(.title2.bold()).multilineTextAlignment(.center)
                    GlassEffectContainer {
                        HStack(spacing: 24) {
                            Button(L10n.shuffle, systemImage: "shuffle") { store.shuffle() }
                                .accessibilityIdentifier("player-shuffle")
                            Button(store.isPlaying ? L10n.pause : L10n.play, systemImage: store.isPlaying ? "pause.fill" : "play.fill") { store.togglePlay() }
                                .font(.title).disabled(!store.hasSelection).accessibilityIdentifier("player-toggle")
                            Button(L10n.nextMix, systemImage: "forward.end.fill") { store.playNextRandomMix() }
                        }
                        .labelStyle(.iconOnly).buttonStyle(.glass).controlSize(.large)
                    }
                    VolumeControl(label: L10n.globalVolume, value: Binding(get: { store.globalVolume }, set: { store.setGlobalVolume($0) }))
                    AudioRoutePicker().frame(width: 44, height: 44).accessibilityLabel(T("audio_output", "Audio output"))
                }
                .frame(maxWidth: .infinity).padding(.vertical)
            }
            Section {
                Button(L10n.presetSaveCurrent, systemImage: "square.and.arrow.down") { savePresented = true }
                    .disabled(!store.canSaveCustomMix)
            }
            Section(L10n.currentlyPlaying) {
                if !store.hasSelection {
                    ContentUnavailableView(T("choose_sounds", "Choose your sounds"), systemImage: "waveform")
                }
                ForEach(SoundsData.categories.flatMap(\.sounds).filter { store.sounds[$0.id]?.isSelected == true }) { sound in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SoundSymbol(name: sound.iconName).frame(width: 22, height: 22)
                            Text(L10n.soundLabel(sound.id))
                            Spacer()
                            Button(T("remove", "Remove"), systemImage: "minus.circle") { store.unselect(sound.id) }
                                .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44).buttonStyle(.borderless)
                        }
                        VolumeControl(label: L10n.volumeForLabel(L10n.soundLabel(sound.id)), value: Binding(get: { store.sounds[sound.id]?.volume ?? 0.5 }, set: { store.setVolume(sound.id, $0) }), showLabel: false)
                    }.padding(.vertical, 4)
                }
                Button(L10n.unselectAll, role: .destructive) { store.unselectAll() }.disabled(!store.hasSelection)
            }
        }
        .sheet(isPresented: $savePresented) { CustomMixEditor() }
        .navigationTitle(T("player", "Player"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.close) { dismiss() } } }
    }
}

struct VolumeControl: View {
    let label: String
    @Binding var value: Double
    var showLabel = true
    var body: some View {
        VStack {
            if showLabel {
                HStack { Text(label); Spacer(); Text(value, format: .percent.precision(.fractionLength(0))).monospacedDigit() }
            }
            Slider(value: $value, in: 0...1)
                .accessibilityLabel(label)
                .accessibilityValue(value.formatted(.percent.precision(.fractionLength(0))))
        }
    }
}
