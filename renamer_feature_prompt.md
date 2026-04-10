# NativeFinder — Smart Rename Module: Implementation Prompt for Claude Code

## Context & Scope

You are implementing the **SmartRename** module for NativeFinder, a native macOS file manager built in SwiftUI (macOS 26+, Apple Silicon). This module already exists as a Swift Package target at `Modules/BatchRename/`. Your task is to implement it from scratch following the exact specifications below.

Do not invent, assume, or hallucinate any APIs, system behaviors, or file formats that are not described in this prompt or not part of the macOS 26 SDK. If something is unclear, implement the safest, simplest interpretation and leave a `// DECISION: explain` comment so the developer can review it.

Use `Foundation`, `UniformTypeIdentifiers`, `AppKit`, and `SwiftUI` only. Do not add third-party dependencies.

---

## Architecture Rules (non-negotiable)

- Follow the existing project pattern: **MVVM**, `@Observable` view models, `Actor`-isolated services
- All rename operations run on a **background actor** (`RenameActor`) — never on the MainActor
- Every rename operation is a **pure function**: `(RenameRule, String) -> String` — the rule transforms the input name and returns the result. No side effects inside rule execution
- The final apply step (writing to disk) is the **only** place that touches the filesystem
- The entire batch is treated as a **single UndoManager transaction** — one `Cmd+Z` undoes all renames
- The module exposes a public protocol `RenameProviding` so it can be mocked in tests
- Every public type and function has a doc comment
- No `try!`, no force-unwrap

---

## Module File Structure

Create exactly these files inside `Modules/BatchRename/Sources/BatchRename/`:

```
BatchRename/
+-- RenameRule.swift           # All rule types as an enum + their pure transform logic
+-- RenameEngine.swift         # Orchestrates rule chaining, conflict detection, dry-run
+-- RenameActor.swift          # Background actor that performs disk writes
+-- RenamePreset.swift         # Codable model for saving/loading named presets
+-- RenameConflict.swift       # Conflict and error types
+-- UI/
|   +-- SmartRenameSheet.swift # Main SwiftUI sheet — the entry point
|   +-- RuleBuilderView.swift  # Drag-reorderable list of active rules
|   +-- RuleRowView.swift      # One row per rule with its controls
|   +-- PreviewTableView.swift # Live preview: old name → new name for every file
|   +-- PresetPickerView.swift # Save, load, and delete named presets
|   +-- ConflictBannerView.swift # Inline warning when two files would get the same name
+-- Tests/
    +-- RenameEngineTests.swift
```

---

## Step 1 — Define RenameRule

Implement `RenameRule` as a Swift enum where each case carries its parameters. Each case must implement the `apply(to name: String, index: Int, total: Int) -> String` method. The `index` and `total` parameters are needed for sequential numbering rules.

The `name` parameter passed to `apply` is the **filename without extension** (stem only). The extension is preserved separately and re-attached after all rules have been applied. If the final extension must change, use the `changeExtension` rule below.

### Required Rule Cases

Implement all of the following. Do not add cases that are not listed here.

```swift
enum RenameRule: Identifiable, Hashable, Codable {

    // --- TEXT MANIPULATION ---

    /// Replace all occurrences of a literal string or regex pattern.
    /// - isCaseSensitive: whether matching is case-sensitive
    /// - isRegex: if true, `find` is a regex pattern; capture groups $1, $2 usable in `replacement`
    case replace(find: String, replacement: String, isCaseSensitive: Bool, isRegex: Bool)

    /// Insert a string at a given position.
    /// - position: .prefix, .suffix, or .atIndex(Int) (0-based, clamped to name length)
    case insert(text: String, position: InsertPosition)

    /// Remove a range of characters by position.
    /// - from: 0-based start index (negative = from end: -1 is last char)
    /// - to: 0-based end index (inclusive; negative counts from end)
    case removeRange(from: Int, to: Int)

    /// Remove all characters matching a character set.
    /// - preset: .whitespace, .specialChars, .digits, .custom(String)
    ///   where custom contains the literal characters to remove
    case removeCharacters(preset: CharacterSetPreset)

    // --- CASE ---

    /// Transform the case of the entire name.
    /// - style: .lowercase, .uppercase, .titleCase, .camelCase, .snakeCase, .kebabCase
    case changeCase(style: CaseStyle)

    // --- NUMBERING ---

    /// Add a sequential number to each file.
    /// - position: .prefix, .suffix, or .atIndex(Int)
    /// - startAt: the first number in the sequence (default 1)
    /// - step: increment between numbers (default 1)
    /// - padToDigits: zero-pad to this many digits (e.g., 3 → "001"). 0 = no padding
    /// - separator: string placed between the number and the name (e.g., "_", " - ", "")
    case addNumber(position: InsertPosition, startAt: Int, step: Int, padToDigits: Int, separator: String)

    // --- DATE & TIME ---

    /// Insert a date derived from file metadata.
    /// - source: .creationDate, .modificationDate, .currentDate
    /// - format: a DateFormatter format string (e.g., "yyyy-MM-dd", "yyyyMMdd_HHmmss")
    /// - position: .prefix, .suffix, or .atIndex(Int)
    /// - separator: string placed between the date and the name
    case insertDate(source: DateSource, format: String, position: InsertPosition, separator: String)

    // --- METADATA ---

    /// Insert EXIF or media metadata tags into the filename.
    /// Only applied to supported file types; silently skipped for unsupported files.
    /// - tags: ordered list of metadata fields to insert, separated by `separator`
    /// Available tags: .exifDate, .exifCamera, .exifLens, .exifISO,
    ///                 .imageWidth, .imageHeight,
    ///                 .audioArtist, .audioAlbum, .audioTrackNumber, .audioYear,
    ///                 .videoResolution, .videoDuration
    case insertMetadata(tags: [MetadataTag], separator: String, position: InsertPosition)

    // --- EXTENSION ---

    /// Change the file extension (without the dot).
    /// - newExtension: the new extension (e.g., "jpg", "txt"). Empty string removes the extension.
    /// This rule operates on the extension string, not the stem.
    case changeExtension(newExtension: String)

    // --- TRUNCATION ---

    /// Trim the name to a maximum number of characters.
    /// - maxLength: maximum character count of the stem
    /// - from: .start or .end — which side to trim from
    case truncate(maxLength: Int, from: TruncateSide)
}
```

Also define the supporting enums:

```swift
enum InsertPosition: Hashable, Codable {
    case prefix
    case suffix
    case atIndex(Int)    // 0-based, negative = from end, clamped to valid range
}

enum CaseStyle: String, Hashable, Codable, CaseIterable {
    case lowercase, uppercase, titleCase, camelCase, snakeCase, kebabCase
}

enum CharacterSetPreset: Hashable, Codable {
    case whitespace
    case specialChars     // everything that is not alphanumeric, dot, dash, or underscore
    case digits
    case custom(String)   // literal characters to remove
}

enum DateSource: String, Hashable, Codable {
    case creationDate, modificationDate, currentDate
}

enum MetadataTag: String, Hashable, Codable, CaseIterable {
    case exifDate, exifCamera, exifLens, exifISO
    case imageWidth, imageHeight
    case audioArtist, audioAlbum, audioTrackNumber, audioYear
    case videoResolution, videoDuration
}

enum TruncateSide: String, Hashable, Codable {
    case start, end
}
```

---

## Step 2 — Implement RenameEngine

`RenameEngine` is a pure (no side effects), synchronous struct. It takes a list of rules and a list of `FileItem` values and returns a list of `RenameResult` values.

```swift
struct RenameEngine {

    /// Apply a chain of rules to a single filename.
    /// Rules are applied left-to-right in order.
    /// Returns the proposed new full filename (stem + extension).
    func apply(rules: [RenameRule], to item: FileItem, index: Int, total: Int) -> String

    /// Compute proposed names for all items and detect conflicts.
    /// A conflict is when two or more items would receive the same proposed name.
    func preview(rules: [RenameRule], items: [FileItem]) -> [RenameResult]
}

struct RenameResult: Identifiable {
    let id: UUID              // same as the source FileItem.id
    let original: String      // original filename (stem + extension)
    let proposed: String      // proposed new filename (stem + extension)
    let conflict: Bool        // true if another item has the same proposed name
    let unchanged: Bool       // true if proposed == original (rule produced no change)
}
```

Implementation rules for `RenameEngine`:
- The extension is split from the stem before rules are applied, then re-joined after, unless a `changeExtension` rule is present
- Use `URL(fileURLWithPath:).deletingPathExtension().lastPathComponent` to extract the stem
- Use `URL(fileURLWithPath:).pathExtension` to extract the extension
- For `case replace` with `isRegex: true`, use `NSRegularExpression`. If the pattern is invalid, return the original name unchanged and mark the result with a new error field `invalidRegex: Bool = true`
- For `case insertMetadata`, read EXIF using `ImageIO` (`CGImageSourceCopyPropertiesAtIndex`) and audio/video metadata using `AVFoundation` (`AVAsset`). These calls happen synchronously inside the engine during preview computation; they run on `RenameActor`, not MainActor
- For `case changeCase(.titleCase)`, capitalize the first letter of every word delimited by spaces, underscores, or hyphens
- For `case changeCase(.camelCase)`, split on spaces/underscores/hyphens, lowercase all words, capitalize words[1...], join with no separator
- For `case changeCase(.snakeCase)`, split on spaces/hyphens, lowercase, join with `_`
- For `case changeCase(.kebabCase)`, split on spaces/underscores, lowercase, join with `-`
- Conflict detection: collect all proposed names into a `[String: Int]` frequency map; any name with count > 1 is a conflict

---

## Step 3 — Implement RenameActor

`RenameActor` is a Swift Actor that performs the actual disk operations. It must never be called until the user clicks "Rename" after reviewing the preview.

```swift
actor RenameActor {

    /// Applies all renames to disk.
    /// - items: the FileItems to rename
    /// - results: the RenameResult list from RenameEngine.preview()
    /// - undoManager: the UndoManager to register a single undo action
    /// Returns a RenameReport summarizing successes and failures.
    func applyRenames(
        items: [FileItem],
        results: [RenameResult],
        undoManager: UndoManager
    ) async throws -> RenameReport
}

struct RenameReport {
    let succeeded: Int
    let failed: [(item: FileItem, error: Error)]
    let skipped: Int          // items where proposed == original
}
```

Implementation rules for `RenameActor`:
- Use `FileManager.default.moveItem(at:to:)` for each rename
- Skip items where `result.unchanged == true` or `result.conflict == true`
- Register a **single** undo action on the provided `UndoManager` that calls `moveItem` in reverse for all successfully renamed items
- The undo action must be registered as a group: call `undoManager.beginUndoGrouping()` before the loop and `undoManager.endUndoGrouping()` after
- If any individual rename fails, continue with the others and collect the error — do not abort the entire batch
- Use `FileManager.default.fileExists(atPath:)` to verify the destination does not already exist before each rename (last safety check even if conflict detection already ran)

---

## Step 4 — Implement RenamePreset

Presets allow users to save and reload named rule configurations.

```swift
struct RenamePreset: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var rules: [RenameRule]
    var createdAt: Date
    var updatedAt: Date
}

class RenamePresetStore: ObservableObject {
    /// Persisted to: ~/Library/Application Support/NativeFinder/RenamePresets.json
    @Published private(set) var presets: [RenamePreset]

    func save(_ preset: RenamePreset)
    func delete(_ preset: RenamePreset)
    func update(_ preset: RenamePreset)
    func load() throws
    func persist() throws
}
```

Use `JSONEncoder`/`JSONDecoder` with `.prettyPrinted` for the file. Do not use `UserDefaults` — the file must be stored in Application Support so it survives app reinstalls.

---

## Step 5 — Implement the UI

### SmartRenameSheet.swift

This is the root SwiftUI sheet. It is presented as a `.sheet` or `.fullScreenCover` from the main file pane when the user selects multiple files and triggers "Rename..." from the context menu or `Cmd+Shift+R`.

**Layout:**

```
+-----------------------------------------------+
|  TOOLBAR: [Preset Picker ▾]  [Save Preset]    |
+------------------------+----------------------+
|  RULE BUILDER          |  LIVE PREVIEW TABLE  |
|  (left panel ~40%)     |  (right panel ~60%)  |
|                        |                      |
|  [+ Add Rule ▾]        |  Original → Proposed |
|  Rule 1 (draggable)    |  file.txt → file.txt |
|  Rule 2 (draggable)    |  ...                 |
|  ...                   |                      |
+------------------------+----------------------+
|  STATUS BAR: "12 files · 10 renamed · 2 unchanged · 0 conflicts"  |
+-------------------------------------------------------------------+
|  [Cancel]                                    [Rename X files →]  |
+-------------------------------------------------------------------+
```

**Behavior rules:**
- The preview table updates on every keystroke / every rule change — debounced by 150ms using `Task.sleep`
- The "Rename X files →" button is disabled if: (a) there are any conflicts, (b) there are no rules, or (c) all items are unchanged
- Rules in the builder are reordered via drag. Use `.onMove` with `List`
- The `+` Add Rule button shows a `Menu` listing all rule types, organized in sections matching the categories: Text, Case, Numbering, Date, Metadata, Extension, Truncation
- Clicking a rule type adds it at the bottom of the rule list with sensible defaults

### RuleRowView.swift

Each active rule renders as a row in the rule builder. Every row contains:
- A drag handle on the left (`line.3.horizontal` SF Symbol)
- An inline editor for the rule's parameters (see parameter editors below)
- A delete button on the right (`minus.circle` SF Symbol)
- A toggle to temporarily disable the rule without removing it (eye icon)

**Parameter editors by rule type:**

| Rule | Editor components |
|---|---|
| `replace` | Two `TextField` (Find / Replace), two `Toggle` (Case Sensitive, Regex) |
| `insert` | `TextField` (text), `Picker` for position (Prefix / Suffix / At Index), conditional `Stepper` for index |
| `removeRange` | Two `TextField` with `Int` binding (From / To), hint label showing "negative = from end" |
| `removeCharacters` | `Picker` for preset (Whitespace / Special Chars / Digits / Custom), conditional `TextField` for custom chars |
| `changeCase` | `Picker` with all CaseStyle options |
| `addNumber` | `Picker` for position, `Stepper` for startAt and step, `Stepper` for padToDigits (0–8), `TextField` for separator |
| `insertDate` | `Picker` for source, `TextField` for format string with placeholder "yyyy-MM-dd", `Picker` for position, `TextField` for separator |
| `insertMetadata` | Multi-select list of `MetadataTag` cases, `TextField` for separator, `Picker` for position |
| `changeExtension` | Single `TextField` with placeholder "e.g. jpg" |
| `truncate` | `Stepper` for maxLength, `Picker` for side (Start / End) |

### PreviewTableView.swift

A scrollable `Table` (using SwiftUI `Table` on macOS) with three columns:
- **#** — row index, `--text-sm` size, muted color
- **Original** — original filename, monospaced font
- **→ Proposed** — proposed filename, monospaced font
  - If `unchanged`: render in `--color-text-muted` (dimmed)
  - If `conflict`: render with a red background tint and a ⚠️ icon
  - If changed and no conflict: render the **differing characters** in accent color (character-level diff highlight)

For the character diff highlight: compute the longest common subsequence (LCS) between original and proposed. Characters in proposed that are not part of the LCS are "added" — render them in the accent color. Keep the implementation simple: a character-by-character comparison using `zip` followed by a scan for the differing suffix/prefix is sufficient. Full LCS is not required if it adds significant complexity.

### ConflictBannerView.swift

A sticky banner rendered above the preview table when `results.contains(where: { $0.conflict })`. Shows:
- Warning icon and message: "X files would get duplicate names. Rename is disabled until conflicts are resolved."
- Lists the conflicting proposed names with the count of files affected

---

## Step 6 — Write Tests

In `Tests/RenameEngineTests.swift`, write unit tests covering:

1. `replace` with literal string — basic substitution
2. `replace` with regex and capture group (`$1`)
3. `replace` with invalid regex — must return original name, `invalidRegex: true`
4. `changeCase(.snakeCase)` on a name with spaces and hyphens
5. `changeCase(.camelCase)` on a name with underscores
6. `addNumber` with zero-padding and suffix position
7. `insertDate` with `.currentDate` source — mock the date to `2026-01-15` to make the test deterministic
8. `removeRange` with negative indices
9. Rule chaining: `replace` → `changeCase` → `addNumber` applied in order
10. Conflict detection: two files that produce the same proposed name
11. `truncate` from start, from end
12. `changeExtension` changes only the extension, not the stem

Use `XCTest`. Do not use any mocking frameworks. For the `insertDate` test, inject the date via a parameter on the engine (add `func preview(rules:items:referenceDate:)` overload where `referenceDate` defaults to `Date.now`).

---

## Integration Point

In the existing `FilePane` module, the context menu for multi-file selection must include a "Rename..." menu item that presents `SmartRenameSheet` as a `.sheet`. Pass the selected `[FileItem]` and the window's `UndoManager` (via `@Environment(\.undoManager)`) to the sheet.

The sheet is dismissed:
- On "Cancel" — no changes, no undo registered
- On "Rename X files →" — `RenameActor.applyRenames` is called, then the sheet is dismissed on success

After a successful rename, the `FileSystemService` FSEvents watcher will automatically refresh the pane — no manual refresh call needed.

---

## What NOT to implement in this PR

Do not implement the following — they are out of scope for this module:
- AI-assisted rename suggestions
- Rename based on file content (OCR, text extraction)
- Cloud metadata (Spotlight comments, Finder tags)
- Folder-level recursive renaming
- Undo history UI panel

These will be separate modules. Leave `// TODO(future): [feature name]` comments at the obvious extension points.

---

## Definition of Done

This module is complete when:
- [ ] All files listed in the module structure exist and compile with zero warnings
- [ ] `RenameEngineTests` passes all 12 test cases
- [ ] `SmartRenameSheet` opens when multiple files are selected and "Rename..." is triggered
- [ ] Live preview updates within 150ms of any rule change
- [ ] Renaming 100 files completes without blocking the UI
- [ ] All renames are undoable with a single `Cmd+Z`
- [ ] Presets are saved to and loaded from Application Support correctly
- [ ] No `.DS_Store` files are created or modified by any operation in this module
