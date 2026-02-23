import SwiftUI

struct TimerSetupView: View {
    @ObservedObject var store: SoundStore
    var onDismiss: () -> Void

    @State private var minutesText = ""
    @State private var isCancelHovered = false
    @State private var isStopHovered = false
    @State private var isStartHovered = false
    @FocusState private var isMinutesFocused: Bool

    private let quickPresetMinutes: [Int] = [15, 30, 45, 60, 90, 120]
    private let maxMinutes = 24 * 60

    private var parsedMinutes: Int? {
        Int(minutesText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var canStart: Bool {
        guard let minutes = parsedMinutes else { return false }
        return (1...maxMinutes).contains(minutes)
    }

    private var validationMessage: String? {
        guard !minutesText.isEmpty else { return nil }
        guard let minutes = parsedMinutes, (1...maxMinutes).contains(minutes) else {
            return L10n.timerMinutesValidation
        }
        if minutes >= 60 {
            let hours = Double(minutes) / 60.0
            return String(format: "%.1f h", hours)
        }
        return "\(minutes) min"
    }

    private var hasActiveTimer: Bool {
        store.activeTimer != nil
    }

    private var primaryButtonTitle: String {
        hasActiveTimer ? L10n.timerReplace : L10n.timerStart
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: MoodistTheme.Spacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    MoodistTheme.Colors.accent.opacity(0.25),
                                    MoodistTheme.Colors.cardBackground.opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                    Image(systemName: "timer")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(MoodistTheme.Colors.accent)
                }
                .frame(width: 62, height: 62)

                Text(L10n.timerCustomTitle)
                    .font(.title3.weight(.semibold))
                Text(L10n.timerCustomMessage)
                    .font(.subheadline)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, MoodistTheme.Spacing.large)

            if let timer = store.activeTimer {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundStyle(MoodistTheme.Colors.accent)
                    Text(L10n.timerActiveNow(formatRemaining(seconds: timer.remainingSeconds)))
                        .font(.subheadline)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, MoodistTheme.Spacing.medium)
                .padding(.vertical, MoodistTheme.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                        .fill(MoodistTheme.Colors.cardBackground.opacity(0.65))
                        .overlay(
                            RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.bottom, MoodistTheme.Spacing.medium)
            }

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                TextField(L10n.timerMinutesPlaceholder, text: $minutesText)
                    .focused($isMinutesFocused)
                    .textFieldStyle(.plain)
                    .onSubmit { startAndDismiss() }
                    .onChange(of: minutesText) { _, newValue in
                        let filtered = String(newValue.filter(\.isNumber))
                        if filtered != newValue {
                            minutesText = filtered
                        }
                    }
            }
            .padding(.horizontal, MoodistTheme.Spacing.medium)
            .padding(.vertical, MoodistTheme.Spacing.small + 2)
            .background(
                RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                    .fill(MoodistTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                            .strokeBorder(canStart || minutesText.isEmpty ? Color.primary.opacity(0.12) : Color.red.opacity(0.45), lineWidth: 1)
                    )
            )

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(canStart ? MoodistTheme.Colors.secondaryText : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, MoodistTheme.Spacing.xSmall)
            }

            VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                Text(L10n.timerQuickPresets)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                    ForEach(quickPresetMinutes, id: \.self) { minutes in
                        Button {
                            minutesText = "\(minutes)"
                        } label: {
                            Text(formatQuickPreset(minutes))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HeaderActionButtonStyle(
                            isHovered: false,
                            isPrimary: parsedMinutes == minutes,
                            isCompact: true
                        ))
                    }
                }
            }
            .padding(.top, MoodistTheme.Spacing.medium)

            HStack(spacing: MoodistTheme.Spacing.small) {
                Button(L10n.cancel) { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(HeaderActionButtonStyle(
                        isHovered: isCancelHovered,
                        isPrimary: false,
                        isCompact: false
                    ))
                    .onHover { isCancelHovered = $0 }

                if hasActiveTimer {
                    Button(L10n.timerStopCurrent) {
                        store.cancelSleepTimer()
                        onDismiss()
                    }
                    .buttonStyle(HeaderActionButtonStyle(
                        isHovered: isStopHovered,
                        isPrimary: false,
                        isCompact: false
                    ))
                    .onHover { isStopHovered = $0 }
                }

                Button(primaryButtonTitle) { startAndDismiss() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(HeaderActionButtonStyle(
                        isHovered: isStartHovered,
                        isPrimary: true,
                        isCompact: false
                    ))
                    .onHover { isStartHovered = $0 }
                    .disabled(!canStart)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, MoodistTheme.Spacing.large)
        }
        .padding(MoodistTheme.Spacing.xLarge)
        .frame(width: 380)
        .background(PlatformColor.windowBackground)
        .onAppear { isMinutesFocused = true }
    }

    private func startAndDismiss() {
        guard canStart, let minutes = parsedMinutes else { return }
        store.startSleepTimer(durationSeconds: minutes * 60)
        onDismiss()
    }

    private func formatRemaining(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        if seconds >= 3600 {
            formatter.allowedUnits = [.hour, .minute]
        } else if seconds >= 60 {
            formatter.allowedUnits = [.minute, .second]
            formatter.zeroFormattingBehavior = .pad
        } else {
            formatter.allowedUnits = [.second]
        }
        return formatter.string(from: TimeInterval(seconds)) ?? "\(seconds)s"
    }

    private func formatQuickPreset(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours > 0 && remainder > 0 {
            return "\(hours)h \(remainder)m"
        }
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }
}
