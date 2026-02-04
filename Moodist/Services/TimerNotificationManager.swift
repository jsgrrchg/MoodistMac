//
//  TimerNotificationManager.swift
//  MoodistMac
//
//  Notificación local cuando termina un temporizador.
//

import Foundation
import UserNotifications

final class TimerNotificationManager {
    static let shared = TimerNotificationManager()

    private init() {}

    func scheduleFinishedNotification(name: String) {
        let content = UNMutableNotificationContent()
        content.title = L10n.timerFinishedTitle
        content.body = L10n.timerFinishedBody(name)
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
