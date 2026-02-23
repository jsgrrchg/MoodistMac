//
//  ContentToolbar.swift
//  MoodistMac
//
//  Toolbar content extracted from ContentView.
//

import SwiftUI

struct ContentToolbar: ToolbarContent {
    let windowWidth: CGFloat
    let compactThreshold: CGFloat
    let mediumThreshold: CGFloat
    let toolbarContentOffset: CGFloat
    let toolbarSearchFieldWidth: CGFloat
    let toolbarSearchFieldHeight: CGFloat
    let toolbarSearchFieldFocusPadding: CGFloat
    let toolbarSearchFieldYOffset: CGFloat

    @Binding var selectedSection: ContentSection
    @Binding var searchQuery: String
    @Binding var requestSearchFocus: Bool

    let onRequestSectionChange: (ContentSection) -> Void
    let onTogglePlay: () -> Void
    let onShuffle: () -> Void
    let onNextMix: () -> Void
    let onUnselectAll: () -> Void

    let isPlaying: Bool
    let hasSelection: Bool

    var body: some ToolbarContent {
        let availableToolbarWidth = windowWidth
        if availableToolbarWidth >= compactThreshold {
            ToolbarItem(placement: .principal) {
                if availableToolbarWidth >= mediumThreshold {
                    principalToolbarContent
                } else {
                    sectionPickerMenu
                }
            }
        } else {
            ToolbarItem(placement: .principal) {
                compactToolbarMenu
            }
        }

        ToolbarItem(placement: .automatic) {
            ToolbarSearchField(
                text: $searchQuery,
                placeholder: L10n.searchPlaceholder,
                requestFocus: $requestSearchFocus,
                height: toolbarSearchFieldHeight
            )
            .frame(width: toolbarSearchFieldWidth, height: toolbarSearchFieldHeight)
            .padding(.vertical, toolbarSearchFieldFocusPadding)
            .offset(y: toolbarSearchFieldYOffset)
        }
    }

    private var compactToolbarMenu: some View {
        Menu {
            Button(L10n.sounds) { onRequestSectionChange(.sounds) }
            Button(L10n.mixes) { onRequestSectionChange(.mixes) }
            Divider()
            Button(L10n.search + "...") {
                requestSearchFocus = true
            }
            .keyboardShortcut("f", modifiers: [.command])
            Divider()
            Button(isPlaying ? L10n.pause : L10n.play) { onTogglePlay() }
                .disabled(!hasSelection)
            Button(L10n.shuffle) { onShuffle() }
            Button(L10n.nextMix) { onNextMix() }
            Divider()
            Button(L10n.unselectAll) { onUnselectAll() }
                .disabled(!hasSelection)
        } label: {
            Image(systemName: "line.3.horizontal.circle")
        }
        .offset(x: toolbarContentOffset)
        .help(L10n.controls)
    }

    private var principalToolbarContent: some View {
        Group {
            if #available(macOS 26.0, *) {
                segmentedPicker
                    .controlSize(.large)
                    .frame(height: 29)
                    .fixedSize()
                    .padding(.vertical, 1)
                    .padding(.horizontal, 4)
            } else {
                segmentedPicker
                    .controlSize(.large)
                    .frame(width: 210, height: 28)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(PlatformColor.windowBackground.opacity(0.9))
                    }
            }
        }
        .offset(x: toolbarContentOffset)
        .accessibilityLabel(L10n.section)
        .accessibilityValue(selectedSection == .sounds ? L10n.sounds : L10n.mixes)
    }

    private var segmentedPicker: some View {
        Picker(
            L10n.section,
            selection: Binding(
                get: { selectedSection },
                set: { onRequestSectionChange($0) }
            )
        ) {
            Text(L10n.sounds).tag(ContentSection.sounds)
            Text(L10n.mixes).tag(ContentSection.mixes)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var sectionPickerMenu: some View {
        Menu {
            Button(L10n.sounds) { onRequestSectionChange(.sounds) }
            Button(L10n.mixes) { onRequestSectionChange(.mixes) }
        } label: {
            HStack(spacing: 4) {
                Text(selectedSection == .sounds ? L10n.sounds : L10n.mixes)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
            }
        }
        .menuStyle(.borderlessButton)
        .frame(minWidth: 44)
        .offset(x: toolbarContentOffset)
        .accessibilityLabel(L10n.section)
        .accessibilityValue(selectedSection == .sounds ? L10n.sounds : L10n.mixes)
    }
}
