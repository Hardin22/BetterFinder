import SwiftUI

// MARK: - ConflictBannerView

/// Sticky warning banner shown above the preview table when naming conflicts exist.
struct ConflictBannerView: View {

    let conflictCount: Int
    let summaries: [ConflictSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.system(size: 13))
                Text(headerText)
                    .font(.system(size: 12, weight: .semibold))
            }

            // List of conflicting names
            if !summaries.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(summaries.prefix(5)) { summary in
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 4))
                                .foregroundStyle(.secondary)
                            Text("\"\(summary.proposedName)\"")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.primary)
                            Text("— \(summary.count) files")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if summaries.count > 5 {
                        Text("…and \(summaries.count - 5) more")
                            .font(.system(size: 11))
                            .foregroundStyle(.quaternary)
                    }
                }
                .padding(.leading, 20)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .overlay(alignment: .bottom) { Divider() }
    }

    private var headerText: String {
        "\(conflictCount) file\(conflictCount == 1 ? "" : "s") would get duplicate names. Rename is disabled until conflicts are resolved."
    }
}
