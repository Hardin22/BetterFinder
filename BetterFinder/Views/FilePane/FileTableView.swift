import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - SwiftUI wrapper

struct FileTableView: NSViewRepresentable {
    let browser: BrowserState
    let items: [FileItem]
    let appState: AppState

    func makeCoordinator() -> Coordinator { Coordinator(browser: browser, appState: appState) }
    func makeNSView(context: Context) -> NSScrollView { context.coordinator.scrollView }
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.update(items: items)
    }
}

// MARK: - NSTableView subclass (custom context menu)

fileprivate final class BFTableView: NSTableView {
    var menuProvider: ((Int) -> NSMenu?)?

    override func menu(for event: NSEvent) -> NSMenu? {
        let row = row(at: convert(event.locationInWindow, from: nil))
        return menuProvider?(row) ?? super.menu(for: event)
    }
}

// MARK: - Coordinator

final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {

    let browser: BrowserState
    let appState: AppState
    fileprivate let tableView = BFTableView()
    let scrollView = NSScrollView()

    private var items: [FileItem] = []
    private let iconCache = NSCache<NSURL, NSImage>()
    private var suppressSelectionSync = false

    init(browser: BrowserState, appState: AppState) {
        self.browser = browser
        self.appState = appState
        super.init()
        setupTable()
    }

    // MARK: - Setup

    private func setupTable() {
        // Columns
        let cols: [(id: String, title: String, w: CGFloat, min: CGFloat)] = [
            ("name", "Name",          280, 160),
            ("date", "Date Modified", 160, 120),
            ("size", "Size",           80,  60),
            ("kind", "Kind",          130,  80),
        ]
        for (id, title, w, minW) in cols {
            let col = NSTableColumn(identifier: .init(id))
            col.title = title
            col.width = w
            col.minWidth = minW
            col.resizingMask = .userResizingMask
            tableView.addTableColumn(col)
        }

        tableView.dataSource   = self
        tableView.delegate     = self
        tableView.allowsMultipleSelection  = true
        tableView.allowsEmptySelection     = true
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.style        = .inset
        tableView.rowHeight    = 22
        tableView.intercellSpacing = NSSize(width: 3, height: 0)
        tableView.columnAutoresizingStyle  = .lastColumnOnlyAutoresizingStyle
        tableView.headerView   = NSTableHeaderView()

        // Double-click
        tableView.target       = self
        tableView.doubleAction = #selector(handleDoubleClick)

        // Drag source: NSTableView calls pasteboardWriterForRow automatically
        tableView.setDraggingSourceOperationMask([.copy, .move], forLocal: false)
        tableView.setDraggingSourceOperationMask([.copy, .move], forLocal: true)

        // Drop destination
        tableView.registerForDraggedTypes([.fileURL])

        // Context menu
        tableView.menuProvider = { [weak self] row in self?.buildContextMenu(row: row) }

        // Scroll view
        scrollView.documentView  = tableView
        scrollView.hasVerticalScroller   = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers    = true
        scrollView.borderType            = .noBorder
        scrollView.drawsBackground       = false
    }

    // MARK: - Update from SwiftUI

    func update(items newItems: [FileItem]) {
        let changed = newItems.map(\.id) != items.map(\.id)
        items = newItems
        tableView.reloadData()

        // Sync selection from browser → table (only when items changed structurally)
        if changed { syncSelection() }
    }

    private func syncSelection() {
        suppressSelectionSync = true
        var idx = IndexSet()
        for (i, item) in items.enumerated() where browser.selectedItems.contains(item.id) {
            idx.insert(i)
        }
        tableView.selectRowIndexes(idx, byExtendingSelection: false)
        suppressSelectionSync = false
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int { items.count }

    /// One writer per row — NSTableView handles multi-row drag automatically.
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        guard row < items.count else { return nil }
        return items[row].url as NSURL
    }

    // MARK: Drop validation

    func tableView(_ tableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation drop: NSTableView.DropOperation) -> NSDragOperation {

        // Don't drop a file onto itself
        var sourceURLs: [URL] = []
        info.enumerateDraggingItems(options: [.concurrent], for: nil,
                                    classes: [NSURL.self],
                                    searchOptions: [.urlReadingFileURLsOnly: true]) { item, _, _ in
            if let u = item.item as? URL { sourceURLs.append(u) }
        }
        guard !sourceURLs.isEmpty else { return [] }

        if drop == .on, row >= 0, row < items.count {
            let target = items[row]
            if target.isDirectory && !target.isPackage &&
               !sourceURLs.contains(target.url) {
                return .move        // drop ON a folder → move into it
            }
        }

        // Any other position → redirect to whole-table drop (= current directory)
        tableView.setDropRow(-1, dropOperation: .on)
        return .move
    }

    // MARK: Drop acceptance

    func tableView(_ tableView: NSTableView,
                   acceptDrop info: NSDraggingInfo,
                   row: Int,
                   dropOperation: NSTableView.DropOperation) -> Bool {

        let destination: URL
        if dropOperation == .on, row >= 0, row < items.count, items[row].isDirectory {
            destination = items[row].url
        } else {
            destination = browser.currentURL
        }

        var urlsToMove: [URL] = []
        info.enumerateDraggingItems(options: [], for: nil,
                                    classes: [NSURL.self],
                                    searchOptions: [.urlReadingFileURLsOnly: true]) { item, _, _ in
            if let u = item.item as? URL { urlsToMove.append(u) }
        }
        guard !urlsToMove.isEmpty else { return false }

        let showHidden = appState.preferences.showHiddenFiles
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var changed = false
            for source in urlsToMove {
                let dstPath = destination.path(percentEncoded: false)
                let srcPath = source.path(percentEncoded: false)
                guard source != destination,
                      !dstPath.hasPrefix(srcPath + "/") else { continue }
                let dest = destination.appendingPathComponent(source.lastPathComponent)
                do {
                    try FileManager.default.moveItem(at: source, to: dest)
                    changed = true
                } catch {
                    if (try? FileManager.default.copyItem(at: source, to: dest)) != nil {
                        changed = true
                    }
                }
            }
            if changed {
                DispatchQueue.main.async { [weak self] in
                    Task { await self?.browser.load(showHidden: showHidden) }
                }
            }
        }
        return true
    }

    // MARK: - NSTableViewDelegate — cell views

    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        guard row < items.count else { return nil }
        let item = items[row]
        switch tableColumn?.identifier.rawValue {
        case "name": return nameCellView(item: item, in: tableView)
        case "date": return labelCell(item.formattedDate, id: "date", align: .left,  in: tableView)
        case "size": return labelCell(item.formattedSize, id: "size", align: .right, in: tableView)
        case "kind": return labelCell(item.kindDescription, id: "kind", align: .left, in: tableView)
        default: return nil
        }
    }

    private func nameCellView(item: FileItem, in tv: NSTableView) -> NSView {
        let id = NSUserInterfaceItemIdentifier("NameCell")
        let cell = (tv.makeView(withIdentifier: id, owner: nil) as? NameCellView) ?? {
            let v = NameCellView(); v.identifier = id; return v
        }()
        let cachedIcon = iconCache.object(forKey: item.url as NSURL)
        cell.configure(item: item, icon: cachedIcon)
        if cachedIcon == nil {
            let url = item.url
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let img = NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false))
                img.size = NSSize(width: 32, height: 32)
                DispatchQueue.main.async {
                    self?.iconCache.setObject(img, forKey: url as NSURL)
                    guard let self,
                          let row = self.items.firstIndex(where: { $0.url == url }),
                          let colIdx = tv.tableColumns.firstIndex(where: { $0.identifier.rawValue == "name" })
                    else { return }
                    tv.reloadData(forRowIndexes: [row], columnIndexes: [colIdx])
                }
            }
        }
        return cell
    }

    private func labelCell(_ text: String, id: String, align: NSTextAlignment,
                            in tv: NSTableView) -> NSView {
        let nsid = NSUserInterfaceItemIdentifier("Label-\(id)")
        let cell = (tv.makeView(withIdentifier: nsid, owner: nil) as? LabelCellView) ?? {
            let v = LabelCellView(); v.identifier = nsid; return v
        }()
        cell.configure(text: text, align: align)
        return cell
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let id = NSUserInterfaceItemIdentifier("Row")
        return (tableView.makeView(withIdentifier: id, owner: nil) as? NSTableRowView) ?? {
            let v = NSTableRowView(); v.identifier = id; return v
        }()
    }

    // MARK: - Drag image

    /// Called by AppKit just before the drag session starts.
    /// We replace every dragging item's image with a render of the Name cell,
    /// so the ghost always shows icon + filename regardless of which column
    /// the drag was initiated from — matching Finder's behaviour.
    func tableView(_ tableView: NSTableView,
                   draggingSession session: NSDraggingSession,
                   willBeginAt screenPoint: NSPoint,
                   forRowIndexes rowIndexes: IndexSet) {
        guard let nameColIdx = tableView.tableColumns.firstIndex(where: {
            $0.identifier.rawValue == "name"
        }) else { return }

        let sortedRows = rowIndexes.sorted()
        var enumIdx    = 0

        session.enumerateDraggingItems(
            options: [], for: tableView,
            classes: [NSURL.self],
            searchOptions: [.urlReadingFileURLsOnly: true]
        ) { item, _, _ in
            guard enumIdx < sortedRows.count else { return }
            let row = sortedRows[enumIdx]; enumIdx += 1

            guard let cell = tableView.view(atColumn: nameColIdx, row: row,
                                            makeIfNecessary: false) else { return }

            // PDF rendering is coordinate-system-agnostic and always works for
            // on-screen views — no lockFocus / bitmap flipping required.
            let pdfData = cell.dataWithPDF(inside: cell.bounds)
            guard let img = NSImage(data: pdfData) else { return }

            item.setDraggingFrame(
                NSRect(origin: item.draggingFrame.origin, size: cell.bounds.size),
                contents: img
            )
        }
    }

    // MARK: - Selection

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !suppressSelectionSync else { return }
        let ids = Set(tableView.selectedRowIndexes.compactMap {
            $0 < items.count ? items[$0].id : nil
        })
        browser.selectedItems = ids
    }

    // MARK: - Double-click

    @objc private func handleDoubleClick() {
        let row = tableView.clickedRow
        guard row >= 0, row < items.count else { return }
        let item = items[row]
        if item.isDirectory && !item.isPackage {
            browser.navigate(to: item.url)
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }

    // MARK: - Context menu

    private func buildContextMenu(row: Int) -> NSMenu? {
        // If right-clicking on a non-selected row, select it first
        if row >= 0, !tableView.selectedRowIndexes.contains(row) {
            tableView.selectRowIndexes([row], byExtendingSelection: false)
        }
        let selection = tableView.selectedRowIndexes.compactMap {
            $0 < items.count ? items[$0] : nil
        }
        guard !selection.isEmpty else { return nil }

        let menu = NSMenu()

        if selection.count == 1, let item = selection.first {
            menu.addItem(menuItem("Open", #selector(openSelected)))
            if item.isDirectory {
                let title = appState.isDualPane ? "Open in Other Pane" : "Open in New Pane"
                menu.addItem(menuItem(title, #selector(openInOtherPane)))
            }
            menu.addItem(.separator())
            menu.addItem(menuItem("Copy Path", #selector(copyPath)))
            menu.addItem(.separator())
            menu.addItem(menuItem("Move to Trash", #selector(trashSelected)))
        } else {
            menu.addItem(menuItem("Open \(selection.count) Items", #selector(openSelected)))
            menu.addItem(.separator())
            menu.addItem(menuItem("Move \(selection.count) Items to Trash", #selector(trashSelected)))
        }
        return menu
    }

    private func menuItem(_ title: String, _ action: Selector) -> NSMenuItem {
        NSMenuItem(title: title, action: action, keyEquivalent: "").also { $0.target = self }
    }

    @objc private func openSelected() {
        for idx in tableView.selectedRowIndexes where idx < items.count {
            let item = items[idx]
            if item.isDirectory && !item.isPackage { browser.navigate(to: item.url) }
            else { NSWorkspace.shared.open(item.url) }
        }
    }

    @objc private func openInOtherPane() {
        guard let first = tableView.selectedRowIndexes.first, first < items.count else { return }
        appState.secondaryBrowser.navigate(to: items[first].url)
        appState.isDualPane = true
    }

    @objc private func copyPath() {
        let paths = tableView.selectedRowIndexes
            .compactMap { $0 < items.count ? items[$0].url.path(percentEncoded: false) : nil }
            .joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(paths, forType: .string)
    }

    @objc private func trashSelected() {
        for idx in tableView.selectedRowIndexes where idx < items.count {
            try? FileManager.default.trashItem(at: items[idx].url, resultingItemURL: nil)
        }
    }
}

// MARK: - Label cell (date / size / kind)

private final class LabelCellView: NSTableCellView {
    private let label = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.cell?.lineBreakMode = .byTruncatingTail
        label.cell?.usesSingleLineMode = true
        addSubview(label)
        textField = label
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(text: String, align: NSTextAlignment) {
        label.stringValue = text
        label.alignment   = align
    }

    override func layout() {
        super.layout()
        let h = bounds.height
        let labelH = label.intrinsicContentSize.height
        label.frame = NSRect(x: 0, y: (h - labelH) / 2, width: bounds.width, height: labelH)
    }
}

// MARK: - Name cell (icon + label)

private final class NameCellView: NSTableCellView {
    private let icon  = NSImageView()
    private let label = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.imageAlignment = .alignCenter
        addSubview(icon)
        label.font = .systemFont(ofSize: 13)
        label.cell?.lineBreakMode = .byTruncatingMiddle
        addSubview(label)
        imageView = icon
        textField = label
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(item: FileItem, icon loadedIcon: NSImage?) {
        label.stringValue = item.name
        label.alphaValue  = item.isHidden ? 0.45 : 1.0
        if let img = loadedIcon {
            icon.image = img
        } else {
            icon.image = NSImage(systemSymbolName: item.isDirectory ? "folder.fill" : "doc",
                                 accessibilityDescription: nil)
        }
    }

    override func layout() {
        super.layout()
        let h = bounds.height
        let labelH = label.intrinsicContentSize.height
        icon.frame  = NSRect(x: 4, y: (h - 16) / 2, width: 16, height: 16)
        label.frame = NSRect(x: 24, y: (h - labelH) / 2, width: bounds.width - 28, height: labelH)
    }
}

// MARK: - Tiny helper

private extension NSMenuItem {
    func also(_ configure: (NSMenuItem) -> Void) -> NSMenuItem { configure(self); return self }
}
