import Foundation
import MoodistKit
import UserNotifications

@MainActor
final class SleepNotificationController {
    private let identifier = "Moodist.sleep"
    private var requestTask: Task<Void, Never>?
    func schedule(name: String, at date: Date) {
        cancel()
        requestTask = Task { [identifier] in
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true,
                  !Task.isCancelled, date > Date() else { return }
            let content = UNMutableNotificationContent()
            content.title = L10n.timerFinishedTitle
            content.body = L10n.timerFinishedBody(name)
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
            try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            if Task.isCancelled { center.removePendingNotificationRequests(withIdentifiers: [identifier]) }
        }
    }
    func cancel() {
        requestTask?.cancel()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
