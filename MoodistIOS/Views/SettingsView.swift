import SwiftUI
import MoodistKit

struct SettingsView: View {
    @EnvironmentObject private var store: SoundStore
    @EnvironmentObject private var session: IOSAudioSessionController
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PersistenceService.appearanceModeKey) private var appearance = "system"
    @AppStorage(PersistenceService.accentColorHexKey) private var accent = "graphite"
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparency = true
    @AppStorage(PersistenceService.appLanguageKey) private var language = "system"
    @AppStorage(PersistenceService.maxRecentSoundsCountKey) private var soundLimit = 12
    @AppStorage(PersistenceService.maxRecentMixesCountKey) private var mixLimit = 10
    @AppStorage(PersistenceService.mediaKeyNextMixKey) private var nextKey = true
    @AppStorage(PersistenceService.collapseCategoriesOnColdOpenKey) private var collapse = false
    @State private var resetRequested = false
    @State private var restoreRequested = false
    @State private var sessionError: String?
    var body: some View {
        Form {
            Section(L10n.playbackSection) {
                VolumeControl(label: L10n.globalVolume, value: Binding(get: { store.globalVolume }, set: { store.setGlobalVolume($0) }))
                Toggle(T("mix_other_apps", "Mix with other apps"), isOn: Binding(get: { session.mixesWithOthers }, set: {
                    do { try session.setMixing($0) } catch { sessionError = error.localizedDescription }
                }))
                Text(T("mix_other_apps_hint", "When mixing, another audio app may own the Lock Screen and headphone controls. Use Moodist’s player to control this mix.")).font(.footnote).foregroundStyle(.secondary)
                Toggle(L10n.mediaKeyNextMix, isOn: $nextKey)
                Stepper("\(T("recent_sounds", "Recent sounds")): \(soundLimit)", value: $soundLimit, in: 5...15)
                Stepper("\(T("recent_mixes", "Recent mixes")): \(mixLimit)", value: $mixLimit, in: 5...15)
                Toggle(L10n.collapseCategoriesOnColdOpen, isOn: $collapse)
            }
            Section(L10n.appearanceSection) {
                Picker(L10n.appearanceMode, selection: $appearance) {
                    Text(L10n.appearanceAutomatic).tag("system")
                    Text(L10n.appearanceLight).tag("light")
                    Text(L10n.appearanceDark).tag("dark")
                }
                Picker(L10n.accentColor, selection: $accent) {
                    ForEach(IOSAccent.choices, id: \.self) { raw in Text(IOSAccent.label(raw)).tag(raw) }
                }
                Toggle(L10n.disableTransparencies, isOn: Binding(get: { !transparency }, set: { transparency = !$0 }))
                Text(T("transparency_hint", "Custom surfaces become solid. System bars follow your iPhone’s accessibility and Liquid Glass settings.")).font(.footnote).foregroundStyle(.secondary)
            }
            Section(L10n.language) {
                Picker(L10n.language, selection: $language) {
                    Text(L10n.languageSystem).tag("system")
                    Text(L10n.languageEnglish).tag("en")
                    Text(L10n.languageSpanish).tag("es")
                    Text(L10n.languagePortuguese).tag("pt-BR")
                }
            }
            PreferenceFilesSection()
            Section(L10n.dataSection) {
                Button(L10n.resetSelectionAndFavorites, role: .destructive) { resetRequested = true }
                Button(L10n.restoreAllDefaults, role: .destructive) { restoreRequested = true }
            }
            Section {
                NavigationLink(L10n.aboutSection) { AboutView() }
            }
        }
        .navigationTitle(L10n.options)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.close) { dismiss() } } }
        .onChange(of: soundLimit) { _, _ in store.trimRecentSoundIdsToLimit() }
        .onChange(of: mixLimit) { _, _ in store.trimRecentMixIdsToLimit() }
        .alert(L10n.resetConfirmTitle, isPresented: $resetRequested) {
            Button(L10n.reset, role: .destructive) { store.resetSelectionAndFavorites() }
            Button(L10n.cancel, role: .cancel) {}
        } message: { Text(L10n.resetConfirmMessage) }
        .alert(L10n.restoreConfirmTitle, isPresented: $restoreRequested) {
            Button(L10n.restore, role: .destructive) {
                store.resetAllToDefaults()
                do { try session.setMixing(false) } catch { sessionError = error.localizedDescription }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: { Text(L10n.restoreConfirmMessage) }
        .alert(T("audio_session_error", "Audio settings could not be changed"), isPresented: Binding(get: { sessionError != nil }, set: { if !$0 { sessionError = nil } })) {
            Button(L10n.close) { sessionError = nil }
        } message: { Text(sessionError ?? "") }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section("Moodist") {
                LabeledContent(L10n.version, value: "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                Text(T("about_description", "Ambient sounds for focus and relaxation. Your mixes stay on this device unless you export them."))
            }
            Section(L10n.aboutSection) {
                Link(L10n.sourceCode, destination: URL(string: "https://github.com/jsgrrchg/MoodistMac")!)
                Link(T("support", "Support"), destination: URL(string: "https://github.com/jsgrrchg/MoodistMac/issues")!)
                Text(T("credits", "Inspired by Moodist by remvze. Audio includes third-party resources credited in the project."))
            }
        }.navigationTitle(L10n.aboutSection)
    }
}
