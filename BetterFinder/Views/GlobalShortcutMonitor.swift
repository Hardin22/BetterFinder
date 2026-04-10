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
                    
                    let prefs = appState.preferences
                    
                    // Check each shortcut
                    if prefs.shortcutToggleTerminal.matches(event) {
                        self.action?(.toggleTerminal)
                        return nil
                    }
                    
                    if prefs.shortcutClearTerminal.matches(event) {
                        self.action?(.clearTerminal)
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