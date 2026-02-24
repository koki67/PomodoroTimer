import AppKit

enum SleepWakeEvent { case sleep, wake }

/// Observes macOS system sleep/wake events via NSWorkspace notifications.
final class SleepWakeObserver {

    private var observers: [NSObjectProtocol] = []
    private let callback: @MainActor (SleepWakeEvent) -> Void

    init(callback: @escaping @MainActor (SleepWakeEvent) -> Void) {
        self.callback = callback
        let nc = NSWorkspace.shared.notificationCenter

        observers.append(nc.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.callback(.sleep) }
        })

        observers.append(nc.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.callback(.wake) }
        })
    }

    deinit {
        let nc = NSWorkspace.shared.notificationCenter
        observers.forEach { nc.removeObserver($0) }
    }
}
