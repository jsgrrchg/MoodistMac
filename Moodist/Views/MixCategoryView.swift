//
//  MixCategoryView.swift
//  MoodistMac
//
//  Vista de una categoría de mixes: título, icono, lista de mixes. Tap en un mix aplica y reproduce.
//

import SwiftUI

struct MixCategoryView: View {
    let category: MixCategory
    @ObservedObject var store: SoundStore
    @Environment(\.contentAreaWidth) private var contentAreaWidth
    /// Si no es nil, se muestran solo estos mixes (p. ej. resultados de búsqueda). Si es nil, se usan category.mixes.
    var mixesToShow: [Mix]? = nil
    /// Binding opcional para controlar el estado expandido desde fuera. Si es nil, usa estado interno.
    var isExpanded: Binding<Bool>? = nil
    @State private var internalIsExpanded = true
    
    private var expandedState: Bool {
        isExpanded?.wrappedValue ?? internalIsExpanded
    }
    
    private func setExpandedState(_ value: Bool) {
        if let binding = isExpanded {
            binding.wrappedValue = value
        } else {
            internalIsExpanded = value
        }
    }

    private var displayedMixes: [Mix] {
        mixesToShow ?? category.mixes
    }

    private var isNarrow: Bool { contentAreaWidth < 420 }

    var body: some View {
        VStack(alignment: .leading, spacing: isNarrow ? MoodistTheme.Spacing.xSmall : MoodistTheme.Spacing.small) {
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.2)) { 
                    setExpandedState(!expandedState)
                }
            }) {
                HStack(spacing: isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium) {
                    Image(systemName: category.iconName)
                        .font(isNarrow ? .body : .title3)
                        .frame(width: isNarrow ? 24 : 28, height: isNarrow ? 24 : 28)
                        .foregroundStyle(MoodistTheme.Colors.accent)
                    Text(L10n.mixCategoryTitle(category.id))
                        .font((isNarrow ? Font.headline : Font.title2).weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.9)
                        .layoutPriority(1)
                    Spacer()
                    Image(systemName: expandedState ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                }
                .padding(.vertical, MoodistTheme.Spacing.xSmall)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(L10n.mixCategoryTitle(category.id)), \(expandedState ? L10n.stateExpanded : L10n.stateCollapsed)")

            if expandedState {
                if displayedMixes.isEmpty, category.id == MixesData.custom.id {
                    Text(L10n.customMixesEmpty)
                        .font(MoodistTheme.Typography.subheadline)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, MoodistTheme.Spacing.medium)
                } else {
                    LazyVStack(alignment: .leading, spacing: isNarrow ? MoodistTheme.Spacing.xSmall : MoodistTheme.Spacing.small) {
                        ForEach(displayedMixes, id: \.id) { mix in
                            MixRowView(mix: mix, store: store)
                        }
                    }
                }
            }
        }
        .padding(.vertical, isNarrow ? MoodistTheme.Spacing.xSmall : MoodistTheme.Spacing.small)
        .padding(.horizontal, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)
    }
}

struct MixRowView: View {
    let mix: Mix
    @ObservedObject var store: SoundStore
    @Environment(\.contentAreaWidth) private var contentAreaWidth
    @Environment(\.isUserScrolling) private var isUserScrolling
    @State private var isHovered = false
    
    // Cache estático para evitar recalcular soundsInMix en cada render (solo en main thread).
    private static var soundsCache: [String: [Sound]] = [:]

    private var isCurrentMix: Bool {
        store.currentMixId == mix.id
    }

    private var isFavoriteMix: Bool {
        store.favoriteMixIds.contains(mix.id)
    }

    /// Nombre a mostrar: para mixes built-in usa L10n; para custom presets usa mix.name.
    private var mixDisplayName: String {
        (L10n.mixName(mix.id) == mix.id) ? mix.name : L10n.mixName(mix.id)
    }

    private static let soundsCacheMaxEntries = 200

    private var soundsInMix: [Sound] {
        if let cached = Self.soundsCache[mix.id] {
            return cached
        }
        if Self.soundsCache.count >= Self.soundsCacheMaxEntries, let keyToEvict = Self.soundsCache.keys.first {
            Self.soundsCache.removeValue(forKey: keyToEvict)
        }
        let sounds = mix.soundIds.compactMap { SoundsData.allSoundsById[$0] }
        Self.soundsCache[mix.id] = sounds
        return sounds
    }

    private var isNarrow: Bool { contentAreaWidth < 420 }
    private var isVeryNarrow: Bool { contentAreaWidth < 340 }

    var body: some View {
        VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xSmall) {
            Button(action: { 
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    store.applyMix(mix)
                }
            }) {
                HStack(spacing: isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium) {
                    Image(systemName: mix.iconName)
                        .font(.system(size: isNarrow ? 14 : 15, weight: isCurrentMix ? .medium : .regular))
                        .frame(width: isNarrow ? 18 : 20, height: isNarrow ? 18 : 20)
                        .foregroundStyle(isCurrentMix ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText)
                    Text(mixDisplayName)
                        .font(MoodistTheme.Typography.body)
                        .fontWeight(isCurrentMix ? .medium : .regular)
                        .foregroundStyle(isCurrentMix ? Color.primary : Color.primary.opacity(0.9))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.85)
                        .layoutPriority(1)
                    Spacer(minLength: 0)
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            store.toggleFavoriteMix(id: mix.id)
                        }
                    }) {
                        Image(systemName: isFavoriteMix ? "star.fill" : "star")
                            .font(.system(size: isNarrow ? 12 : 14, weight: isFavoriteMix ? .medium : .regular))
                            .foregroundStyle(isFavoriteMix ? MoodistTheme.Colors.favorite : (isHovered ? MoodistTheme.Colors.secondaryText.opacity(0.8) : MoodistTheme.Colors.secondaryText.opacity(0.5)))
                            .frame(width: isNarrow ? 18 : 20, height: isNarrow ? 18 : 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isFavoriteMix ? L10n.removeFromFavoritesLabel(mixDisplayName) : L10n.addToFavoritesLabel(mixDisplayName))
                    if isCurrentMix {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    }
                    if !isVeryNarrow {
                        Text(L10n.countSounds(mix.soundIds.count))
                            .font(MoodistTheme.Typography.subheadline)
                            .foregroundStyle(MoodistTheme.Colors.secondaryText)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .padding(.vertical, isNarrow ? MoodistTheme.Spacing.small : (MoodistTheme.Spacing.small + 2))
                .padding(.horizontal, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)
                .contentShape(Rectangle())
            }
            .buttonStyle(ModernMixRowButtonStyle(isSelected: isCurrentMix, isHovered: isHovered))
            .onHover { hovering in
                guard !isUserScrolling else { return }
                guard isHovered != hovering else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .contextMenu {
                Button(L10n.presetApply) {
                    store.applyMix(mix)
                }
                Divider()
                if isFavoriteMix {
                    Button(L10n.removeFromFavoritesLabel(mixDisplayName)) {
                        store.toggleFavoriteMix(id: mix.id)
                    }
                } else {
                    Button(L10n.addToFavoritesLabel(mixDisplayName)) {
                        store.toggleFavoriteMix(id: mix.id)
                    }
                }
                if store.presets.contains(where: { $0.id == mix.id }) {
                    Divider()
                    Button(L10n.presetDelete, role: .destructive) {
                        store.deletePreset(id: mix.id)
                    }
                }
            }
            .accessibilityLabel("\(mixDisplayName), \(L10n.countSounds(mix.soundIds.count))")
            .accessibilityHint(L10n.doubleTapPlayMix)

            if isCurrentMix {
                LazyVStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                    ForEach(soundsInMix, id: \.id) { sound in
                        SoundRow(sound: sound, store: store)
                    }
                }
                .padding(.leading, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)
                .padding(.trailing, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)
                .padding(.vertical, MoodistTheme.Spacing.small)
            }
        }
    }
}

// MARK: - Estilo integrado para botones de mix (sin fondo azul por defecto)

struct ModernMixRowButtonStyle: ButtonStyle {
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
    MixCategoryView(category: MixesData.natureRelaxation, store: SoundStore(audioService: AudioService()))
        .padding()
}
