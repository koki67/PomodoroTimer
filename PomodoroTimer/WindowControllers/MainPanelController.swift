import AppKit
import SwiftUI

/// Manages the floating NSPanel that shows the main timer UI.
///
/// Key NSPanel choices:
/// - `.nonactivatingPanel`: clicking buttons does NOT steal key focus from other apps.
/// - `.floating` level: appears above normal windows.
/// - `orderFrontRegardless()`: shows without activating the app.
/// - `collectionBehavior [.canJoinAllSpaces, .fullScreenAuxiliary]`: visible on all Spaces and in fullscreen.
@MainActor
final class MainPanelController {

    private var panel: NSPanel?
    private let timerVM: TimerViewModel
    private let settingsVM: SettingsViewModel

    // Blend-into-work parameters
    private var blendTimer: Timer?
    private let blendAlpha: CGFloat   = 0.7
    private let normalAlpha: CGFloat  = 1.0
    private let compactHeight: CGFloat  = 110
    private let expandedHeight: CGFloat = 220
    private let panelWidth: CGFloat     = 280

    // UserDefaults key for panel position persistence
    private let frameKey = "MainPanelFrame"

    init(timerVM: TimerViewModel, settingsVM: SettingsViewModel) {
        self.timerVM    = timerVM
        self.settingsVM = settingsVM
        buildPanel()
    }

    // MARK: - Visibility

    func show() {
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func toggle() {
        guard let panel else { return }
        if panel.isVisible { hide() } else { show() }
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    // MARK: - Blend Into Work

    func handleTimerStatusChange(_ status: TimerStatus) {
        switch status {
        case .running:
            scheduleBlend(delay: settingsVM.settings.blendDelay)
        case .paused, .idle:
            blendTimer?.invalidate()
            blendTimer = nil
            restoreNormal()
        }
    }

    // MARK: - Always on Top

    func applyAlwaysOnTop(_ alwaysOnTop: Bool) {
        panel?.level = alwaysOnTop ? .floating : .normal
    }

    // MARK: - Appearance

    func applyAppearance(_ themeMode: ThemeMode) {
        switch themeMode {
        case .system: panel?.appearance = nil
        case .light:  panel?.appearance = NSAppearance(named: .aqua)
        case .dark:   panel?.appearance = NSAppearance(named: .darkAqua)
        }
    }

    // MARK: - Frame Persistence

    func saveFrame() {
        guard let panel else { return }
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: frameKey)
    }

    // MARK: - Private

    private func buildPanel() {
        let contentRect = NSRect(x: 0, y: 0, width: panelWidth, height: expandedHeight)
        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.level             = settingsVM.settings.alwaysOnTop ? .floating : .normal
        panel.isOpaque          = false
        panel.backgroundColor   = .clear
        panel.hasShadow         = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        let rootView = MainPanelView()
            .environment(timerVM)
            .environment(settingsVM)
            .preferredColorScheme(settingsVM.preferredColorScheme)

        let hosting = NSHostingView(rootView: rootView)
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting

        // Restore saved position or place near top-right of main screen.
        if let saved = UserDefaults.standard.string(forKey: frameKey) {
            let frame = NSRectFromString(saved)
            if frame != .zero { panel.setFrame(frame, display: false) }
        } else {
            placeInitially(panel: panel)
        }

        self.panel = panel
    }

    private func placeInitially(panel: NSPanel) {
        guard let screen = NSScreen.main else { panel.center(); return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - panelWidth - 20
        let y = screenFrame.maxY - expandedHeight - 20
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func scheduleBlend(delay: TimeInterval) {
        blendTimer?.invalidate()
        blendTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.applyBlend() }
        }
    }

    private func applyBlend() {
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.4
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = blendAlpha
            var f = panel.frame
            let delta = f.size.height - compactHeight
            f.origin.y += delta
            f.size.height = compactHeight
            panel.animator().setFrame(f, display: true)
        }
    }

    private func restoreNormal() {
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = normalAlpha
            var f = panel.frame
            let delta = expandedHeight - f.size.height
            f.origin.y -= delta
            f.size.height = expandedHeight
            panel.animator().setFrame(f, display: true)
        }
    }
}
