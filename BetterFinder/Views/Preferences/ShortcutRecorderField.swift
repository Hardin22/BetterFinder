import AppKit
import SwiftUI

// MARK: - SwiftUI wrapper

/// A field that displays the current shortcut and lets the user record a new one
/// by clicking and pressing the desired key combination.
struct ShortcutRecorderField: NSViewRepresentable {
    @Binding var shortcut: AppShortcut

    func makeCoordinator() -> Coordinator { Coordinator(shortcut: $shortcut) }

    func makeNSView(context: Context) -> ShortcutRecorderView {
        let v = ShortcutRecorderView()
        v.coordinator = context.coordinator
        return v
    }

    func updateNSView(_ nsView: ShortcutRecorderView, context: Context) {
        if !nsView.isRecording {
            nsView.displayShortcut = shortcut
        }
    }

    // MARK: - Coordinator

    final class Coordinator {
        var shortcut: Binding<AppShortcut>
        init(shortcut: Binding<AppShortcut>) { self.shortcut = shortcut }
    }
}

// MARK: - NSView

final class ShortcutRecorderView: NSView {

    weak var coordinator: ShortcutRecorderField.Coordinator?

    var displayShortcut: AppShortcut = AppShortcut(keyCode: 0, modifiers: 0) {
        didSet { updateLabel() }
    }
    private(set) var isRecording = false

    private let label = NSTextField(labelWithString: "")
    private let clearButton = NSButton(title: "", target: nil, action: nil)

    // MARK: - Setup

    override init(frame: NSRect) {
        super.init(frame: frame)

        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.borderWidth  = 1

        label.font          = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.alignment     = .center
        label.isEditable    = false
        label.isSelectable  = false
        label.drawsBackground = false
        label.isBordered    = false
        addSubview(label)

        // Small × button to clear the shortcut (sets keyCode 0 / no modifiers → "none")
        clearButton.image        = NSImage(systemSymbolName: "xmark.circle.fill",
                                           accessibilityDescription: "Clear shortcut")
        clearButton.bezelStyle   = .inline
        clearButton.isBordered   = false
        clearButton.target       = self
        clearButton.action       = #selector(clearShortcut)
        clearButton.contentTintColor = .tertiaryLabelColor
        addSubview(clearButton)

        updateAppearance()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - First responder

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        isRecording = true
        updateAppearance()
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        updateAppearance()
        return super.resignFirstResponder()
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }

        // Escape → cancel recording without changing shortcut
        if event.keyCode == 53 {
            window?.makeFirstResponder(nil)
            return
        }

        // Delete / Backspace → clear shortcut
        if event.keyCode == 51 {
            coordinator?.shortcut.wrappedValue = AppShortcut(keyCode: 0, modifiers: 0)
            window?.makeFirstResponder(nil)
            return
        }

        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let isFunctionKey = AppShortcut.functionKeyCodes.contains(event.keyCode)

        // Require at least one modifier for non-function keys
        guard isFunctionKey || !mods.isEmpty else { return }

        coordinator?.shortcut.wrappedValue = AppShortcut(keyCode: event.keyCode,
                                                          modifiers: mods.rawValue)
        window?.makeFirstResponder(nil)
    }

    // MARK: - Clear

    @objc private func clearShortcut() {
        coordinator?.shortcut.wrappedValue = AppShortcut(keyCode: 0, modifiers: 0)
    }

    // MARK: - Appearance

    private func updateLabel() {
        if isRecording { return }
        let s = displayShortcut
        label.stringValue = (s.keyCode == 0 && s.modifiers == 0) ? "–" : s.displayString
    }

    private func updateAppearance() {
        if isRecording {
            label.stringValue  = "Press keys…"
            label.textColor    = NSColor.secondaryLabelColor
            layer?.borderColor = NSColor.controlAccentColor.cgColor
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.07).cgColor
        } else {
            updateLabel()
            label.textColor    = NSColor.labelColor
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }
    }

    // MARK: - Layout

    override func layout() {
        super.layout()
        let h = bounds.height
        let btnSize: CGFloat = 16
        let btnX = bounds.maxX - btnSize - 4
        clearButton.frame = NSRect(x: btnX, y: (h - btnSize) / 2, width: btnSize, height: btnSize)
        label.frame = NSRect(x: 6, y: (h - 18) / 2, width: btnX - 8, height: 18)
    }
}

// MARK: - AppShortcut extension

private extension AppShortcut {
    static let functionKeyCodes: Set<UInt16> = [
        96, 97, 98, 99, 100, 101, 103, 104, 105, 107, 109, 111,
        118, 119, 120, 121, 122, 123
    ]
}
