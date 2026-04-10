import SwiftUI

// MARK: - RuleBuilderView

/// Drag-reorderable list of active rename rules with an "Add Rule" menu.
struct RuleBuilderView: View {

    @Bindable var viewModel: SmartRenameViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Rules")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                addRuleMenu
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            if viewModel.activeRules.isEmpty {
                emptyState
            } else {
                ruleList
            }
        }
    }

    // MARK: - Rule List

    private var ruleList: some View {
        List {
            // Use indices so each row can call removeRule(at:) directly
            ForEach(viewModel.activeRules.indices, id: \.self) { idx in
                RuleRowView(
                    activeRule: $viewModel.activeRules[idx],
                    onDelete: { viewModel.removeRule(at: IndexSet(integer: idx)) },
                    onChange:  { viewModel.schedulePreviewUpdate() }
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                .listRowSeparator(.hidden)
            }
            .onMove { source, dest in
                viewModel.moveRule(from: source, to: dest)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 28))
                .foregroundStyle(.quaternary)
            Text("No Rules")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.tertiary)
            Text("Add a rule to get started.")
                .font(.system(size: 11))
                .foregroundStyle(.quaternary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Add Rule Menu

    private var addRuleMenu: some View {
        Menu {
            Section("Text") {
                addButton("Replace Text",      .replace(find: "", replacement: "", isCaseSensitive: false, isRegex: false))
                addButton("Insert Text",       .insert(text: "", position: .prefix))
                addButton("Remove Range",      .removeRange(from: 0, to: 0))
                addButton("Remove Characters", .removeCharacters(preset: .whitespace))
            }
            Section("Case") {
                addButton("Change Case", .changeCase(style: .lowercase))
            }
            Section("Numbering") {
                addButton("Add Number", .addNumber(position: .suffix, startAt: 1, step: 1, padToDigits: 0, separator: "_"))
                addButton("Sequential Name", .sequentialName(baseName: "Week", startAt: 1, step: 1, padToDigits: 0, separator: " "))
            }
            Section("Date") {
                addButton("Insert Date", .insertDate(source: .currentDate, format: "yyyy-MM-dd", position: .prefix, separator: "_"))
            }
            Section("Metadata") {
                addButton("Insert Metadata", .insertMetadata(tags: [.exifDate], separator: "_", position: .suffix))
            }
            Section("Extension") {
                addButton("Change Extension", .changeExtension(newExtension: ""))
            }
            Section("Truncation") {
                addButton("Truncate", .truncate(maxLength: 50, from: .end))
            }
        } label: {
            Label("Add Rule", systemImage: "plus")
                .font(.system(size: 12))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func addButton(_ title: String, _ rule: RenameRule) -> some View {
        Button(title) { viewModel.addRule(rule) }
    }
}
