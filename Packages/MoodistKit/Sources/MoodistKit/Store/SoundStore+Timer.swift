import Foundation

private struct SavedTimers: Codable {
    var sleep: Date?
    var sleepName: String?
    var duration: Int?
    var nextMix: Date?
    var interval: Int?
    var customOnly: Bool
}

public extension SoundStore {
    static let autoMixIntervalPresets = [5, 10, 15, 20, 30, 40, 50, 60].map { $0 * 60 }
    var hasActiveAutoMixTimer: Bool { autoMixIntervalSeconds != nil }
    var autoMixNextFireDate: Date? { nextAutoMixDate }
    var sleepDeadline: Date? {
        if case .running(let end) = activeTimer?.state { return end }
        return nil
    }
    var sleepRemainingSeconds: Int { sleepDeadline.map { max(0, Int(ceil($0.timeIntervalSince(now())))) } ?? 0 }

    func startAutoMixTimer(intervalSeconds: Int) {
        guard intervalSeconds > 0 else { return }
        autoMixTimerToken?.cancel()
        autoMixIntervalSeconds = intervalSeconds
        nextAutoMixDate = now().addingTimeInterval(Double(intervalSeconds))
        persistTimers()
        scheduleTimers()
    }
    func cancelAutoMixTimer() {
        autoMixTimerToken?.cancel()
        autoMixTimerToken = nil
        autoMixIntervalSeconds = nil
        nextAutoMixDate = nil
        persistTimers()
    }
    func startSleepTimer(durationSeconds: Int, name: String? = nil) {
        cancelSleepTimer()
        let duration = max(1, durationSeconds)
        let label = name ?? timerLabel(forSeconds: duration)
        let end = now().addingTimeInterval(Double(duration))
        activeTimer = TimerItem(name: label, durationSeconds: duration, state: .running(endDate: end))
        timerUsageCounts[duration, default: 0] += 1
        preferences.saveTimerUsageCounts(timerUsageCounts)
        persistTimers()
        onTimerScheduled?(label, end)
        scheduleTimers()
        NotificationCenter.default.post(name: .timerStateDidChange, object: nil)
    }
    func cancelSleepTimer() {
        activeTimerToken?.cancel()
        activeTimerToken = nil
        activeTimer = nil
        onTimerCancelled?()
        persistTimers()
        NotificationCenter.default.post(name: .timerStateDidChange, object: nil)
    }
    /// Reconciles wall-clock deadlines once, never replaying a backlog of rotations.
    func reconcileTimers() {
        let instant = now()
        if let end = sleepDeadline, end <= instant {
            let name = activeTimer?.name ?? L10n.timer
            activeTimerToken?.cancel()
            activeTimerToken = nil
            activeTimer = nil
            cancelAutoMixTimer()
            stopPlayback()
            persistTimers()
            onTimerFinished?(name)
            NotificationCenter.default.post(name: .timerStateDidChange, object: nil)
            return
        }
        if let next = nextAutoMixDate, let interval = autoMixIntervalSeconds, next <= instant {
            nextAutoMixDate = instant.addingTimeInterval(Double(interval))
            if isPlaying { playNextRandomMix() }
            persistTimers()
        }
        scheduleTimers()
    }
    func persistTimers() {
        let saved = SavedTimers(sleep: sleepDeadline, sleepName: activeTimer?.name,
            duration: activeTimer?.durationSeconds, nextMix: nextAutoMixDate,
            interval: autoMixIntervalSeconds, customOnly: autoMixCustomOnly)
        if let data = try? JSONEncoder().encode(saved) { preferences.defaults.set(data, forKey: "Moodist.timerState") }
    }
    func restoreTimers() {
        guard let data = preferences.defaults.data(forKey: "Moodist.timerState"),
              let saved = try? JSONDecoder().decode(SavedTimers.self, from: data) else { return }
        if let end = saved.sleep {
            activeTimer = TimerItem(name: saved.sleepName ?? L10n.timer, durationSeconds: saved.duration ?? 1, state: .running(endDate: end))
        }
        if let interval = saved.interval, interval > 0 {
            autoMixIntervalSeconds = interval
            nextAutoMixDate = saved.nextMix ?? now().addingTimeInterval(Double(interval))
        }
        autoMixCustomOnly = saved.customOnly
        reconcileTimers()
    }
    var timerRemainingMenuTitle: String? {
        guard activeTimer != nil else { return nil }
        return L10n.timerRemaining(timerLabel(forSeconds: sleepRemainingSeconds))
    }
    func timerLabel(forSeconds seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: Double(seconds)) ?? "\(seconds)s"
    }
    func autoMixIntervalLabel(forSeconds seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute]
        return formatter.string(from: Double(seconds)) ?? timerLabel(forSeconds: seconds)
    }
    private func scheduleTimers() {
        activeTimerToken?.cancel()
        autoMixTimerToken?.cancel()
        activeTimerToken = sleepDeadline.map { date in
            scheduler.schedule(at: date) { [weak self] in self?.reconcileTimers() }
        }
        autoMixTimerToken = nextAutoMixDate.map { date in
            scheduler.schedule(at: date) { [weak self] in self?.reconcileTimers() }
        }
    }
}
