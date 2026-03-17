//
//  OptionsView.swift
//  MoodistMac
//
//  Menú de opciones: Reproducción, Datos, Acerca de.
//

import AppKit
import Sparkle
import SwiftUI

private enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark
}

struct OptionsView: View {
    @EnvironmentObject var store: SoundStore
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.sparkleUpdater) private var sparkleUpdater
    @AppStorage(PersistenceService.menuBarEnabledKey) private var menuBarEnabled = false
    @AppStorage(PersistenceService.appearanceModeKey) private var appearanceModeRaw = AppearanceMode
        .system.rawValue
    @AppStorage(PersistenceService.accentColorHexKey) private var accentColorRaw = AccentColorChoice
        .graphite.rawValue
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparencyEnabled = true
    @AppStorage(PersistenceService.maxRecentMixesCountKey) private var maxRecentMixesCount: Int = 10
    @AppStorage(PersistenceService.maxRecentSoundsCountKey) private var maxRecentSoundsCount: Int =
        12
    @AppStorage(PersistenceService.mediaKeyNextMixKey) private var mediaKeyNextMix = true
    @AppStorage(PersistenceService.collapseCategoriesOnColdOpenKey) private
        var collapseCategoriesOnColdOpen = true
    @State private var showResetConfirmation = false
    @State private var showRestoreConfirmation = false
    private let optionsWindowSize = CGSize(width: 510, height: 650)

    private var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }

    private var accentChoice: AccentColorChoice {
        get { AccentColorChoice(rawValue: accentColorRaw) ?? .graphite }
        nonmutating set { accentColorRaw = newValue.rawValue }
    }

    var body: some View {
        formContent
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.optionsTitle)
            .background(optionsBackground)
            .background(
                OptionsWindowConfigurator(
                    size: optionsWindowSize, transparencyEnabled: transparencyEnabled)
            )
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
            .onChange(of: accentColorRaw) { _, _ in
                NotificationCenter.default.post(name: .accentPreferenceDidChange, object: nil)
            }
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
        .toggleStyle(OptionsToggleStyle())
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
        if maxRecentMixesCount < 5 || maxRecentMixesCount > 15 {
            maxRecentMixesCount = 10
        }
        if maxRecentSoundsCount < 5 || maxRecentSoundsCount > 15 {
            maxRecentSoundsCount = 12
        }
        if AccentColorChoice(rawValue: accentColorRaw) == nil {
            accentColorRaw = AccentColorChoice.graphite.rawValue
        }
        if UserDefaults.standard.object(forKey: PersistenceService.transparencyEnabledKey) == nil {
            transparencyEnabled = PersistenceService.loadTransparencyEnabled()
        }
    }

    private func handleMenuBarChange() {
        NotificationCenter.default.post(name: .menuBarPreferenceDidChange, object: nil)
    }

    private func handleAppearanceChange() {
        NotificationCenter.default.post(name: .appearancePreferenceDidChange, object: nil)
    }

    private func handleMaxRecentMixesChange() {
        store.trimRecentMixIdsToLimit()
    }

    private func handleMaxRecentSoundsChange() {
        store.trimRecentSoundIdsToLimit()
    }

    private func handleTransparencyToggle() {
        PersistenceService.saveTransparencyEnabled(transparencyEnabled)
        NotificationCenter.default.post(name: .transparencyPreferenceDidChange, object: nil)
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

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.accentColor)
                AccentColorPicker(
                    selection: Binding(
                        get: { accentChoice },
                        set: { accentChoice = $0 }
                    ))
                Text(accentChoice.displayName)
                    .font(.footnote)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
            }

            Toggle(
                isOn: Binding(
                    get: { !transparencyEnabled },
                    set: { transparencyEnabled = !$0 }
                )
            ) {
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
            }
            .accessibilityLabel(L10n.maxRecentMixes)
            .accessibilityValue("\(maxRecentMixesCount)")
            Slider(
                value: Binding(
                    get: { Double(maxRecentMixesCount) },
                    set: { maxRecentMixesCount = Int($0.rounded()) }
                ),
                in: 5...15,
                step: 1
            )
            .controlSize(.small)
            .frame(height: 22)
            Text(L10n.maxRecentMixesFooter)
                .font(.footnote)
                .foregroundStyle(MoodistTheme.Colors.secondaryText)
            HStack {
                Text(L10n.maxRecentSounds)
                Spacer()
                Text("\(maxRecentSoundsCount)")
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    .frame(minWidth: 24, alignment: .trailing)
            }
            .accessibilityLabel(L10n.maxRecentSounds)
            .accessibilityValue("\(maxRecentSoundsCount)")
            Slider(
                value: Binding(
                    get: { Double(maxRecentSoundsCount) },
                    set: { maxRecentSoundsCount = Int($0.rounded()) }
                ),
                in: 5...15,
                step: 1
            )
            .controlSize(.small)
            .frame(height: 22)
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
            Toggle(isOn: $collapseCategoriesOnColdOpen) {
                Text(L10n.collapseCategoriesOnColdOpen)
            }
            .accessibilityLabel(L10n.collapseCategoriesOnColdOpen)
            .accessibilityHint(L10n.collapseCategoriesOnColdOpenFooter)
            Text(L10n.collapseCategoriesOnColdOpenFooter)
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
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .offset(y: -0.5)
                    Text(L10n.exportPreferences)
                }
            }
            .buttonStyle(OptionsCapsuleButtonStyle(isPrimary: false))
            .accessibilityLabel(L10n.exportPreferences)
            .accessibilityHint(L10n.exportPreferencesHint)

            Button(role: .none) {
                _ = store.importPreferences()
            } label: {
                Label(L10n.importPreferences, systemImage: "square.and.arrow.down")
            }
            .buttonStyle(OptionsCapsuleButtonStyle(isPrimary: false))
            .accessibilityLabel(L10n.importPreferences)
            .accessibilityHint(L10n.importPreferencesHint)

            Button(role: .none) {
                showResetConfirmation = true
            } label: {
                Label(L10n.resetSelectionAndFavorites, systemImage: "star.slash")
            }
            .buttonStyle(OptionsCapsuleButtonStyle(isPrimary: false))
            .accessibilityLabel(L10n.resetSelectionAndFavorites)
            .accessibilityHint(L10n.resetSelectionHint)

            Button(role: .none) {
                showRestoreConfirmation = true
            } label: {
                Label(L10n.restoreAllDefaults, systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(OptionsCapsuleButtonStyle(isPrimary: false))
            .accessibilityLabel(L10n.restoreAllDefaults)
            .accessibilityHint(L10n.restoreDefaultsHint)
        } header: {
            Text(L10n.dataSection)
        } footer: {
            Text(L10n.dataSectionFooter)
        }
    }

    private var updatesSection: some View {
        Section {
            if let updater = sparkleUpdater {
                SparkleCheckForUpdatesButton(updater: updater)
                    .buttonStyle(OptionsCapsuleButtonStyle(isPrimary: false))
                    .accessibilityLabel(L10n.checkForUpdates)
            }
        } header: {
            Text(L10n.updatesSection)
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

            HStack {
                Text(L10n.createdBy)
                Spacer()
                Text("José Gurruchaga")
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(L10n.createdBy) José Gurruchaga")

            if let url = URL(string: "https://buymeacoffee.com/jsgrrchg") {
                Link(destination: url) {
                    Label(L10n.buyMeACoffee, systemImage: "cup.and.saucer")
                }
                .buttonStyle(OptionsCapsuleButtonStyle(isPrimary: false))
            }
            if let url = URL(string: "mailto:jsgrrchg@outlook.com") {
                Link(destination: url) {
                    Label(L10n.askForNewSound, systemImage: "envelope")
                }
                .buttonStyle(OptionsCapsuleButtonStyle(isPrimary: false))
            }

            if let url = URL(string: "https://moodist.mvze.net") {
                Link(destination: url) {
                    Label(L10n.visitWeb, systemImage: "globe")
                }
                .buttonStyle(OptionsCapsuleButtonStyle(isPrimary: false))
            }
            if let url = URL(string: "https://github.com/jsgrrchg/MoodistMac") {
                Link(destination: url) {
                    Label(L10n.sourceCode, systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .buttonStyle(OptionsCapsuleButtonStyle(isPrimary: false))
            }
        } header: {
            Text(L10n.aboutSection)
        }
    }

    @ViewBuilder private var optionsBackground: some View {
        if transparencyEnabled {
            VisualEffectBackground(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea(.container)
        } else {
            PlatformColor.windowBackground
                .ignoresSafeArea(.container)
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
    let transparencyEnabled: Bool

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
        if transparencyEnabled {
            window.isOpaque = false
            window.backgroundColor = .clear
        } else {
            window.isOpaque = true
            window.backgroundColor = NSColor.windowBackgroundColor
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

private struct OptionsCapsuleButtonStyle: ButtonStyle {
    let isPrimary: Bool
    let fillWidth: Bool
    @Environment(\.isEnabled) private var isEnabled

    init(isPrimary: Bool, fillWidth: Bool = true) {
        self.isPrimary = isPrimary
        self.fillWidth = fillWidth
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: fillWidth ? .infinity : nil, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .overlay(
                Capsule()
                    .strokeBorder(borderColor(isPressed: configuration.isPressed), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .opacity(isEnabled ? 1 : 0.5)
    }

    private var foregroundColor: Color {
        if !isEnabled { return MoodistTheme.Colors.secondaryText.opacity(0.8) }
        return isPrimary ? MoodistTheme.Colors.accent : Color.primary.opacity(0.88)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if !isEnabled { return MoodistTheme.Colors.cardBackground.opacity(0.22) }
        if isPressed { return MoodistTheme.Colors.cardBackground.opacity(0.9) }
        return MoodistTheme.Colors.cardBackground.opacity(0.55)
    }

    private func borderColor(isPressed: Bool) -> Color {
        if !isEnabled { return Color.primary.opacity(0.08) }
        if isPrimary {
            return MoodistTheme.Colors.accent.opacity(isPressed ? 0.5 : 0.34)
        }
        return Color.primary.opacity(isPressed ? 0.2 : 0.12)
    }
}

private struct SparkleCheckForUpdatesButton: View {
    private let updater: SPUUpdater
    @StateObject private var viewModel: CheckForUpdatesViewModel

    init(updater: SPUUpdater) {
        self.updater = updater
        _viewModel = StateObject(wrappedValue: CheckForUpdatesViewModel(updater: updater))
    }

    var body: some View {
        Button {
            updater.checkForUpdates()
        } label: {
            Label(L10n.checkForUpdates, systemImage: "arrow.down.circle")
        }
        .disabled(!viewModel.canCheckForUpdates)
    }
}

private struct OptionsToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        ToggleControl(configuration: configuration)
    }

    private struct ToggleControl: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled
        @State private var isHovered = false
        @FocusState private var isFocused: Bool

        private let trackSize = CGSize(width: 36, height: 20)
        private let thumbSize: CGFloat = 16

        var body: some View {
            Button {
                configuration.isOn.toggle()
            } label: {
                HStack(spacing: MoodistTheme.Spacing.medium) {
                    configuration.label
                    Spacer(minLength: MoodistTheme.Spacing.medium)
                    toggleTrack
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable()
            .focused($isFocused)
            .focusEffectDisabled()
            .onHover { hovering in
                isHovered = hovering
            }
            .opacity(isEnabled ? 1 : 0.52)
        }

        private var toggleTrack: some View {
            RoundedRectangle(cornerRadius: trackSize.height / 2, style: .continuous)
                .fill(trackFill)
                .overlay {
                    RoundedRectangle(cornerRadius: trackSize.height / 2, style: .continuous)
                        .strokeBorder(trackBorder, lineWidth: 1)
                }
                .frame(width: trackSize.width, height: trackSize.height)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Color.white.opacity(isEnabled ? 0.98 : 0.9))
                        .frame(width: thumbSize, height: thumbSize)
                        .padding(2)
                        .shadow(
                            color: .black.opacity(0.28), radius: isHovered ? 2.5 : 2, x: 0, y: 1)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: trackSize.height / 2, style: .continuous)
                        .strokeBorder(
                            isFocused ? MoodistTheme.Colors.accent.opacity(0.55) : .clear,
                            lineWidth: 2
                        )
                        .padding(-2)
                }
                .scaleEffect(isHovered ? 1.01 : 1)
                .animation(
                    .interactiveSpring(response: 0.22, dampingFraction: 0.82),
                    value: configuration.isOn
                )
                .animation(.easeInOut(duration: 0.14), value: isHovered)
        }

        private var trackFill: Color {
            if configuration.isOn {
                return MoodistTheme.Colors.accent.opacity(isHovered ? 0.98 : 0.9)
            }
            return MoodistTheme.Colors.cardBackground.opacity(isHovered ? 0.86 : 0.72)
        }

        private var trackBorder: Color {
            if configuration.isOn {
                return MoodistTheme.Colors.accent.opacity(0.42)
            }
            return Color.primary.opacity(0.18)
        }
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
