import SwiftUI

// MARK: - PreviewTableView

/// Scrollable table showing original → proposed names for every file in the batch.
struct PreviewTableView: View {

    let results: [RenameResult]

    @State private var sortOrder = [KeyPathComparator(\RenameResult.original)]

    private var sortedResults: [RenameResult] {
        results.sorted(using: sortOrder)
    }

    var body: some View {
        Table(sortedResults, sortOrder: $sortOrder) {
            TableColumn("#") { result in
                Text("\(index(of: result))")
                    .font(.system(size: 11))
                    .foregroundStyle(.quaternary)
                    .monospacedDigit()
            }
            .width(30)

            TableColumn("Original", value: \.original) { result in
                Text(result.original)
                    .font(.system(size: 12, design: .monospaced))
                    .lineLimit(1)
            }

            TableColumn("→ Proposed", value: \.proposed) { result in
                proposedCell(result)
            }
        }
    }

    // MARK: - Proposed Cell

    @ViewBuilder
    private func proposedCell(_ result: RenameResult) -> some View {
        if result.unchanged {
            Text(result.proposed)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        } else if result.conflict {
            HStack(spacing: 4) {
                Text("⚠️")
                    .font(.system(size: 11))
                Text(result.proposed)
                    .font(.system(size: 12, design: .monospaced))
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 3))
        } else {
            // Highlight differing characters in the accent color
            diffHighlighted(original: result.original, proposed: result.proposed)
                .font(.system(size: 12, design: .monospaced))
                .lineLimit(1)
        }
    }

    // MARK: - Diff Highlight

    /// Renders `proposed` with characters that differ from `original` in the accent color.
    ///
    /// Uses a simple prefix/suffix scan: characters that appear only in the proposed name
    /// (not in a shared prefix or suffix) are highlighted. This covers the common cases
    /// (insertions, replacements, case changes) without a full LCS algorithm.
    private func diffHighlighted(original: String, proposed: String) -> Text {
        let oChars = Array(original)
        let pChars = Array(proposed)

        // Common prefix length
        var prefixLen = 0
        while prefixLen < oChars.count && prefixLen < pChars.count
                && oChars[prefixLen] == pChars[prefixLen] {
            prefixLen += 1
        }

        // Common suffix length (from the end, outside the prefix)
        var suffixLen = 0
        while suffixLen < (oChars.count - prefixLen)
              && suffixLen < (pChars.count - prefixLen)
              && oChars[oChars.count - 1 - suffixLen] == pChars[pChars.count - 1 - suffixLen] {
            suffixLen += 1
        }

        let prefixText  = String(pChars.prefix(prefixLen))
        let diffText    = String(pChars[prefixLen ..< max(prefixLen, pChars.count - suffixLen)])
        let suffixText  = String(pChars.suffix(suffixLen))

        return Text(prefixText)
            + Text(diffText).foregroundColor(.accentColor)
            + Text(suffixText)
    }

    // MARK: - Index helper

    private func index(of result: RenameResult) -> Int {
        (results.firstIndex(where: { $0.id == result.id }) ?? 0) + 1
    }
}
