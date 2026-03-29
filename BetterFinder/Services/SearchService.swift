import Foundation
import AppKit
import UniformTypeIdentifiers

/// Performs async file searches for non-current-folder scopes.
/// Current-folder filtering is handled synchronously in BrowserState.filteredItems.
enum SearchService {

    // MARK: - Public entry point

    static func search(
        query: String,
        options: SearchOptions,
        inFolder root: URL,
        showHidden: Bool
    ) async -> [FileItem] {
        switch options.scope {
        case .currentFolder:
            return []   // handled client-side
        case .recursive:
            return await recursiveSearch(query: query, options: options,
                                         root: root, showHidden: showHidden)
        case .homeDirectory:
            return await spotlightSearch(query: query, options: options,
                                         showHidden: showHidden,
                                         scopes: [NSMetadataQueryUserHomeScope])
        case .entireDisk:
            return await spotlightSearch(query: query, options: options,
                                         showHidden: showHidden,
                                         scopes: [NSMetadataQueryLocalComputerScope])
        }
    }

    // MARK: - Recursive (FileManager)

    private static func recursiveSearch(
        query: String,
        options: SearchOptions,
        root: URL,
        showHidden: Bool
    ) async -> [FileItem] {
        await Task.detached(priority: .userInitiated) {
            var results: [FileItem] = []
            let fmOpts: FileManager.DirectoryEnumerationOptions =
                showHidden ? [] : [.skipsHiddenFiles]

            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: resourceKeys,
                options: fmOpts
            ) else { return [] }

            for case let url as URL in enumerator {
                guard !Task.isCancelled else { break }
                guard textMatches(url.lastPathComponent, query: query, mode: options.matchMode),
                      kindMatches(url, kind: options.fileKind)
                else { continue }
                if let item = makeFileItem(url: url) { results.append(item) }
                if results.count >= 1_000 { break }   // safety cap
            }
            return results
        }.value
    }

    // MARK: - Spotlight (NSMetadataQuery)

    @MainActor
    private static func spotlightSearch(
        query: String,
        options: SearchOptions,
        showHidden: Bool,
        scopes: [Any]
    ) async -> [FileItem] {
        let mq = NSMetadataQuery()
        mq.searchScopes = scopes
        mq.predicate    = buildSpotlightPredicate(query: query, options: options)
        mq.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemFSNameKey, ascending: true)]

        return await withCheckedContinuation { (continuation: CheckedContinuation<[FileItem], Never>) in
            var observer: NSObjectProtocol?
            observer = NotificationCenter.default.addObserver(
                forName: .NSMetadataQueryDidFinishGathering,
                object: mq,
                queue: .main
            ) { _ in
                mq.stop()
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                    observer = nil
                }
                var results: [FileItem] = []
                for i in 0 ..< mq.resultCount {
                    guard let md   = mq.result(at: i) as? NSMetadataItem,
                          let path = md.value(forAttribute: NSMetadataItemPathKey) as? String
                    else { continue }
                    let url = URL(fileURLWithPath: path)
                    if !showHidden, url.lastPathComponent.hasPrefix(".") { continue }
                    if let item = makeFileItem(url: url) { results.append(item) }
                }
                continuation.resume(returning: results)
            }
            mq.start()
        }
    }

    // MARK: - Spotlight predicate

    private static func buildSpotlightPredicate(
        query: String, options: SearchOptions
    ) -> NSPredicate {
        var parts: [NSPredicate] = []

        // Text predicate
        if !query.isEmpty {
            let key = "kMDItemFSName"
            let p: NSPredicate
            switch options.matchMode {
            case .nameContains:
                p = NSPredicate(format: "%K CONTAINS[cd] %@", key, query)
            case .nameStartsWith:
                p = NSPredicate(format: "%K BEGINSWITH[cd] %@", key, query)
            case .nameEndsWith:
                p = NSPredicate(format: "%K ENDSWITH[cd] %@", key, query)
            case .nameExact:
                p = NSPredicate(format: "%K ==[cd] %@", key, query)
            case .extensionIs:
                let ext = query.hasPrefix(".") ? query : ".\(query)"
                p = NSPredicate(format: "%K ENDSWITH[cd] %@", key, ext)
            }
            parts.append(p)
        }

        // Kind predicate
        switch options.fileKind {
        case .any: break
        case .folder:
            parts.append(NSPredicate(format: "kMDItemContentType ==[cd] %@", "public.folder"))
        case .file:
            parts.append(NSPredicate(format: "kMDItemContentType !=[cd] %@", "public.folder"))
        case .image:
            parts.append(NSPredicate(format: "kMDItemContentTypeTree ==[cd] %@", "public.image"))
        case .video:
            parts.append(NSPredicate(format: "kMDItemContentTypeTree ==[cd] %@", "public.movie"))
        case .audio:
            parts.append(NSPredicate(format: "kMDItemContentTypeTree ==[cd] %@", "public.audio"))
        case .document:
            // Expand into flat parts to avoid nested NSCompoundPredicate (crashes NSMetadataQuery)
            parts.append(NSPredicate(format: "kMDItemContentTypeTree ==[cd] %@", "public.content"))
            parts.append(NSPredicate(format: "kMDItemContentType !=[cd] %@", "public.folder"))
        case .code:
            parts.append(NSPredicate(format: "kMDItemContentTypeTree ==[cd] %@", "public.source-code"))
        case .archive:
            parts.append(NSPredicate(format: "kMDItemContentTypeTree ==[cd] %@", "public.archive"))
        }

        switch parts.count {
        case 0:  return NSPredicate(value: true)
        case 1:  return parts[0]                                          // NSMetadataQuery rejects NSCompoundPredicate with 1 sub-predicate
        default: return NSCompoundPredicate(andPredicateWithSubpredicates: parts)
        }
    }

    // MARK: - Local match helpers

    static func textMatches(_ name: String, query: String, mode: SearchOptions.MatchMode) -> Bool {
        guard !query.isEmpty else { return true }
        switch mode {
        case .nameContains:
            return name.localizedCaseInsensitiveContains(query)
        case .nameStartsWith:
            return name.range(of: query, options: [.caseInsensitive, .anchored]) != nil
        case .nameEndsWith:
            return name.range(of: query, options: [.caseInsensitive, .anchored, .backwards]) != nil
        case .nameExact:
            return name.localizedCaseInsensitiveCompare(query) == .orderedSame
        case .extensionIs:
            let ext = URL(fileURLWithPath: name).pathExtension
            let target = query.hasPrefix(".") ? String(query.dropFirst()) : query
            return ext.localizedCaseInsensitiveCompare(target) == .orderedSame
        }
    }

    static func kindMatches(_ url: URL, kind: SearchOptions.FileKindFilter) -> Bool {
        switch kind {
        case .any:    return true
        case .folder: return (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        case .file:   return !((try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false)
        default:      return kind.extensions.contains(url.pathExtension.lowercased())
        }
    }

    // MARK: - FileItem factory

    private static let resourceKeys: [URLResourceKey] = [
        .isDirectoryKey, .isPackageKey, .isHiddenKey, .isSymbolicLinkKey,
        .fileSizeKey, .contentModificationDateKey, .creationDateKey, .contentTypeKey
    ]

    static func makeFileItem(url: URL) -> FileItem? {
        guard let v = try? url.resourceValues(forKeys: Set(resourceKeys)) else { return nil }
        return FileItem(
            id:               UUID(),
            url:              url,
            size:             v.fileSize.map { Int64($0) },
            isDirectory:      v.isDirectory      ?? false,
            isPackage:        v.isPackage         ?? false,
            isHidden:         v.isHidden          ?? false,
            isSymlink:        v.isSymbolicLink    ?? false,
            modificationDate: v.contentModificationDate,
            creationDate:     v.creationDate,
            contentType:      v.contentType
        )
    }
}
