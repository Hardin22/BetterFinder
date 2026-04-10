import SwiftUI
import AppKit

/// Global shortcut monitor that handles configurable keyboard shortcuts.
/// Attach via `.background(GlobalShortcutMonitor { ... })`.
struct GlobalShortcutMonitor: NSViewRepresentable {
    let appState: AppState
    let action: (GlobalShortcutAction) -> Void

    func makeNSView(context: Context) -> _MonitorView {
        let v = _MonitorView()
        v.appState = appState
        v.action = action
        return v
    }
    
    func updateNSView(_ v: _MonitorView, context: Context) {
        v.appState = appState
        v.action = action
    }

    final class _MonitorView: NSView {
        var appState: AppState?
        var action: ((GlobalShortcutAction) -> Void)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    guard let self = self, let appState = self.appState else { return event }
                    
                    // Skip if terminal is hidden (let characters pass through)
                    guard appState.activeBrowser.showTerminal else { return event }
                    
                    let prefs = appState.preferences
                    
                    // Check each shortcut - only if not a simple character
                    let isSimpleChar = event.keyCode < 127 && !event.modifierFlags.contains(.command)
                    
                    // Terminal font shortcuts (only when terminal is visible)
                    if prefs.shortcutTerminalFontUp.matches(event) {
                        self.action?(.terminalFontUp)
                        return nil
                    }
                    if prefs.shortcutTerminalFontDown.matches(event) {
                        self.action?(.terminalFontDown)
                        return nil
                    }
                    if prefs.shortcutTerminalFontReset.matches(event) {
                        self.action?(.terminalFontReset)
                        return nil
                    }
                    
                    // Clear terminal
                    if prefs.shortcutClearTerminal.matches(event) {
                        self.action?(.clearTerminal)
                        return nil
                    }
                    
                    // Toggle/focus terminal shortcuts
                    if prefs.shortcutToggleTerminal.matches(event) {
                        self.action?(.toggleTerminal)
                        return nil
                    }
                    if prefs.shortcutFocusTerminal.matches(event) {
                        self.action?(.focusTerminal)
                        return nil
                    }
                    
                    if prefs.shortcutToggleDualPane.matches(event) {
                        self.action?(.toggleDualPane)
                        return nil
                    }
                    
                    // Let simple characters pass through to terminal
                    return event
                }
            } else {
                if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
            }
        }

        deinit {
            if let m = monitor { NSEvent.removeMonitor(m) }
        }
    }
}

enum GlobalShortcutAction {
    case toggleTerminal
    case clearTerminal
    case focusTerminal
    case terminalFontUp
    case terminalFontDown
    case terminalFontReset
    case toggleDualPane
}