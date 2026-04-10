import Foundation
import Combine

// MARK: - RenamePreset

/// A named, saved configuration of rename rules.
struct RenamePreset: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var rules: [RenameRule]
    let createdAt: Date
    var updatedAt: Date

    init(name: String, rules: [RenameRule]) {
        self.id        = UUID()
        self.name      = name
        self.rules     = rules
        self.createdAt = .now
        self.updatedAt = .now
    }
}

// MARK: - RenamePresetStore

/// Persists named presets to `~/Library/Application Support/NativeFinder/RenamePresets.json`.
final class RenamePresetStore: ObservableObject {

    /// All saved presets, sorted by most recently updated.
    @Published private(set) var presets: [RenamePreset] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL.homeDirectory.appending(component: "Library/Application Support")

        let folder = appSupport.appending(component: "NativeFinder")
        // Ensure directory exists; ignore errors if it already does
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        self.fileURL = folder.appending(component: "RenamePresets.json")
        try? load()
    }

    // MARK: - CRUD

    /// Add a new preset. Does nothing if a preset with the same `id` already exists.
    func save(_ preset: RenamePreset) {
        guard !presets.contains(where: { $0.id == preset.id }) else { return }
        presets.append(preset)
        try? persist()
    }

    /// Delete a preset by id.
    func delete(_ preset: RenamePreset) {
        presets.removeAll { $0.id == preset.id }
        try? persist()
    }

    /// Replace an existing preset's name and rules.
    func update(_ preset: RenamePreset) {
        guard let idx = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        var updated = preset
        updated.updatedAt = .now
        presets[idx] = updated
        try? persist()
    }

    // MARK: - Persistence

    /// Load presets from disk. Called automatically on `init`.
    func load() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return }
        let data = try Data(contentsOf: fileURL)
        presets = try JSONDecoder().decode([RenamePreset].self, from: data)
    }

    /// Write current presets to disk.
    func persist() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(presets)
        try data.write(to: fileURL, options: .atomicWrite)
    }
}
