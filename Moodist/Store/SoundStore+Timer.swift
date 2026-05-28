import Foundation

extension SoundStore {
    // MARK: - Auto Mix Timer

    /// Available intervals for automatic mix changes.
    static let autoMixIntervalPresets: [Int] = [5, 10, 15, 20, 30, 40, 50, 60].map { $0 * 60 }

    var hasActiveAutoMixTimer: Bool { autoMixIntervalSeconds != nil }
    /// Date when the timer will trigger the next mix change.
    var autoMixNextFireDate: Date? { autoMixTimerToken?.fireDate }

    /// Starts a repeating timer that switches to the next random mix every `intervalSeconds`.
    func startAutoMixTimer(intervalSeconds: Int) {
        autoMixTimerToken?.invalidate()
        autoMixIntervalSeconds = intervalSeconds
        autoMixTimerToken = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(intervalSeconds), repeats: true
        ) { [weak self] _ in
            Task { @MainActor in self?.playNextRandomMix() }
        }
    }

    /// Stops the automatic mix-change timer.
    func cancelAutoMixTimer() {
        autoMixTimerToken?.invalidate()
        autoMixTimerToken = nil
        autoMixIntervalSeconds = nil
    }

    /// Long label for the Pomodoro menu ("5 minutes", "1 hour", etc.).
    func autoMixIntervalLabel(forSeconds seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = seconds >= 3600 ? [.hour] : [.minute]
        return formatter.string(from: TimeInterval(seconds)) ?? timerLabel(forSeconds: seconds)
    }

    // MARK: - Timers (Sleep)

    // Starts a sleep timer, records usage, and schedules the completion callback.
    func startSleepTimer(durationSeconds: Int, name: String? = nil) {
        let safeDuration = max(1, durationSeconds)
        cancelSleepTimer()
        let displayName = name ?? timerLabel(forSeconds: safeDuration)
        let endDate = Date().addingTimeInterval(TimeInterval(safeDuration))
        activeTimer = TimerItem(
            name: displayName, durationSeconds: safeDuration, state: .running(endDate: endDate))
        timerUsageCounts[safeDuration, default: 0] += 1
        PersistenceService.saveTimerUsageCounts(timerUsageCounts)
        TimerNotificationManager.shared.requestAuthorizationIfNeeded()
        activeTimerToken = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(safeDuration), repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.completeSleepTimer()
            }
        }
        NotificationCenter.default.post(name: .timerStateDidChange, object: nil)
    }

    // Cancels the active timer and notifies menus/UI to refresh state.
    func cancelSleepTimer() {
        activeTimerToken?.invalidate()
        activeTimerToken = nil
        activeTimer = nil
        NotificationCenter.default.post(name: .timerStateDidChange, object: nil)
    }
    // Computes remaining time for the active timer and formats the menu label.
    var timerRemainingMenuTitle: String? {
        guard let activeTimer else { return nil }
        let remaining = activeTimer.remainingSeconds
        return L10n.timerRemaining(timerRemainingString(seconds: remaining))
    }

    // Label used for timer presets in menus.
    func timerLabel(forSeconds seconds: Int) -> String {
        timerPresetString(seconds: seconds)
    }

    // Formats minute/hour presets compactly.
    private func timerPresetString(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        if seconds >= 3600 {
            formatter.allowedUnits = [.hour, .minute]
        } else {
            formatter.allowedUnits = [.minute]
        }
        return formatter.string(from: TimeInterval(seconds)) ?? "\(seconds)s"
    }

    // Formats remaining time with more granularity near the end.
    private func timerRemainingString(seconds: Int) -> String {
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

    // Timer completion flow: stops audio, clears state, and triggers a local notification.
    private func completeSleepTimer() {
        activeTimerToken?.invalidate()
        activeTimerToken = nil
        let timerName = activeTimer?.name ?? L10n.timer
        activeTimer = nil
        stopPlayback()
        TimerNotificationManager.shared.scheduleFinishedNotification(name: timerName)
        NotificationCenter.default.post(name: .timerStateDidChange, object: nil)
    }
}
