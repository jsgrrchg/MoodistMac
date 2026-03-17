import Foundation

extension SoundStore {
    // MARK: - Auto Mix Timer

    /// Intervalos disponibles para el cambio automático de mix.
    static let autoMixIntervalPresets: [Int] = [5, 10, 15, 20, 30, 40, 50, 60].map { $0 * 60 }

    var hasActiveAutoMixTimer: Bool { autoMixIntervalSeconds != nil }
    /// Fecha en que el timer disparará el siguiente cambio de mix.
    var autoMixNextFireDate: Date? { autoMixTimerToken?.fireDate }

    /// Inicia un timer repetitivo que cambia al siguiente mix aleatorio cada `intervalSeconds`.
    func startAutoMixTimer(intervalSeconds: Int) {
        autoMixTimerToken?.invalidate()
        autoMixIntervalSeconds = intervalSeconds
        autoMixTimerToken = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(intervalSeconds), repeats: true
        ) { [weak self] _ in
            Task { @MainActor in self?.playNextRandomMix() }
        }
    }

    /// Detiene el timer de cambio automático de mix.
    func cancelAutoMixTimer() {
        autoMixTimerToken?.invalidate()
        autoMixTimerToken = nil
        autoMixIntervalSeconds = nil
    }

    /// Etiqueta larga para el menú del Pomodoro ("5 minutes", "1 hour", etc.).
    func autoMixIntervalLabel(forSeconds seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = seconds >= 3600 ? [.hour] : [.minute]
        return formatter.string(from: TimeInterval(seconds)) ?? timerLabel(forSeconds: seconds)
    }

    // MARK: - Timers (Sleep)

    // Inicia timer de sueño, registra uso y programa callback de finalización.
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

    // Cancela timer activo y notifica cambio de estado para refrescar menús/UI.
    func cancelSleepTimer() {
        activeTimerToken?.invalidate()
        activeTimerToken = nil
        activeTimer = nil
        NotificationCenter.default.post(name: .timerStateDidChange, object: nil)
    }
    // Calcula tiempo restante del timer activo y formatea etiqueta
    var timerRemainingMenuTitle: String? {
        guard let activeTimer else { return nil }
        let remaining = activeTimer.remainingSeconds
        return L10n.timerRemaining(timerRemainingString(seconds: remaining))
    }

    // Etiqueta usada para presets de timer en menús.
    func timerLabel(forSeconds seconds: Int) -> String {
        timerPresetString(seconds: seconds)
    }

    // Formatea presets (minutos/horas) de forma compacta.
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

    // Formatea el tiempo restante con más granularidad cerca del final.
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

    // Flujo de fin de timer: detiene audio, limpia estado y dispara notificación local.
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
