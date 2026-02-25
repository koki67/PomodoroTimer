import AppKit
import SwiftUI

/// Manages the floating NSPanel that shows the main timer UI.
///
/// Key NSPanel choices:
/// - `.nonactivatingPanel`: clicking buttons does NOT steal key focus from other apps.
/// - `.floating` level: appears above normal windows (unconditional).
/// - `orderFrontRegardless()`: shows without activating the app.
/// - `collectionBehavior [.canJoinAllSpaces, .fullScreenAuxiliary]`: visible on all Spaces and in fullscreen.
@MainActor
final class MainPanelController {

    private var panel: NSPanel?
    private let timerVM: TimerViewModel
    private let settingsVM: SettingsViewModel

    private let panelWidth: CGFloat  = 220
    private let panelHeight: CGFloat = 220

    // UserDefaults key for panel position persistence
    private let frameKey = "MainPanelFrame3"

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
        let contentRect = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.level             = .floating
        panel.alphaValue        = 1.0
        panel.isOpaque          = false
        panel.backgroundColor   = .clear
        panel.hasShadow         = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.minSize           = NSSize(width: panelWidth, height: panelHeight)

        let rootView = MainPanelView(onClose: { [weak self] in self?.hide() })
            .environment(timerVM)
            .environment(settingsVM)
            .preferredColorScheme(settingsVM.preferredColorScheme)

        let hosting = NSHostingView(rootView: rootView)
        hosting.autoresizingMask = [.width, .height]
        hosting.sizingOptions = []   // prevent SwiftUI content size from driving panel resize
        panel.contentView = hosting

        // Restore saved position or place near top-right of main screen.
        // Clamp both dimensions to current minimums to migrate old saved frames.
        if let saved = UserDefaults.standard.string(forKey: frameKey) {
            let frame = NSRectFromString(saved)
            if frame != .zero {
                let migratedSize = NSSize(width:  max(frame.width,  panelWidth),
                                         height: max(frame.height, panelHeight))
                panel.setFrame(NSRect(origin: frame.origin, size: migratedSize),
                               display: false)
            }
        } else {
            placeInitially(panel: panel)
        }

        self.panel = panel
    }

    private func placeInitially(panel: NSPanel) {
        guard let screen = NSScreen.main else { panel.center(); return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - panelWidth - 20
        let y = screenFrame.maxY - panelHeight - 20
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
