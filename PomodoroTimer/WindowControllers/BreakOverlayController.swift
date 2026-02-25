import AppKit
import SwiftUI

/// Manages full-screen blurred overlays shown during breaks — one window per display.
///
/// Appears when a focus session completes (if `forceBreakScreenEnabled` is on)
/// and dismisses when the break ends or the user clicks skip.
@MainActor
final class BreakOverlayController {

    private var windows: [NSWindow] = []
    private let timerVM: TimerViewModel

    /// Called when the user clicks the skip button inside the overlay.
    var onSkip: (() -> Void)?

    init(timerVM: TimerViewModel) {
        self.timerVM = timerVM
    }

    // MARK: - Visibility

    func show() {
        buildWindows()   // always rebuild so the current screen list is used
        windows.forEach { $0.alphaValue = 0; $0.orderFrontRegardless() }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.4
            self.windows.forEach { $0.animator().alphaValue = 1 }
        }
    }

    func hide() {
        let closing = windows
        windows = []
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            closing.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: {
            closing.forEach { $0.orderOut(nil) }
        }
    }

    // MARK: - Private

    private func buildWindows() {
        windows.forEach { $0.orderOut(nil) }
        windows = NSScreen.screens.map { makeWindow(for: $0) }
    }

    private func makeWindow(for screen: NSScreen) -> NSWindow {
        let win = NSWindow(
            contentRect: screen.frame,   // positions the window on this screen
            styleMask:   [.borderless],
            backing:     .buffered,
            defer:       false
        )
        win.level             = .screenSaver   // covers all apps, Dock, and menu bar
        win.isOpaque          = false
        win.backgroundColor   = .clear
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Use (0,0) origin for all subviews.
        // screen.frame.origin is in global screen coordinates — using it as a
        // window-local subview frame shifts content by the screen's global offset,
        // causing the timer to appear off-center when the screen is not at (0,0).
        let size = screen.frame.size
        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        effectView.blendingMode    = .behindWindow
        effectView.state           = .active
        effectView.material        = .fullScreenUI
        effectView.autoresizingMask = [.width, .height]

        let rootView = BreakOverlayView(onSkip: { [weak self] in self?.onSkip?() })
            .environment(timerVM)
        let hosting = NSHostingView(rootView: rootView)
        hosting.frame            = NSRect(origin: .zero, size: size)
        hosting.autoresizingMask = [.width, .height]
        hosting.sizingOptions    = []

        effectView.addSubview(hosting)
        win.contentView = effectView
        return win
    }
}
