import SwiftUI

// MARK: - Drum Column Picker

private struct TimerColumnPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(MoodistTheme.Colors.secondaryText)

            // Number: TextField while editing, Text otherwise
            if isEditing {
                TextField("", text: $editText)
                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .frame(width: 72, height: 58)
                    .focused($fieldFocused)
                    .onSubmit { commitEdit() }
                    .onChange(of: editText) { _, newVal in
                        let filtered = String(newVal.filter(\.isNumber).prefix(2))
                        if filtered != newVal { editText = filtered }
                    }
                    .onChange(of: fieldFocused) { _, focused in
                        if !focused { commitEdit() }
                    }
            } else {
                Text(String(format: "%02d", value))
                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(width: 72, height: 58)
                    .contentShape(Rectangle())
                    .onTapGesture { beginEdit() }
            }
        }
    }

    private func beginEdit() {
        editText = String(format: "%02d", value)
        isEditing = true
        fieldFocused = true
    }

    private func commitEdit() {
        if let parsed = Int(editText) {
            value = max(range.lowerBound, min(range.upperBound, parsed))
        }
        isEditing = false
        editText = ""
    }
}

// MARK: - Separator

private struct ColonSeparator: View {
    var body: some View {
        VStack(spacing: 6) {
            // Spacer matching the label row height
            Color.clear.frame(height: 16)
            Text(":")
                .font(.system(size: 42, weight: .thin, design: .monospaced))
                .foregroundStyle(MoodistTheme.Colors.secondaryText)
                .frame(height: 58)
        }
    }
}

// MARK: - Timer Setup View

struct TimerSetupView: View {
    @ObservedObject var store: SoundStore
    var onDismiss: () -> Void

    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 15
    @State private var selectedSeconds: Int = 0

    @State private var isCancelHovered = false
    @State private var isStopHovered = false
    @State private var isStartHovered = false

    private let quickPresetMinutes: [Int] = [15, 30, 45, 60, 90, 120]

    private var totalSeconds: Int {
        selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds
    }

    private var canStart: Bool { totalSeconds >= 1 }

    private var hasActiveTimer: Bool { store.activeTimer != nil }

    private var primaryButtonTitle: String {
        hasActiveTimer ? L10n.timerReplace : L10n.timerStart
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            VStack(spacing: MoodistTheme.Spacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    MoodistTheme.Colors.accent.opacity(0.25),
                                    MoodistTheme.Colors.cardBackground.opacity(0.85),
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
                .frame(width: 56, height: 56)

                Text(L10n.timerCustomTitle)
                    .font(.title3.weight(.semibold))
                Text(L10n.timerCustomMessage)
                    .font(.subheadline)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, MoodistTheme.Spacing.medium)

            // MARK: Active timer banner
            if let timer = store.activeTimer {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundStyle(MoodistTheme.Colors.accent)
                    Text(L10n.timerActiveNow(formatRemaining(seconds: timer.remainingSeconds)))
                        .font(.subheadline)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, MoodistTheme.Spacing.small)
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

            // MARK: Drum Picker
            HStack(alignment: .top, spacing: 0) {
                Spacer(minLength: 0)
                TimerColumnPicker(value: $selectedHours, range: 0...23, label: "h")
                ColonSeparator()
                TimerColumnPicker(value: $selectedMinutes, range: 0...59, label: "min")
                ColonSeparator()
                TimerColumnPicker(value: $selectedSeconds, range: 0...59, label: "s")
                Spacer(minLength: 0)
            }
            .padding(.horizontal, MoodistTheme.Spacing.medium)
            .padding(.vertical, MoodistTheme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: MoodistTheme.Radius.large)
                    .fill(MoodistTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MoodistTheme.Radius.large)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )

            // MARK: Quick Presets
            VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                Text(L10n.timerQuickPresets)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 6)], spacing: 6) {
                    ForEach(quickPresetMinutes, id: \.self) { minutes in
                        Button {
                            applyQuickPreset(minutes: minutes)
                        } label: {
                            Text(formatQuickPreset(minutes))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(
                            HeaderActionButtonStyle(
                                isHovered: false,
                                isPrimary: isActivePreset(minutes: minutes),
                                isCompact: true
                            ))
                    }
                }
            }
            .padding(.top, MoodistTheme.Spacing.medium)

            // MARK: Action Buttons
            HStack(spacing: 8) {
                Button(L10n.cancel) { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(
                        HeaderActionButtonStyle(
                            isHovered: isCancelHovered,
                            isPrimary: false,
                            isCompact: false
                        )
                    )
                    .onHover { isCancelHovered = $0 }

                if hasActiveTimer {
                    Button(L10n.timerStopCurrent) {
                        store.cancelSleepTimer()
                        onDismiss()
                    }
                    .buttonStyle(
                        HeaderActionButtonStyle(
                            isHovered: isStopHovered,
                            isPrimary: false,
                            isCompact: false
                        )
                    )
                    .onHover { isStopHovered = $0 }
                }

                Button(primaryButtonTitle) { startAndDismiss() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(
                        HeaderActionButtonStyle(
                            isHovered: isStartHovered,
                            isPrimary: true,
                            isCompact: false
                        )
                    )
                    .onHover { isStartHovered = $0 }
                    .disabled(!canStart)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, MoodistTheme.Spacing.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(width: 348)
        .background(PlatformColor.windowBackground)
    }

    // MARK: - Helpers

    private func applyQuickPreset(minutes: Int) {
        selectedHours = minutes / 60
        selectedMinutes = minutes % 60
        selectedSeconds = 0
    }

    private func isActivePreset(minutes: Int) -> Bool {
        selectedSeconds == 0 && selectedHours == minutes / 60 && selectedMinutes == minutes % 60
    }

    private func startAndDismiss() {
        // Fuerza commit del TextField activo antes de leer totalSeconds.
        NSApp.keyWindow?.makeFirstResponder(nil)
        DispatchQueue.main.async {
            guard canStart else { return }
            store.startSleepTimer(durationSeconds: totalSeconds)
            onDismiss()
        }
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
        if hours > 0 && remainder > 0 { return "\(hours)h \(remainder)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(minutes)m"
    }
}
