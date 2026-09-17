import SwiftUI
import UserNotifications
import MoodistKit

struct SleepTimerView: View {
    @EnvironmentObject private var store: SoundStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var hours = 0
    @State private var minutes = 15
    @State private var seconds = 0
    @State private var notificationsDenied = false
    private var duration: Int { hours * 3600 + minutes * 60 + seconds }
    var body: some View {
        Form {
            if store.hasActiveTimer {
                Section {
                    TimerStatusView()
                    Button(L10n.timerStopCurrent, role: .destructive) { store.cancelSleepTimer() }
                }
            }
            Section(L10n.timerCustomTitle) {
                Picker(L10n.timerHours, selection: $hours) { ForEach(0..<24) { Text("\($0)").tag($0) } }
                Picker(L10n.timerMinutes, selection: $minutes) { ForEach(0..<60) { Text("\($0)").tag($0) } }
                Picker(T("seconds", "Seconds"), selection: $seconds) { ForEach(0..<60) { Text("\($0)").tag($0) } }
                Button(store.hasActiveTimer ? L10n.timerReplace : L10n.timerStart) {
                    store.startSleepTimer(durationSeconds: duration)
                    dismiss()
                }.disabled(duration == 0).accessibilityIdentifier("start-sleep-timer")
            }
            Section(L10n.timerQuickPresets) {
                ForEach(SoundStore.timerMenuMinutesPresets + SoundStore.timerMenuHoursPresets, id: \.self) { duration in
                    Button(store.timerLabel(forSeconds: duration)) {
                        store.startSleepTimer(durationSeconds: duration)
                        dismiss()
                    }
                }
            }
            if notificationsDenied {
                Section {
                    Text(T("notifications_denied", "The timer still stops playback. Enable notifications in Settings if you want a completion alert."))
                    Button(L10n.options) { openURL(URL(string: UIApplication.openSettingsURLString)!) }
                }
            }
        }
        .navigationTitle(L10n.timer)
        .task { notificationsDenied = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied }
    }
}

struct TimerStatusView: View {
    @EnvironmentObject private var store: SoundStore
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            if store.hasActiveTimer {
                Label(store.timerLabel(forSeconds: store.sleepRemainingSeconds), systemImage: "moon.zzz")
                    .monospacedDigit().accessibilityLabel(L10n.timer)
                    .accessibilityValue(store.timerLabel(forSeconds: store.sleepRemainingSeconds))
            }
        }
    }
}
