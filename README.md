# BetterFinder

A native macOS file manager built with SwiftUI + AppKit — a power-user replacement for Apple Finder, inspired by Marta and ForkLift.

> **Requires:** macOS 15 Sequoia or later · Apple Silicon (arm64)

---

## Download & Install

1. Go to the [**Releases**](../../releases/latest) page and download **BetterFinder-x.x.x.dmg**
2. Open the DMG and drag **BetterFinder** into your **Applications** folder
3. Launch BetterFinder — on first run a prompt will appear asking for **Full Disk Access**
4. Click **Open Privacy Settings**, enable the toggle next to BetterFinder, then **relaunch the app**

### Why Full Disk Access?

BetterFinder is a file manager — it needs to read every folder on your system, including protected directories (`~/Library`, `/System`, hidden paths) and run system-wide Spotlight searches. Without FDA, some folders will appear empty or be inaccessible.

---

## Table of Contents

1. [Navigation](#1-navigation)
2. [Sidebar](#2-sidebar)
3. [File Pane](#3-file-pane)
4. [Preview Panel](#4-preview-panel)
5. [Dual Pane](#5-dual-pane)
6. [File Operations](#6-file-operations)
7. [Drop Stack](#7-drop-stack)
8. [Trash Drop Zone](#8-trash-drop-zone)
9. [Keyboard Shortcuts](#9-keyboard-shortcuts)
10. [Terminal](#10-terminal)
11. [Search](#11-search)
12. [Toolbar](#12-toolbar)
13. [Preferences](#13-preferences)
14. [Global Hotkey](#14-global-hotkey)
15. [macOS Integration](#15-macos-integration)
16. [Architecture](#16-architecture)
17. [Smart Rename (Batch Rename)](#17-smart-rename-batch-rename)
18. [Planned](#18-planned)

---

## 1. Navigation

| Feature | Description | Status |
|---|---|---|
| Back / Forward | Per-pane history — `⌘[` / `⌘]` | ✅ |
| Go Up | Navigate to parent folder — `⌘↑` | ✅ |
| Go Home | Jump to home directory — `⌘⇧H` | ✅ |
| Path Bar | Clickable breadcrumbs below the toolbar, toggleable | ✅ |
| Single-click in sidebar | Navigates active pane to that folder | ✅ |
| Double-click in file pane | Opens folder / launches file with default app | ✅ |
| Sidebar auto-collapses | When navigating back, sidebar tree closes folders that are no longer on the current path | ✅ |

---

## 2. Sidebar

### Favorites

Pinned shortcuts to the most common folders. Shown with Finder-style outlined SF Symbols.

| Location | Icon |
|---|---|
| Applications | `square.grid.2x2` |
| Desktop | `menubar.dock.rectangle` |
| Documents | `doc` |
| Downloads | `arrow.down.circle` |

### Recents

Collapsible section that remembers your last visited folders. Right-click any entry to open it in a specific pane, copy its path, or remove it.

### Locations

Dynamically populated — no hardcoding:

| Location | How discovered |
|---|---|
| Macintosh HD | Always present (`/`) |
| iCloud Drive | `~/Library/CloudStorage/iCloud*` (Ventura+) or legacy CloudDocs path |
| Third-party cloud providers | All entries in `~/Library/CloudStorage/` (Nextcloud, OneDrive, Dropbox…) |
| Home folder | `URL.homeDirectory` |
| External volumes | `FileManager.mountedVolumeURLs` — updates on mount/unmount |
| Network shares | Same enumeration, listed after local volumes |
| Trash | `~/.Trash` |

### Sidebar behaviour

| Feature | Description | Status |
|---|---|---|
| Lazy tree expansion | Children loaded on demand, spinner shown while loading | ✅ |
| Auto-expand on navigate | Expands ancestors in Macintosh HD to reveal current folder | ✅ |
| Auto-scroll to active | Active node scrolls into view when navigating | ✅ |
| Auto-collapse on back | Folders opened by navigation close when you go to a different branch | ✅ |
| Drag & drop files onto folder | Moves files; undo-registered (`⌘Z` reverses) | ✅ |
| Spring loading | Hovering a drag over a sidebar row for 1.2 s auto-expands it | ✅ |
| Volume auto-refresh | Sidebar updates when drives are mounted / unmounted | ✅ |
| Context menu | Open in Pane 1, Open in Pane 2, Copy Path, Open in Terminal | ✅ |
| Isolated expansion | Clicking a folder in one section never auto-opens it in another section | ✅ |

---

## 3. File Pane

| Feature | Description | Status |
|---|---|---|
| Native NSTableView | AppKit table for performance and native interaction | ✅ |
| Columns | Name (icon + label), Date Modified, Size, Kind | ✅ |
| Column resizing | All columns user-resizable | ✅ |
| Alternating row colors | macOS-standard zebra striping | ✅ |
| Folders before files | Optional toggle in Preferences → General (default: mixed) | ✅ |
| Hidden files | Shown at 45 % opacity when "Show Dot Files" is on | ✅ |
| Multi-selection | Click, Shift-click, ⌘-click, rubber-band drag | ✅ |
| Drag & drop source/target | Drag out to move/copy; drop in or onto a row | ✅ |
| Lazy icon loading | File icons loaded async; placeholder shown immediately | ✅ |
| Inline rename | Triple-click, `⌘R`, or F2 — Esc to cancel, ↩ to confirm | ✅ |
| Context menu | Open, Quick Look, Cut (`⌘X`), Copy, Copy Path, Get Info, Rename, Duplicate, Make Alias, Move to Trash | ✅ |
| Context menu shortcuts | Key equivalents shown next to each item, fully customisable in Preferences | ✅ |
| Status bar | Item count and selected count at bottom | ✅ |

---

## 4. Preview Panel

A resizable right-side panel toggled with **`⌘⌥P`** or the toolbar button.

| Feature | Status |
|---|---|
| Image preview (JPEG, PNG, GIF, HEIC, WebP, SVG…) | ✅ |
| PDF preview (first page) | ✅ |
| Text / code preview with syntax awareness | ✅ |
| Web content preview (HTML files) | ✅ |
| Audio / video waveform placeholder | ✅ |
| File info bar — Kind, Size, Modified, Created, full Path | ✅ |
| Metadata labels left-aligned, path selectable | ✅ |
| Updates instantly on selection change | ✅ |

---

## 5. Dual Pane

Toggle with **`⌘D`**.

| Feature | Description | Status |
|---|---|---|
| Two independent panes | Each pane has its own navigation history, selection, search and terminal | ✅ |
| Active pane indicator | Accent top border + tinted header + dot | ✅ |
| Switch active pane | Click anywhere in a pane or `⌘1` / `⌘2` | ✅ |
| Swap panes | Toolbar button swaps the current directories of both panes | ✅ |
| Per-pane search bar | Replaces the single toolbar search field in dual-pane mode | ✅ |
| Per-pane terminal | F4 toggles the terminal in whichever pane is active | ✅ |
| Go to Other Pane | Navigate active pane to the other pane's folder | ✅ |
| Mirror Pane | Navigate the other pane to the active pane's folder | ✅ |
| Copy / Move to Other Pane | F5 / F6 with confirmation dialog | ✅ |

---

## 6. File Operations

All operations target the **active pane**. Every destructive operation is **undo-registered** — `⌘Z` reverses it.

| Operation | Shortcut | Notes | Status |
|---|---|---|---|
| New File | `⌘⌥N` | Prompts for name, creates empty file | ✅ |
| New Folder | `⌘⇧N` / F7 | Prompts for name | ✅ |
| Rename | `⌘R` / F2 / triple-click | Inline, in-place | ✅ |
| Cut | `⌘X` | Stages selection for move; paste with `⌘V` | ✅ |
| Copy path | `⌘⇧C` | Copies POSIX path to clipboard | ✅ |
| Move to Trash | `⌘⌫` | No confirmation; `⌘Z` restores | ✅ |
| Copy to Other Pane | F5 | Dual-pane only; confirmation dialog | ✅ |
| Move to Other Pane | F6 | Dual-pane only; confirmation dialog | ✅ |
| Quick Look | `Space` | System Quick Look panel | ✅ |
| Get Info | `⌘I` | Opens Finder's Get Info panel | ✅ |
| Duplicate | `⌘⌥D` | Creates a copy in the same folder | ✅ |
| Make Alias | `⌘L` | Creates a `.alias` file | ✅ |
| Undo / Redo | `⌘Z` / `⌘⇧Z` | Reverses rename, move, trash, new file/folder | ✅ |
| Open file | `↩` / double-click | Opens with default app via NSWorkspace | ✅ |
| Drag to move | Drag within pane or to sidebar | Undo-registered | ✅ |

### Operations Bar

Persistent bar at the bottom of the window with the most common actions and their shortcut hints. Buttons auto-disable when no selection is active.

- **Single pane:** Rename (F2) · New Folder (F7) · Trash (⌘⌫)
- **Dual pane adds:** Copy → Pane N (F5) · Move → Pane N (F6) · Go to Other Pane · Mirror Pane

---

## 7. Drop Stack

A collapsible shelf in the sidebar (above Favorites) for temporarily holding files across navigation.

| Feature | Status |
|---|---|
| Drag any file from the pane into the Drop Stack | ✅ |
| Files persist while you navigate to the destination folder | ✅ |
| **Copy** button — copies all stacked files to the active pane | ✅ |
| **Move** button — moves all stacked files to the active pane | ✅ |
| Remove individual items with ✕ | ✅ |
| Clear all with the trash button | ✅ |
| Drag a file out of the stack back to any pane | ✅ |
| Auto-expands when you hover a drag over the "Drop Stack" header | ✅ |

**Typical workflow:** open a folder, drag files you want to move into the Drop Stack, navigate to the destination, click **Move**.

---

## 8. Trash Drop Zone

A collapsible panel below the Preview Panel for quick drag-to-trash.

| Feature | Status |
|---|---|
| Drop files onto the zone to move them to Trash | ✅ |
| Trash icon animates red on hover | ✅ |
| Vertically resizable by dragging the top handle | ✅ |
| "Open Trash" button / double-click navigates the active pane to `~/.Trash` | ✅ |

---

## 9. Keyboard Shortcuts

### Navigation

| Shortcut | Action |
|---|---|
| `⌘[` | Back |
| `⌘]` | Forward |
| `⌘↑` | Enclosing folder |
| `⌘⇧H` | Go to Home |
| `↩` | Open selected / enter folder |

### View

| Shortcut | Action |
|---|---|
| `⌘D` | Toggle dual pane |
| `⌘⇧.` | Toggle hidden files |
| `⌘⌥P` | Toggle Preview Panel |
| F4 | Toggle terminal in active pane |

### Dual Pane

| Shortcut | Action |
|---|---|
| `⌘1` | Activate Pane 1 |
| `⌘2` | Activate Pane 2 |

### File Operations

| Shortcut | Action |
|---|---|
| `⌘⌥N` | New File |
| `⌘⇧N` / F7 | New Folder |
| `⌘R` / F2 | Rename (inline) |
| `⌘X` | Cut (stage for move) |
| `⌘C` | Copy path |
| `⌘⇧C` | Copy path to clipboard |
| `⌘⌫` | Move to Trash |
| `Space` | Quick Look |
| `⌘I` | Get Info |
| `⌘⌥D` | Duplicate |
| `⌘L` | Make Alias |
| `⌘Z` / `⌘⇧Z` | Undo / Redo |
| F5 | Copy to other pane (dual-pane) |
| F6 | Move to other pane (dual-pane) |

All shortcuts are **fully customisable** in **Settings → Context Menu**.

---

## 10. Terminal

| Feature | Description | Status |
|---|---|---|
| Integrated terminal drawer | Slides up from the bottom of the active pane | ✅ |
| Toggle | F4 | ✅ |
| Auto-cd on open | Changes to pane's current folder when opened | ✅ |
| Auto-cd on navigate | Follows pane navigation automatically | ✅ |
| Per-pane in dual mode | Each pane has its own independent terminal | ✅ |
| Resize | Drag the divider to adjust height | ✅ |
| Font size | `⌘+` / `⌘−` in View menu | ✅ |
| Full shell support | Uses `$SHELL` (zsh, bash, fish…) | ✅ |

---

## 11. Search

### Default behaviour
Filters the current folder by filename as you type — instant, client-side, no network or disk access. Intentionally the opposite of Finder, which searches the whole system by default.

### Search Filter Bar
Appears automatically below the path bar whenever a query is active.

| Control | Options | Default |
|---|---|---|
| **Scope** | This Folder · Subfolders · Home · Entire Disk | This Folder |
| **Match** | Name Contains · Starts With · Ends With · Exact · Extension | Name Contains |
| **Kind** | Any · Folder · File · Image · Video · Audio · Document · Code · Archive | Any |

| Scope | Mechanism | Speed |
|---|---|---|
| This Folder | Client-side filter on loaded items | Instant |
| Subfolders | `FileManager.enumerator` walk (≤ 1 000 results) | < 1 s |
| Home | Spotlight `NSMetadataQueryUserHomeScope` | ~1–2 s |
| Entire Disk | Spotlight `NSMetadataQueryLocalComputerScope` | ~1–3 s |

In async scopes a spinner and result count appear. The "Kind" column becomes **"Location"** showing the parent folder for each result.

---

## 12. Toolbar

| Button | Shortcut | Description |
|---|---|---|
| Back / Forward | `⌘[` / `⌘]` | Pane navigation history |
| Go Up | `⌘↑` | Parent folder |
| Search field | — | Adaptive (hidden in dual-pane mode) |
| Hidden files toggle | `⌘⇧.` | Eye icon |
| Preview Panel toggle | `⌘⌥P` | Sidebar right |
| Dual pane toggle | `⌘D` | Grid icon |
| Swap panes | — | Arrows icon (dual-pane only) |
| Terminal toggle | F4 | Terminal icon |

---

## 13. Preferences

Open with **`⌘,`** or **BetterFinder → Settings…**

### General

| Preference | Default |
|---|---|
| Show hidden files | off |
| Show path bar | on |
| Show status bar | on |
| Start in dual-pane mode | off |
| Open terminal by default | off |
| Show folders before files | off |

### Search

Default scope, match mode, and file kind for new searches.

### Context Menu

Customise the keyboard shortcut shown next to each context menu item.

| Action | Default |
|---|---|
| Quick Look | `Space` |
| Cut | `⌘X` |
| Copy | `⌘C` |
| Copy Path | `⌘⇧C` |
| Get Info | `⌘I` |
| Duplicate | `⌘⌥D` |
| Make Alias | `⌘L` |

### Global Hotkey

Customise the system-wide shortcut that brings BetterFinder to the front from any other app (default: **`⌘⇧B`**).

---

## 14. Global Hotkey

BetterFinder registers a **system-wide hotkey** that brings the app to the front instantly — even when you're in another app, a game, or a full-screen window.

**Default: `⌘⇧B`**

- Works without Accessibility permissions (registered via Carbon `RegisterEventHotKey`)
- Customisable in **Settings → Global Hotkey**
- To disable: clear the field in Preferences

---

## 15. macOS Integration

| Feature | Description |
|---|---|
| **Reveal in BetterFinder** | Appears in the right-click Services menu of any Cocoa app when a file is selected; navigates BetterFinder to that file's parent folder |
| **Undo / Redo** | Plugged into macOS Edit menu — `⌘Z` / `⌘⇧Z` reverse all file operations |
| **Quick Look** | Native `QLPreviewPanel` — supports all system-registered types |
| **Get Info** | Opens Finder's native Get Info window (`⌘I`) |
| **Drag & Drop** | Compatible with Finder and other apps as both source and destination |

---

## 16. Architecture

```
BetterFinder/
├── BetterFinderApp.swift          # Entry point, menu commands, global hotkey, FDA onboarding
├── ContentView.swift              # Root layout: sidebar ↔ pane(s) ↔ preview panel
├── State/
│   ├── AppState.swift             # Global state, all file operations, Drop Stack, undo
│   ├── BrowserState.swift         # Per-pane navigation, selection, search, terminal
│   └── AppPreferences.swift       # UserDefaults-backed prefs (view, startup, search, shortcuts)
├── Models/
│   ├── FileItem.swift             # File metadata value type
│   ├── TreeNode.swift             # Sidebar tree node (kind, icon, lazy children)
│   ├── AppShortcut.swift          # Codable keyboard shortcut (keyCode + modifiers)
│   └── SearchOptions.swift        # Search scope / match mode / file kind
├── Services/
│   ├── FileSystemService.swift    # Async directory loading (POSIX readdir for sidebar)
│   ├── SearchService.swift        # Recursive + Spotlight search engine
│   ├── GlobalHotkeyManager.swift  # Carbon RegisterEventHotKey — no Accessibility needed
│   ├── ServiceProvider.swift      # NSServices "Reveal in BetterFinder"
│   └── DirectoryWatcher.swift     # FSEvents watcher
├── Views/
│   ├── Toolbar/                   # BrowserToolbar, adaptive search field
│   ├── Sidebar/                   # SidebarView, TreeRow, collapsible sections
│   ├── DropStack/                 # SidebarDropStackSection
│   ├── FilePane/                  # FilePaneView, FileTableView (NSTableView)
│   ├── Preview/                   # PreviewPanelView, FilePreviewContent, FileInfoBar
│   ├── Trash/                     # TrashDropZoneView (resizable, drag-to-trash)
│   ├── PathBar/                   # Clickable breadcrumbs
│   ├── Terminal/                  # TerminalPanelView, SwiftTermView, F4KeyMonitor
│   ├── Operations/                # OperationsBarView
│   ├── Search/                    # SearchFilterBar
│   ├── Preferences/               # PreferencesView (4 tabs), ShortcutRecorderField
│   └── Onboarding/                # FullDiskAccessView (first-launch FDA prompt)
└── State/
    └── TreeController.swift       # Sidebar expand/collapse/flatten, collapseIrrelevantNodes
```

### Key design decisions

- **No sandbox** — required for a file manager that reads the whole filesystem
- **Full Disk Access** — requested on first launch; needed for protected directories
- **NSTableView over SwiftUI List** — needed for performance (thousands of rows), column resizing, and drag ghost image control
- **@Observable** — all state uses Swift 5.9 `@Observable`; no `ObservableObject`
- **POSIX readdir** for sidebar tree — avoids `URLResourceValues` latency when expanding large directories
- **Carbon RegisterEventHotKey** — system-wide hotkey without requiring Accessibility permissions

---

## 17. Smart Rename (Batch Rename)

A powerful built-in batch rename tool for renaming multiple files at once. Select 2+ files, right-click → **"Rename…"** or press **`⌘⇧R`** to open the Smart Rename sheet.

### Layout

- **Left panel (~40%):** Rule Builder — drag-reorderable list of active rules
- **Right panel (~60%):** Live Preview Table — shows original → proposed name for every file
- **Status bar:** File count, renamed count, unchanged count, conflict count
- **Preset toolbar:** Save and load named rule configurations

### Available Rule Types

Rules are applied left-to-right in order. Chain multiple rules for complex transformations.

| # | Rule | Category | Description |
|---|---|---|---|
| 1 | **Replace Text** | Text | Find & replace (literal or regex with capture groups `$1`, `$2`) |
| 2 | **Insert Text** | Text | Insert text at prefix, suffix, or a specific character index |
| 3 | **Remove Range** | Text | Remove characters by position (supports negative indices from end) |
| 4 | **Remove Characters** | Text | Strip whitespace, special chars, digits, or a custom set |
| 5 | **Change Case** | Case | lowercase, UPPERCASE, Title Case, camelCase, snake_case, kebab-case |
| 6 | **Add Number** | Numbering | Sequential number at prefix/suffix/index with start, step, zero-padding, separator |
| 7 | **Sequential Name** | Numbering | **Replace entire filename** with base name + number (e.g., `IMG_0321` → `Week 1`) |
| 8 | **Insert Date** | Date | Insert creation/modification/current date in any format (e.g., `yyyy-MM-dd`) |
| 9 | **Insert Metadata** | Metadata | Insert EXIF (camera, lens, ISO), image dimensions, audio/video tags |
| 10 | **Change Extension** | Extension | Change or remove the file extension |
| 11 | **Truncate** | Truncation | Trim filename to max length, from start or end |

### Sequential Name — Bulk Rename Use Case

The **Sequential Name** rule is designed for renaming a batch of files to a completely new naming scheme:

| Setting | Description | Default |
|---|---|---|
| **Name** | Base text for all files (e.g., "Week", "Screenshot", "Photo") | Week |
| **Separator** | Character(s) between name and number (space, underscore, dash) | ` ` (space) |
| **Start** | First number in the sequence | 1 |
| **Step** | Increment between consecutive files | 1 |
| **Pad** | Zero-pad numbers to N digits (e.g., 3 → 001, 002, 003) | 0 (no padding) |

**Example:** Renaming `IMG_0321.png`, `IMG_0322.png`, `IMG_0323.png` with base name `Week`:

```
IMG_0321.png  →  Week 1.png
IMG_0322.png  →  Week 2.png
IMG_0323.png  →  Week 3.png
```

### Key Features

| Feature | Description | Status |
|---|---|---|
| Live preview | Updates within 150ms of any rule change | ✅ |
| Conflict detection | Red banner when two files would get the same name; Rename button disabled | ✅ |
| Character diff highlighting | Changed characters highlighted in accent color in preview | ✅ |
| Drag-reorder rules | Drag rules up/down to change application order | ✅ |
| Enable/disable toggle | Eye icon to temporarily skip a rule without removing it | ✅ |
| Presets | Save & load named rule configurations (stored in Application Support) | ✅ |
| Single undo | One `⌘Z` undoes the entire batch rename | ✅ |
| Safe rename | Checks for destination conflicts before each rename | ✅ |
| All 14 unit tests passing | Replace, regex, case, numbering, date, truncate, conflicts | ✅ |

---

## 18. Planned

| Feature | Notes |
|---|---|
| FSEvents file watcher | Auto-refresh pane when files change on disk |
| Column header sorting | Click columns to sort by name / date / size / kind |
| Folder diff & sync | Compare two panes, sync in either direction |
| Size browser | Treemap / disk usage visualisation |
| Git status badges | Modified/staged/untracked indicators on files in git repos |
| Permissions viewer | `rwxrwxrwx` display + chmod buttons in preview panel |
| Tabs | Multiple browser tabs per window |
| Favorites editing | Drag to reorder, add/remove items |
| SMB / WebDAV connections | Mount network shares directly from the sidebar |
