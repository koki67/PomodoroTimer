import AppKit
import SwiftUI

/// Manages a full-screen blurred overlay shown during breaks.
///
/// Appears when a focus session completes (if `forceBreakScreenEnabled` is on)
/// and dismisses when the break ends or the user clicks skip.
@MainActor
final class BreakOverlayController {

    private var window: NSWindow?
    private let timerVM: TimerViewModel

    /// Called when the user clicks the skip button inside the overlay.
    var onSkip: (() -> Void)?

    init(timerVM: TimerViewModel) {
        self.timerVM = timerVM
    }

    // MARK: - Visibility

    func show() {
        if window == nil { buildWindow() }
        window?.alphaValue = 0
        window?.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.4
            self.window?.animator().alphaValue = 1
        }
    }

    func hide() {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            self.window?.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
        }
    }

    // MARK: - Private

    private func buildWindow() {
        guard let screen = NSScreen.main else { return }
        let win = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.level = .screenSaver           // covers all apps, Dock, and menu bar
        win.isOpaque = false
        win.backgroundColor = .clear
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let effectView = NSVisualEffectView(frame: screen.frame)
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.material = .fullScreenUI
        effectView.autoresizingMask = [.width, .height]

        let rootView = BreakOverlayView(onSkip: { [weak self] in self?.onSkip?() })
            .environment(timerVM)
        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = effectView.bounds
        hosting.autoresizingMask = [.width, .height]
        hosting.sizingOptions = []

        effectView.addSubview(hosting)
        win.contentView = effectView
        self.window = win
    }
}
