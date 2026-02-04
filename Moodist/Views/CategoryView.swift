//
//  CategoryView.swift
//  MoodistMac
//
//  Vista de una categoría: título e icono, lista de sonidos. Compatible con Liquid Glass (macOS 26+).
//

import SwiftUI

struct CategoryView: View {
    let category: SoundCategory
    @ObservedObject var store: SoundStore
    @Binding var isExpanded: Bool
    @Environment(\.contentAreaWidth) private var contentAreaWidth

    init(category: SoundCategory, store: SoundStore, isExpanded: Binding<Bool>) {
        self.category = category
        self.store = store
        _isExpanded = isExpanded
    }

    private var isNarrow: Bool { contentAreaWidth < 420 }

    var body: some View {
        VStack(alignment: .leading, spacing: isNarrow ? MoodistTheme.Spacing.xSmall : MoodistTheme.Spacing.small) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: category.iconName)
                        .font(isNarrow ? .body : .title3)
                        .frame(width: isNarrow ? 24 : 28, height: isNarrow ? 24 : 28)
                        .foregroundStyle(MoodistTheme.Colors.accent)
                    Text(L10n.categoryTitle(category.id))
                        .font(isNarrow ? .headline : .title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.9)
                        .layoutPriority(1)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                }
                .padding(.vertical, MoodistTheme.Spacing.xSmall)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(L10n.categoryTitle(category.id)), \(isExpanded ? L10n.stateExpanded : L10n.stateCollapsed)")
            .accessibilityHint(L10n.categoryExpandHint(isExpanded))
            .accessibilityAddTraits(isExpanded ? [] : [.isButton])

            if isExpanded {
                LazyVStack(alignment: .leading, spacing: isNarrow ? MoodistTheme.Spacing.xSmall : MoodistTheme.Spacing.small) {
                    ForEach(category.sounds, id: \.id) { sound in
                        SoundRow(sound: sound, store: store)
                    }
                }
            }
        }
        .padding(.vertical, isNarrow ? MoodistTheme.Spacing.xSmall : MoodistTheme.Spacing.small)
        .padding(.horizontal, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)
    }
}

#Preview {
    CategoryView(
        category: SoundsData.nature,
        store: SoundStore(audioService: AudioService()),
        isExpanded: .constant(true)
    )
    .padding()
}
