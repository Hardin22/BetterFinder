import SwiftUI

// MARK: - PresetPickerView

/// Dropdown that lets the user load, and delete named rename presets.
struct PresetPickerView: View {

    @ObservedObject var store: RenamePresetStore
    var onLoad: (RenamePreset) -> Void

    @State private var confirmDelete: RenamePreset?

    var body: some View {
        Menu {
            if store.presets.isEmpty {
                Text("No saved presets")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.presets) { preset in
                    Menu(preset.name) {
                        Button("Load") { onLoad(preset) }
                        Divider()
                        Button("Delete", role: .destructive) {
                            confirmDelete = preset
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "tray.and.arrow.down")
                    .font(.system(size: 11))
                Text("Presets")
                    .font(.system(size: 12))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .alert("Delete Preset", isPresented: .init(
            get: { confirmDelete != nil },
            set: { if !$0 { confirmDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let p = confirmDelete { store.delete(p) }
                confirmDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmDelete = nil }
        } message: {
            if let p = confirmDelete {
                Text("Delete \"\(p.name)\"? This cannot be undone.")
            }
        }
    }
}
