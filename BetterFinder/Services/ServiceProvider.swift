import AppKit

/// Handles macOS Services calls. Registered via NSApp.servicesProvider in BetterFinderApp.
/// The method name must match NSMessage in Info.plist ("revealInBetterFinder").
final class ServiceProvider: NSObject {
    weak var appState: AppState?

    @objc func revealInBetterFinder(
        _ pasteboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        // Collect file URLs from the pasteboard.
        // Modern apps write .fileURL; legacy apps write NSFilenamesPboardType.
        var urls: [URL] = []

        if let items = pasteboard.pasteboardItems {
            for item in items {
                if let data = item.data(forType: .fileURL),
                   let str  = String(data: data, encoding: .utf8),
                   let url  = URL(string: str) {
                    urls.append(url)
                }
            }
        }

        if urls.isEmpty,
           let names = pasteboard.propertyList(
               forType: .init("NSFilenamesPboardType")) as? [String] {
            urls = names.map { URL(fileURLWithPath: $0) }
        }

        guard let url = urls.first else { return }

        DispatchQueue.main.async { [weak self] in
            guard let appState = self?.appState else { return }
            // Navigate to the folder that contains the item
            // (or the item itself, if it is a directory).
            let target = url.hasDirectoryPath
                ? url
                : url.deletingLastPathComponent()
            appState.activeBrowser.navigate(to: target)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first { $0.isMainWindow || $0.isMiniaturized == false }?
                .makeKeyAndOrderFront(nil)
        }
    }
}
