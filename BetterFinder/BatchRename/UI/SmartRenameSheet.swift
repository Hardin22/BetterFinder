import SwiftUI
import AppKit

// MARK: - ActiveRule

/// A wrapper around `RenameRule` that adds stable identity and an enable/disable toggle.
struct ActiveRule: Identifiable, Hashable {
    let id: UUID
    var rule: RenameRule
    var isEnabled: Bool

    init(rule: RenameRule, isEnabled: Bool = true) {
        self.id        = UUID()
        self.rule      = rule
        self.isEnabled = isEnabled
    }
}

// MARK: - SmartRenameViewModel

@Observable
final class SmartRenameViewModel {

    // MARK: State
    var activeRules: [ActiveRule] = []
    var results: [RenameResult]   = []
    var isApplying                = false
    var applyError: String?

    let items: [FileItem]
    let presetStore: RenamePresetStore
    private let engine = RenameEngine()
    private let actor  = RenameActor()

    // Debounce
    private var debounceTask: Task<Void, Never>?

    // MARK: Init
    init(items: [FileItem], presetStore: RenamePresetStore) {
        self.items       = items
        self.presetStore = presetStore
        updatePreview()
    }

    // MARK: Computed helpers

    var enabledRules: [RenameRule] { activeRules.filter(\.isEnabled).map(\.rule) }

    var conflictCount: Int { results.filter(\.conflict).count }
    var unchangedCount: Int { results.filter(\.unchanged).count }
    var renamedCount: Int   { results.filter { !$0.unchanged && !$0.conflict }.count }

    var canRename: Bool {
        !enabledRules.isEmpty
        && conflictCount == 0
        && renamedCount > 0
        && !isApplying
    }

    var conflictSummaries: [ConflictSummary] {
        engine.conflictSummaries(from: results)
    }

    // MARK: Rule management

    func addRule(_ rule: RenameRule) {
        activeRules.append(ActiveRule(rule: rule))
        schedulePreviewUpdate()
    }

    func removeRule(at offsets: IndexSet) {
        activeRules.remove(atOffsets: offsets)
        schedulePreviewUpdate()
    }

    func moveRule(from source: IndexSet, to destination: Int) {
        activeRules.move(fromOffsets: source, toOffset: destination)
        schedulePreviewUpdate()
    }

    func updateRule(_ updated: ActiveRule) {
        guard let idx = activeRules.firstIndex(where: { $0.id == updated.id }) else { return }
        activeRules[idx] = updated
        schedulePreviewUpdate()
    }

    // MARK: Preview (debounced 150 ms)

    func schedulePreviewUpdate() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            self.updatePreview()
        }
    }

    func updatePreview() {
        results = engine.preview(rules: enabledRules, items: items)
    }

    // MARK: Apply

    func applyRenames(undoManager: UndoManager) async {
        guard canRename else { return }
        await MainActor.run { isApplying = true; applyError = nil }

        let report = await actor.applyRenames(items: items, results: results, undoManager: undoManager)

        await MainActor.run {
            isApplying = false
            if !report.failed.isEmpty {
                applyError = "\(report.failed.count) file(s) could not be renamed."
            }
        }
    }

    // MARK: Presets

    func loadPreset(_ preset: RenamePreset) {
        activeRules = preset.rules.map { ActiveRule(rule: $0) }
        schedulePreviewUpdate()
    }

    func saveCurrentAsPreset(name: String) {
        let preset = RenamePreset(name: name, rules: enabledRules)
        presetStore.save(preset)
    }
}

// MARK: - SmartRenameSheet

/// Root sheet for the batch rename feature.
///
/// Present this sheet when the user selects multiple files and triggers "Rename…"
/// from the context menu or `Cmd+Shift+R`.
struct SmartRenameSheet: View {

    let items: [FileItem]
    var onDismiss: () -> Void

    @Environment(\.undoManager) private var undoManager
    @State private var viewModel: SmartRenameViewModel
    @State private var showPresetSaveAlert = false
    @State private var newPresetName = ""
    @StateObject private var presetStore = RenamePresetStore()

    init(items: [FileItem], onDismiss: @escaping () -> Void) {
        self.items = items
        self.onDismiss = onDismiss
        let store = RenamePresetStore()
        _viewModel = State(wrappedValue: SmartRenameViewModel(items: items, presetStore: store))
        _presetStore = StateObject(wrappedValue: store)
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Toolbar ──────────────────────────────────────────────────────
            HStack {
                PresetPickerView(store: presetStore) { preset in
                    viewModel.loadPreset(preset)
                }

                Button("Save Preset") {
                    newPresetName = ""
                    showPresetSaveAlert = true
                }
                .disabled(viewModel.enabledRules.isEmpty)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            // ── Main body: rule builder + preview ────────────────────────────
            HSplitView {
                // Left: rule builder (~40%)
                VStack(spacing: 0) {
                    RuleBuilderView(viewModel: viewModel)
                }
                .frame(minWidth: 280)

                // Right: live preview (~60%)
                VStack(spacing: 0) {
                    if viewModel.conflictCount > 0 {
                        ConflictBannerView(
                            conflictCount: viewModel.conflictCount,
                            summaries: viewModel.conflictSummaries
                        )
                    }
                    PreviewTableView(results: viewModel.results)
                }
                .frame(minWidth: 380)
            }

            Divider()

            // ── Status bar ───────────────────────────────────────────────────
            HStack {
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                if let err = viewModel.applyError {
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(.bar)

            Divider()

            // ── Action buttons ───────────────────────────────────────────────
            HStack {
                Button("Cancel") { onDismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                if viewModel.isApplying {
                    ProgressView().controlSize(.small)
                }

                Button(renameButtonLabel) {
                    Task {
                        await viewModel.applyRenames(undoManager: undoManager ?? UndoManager())
                        if viewModel.applyError == nil {
                            onDismiss()
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!viewModel.canRename)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .frame(minWidth: 700, idealWidth: 880, minHeight: 460, idealHeight: 600)
        .alert("Save Preset", isPresented: $showPresetSaveAlert) {
            TextField("Preset name", text: $newPresetName)
            Button("Save") {
                guard !newPresetName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                viewModel.saveCurrentAsPreset(name: newPresetName)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var statusText: String {
        let n = items.count
        let r = viewModel.renamedCount
        let u = viewModel.unchangedCount
        let c = viewModel.conflictCount
        return "\(n) file\(n == 1 ? "" : "s") · \(r) renamed · \(u) unchanged · \(c) conflict\(c == 1 ? "" : "s")"
    }

    private var renameButtonLabel: String {
        let n = viewModel.renamedCount
        return "Rename \(n) File\(n == 1 ? "" : "s") →"
    }
}
