//
//  SoundRow.swift
//  MoodistMac
//
//  Fila de un sonido: icono, nombre, favorito, volumen, selección.
//

import SwiftUI

struct SoundRow: View {
    let sound: Sound
    @ObservedObject var store: SoundStore
    @Environment(\.contentAreaWidth) private var contentAreaWidth
    @State private var isHovered = false

    private var state: SoundStateItem {
        store.sounds[sound.id] ?? .default
    }

    /// Ventana estrecha: menos espaciado y slider más comprimible para que todo quepa.
    private var isNarrow: Bool { contentAreaWidth < 420 }
    private var isVeryNarrow: Bool { contentAreaWidth < 340 }
    private var isUltraNarrow: Bool { contentAreaWidth < 260 }
    private var rowSpacing: CGFloat { isUltraNarrow ? 4 : (isVeryNarrow ? 6 : (isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)) }
    private var iconFrame: CGFloat { isNarrow ? 18 : 20 }
    private var horizontalPadding: CGFloat { isUltraNarrow ? 4 : (isVeryNarrow ? 6 : (isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)) }
    private var sliderHorizontalMaxWidth: CGFloat {
        // La anchura reportada incluye padding del ScrollView; escalamos agresivo para evitar controles fuera de pantalla.
        let proposed = contentAreaWidth * (isUltraNarrow ? 0.12 : (isVeryNarrow ? 0.16 : 0.22))
        let minWidth: CGFloat = isUltraNarrow ? 28 : 44
        let maxWidth: CGFloat = isUltraNarrow ? 90 : 120
        return min(maxWidth, max(minWidth, proposed))
    }

    var body: some View {
        Button(action: toggleSound) {
            ViewThatFits(in: .horizontal) {
                if !(state.isSelected && isVeryNarrow) {
                    horizontalRowContent
                }
                compactRowContent
                ultraCompactRowContent
            }
        }
        .buttonStyle(ModernSoundRowButtonStyle(isSelected: state.isSelected, isHovered: isHovered))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            if state.isSelected {
                Button(L10n.deselect) { store.unselect(sound.id) }
            } else {
                Button(L10n.select) { store.select(sound.id) }
            }
            Divider()
            Button(state.isFavorite ? L10n.removeFromFavoritesLabel(L10n.soundLabel(sound.id)) : L10n.addToFavoritesLabel(L10n.soundLabel(sound.id))) {
                store.toggleFavorite(sound.id)
            }
            Divider()
            Menu(L10n.addToMix) {
                ForEach(store.presets, id: \.id) { preset in
                    Button(preset.name) {
                        store.addSound(sound.id, toPreset: preset.id)
                    }
                }
                if !store.presets.isEmpty {
                    Divider()
                }
                Button(L10n.createNewMix) {
                    store.createNewPresetWithSound(sound.id)
                }
            }
        }
        .accessibilityLabel(state.isSelected ? "\(L10n.deselect) \(L10n.soundLabel(sound.id))" : "\(L10n.select) \(L10n.soundLabel(sound.id))")
        .accessibilityAddTraits(state.isSelected ? [.isSelected] : [])
    }

    private func toggleSound() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if state.isSelected {
                store.unselect(sound.id)
            } else {
                store.select(sound.id)
            }
        }
    }

    private var soundIcon: some View {
        Image(systemName: sound.iconName)
            .font(.system(size: isNarrow ? 14 : 15, weight: state.isSelected ? .medium : .regular))
            .frame(width: isUltraNarrow ? 16 : iconFrame, height: isUltraNarrow ? 16 : iconFrame)
            .foregroundStyle(state.isSelected ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText)
            .animation(.easeInOut(duration: 0.2), value: state.isSelected)
    }

    private var soundTitle: some View {
        Text(L10n.soundLabel(sound.id))
            .font(MoodistTheme.Typography.body)
            .fontWeight(state.isSelected ? .medium : .regular)
            .foregroundStyle(state.isSelected ? Color.primary : Color.primary.opacity(0.9))
            .lineLimit(1)
            .truncationMode(.tail)
            // Deja que el texto se recorte antes de empujar controles fuera de la pantalla.
            .layoutPriority(0)
    }

    private var favoriteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                store.toggleFavorite(sound.id)
            }
        }) {
            Image(systemName: state.isFavorite ? "star.fill" : "star")
                .font(.system(size: isNarrow ? 12 : 14, weight: state.isFavorite ? .medium : .regular))
                .foregroundStyle(
                    state.isFavorite
                        ? MoodistTheme.Colors.favorite
                        : (isHovered ? MoodistTheme.Colors.secondaryText.opacity(0.8) : MoodistTheme.Colors.secondaryText.opacity(0.5))
                )
                .frame(width: isUltraNarrow ? 16 : iconFrame, height: isUltraNarrow ? 16 : iconFrame)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            state.isFavorite
                ? L10n.removeFromFavoritesLabel(L10n.soundLabel(sound.id))
                : L10n.addToFavoritesLabel(L10n.soundLabel(sound.id))
        )
        .accessibilityAddTraits(state.isFavorite ? [.isSelected] : [])
    }

    @ViewBuilder private var volumeControlsHorizontal: some View {
        HStack(spacing: isVeryNarrow ? 3 : 4) {
            if !isVeryNarrow {
                Image(systemName: "speaker.wave.1.fill")
                    .font(.system(size: isNarrow ? 10 : 11))
                    .foregroundStyle(MoodistTheme.Colors.secondaryText.opacity(isHovered ? 0.9 : 0.7))
            }
            Slider(
                value: Binding(
                    get: { state.volume },
                    set: { store.setVolume(sound.id, snappedVolume($0)) }
                ),
                in: 0...1
            )
            .controlSize(isNarrow ? .mini : .small)
            .tint(MoodistTheme.Colors.accent)
            .opacity(isHovered ? 1.0 : 0.9)
            .frame(height: 22)
            .frame(maxWidth: sliderHorizontalMaxWidth)
            .accessibilityLabel(L10n.volumeForLabel(L10n.soundLabel(sound.id)))
            .accessibilityValue("\(Int(state.volume * 100)) percent")
        }
        // Debe comprimirse antes que empujar el botón de favorito fuera de la pantalla.
        .layoutPriority(0)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    @ViewBuilder private var volumeControlsCompact: some View {
        HStack(spacing: 4) {
            Image(systemName: "speaker.wave.1.fill")
                .font(.system(size: 11))
                .foregroundStyle(MoodistTheme.Colors.secondaryText.opacity(0.8))
            Slider(
                value: Binding(
                    get: { state.volume },
                    set: { store.setVolume(sound.id, snappedVolume($0)) }
                ),
                in: 0...1
            )
            .controlSize(.mini)
            .tint(MoodistTheme.Colors.accent)
            .frame(height: 20)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(L10n.volumeForLabel(L10n.soundLabel(sound.id)))
            .accessibilityValue("\(Int(state.volume * 100)) percent")
        }
        // En ultra-estrecho no indentamos para maximizar ancho útil del slider.
        .padding(.leading, isUltraNarrow ? 0 : (iconFrame + rowSpacing))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var horizontalRowContent: some View {
        HStack(spacing: rowSpacing) {
            soundIcon
            soundTitle
            Spacer(minLength: 0)
            if state.isSelected {
                volumeControlsHorizontal
            }
            favoriteButton
        }
        .padding(.vertical, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.small + 2)
        .padding(.horizontal, horizontalPadding)
        .contentShape(Rectangle())
    }

    private var compactRowContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: rowSpacing) {
                soundIcon
                soundTitle
                Spacer(minLength: 0)
                favoriteButton
            }
            if state.isSelected {
                volumeControlsCompact
            }
        }
        .padding(.vertical, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.small + 2)
        .padding(.horizontal, horizontalPadding)
        .contentShape(Rectangle())
    }

    private var ultraCompactRowContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                soundIcon
                soundTitle
                favoriteButton
            }
            if state.isSelected {
                Slider(
                    value: Binding(
                        get: { state.volume },
                        set: { store.setVolume(sound.id, snappedVolume($0)) }
                    ),
                    in: 0...1
                )
                .controlSize(.mini)
                .tint(MoodistTheme.Colors.accent)
                .frame(height: 20)
                .accessibilityLabel(L10n.volumeForLabel(L10n.soundLabel(sound.id)))
                .accessibilityValue("\(Int(state.volume * 100)) percent")
            }
        }
        .padding(.vertical, MoodistTheme.Spacing.small)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }

    private func snappedVolume(_ value: Double) -> Double {
        let step = 0.05
        let snapped = (value / step).rounded() * step
        return min(1, max(0, snapped))
    }
}

// MARK: - Estilo integrado con fondo gris (sin cuadros blancos)

struct ModernSoundRowButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isHovered: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: MoodistTheme.Radius.small)
                    .fill(backgroundColor)
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            // Fondo sutil cuando está seleccionado, integrado con el gris
            return MoodistTheme.Colors.selectedBackground.opacity(0.25)
        } else if isHovered {
            // Hover muy sutil, apenas perceptible
            return Color.primary.opacity(0.05)
        } else {
            // Sin fondo, completamente transparente
            return Color.clear
        }
    }
}

#Preview {
    SoundRow(
        sound: SoundsData.nature.sounds[0],
        store: SoundStore(audioService: AudioService())
    )
    .padding()
}
