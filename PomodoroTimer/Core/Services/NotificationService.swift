import UserNotifications
import AppKit

/// Manages local notifications for session completion events.
@MainActor
final class NotificationService: NSObject {

    static let shared = NotificationService()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error {
                print("NotificationService: auth error: \(error)")
            }
        }
    }

    func send(for phase: TimerPhase, soundName: String) {
        let content = UNMutableNotificationContent()
        switch phase {
        case .focus:
            content.title = "Focus session complete!"
            content.body  = "Time for a well-deserved break."
        case .shortBreak:
            content.title = "Short break over"
            content.body  = "Ready for the next focus session?"
        case .longBreak:
            content.title = "Long break complete"
            content.body  = "Excellent work! Ready to focus again?"
        }
        content.sound = soundName.isEmpty || soundName == "Default"
            ? .default
            : UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // deliver immediately
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("NotificationService: send error: \(error)") }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    // Without this, notifications are silently swallowed when the app is foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .sound])
    }
}
