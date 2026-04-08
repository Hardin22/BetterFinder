import Foundation

// MARK: - RenameResult

/// The outcome of applying a rule chain to a single file.
struct RenameResult: Identifiable {
    /// Same UUID as the source `FileItem.id`.
    let id: UUID
    /// Original full filename (stem + extension).
    let original: String
    /// Proposed new full filename (stem + extension).
    let proposed: String
    /// `true` if another item in the batch would receive the same proposed name.
    let conflict: Bool
    /// `true` if the proposed name is identical to the original (no change).
    let unchanged: Bool
    /// `true` if a `replace` rule contained an invalid regex pattern.
    let invalidRegex: Bool
}

// MARK: - RenameProviding

/// Protocol used to abstract `RenameEngine` so the UI can be tested with a mock.
protocol RenameProviding {
    /// Applies a rule chain to all items and returns preview results.
    func preview(rules: [RenameRule], items: [FileItem], referenceDate: Date) -> [RenameResult]
}

// MARK: - RenameEngine

/// Pure, synchronous engine that computes proposed names and detects conflicts.
///
/// `RenameEngine` has no stored state and performs no filesystem access
/// (metadata reads for `insertMetadata` run synchronously on `RenameActor`).
struct RenameEngine: RenameProviding {

    init() {}

    // MARK: - Public API

    /// Apply a chain of rules to a single `FileItem` and return the proposed full filename.
    ///
    /// Rules are applied left-to-right. The extension is split before processing and
    /// re-joined after, unless a `changeExtension` rule is present.
    ///
    /// - Parameters:
    ///   - rules:         Ordered list of active rules.
    ///   - item:          The file being renamed.
    ///   - index:         0-based index within the batch (for sequential numbering).
    ///   - total:         Total number of files in the batch.
    ///   - referenceDate: Date injected for `.currentDate` source (for testability).
    /// - Returns: The proposed full filename (stem + extension).
    func apply(
        rules: [RenameRule],
        to item: FileItem,
        index: Int,
        total: Int,
        referenceDate: Date = .now
    ) -> String {
        let originalName = item.url.lastPathComponent
        let url = URL(fileURLWithPath: originalName)
        var stem = url.deletingPathExtension().lastPathComponent
        var ext  = url.pathExtension   // empty string if no extension

        let context = RenameContext(item: item, referenceDate: referenceDate)

        // Separate changeExtension rules so we can apply them to the extension, not the stem
        let extRule     = rules.last { if case .changeExtension = $0 { return true }; return false }
        let stemRules   = rules.filter { if case .changeExtension = $0 { return false }; return true }

        for rule in stemRules {
            stem = rule.apply(to: stem, index: index, total: total, context: context)
        }

        if let extRule, case let .changeExtension(newExt) = extRule {
            ext = newExt
        }

        if ext.isEmpty {
            return stem
        } else {
            return stem + "." + ext
        }
    }

    /// Compute proposed names for all items and flag naming conflicts.
    ///
    /// A conflict is when two or more items in `items` would receive the same proposed name.
    ///
    /// - Parameters:
    ///   - rules:         Ordered list of active rules.
    ///   - items:         The files to rename.
    ///   - referenceDate: Date injected for `.currentDate` source (for testability).
    /// - Returns: One `RenameResult` per `FileItem`, in the same order.
    func preview(
        rules: [RenameRule],
        items: [FileItem],
        referenceDate: Date = .now
    ) -> [RenameResult] {
        let total = items.count
        guard !rules.isEmpty else {
            return items.enumerated().map { _, item in
                RenameResult(
                    id: item.id,
                    original: item.url.lastPathComponent,
                    proposed: item.url.lastPathComponent,
                    conflict: false,
                    unchanged: true,
                    invalidRegex: false
                )
            }
        }

        // Detect invalid-regex rules upfront (once, not per file)
        let hasInvalidRegex = rules.contains { rule -> Bool in
            if case let .replace(find, _, isCaseSensitive, true) = rule {
                let opts: NSRegularExpression.Options = isCaseSensitive ? [] : .caseInsensitive
                return (try? NSRegularExpression(pattern: find, options: opts)) == nil
            }
            return false
        }

        // Build (id, original, proposed) triples
        var proposals: [(id: UUID, original: String, proposed: String)] = []
        proposals.reserveCapacity(total)

        for (index, item) in items.enumerated() {
            let original = item.url.lastPathComponent
            let proposed = apply(rules: rules, to: item, index: index, total: total, referenceDate: referenceDate)
            proposals.append((item.id, original, proposed))
        }

        // Conflict detection: frequency map of proposed names
        var frequency: [String: Int] = [:]
        frequency.reserveCapacity(total)
        for p in proposals {
            frequency[p.proposed, default: 0] += 1
        }

        return proposals.map { (id, original, proposed) in
            RenameResult(
                id: id,
                original: original,
                proposed: proposed,
                conflict: (frequency[proposed] ?? 0) > 1,
                unchanged: proposed == original,
                invalidRegex: hasInvalidRegex
            )
        }
    }

    // MARK: - Conflict Summary

    /// Returns a list of `ConflictSummary` values for display in `ConflictBannerView`.
    func conflictSummaries(from results: [RenameResult]) -> [ConflictSummary] {
        var freq: [String: Int] = [:]
        for r in results where r.conflict {
            freq[r.proposed, default: 0] += 1
        }
        return freq.map { ConflictSummary(proposedName: $0.key, count: $0.value) }
            .sorted { $0.proposedName < $1.proposedName }
    }
}
