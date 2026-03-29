import SwiftUI

/// Bottom action bar showing common file operations with keyboard shortcut hints.
/// F5/F6 copy-move buttons appear only in dual-pane mode.
struct OperationsBarView: View {
    @Environment(AppState.self) private var appState

    private var hasSelection: Bool { !appState.activeBrowser.selectedItems.isEmpty }
    private var hasSingleSelection: Bool { appState.activeBrowser.selectedItems.count == 1 }
    private var otherPane: Int { appState.activePaneIsSecondary ? 1 : 2 }

    var body: some View {
        let p = appState.preferences
        HStack(spacing: 0) {
            // ── Basic operations ──────────────────────────────────────
            opButton("Rename",     icon: "pencil",            shortcut: p.shortcutRename.displayString,    enabled: hasSingleSelection) { appState.renameInActivePane() }
            opButton("New File",   icon: "doc.badge.plus",    shortcut: p.shortcutNewFile.displayString,   enabled: true)               { appState.newFileInActivePane() }
            opButton("New Folder", icon: "folder.badge.plus", shortcut: p.shortcutNewFolder.displayString, enabled: true)               { appState.newFolderInActivePane() }
            opButton("Trash",      icon: "trash",             shortcut: p.shortcutTrash.displayString,     enabled: hasSelection)       { appState.trashInActivePane() }

            // ── Cross-pane operations (dual-pane only) ────────────────
            if appState.isDualPane {
                separator()
                opButton("Copy to Pane \(otherPane)", icon: "doc.on.doc",    shortcut: p.shortcutCopyToPane.displayString, enabled: hasSelection) { appState.copySelectionToOtherPane() }
                opButton("Move to Pane \(otherPane)", icon: "arrow.forward", shortcut: p.shortcutMoveToPane.displayString, enabled: hasSelection) { appState.moveSelectionToOtherPane() }

                Spacer()

                // Navigate / sync
                opButton("Go to Other Pane", icon: "arrow.left.and.right", shortcut: "", enabled: true) { appState.goToOtherPaneLocation() }
                    .help("Navigate active pane to the other pane's location")
                opButton("Mirror Pane", icon: "rectangle.on.rectangle",    shortcut: "", enabled: true) { appState.mirrorActivePaneToOther() }
                    .help("Open active pane's folder in the other pane")
                    .padding(.trailing, 6)
            } else {
                Spacer()
            }
        }
        .frame(height: 26)
        .background(.bar)
    }

    // MARK: - Helpers

    private func opButton(
        _ title: String, icon: String, shortcut: String,
        enabled: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11))
                if !shortcut.isEmpty {
                    Text(shortcut)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.4))
        .help(title)
    }

    private func separator() -> some View {
        Divider()
            .frame(height: 14)
            .padding(.horizontal, 4)
    }
}
