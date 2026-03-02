import Foundation

extension Notification.Name {
    static let menuBarPreferenceDidChange = Notification.Name("MoodistMac.menuBarPreferenceDidChange")
    static let appearancePreferenceDidChange = Notification.Name("MoodistMac.appearancePreferenceDidChange")
    static let transparencyPreferenceDidChange = Notification.Name("MoodistMac.transparencyPreferenceDidChange")
    static let accentPreferenceDidChange = Notification.Name("MoodistMac.accentPreferenceDidChange")
    static let timerStateDidChange = Notification.Name("MoodistMac.timerStateDidChange")
    static let requestShowCustomTimerWindow = Notification.Name("MoodistMac.requestShowCustomTimerWindow")
}
