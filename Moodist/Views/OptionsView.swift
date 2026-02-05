//
//  OptionsView.swift
//  MoodistMac
//
//  Menú de opciones: Reproducción, Datos, Acerca de.
//

import SwiftUI
import Sparkle

private enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark
}

struct OptionsView: View {
    @EnvironmentObject var store: SoundStore
    @EnvironmentObject private var updatePresenter: UpdateWindowPresenter
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.sparkleUpdater) private var sparkleUpdater
    @AppStorage(PersistenceService.menuBarEnabledKey) private var menuBarEnabled = false
    @AppStorage(PersistenceService.appearanceModeKey) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage(PersistenceService.accentColorHexKey) private var accentColorRaw = AccentColorChoice.system.rawValue
    @AppStorage(PersistenceService.textSizeKey) private var textSizeRaw = "medium"
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparencyEnabled = true
    @AppStorage(PersistenceService.maxRecentMixesCountKey) private var maxRecentMixesCount: Int = 10
    @AppStorage(PersistenceService.maxRecentSoundsCountKey) private var maxRecentSoundsCount: Int = 12
    @AppStorage(PersistenceService.mediaKeyNextMixKey) private var mediaKeyNextMix = true
    @State private var showResetConfirmation = false
    @State private var showRestoreConfirmation = false
    private let optionsWindowSize = CGSize(width: 510, height: 650)

    private var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }

    private var accentChoice: AccentColorChoice {
        get { AccentColorChoice(rawValue: accentColorRaw) ?? .system }
        nonmutating set { accentColorRaw = newValue.rawValue }
    }

    private var effectiveDynamicTypeSize: DynamicTypeSize {
        switch textSizeRaw {
        case "small": return .small
        case "large": return .large
        case "xLarge": return .xLarge
        default: return .medium
        }
    }

    var body: some View {
        formContent
            .environment(\.dynamicTypeSize, effectiveDynamicTypeSize)
            .formStyle(.grouped)
            .navigationTitle(L10n.optionsTitle)
            .toolbar { toolbarContent }
            .background(OptionsWindowConfigurator(size: optionsWindowSize))
            .confirmationDialog(L10n.resetConfirmTitle, isPresented: $showResetConfirmation) {
                resetConfirmationButtons
            } message: {
                Text(L10n.resetConfirmMessage)
            }
            .confirmationDialog(L10n.restoreConfirmTitle, isPresented: $showRestoreConfirmation) {
                restoreConfirmationButtons
            } message: {
                Text(L10n.restoreConfirmMessage)
            }
            .onAppear { handleOnAppear() }
            .onChange(of: menuBarEnabled) { _, _ in handleMenuBarChange() }
            .onChange(of: appearanceModeRaw) { _, _ in handleAppearanceChange() }
            .onChange(of: maxRecentMixesCount) { _, _ in handleMaxRecentMixesChange() }
            .onChange(of: maxRecentSoundsCount) { _, _ in handleMaxRecentSoundsChange() }
            .onChange(of: transparencyEnabled) { _, _ in handleTransparencyToggle() }
    }
    
    private var formContent: some View {
        Form {
            menuBarSection
            appearanceSection
            generalSection
            dataSection
            updatesSection
            aboutSection
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.close) { closeOptionsWindow() }
                .keyboardShortcut(.cancelAction)
        }
    }
    
    private var resetConfirmationButtons: some View {
        Group {
            Button(L10n.reset, role: .destructive) {
                store.resetSelectionAndFavorites()
                dismissIfNeeded()
            }
            Button(L10n.cancel, role: .cancel) {}
        }
    }
    
    private var restoreConfirmationButtons: some View {
        Group {
            Button(L10n.restore, role: .destructive) {
                store.resetAllToDefaults()
                dismissIfNeeded()
            }
            Button(L10n.cancel, role: .cancel) {}
        }
    }
    
    private func handleOnAppear() {
        if maxRecentMixesCount < 10 || maxRecentMixesCount > 15 {
            maxRecentMixesCount = 10
        }
        if maxRecentSoundsCount < 10 || maxRecentSoundsCount > 15 {
            maxRecentSoundsCount = 12
        }
        let validSizes = ["small", "medium", "large", "xLarge"]
        if !validSizes.contains(textSizeRaw) {
            textSizeRaw = "medium"
        }
        if AccentColorChoice(rawValue: accentColorRaw) == nil {
            accentColorRaw = AccentColorChoice.system.rawValue
        }
        if UserDefaults.standard.object(forKey: PersistenceService.transparencyEnabledKey) == nil {
            transparencyEnabled = PersistenceService.loadTransparencyEnabled()
        }
    }
    
    private func handleMenuBarChange() {
        NotificationCenter.default.post(name: Notification.Name("MoodistMac.menuBarPreferenceDidChange"), object: nil)
    }
    
    private func handleAppearanceChange() {
        NotificationCenter.default.post(name: Notification.Name("MoodistMac.appearancePreferenceDidChange"), object: nil)
    }
    
    private func handleMaxRecentMixesChange() {
        store.trimRecentMixIdsToLimit()
    }

    private func handleMaxRecentSoundsChange() {
        store.trimRecentSoundIdsToLimit()
    }
    
    private func handleTransparencyToggle() {
        PersistenceService.saveTransparencyEnabled(transparencyEnabled)
        NotificationCenter.default.post(name: Notification.Name("MoodistMac.transparencyPreferenceDidChange"), object: nil)
    }

    private var menuBarSection: some View {
        Section {
            Toggle(isOn: $menuBarEnabled) {
                Text(L10n.menuBarShow)
            }
            .accessibilityLabel(L10n.menuBarShow)
            .accessibilityHint(L10n.menuBarShowFooter)
        } header: {
            Text(L10n.menuBar)
        } footer: {
            Text(L10n.menuBarShowFooter)
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker(selection: $appearanceModeRaw, label: Text(L10n.appearanceMode)) {
                Text(L10n.appearanceAutomatic).tag(AppearanceMode.system.rawValue)
                Text(L10n.appearanceLight).tag(AppearanceMode.light.rawValue)
                Text(L10n.appearanceDark).tag(AppearanceMode.dark.rawValue)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.appearanceMode)
            .accessibilityValue(appearanceModeValue)

            Picker(selection: $textSizeRaw, label: Text(L10n.textSize)) {
                Text(L10n.textSizeSmall).tag("small")
                Text(L10n.textSizeMedium).tag("medium")
                Text(L10n.textSizeLarge).tag("large")
                Text(L10n.textSizeExtraLarge).tag("xLarge")
            }
            .pickerStyle(.menu)
            .accessibilityLabel(L10n.textSize)
            .accessibilityValue(textSizeValue)

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.accentColor)
                AccentColorPicker(selection: Binding(
                    get: { accentChoice },
                    set: { accentChoice = $0 }
                ))
                Text(accentChoice.displayName)
                    .font(.footnote)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
            }
            
            Toggle(isOn: Binding(
                get: { !transparencyEnabled },
                set: { transparencyEnabled = !$0 }
            )) {
                Text(L10n.disableTransparencies)
            }
            .accessibilityLabel(L10n.disableTransparencies)
            Text(L10n.disableTransparenciesFooter)
                .font(.footnote)
                .foregroundStyle(MoodistTheme.Colors.secondaryText)
        } header: {
            Text(L10n.appearanceSection)
        }
    }
    
    private var textSizeValue: String {
        switch textSizeRaw {
        case "small": return L10n.textSizeSmall
        case "large": return L10n.textSizeLarge
        case "xLarge": return L10n.textSizeExtraLarge
        default: return L10n.textSizeMedium
        }
    }

    private var appearanceModeValue: String {
        switch appearanceMode {
        case .system: return L10n.appearanceAutomatic
        case .light: return L10n.appearanceLight
        case .dark: return L10n.appearanceDark
        }
    }

    private var generalSection: some View {
        Section {
            HStack {
                Text(L10n.globalVolume)
                Spacer()
                Text("\(Int(store.globalVolume * 100)) %")
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
            }
            Slider(
                value: Binding(
                    get: { store.globalVolume },
                    set: { store.setGlobalVolume(snappedVolume($0)) }
                ),
                in: 0...1
            )
            .controlSize(.small)
            .frame(height: 22)
            HStack {
                Text(L10n.maxRecentMixes)
                Spacer()
                Text("\(maxRecentMixesCount)")
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    .frame(minWidth: 24, alignment: .trailing)
                Stepper(value: $maxRecentMixesCount, in: 10...15, step: 1) {}
            }
            .accessibilityLabel(L10n.maxRecentMixes)
            .accessibilityValue("\(maxRecentMixesCount)")
            Text(L10n.maxRecentMixesFooter)
                .font(.footnote)
                .foregroundStyle(MoodistTheme.Colors.secondaryText)
            HStack {
                Text(L10n.maxRecentSounds)
                Spacer()
                Text("\(maxRecentSoundsCount)")
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    .frame(minWidth: 24, alignment: .trailing)
                Stepper(value: $maxRecentSoundsCount, in: 10...15, step: 1) {}
            }
            .accessibilityLabel(L10n.maxRecentSounds)
            .accessibilityValue("\(maxRecentSoundsCount)")
            Text(L10n.maxRecentSoundsFooter)
                .font(.footnote)
                .foregroundStyle(MoodistTheme.Colors.secondaryText)
            Toggle(isOn: $mediaKeyNextMix) {
                Text(L10n.mediaKeyNextMix)
            }
            .accessibilityLabel(L10n.mediaKeyNextMix)
            .accessibilityHint(L10n.mediaKeyNextMixFooter)
            Text(L10n.mediaKeyNextMixFooter)
                .font(.footnote)
                .foregroundStyle(MoodistTheme.Colors.secondaryText)
        } header: {
            Text(L10n.playbackSection)
        }
    }

    private func snappedVolume(_ value: Double) -> Double {
        let step = 0.05
        let snapped = (value / step).rounded() * step
        return min(1, max(0, snapped))
    }

    private var dataSection: some View {
        Section {
            Button(role: .none) {
                _ = store.exportPreferences()
            } label: {
                Label(L10n.exportPreferences, systemImage: "square.and.arrow.up")
            }
            .foregroundStyle(.primary)
            .accessibilityLabel(L10n.exportPreferences)
            .accessibilityHint(L10n.exportPreferencesHint)

            Button(role: .none) {
                _ = store.importPreferences()
            } label: {
                Label(L10n.importPreferences, systemImage: "square.and.arrow.down")
            }
            .foregroundStyle(.primary)
            .accessibilityLabel(L10n.importPreferences)
            .accessibilityHint(L10n.importPreferencesHint)

            Button(role: .none) {
                showResetConfirmation = true
            } label: {
                Label(L10n.resetSelectionAndFavorites, systemImage: "star.slash")
            }
            .foregroundStyle(.primary)
            .accessibilityLabel(L10n.resetSelectionAndFavorites)
            .accessibilityHint(L10n.resetSelectionHint)

            Button(role: .none) {
                showRestoreConfirmation = true
            } label: {
                Label(L10n.restoreAllDefaults, systemImage: "arrow.counterclockwise")
            }
            .foregroundStyle(.primary)
            .accessibilityLabel(L10n.restoreAllDefaults)
            .accessibilityHint(L10n.restoreDefaultsHint)
        } header: {
            Text(L10n.dataSection)
        } footer: {
            Text(L10n.dataSectionFooter)
        }
    }

    @ViewBuilder
    private var updatesSection: some View {
        if sparkleUpdater != nil {
            Section {
                Button {
                    sparkleUpdater?.checkForUpdates()
                } label: {
                    Label(L10n.checkForUpdates, systemImage: "arrow.down.circle")
                }
                .foregroundStyle(.primary)
                .disabled(!(sparkleUpdater?.canCheckForUpdates ?? false))
                .accessibilityLabel(L10n.checkForUpdates)

                Button {
                    updatePresenter.showPreview()
                } label: {
                    Label(L10n.updatePreviewToggle, systemImage: "sparkles")
                }
                .foregroundStyle(.primary)
                .accessibilityLabel(L10n.updatePreviewToggle)
            } header: {
                Text(L10n.updatesSection)
            } footer: {
                Text(L10n.updatePreviewFooter)
            }
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text(L10n.version)
                Spacer()
                Text(appVersion)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(L10n.version) \(appVersion)")

            if let url = URL(string: "https://moodist.mvze.net") {
                Link(destination: url) {
                    Label(L10n.visitWeb, systemImage: "globe")
                }
            }
            if let url = URL(string: "https://github.com/jsgrrchg/MoodistMac") {
                Link(destination: url) {
                    Label(L10n.sourceCode, systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
        } header: {
            Text(L10n.aboutSection)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func dismissIfNeeded() {
        closeOptionsWindow()
    }

    private func closeOptionsWindow() {
        dismissWindow(id: "options")
        store.showOptionsPanel = false
    }
}

private struct OptionsWindowConfigurator: NSViewRepresentable {
    let size: CGSize

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        if context.coordinator.window !== window {
            context.coordinator.window = window
        }
        if window.styleMask.contains(.resizable) {
            window.styleMask.remove(.resizable)
        }
        if window.minSize != size {
            window.minSize = size
        }
        if window.maxSize != size {
            window.maxSize = size
        }
        let contentSize = window.contentRect(forFrameRect: window.frame).size
        if contentSize.width != size.width || contentSize.height != size.height {
            window.setContentSize(size)
        }
    }

    final class Coordinator {
        weak var window: NSWindow?
    }
}

private struct AccentColorPicker: View {
    @Binding var selection: AccentColorChoice

    private let swatchSize: CGFloat = 14
    private let swatchSpacing: CGFloat = 8

    var body: some View {
        HStack(spacing: swatchSpacing) {
            ForEach(AccentColorChoice.allCases) { option in
                Button {
                    selection = option
                } label: {
                    Circle()
                        .fill(option.swatchStyle)
                        .frame(width: swatchSize, height: swatchSize)
                        .overlay(selectionRing(for: option))
                        .shadow(color: Color.black.opacity(0.08), radius: 0.5, x: 0, y: 0.5)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.displayName)
                .accessibilityAddTraits(selection == option ? [.isSelected] : [])
            }
        }
    }

    @ViewBuilder private func selectionRing(for option: AccentColorChoice) -> some View {
        if selection == option {
            Circle()
                .strokeBorder(Color.primary.opacity(0.7), lineWidth: 2)
        } else {
            Circle()
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        OptionsView()
            .environmentObject(SoundStore(audioService: AudioService()))
    }
}
