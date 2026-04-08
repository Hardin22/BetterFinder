import Foundation
import AppKit

// MARK: - RenameReport

/// Summary of a completed batch rename operation.
struct RenameReport {
    /// Number of files successfully renamed.
    let succeeded: Int
    /// Files that failed to rename, paired with the error.
    let failed: [(item: FileItem, error: Error)]
    /// Files skipped because their proposed name was identical to the original,
    /// or because they had a naming conflict.
    let skipped: Int
}

// MARK: - RenameActor

/// Background actor that performs batch renames to disk.
///
/// This actor must only be called after the user has reviewed the preview and
/// confirmed the operation by clicking "Rename X files →".
///
/// All filesystem writes happen here. The `RenameEngine` and `RenameRule` types
/// are pure and never touch the disk.
actor RenameActor {

    init() {}

    // MARK: - Apply Renames

    /// Rename all eligible files to disk and register a single undo group.
    ///
    /// - Parameters:
    ///   - items:       The `FileItem` values to rename.
    ///   - results:     Preview results from `RenameEngine.preview(...)`.
    ///   - undoManager: The window's `UndoManager`. All renames are grouped into one undo action.
    /// - Returns: A `RenameReport` summarising successes, failures, and skips.
    /// - Throws: Never — individual errors are collected into `RenameReport.failed`.
    func applyRenames(
        items: [FileItem],
        results: [RenameResult],
        undoManager: UndoManager
    ) async -> RenameReport {

        // Build a lookup from FileItem.id → RenameResult
        let resultMap: [UUID: RenameResult] = Dictionary(
            uniqueKeysWithValues: results.map { ($0.id, $0) }
        )

        var succeeded = 0
        var failed: [(item: FileItem, error: Error)] = []
        var skipped  = 0
        var undoPairs: [(from: URL, to: URL)] = []   // (new → old) for undo

        undoManager.beginUndoGrouping()
        undoManager.setActionName("Rename \(items.count) Files")

        for item in items {
            guard let result = resultMap[item.id] else { skipped += 1; continue }

            // Skip unchanged or conflicted files
            if result.unchanged || result.conflict {
                skipped += 1
                continue
            }

            let sourceURL = item.url
            let destURL   = item.url.deletingLastPathComponent()
                                     .appendingPathComponent(result.proposed)

            // Final safety check: destination must not already exist
            guard !FileManager.default.fileExists(atPath: destURL.path(percentEncoded: false)) else {
                failed.append((item, RenameError.destinationAlreadyExists(destURL)))
                continue
            }

            do {
                try FileManager.default.moveItem(at: sourceURL, to: destURL)
                succeeded += 1
                undoPairs.append((from: destURL, to: sourceURL))
            } catch {
                failed.append((item, RenameError.fileSystemError(error)))
            }
        }

        // Register undo for all successful renames as a single group
        if !undoPairs.isEmpty {
            let pairs = undoPairs   // capture for undo closure
            undoManager.registerUndo(withTarget: undoManager as AnyObject) { [pairs] _ in
                for pair in pairs {
                    try? FileManager.default.moveItem(at: pair.from, to: pair.to)
                }
            }
        }

        undoManager.endUndoGrouping()

        return RenameReport(succeeded: succeeded, failed: failed, skipped: skipped)
    }
}
