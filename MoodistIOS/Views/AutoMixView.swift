import SwiftUI
import MoodistKit

struct AutoMixView: View {
    @EnvironmentObject private var store: SoundStore
    @State private var interval = 15 * 60
    var body: some View {
        Form {
            Section {
                Toggle(T("custom_only", "Only my mixes"), isOn: $store.autoMixCustomOnly)
                    .onChange(of: store.autoMixCustomOnly) { _, _ in store.persistTimers() }
                Picker(T("interval", "Interval"), selection: $interval) {
                    ForEach(SoundStore.autoMixIntervalPresets, id: \.self) { seconds in
                        Text(store.autoMixIntervalLabel(forSeconds: seconds)).tag(seconds)
                    }
                }
                Button(store.hasActiveAutoMixTimer ? T("replace_rotation", "Replace rotation") : T("start_rotation", "Start rotation")) {
                    store.startAutoMixTimer(intervalSeconds: interval)
                }.disabled(store.autoMixCustomOnly && store.presets.isEmpty)
                if store.autoMixCustomOnly && store.presets.isEmpty {
                    Text(T("no_custom_mixes", "Save your first mix from the player.")).foregroundStyle(.secondary)
                }
            } footer: {
                Text(T("rotation_behavior", "Mixes change while audio is playing. Pausing keeps the current mix; the sleep timer stops rotation."))
            }
            if store.hasActiveAutoMixTimer {
                Section {
                    AutoMixStatusView()
                    Button(L10n.cancel, role: .destructive) { store.cancelAutoMixTimer() }
                }
            }
        }
        .navigationTitle(T("auto_mix", "Automatic mixes"))
        .onAppear { interval = store.autoMixIntervalSeconds ?? 15 * 60 }
    }
}

struct AutoMixStatusView: View {
    @EnvironmentObject private var store: SoundStore
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            if let next = store.autoMixNextFireDate {
                Label(store.timerLabel(forSeconds: max(0, Int(ceil(next.timeIntervalSince(context.date))))), systemImage: "shuffle")
                    .monospacedDigit()
                    .accessibilityLabel(T("next_rotation", "Next automatic mix"))
            }
        }
    }
}
