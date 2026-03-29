# BetterFinder

A native macOS file manager built with SwiftUI + AppKit, designed as a power-user replacement for Apple Finder.
Target: macOS 26+, Apple Silicon (arm64).

---

## Table of Contents

1. [Navigation](#1-navigation)
2. [Sidebar](#2-sidebar)
3. [File Pane](#3-file-pane)
4. [Dual Pane](#4-dual-pane)
5. [File Operations](#5-file-operations)
6. [Keyboard Shortcuts](#6-keyboard-shortcuts)
7. [Terminal](#7-terminal)
8. [Search](#8-search)
9. [Toolbar](#9-toolbar)
10. [Preferences](#10-preferences)
11. [Planned / In Progress](#11-planned--in-progress)

---

## 1. Navigation

| Feature | Description | Status |
|---|---|---|
| Back / Forward | Navigate history per pane — `⌘[` / `⌘]` | ✅ |
| Go Up | Navigate to parent folder — `⌘↑` | ✅ |
| Go Home | Jump to home directory — `⌘⇧H` | ✅ |
| Path Bar | Clickable breadcrumbs below toolbar, toggleable | ✅ |
| Single-click in sidebar | Navigates active pane to that folder | ✅ |
| Double-click in file pane | Opens folder / launches file | ✅ |

---

## 2. Sidebar

| Feature | Description | Status |
|---|---|---|
| Favorites section | Home, Desktop, Documents, Downloads | ✅ |
| Locations section | Macintosh HD, iCloud Drive, mounted volumes, network shares | ✅ |
| Lazy tree expansion | Children loaded on demand, spinner shown while loading | ✅ |
| Auto-expand on navigate | Tree expands and highlights current folder when pane navigates | ✅ |
| Auto-scroll to active | Active node scrolls into view when navigating | ✅ |
| Toggle expand/collapse | Chevron click expands or collapses a folder | ✅ |
| Re-expand collapsed folder | Click collapsed folder while already at its URL re-expands it | ✅ (bug fix) |
| Drag & drop files | Drag files from pane onto a sidebar folder to move them | ✅ |
| Spring loading | Hovering a dragged file over a sidebar folder for 1.2 s auto-expands it | ✅ |
| Drop highlight | Sidebar row shows accent border and tinted background when drag is over it | ✅ |
| Context menu | Right-click: Open in Pane 1, Open in Pane 2, Copy Path, Open in Terminal | ✅ |
| Volume auto-refresh | Sidebar updates when external drives are mounted / unmounted | ✅ |

---

## 3. File Pane

| Feature | Description | Status |
|---|---|---|
| Native NSTableView | AppKit table for performance and native interaction fidelity | ✅ |
| Columns | Name (icon + label), Date Modified, Size, Kind | ✅ |
| Column resizing | User can resize all columns | ✅ |
| Alternating row colors | macOS-standard zebra striping | ✅ |
| Folders first | Directories always sorted above files | ✅ |
| Hidden files | Shown at 45 % opacity when "Show Dot Files" is on | ✅ |
| Multi-selection | Click, Shift-click, ⌘-click, rubber-band drag | ✅ |
| Drag & drop source | Drag files out of the pane to move/copy them | ✅ |
| Drag & drop target | Drop files into the pane or onto a folder row | ✅ |
| Drag ghost image | Ghost always shows icon + filename, never column text | ✅ (bug fix) |
| Lazy icon loading | File icons loaded async, placeholder shown immediately | ✅ |
| Context menu | Open, Open in Pane N, Copy Path, Move to Trash | ✅ |
| Status bar | Shows item count and selected count at bottom of pane | ✅ |
| Loading / error states | Spinner while loading, error message on failure | ✅ |

---

## 4. Dual Pane

| Feature | Description | Status |
|---|---|---|
| Toggle dual pane | `⌘D` — splits the detail area into two independent panes | ✅ |
| Active pane indicator | Colored top border + tinted header + accent dot on active pane | ✅ |
| Switch active pane | Click anywhere in a pane, or `⌘1` / `⌘2` | ✅ |
| Per-pane search | Each pane header has its own search field (filters only that pane) | ✅ |
| Per-pane terminal | F4 opens/closes the terminal in the active pane only | ✅ |
| Per-pane status bar | Each pane shows its own item / selection count | ✅ |
| Per-pane path bar | Each pane shows its own breadcrumb path bar | ✅ |
| Per-pane navigation | Back/Forward/Up history is independent per pane | ✅ |
| Swap panes | Toolbar button swaps the directories of the two panes | ✅ |
| Toolbar search hidden | Global search bar is hidden in dual-pane mode (per-pane fields used instead) | ✅ |
| Go to Other Pane | Navigates active pane to the other pane's current folder | ✅ |
| Mirror Pane | Navigates the other pane to the active pane's current folder | ✅ |
| Open in Pane 1 / 2 | Sidebar and file pane context menus target the specific pane by number | ✅ |

---

## 5. File Operations

All operations work on the **active pane**. Destructive operations show a confirmation dialog.

| Operation | Trigger | Notes | Status |
|---|---|---|---|
| New File | `⌘⌥N`, Operations Bar, right-click empty space | Prompts for name, pre-filled "untitled" — creates empty file | ✅ |
| New Folder | fn F7, Operations Bar, `⌘⇧N` menu, right-click empty space | Prompts for name, pre-filled "untitled folder" | ✅ |
| Rename | `⌘R`, fn F2, triple-click, context menu, Operations Bar | Inline rename in-place — Esc to cancel, ↩ to confirm | ✅ |
| Move to Trash | `⌘⌫`, Operations Bar, File menu, context menu | No confirmation needed | ✅ |
| Copy to Other Pane | F5, Operations Bar, File menu | Dual-pane only — shows confirmation with destination path | ✅ |
| Move to Other Pane | F6, Operations Bar, File menu | Dual-pane only — shows confirmation with destination path | ✅ |
| Drag to move | Drag within pane or to sidebar | Moves file; falls back to copy on cross-volume | ✅ |
| Open file | Double-click, ↩ | Opens with default app via NSWorkspace | ✅ |
| Copy path | Context menu, sidebar context menu | Copies POSIX path to clipboard | ✅ |

### Operations Bar

A persistent bar at the bottom of the window shows the most common operations with shortcut hints.
Buttons are automatically disabled when no file is selected.

- Single pane: **Rename** (F2) · **New Folder** (F7) · **Trash** (⌘⌫)
- Dual pane adds: **Copy to Pane N** (F5) · **Move to Pane N** (F6) · **Go to Other Pane** · **Mirror Pane**

---

## 6. Keyboard Shortcuts

### Navigation

| Shortcut | Action |
|---|---|
| `⌘[` | Back |
| `⌘]` | Forward |
| `⌘↑` | Go to parent folder |
| `⌘⇧H` | Go to Home |
| `↩` | Open selected file / enter folder |

### View

| Shortcut | Action |
|---|---|
| `⌘D` | Toggle dual pane |
| `⌘⇧.` | Toggle hidden files |
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
| `⌘⇧N` | New Folder |
| `⌘R` | Rename inline (single selection) |
| `⌘⌫` | Move to Trash |
| fn F5 | Copy selection to other pane (dual-pane only) |
| fn F6 | Move selection to other pane (dual-pane only) |
| fn F7 | New Folder |

---

## 7. Terminal

| Feature | Description | Status |
|---|---|---|
| Integrated terminal drawer | Slides up from the bottom of the active pane | ✅ |
| Toggle | F4 — toggles the terminal in the active pane | ✅ |
| Auto-cd on open | Terminal changes directory to the pane's current folder when opened | ✅ |
| Auto-cd on navigate | Terminal follows pane navigation automatically | ✅ |
| Per-pane in dual mode | Each pane has its own independent terminal | ✅ |
| Full shell support | Uses user's default shell (`$SHELL`) | ✅ |
| Slide animation | Smooth ease-in/out transition when opening and closing | ✅ |

---

## 8. Search

### Default behaviour
Filters the current folder by filename as you type — instant, client-side, no network or disk access. This is intentionally the opposite of macOS Finder, which searches the whole system and looks inside file contents by default.

### Search Filter Bar
Appears automatically below the path bar whenever a search query is active. Disappears when the field is cleared.

| Control | Options | Default |
|---|---|---|
| **Scope** | This Folder · Subfolders · Home · Entire Disk | This Folder |
| **Match mode** | Name Contains · Starts With · Ends With · Exact Name · Extension | Name Contains |
| **File Kind** | Any Kind · Folder · File · Image · Video · Audio · Document · Code · Archive | Any Kind |

A **reset button** (×) appears on the right whenever any option differs from the default.

### Scope details

| Scope | How it works | Speed |
|---|---|---|
| **This Folder** | Client-side filter on already-loaded items | Instant |
| **Subfolders** | `FileManager.enumerator` recursive walk, up to 1 000 results | Fast (< 1 s) |
| **Home** | Spotlight (`NSMetadataQuery`, `NSMetadataQueryUserHomeScope`) | ~1–2 s |
| **Entire Disk** | Spotlight (`NSMetadataQueryLocalComputerScope`) | ~1–3 s |

In async scopes a spinner and result count appear in the filter bar. The "Kind" column header changes to **"Location"** and shows the parent folder name for each result, so you always know where a file lives.

### Feature table

| Feature | Status |
|---|---|
| Real-time name filter (current folder, client-side) | ✅ |
| Search filter bar with scope / match / kind controls | ✅ |
| Name Contains / Starts With / Ends With / Exact / Extension modes | ✅ |
| Kind filter: Folder · File · Image · Video · Audio · Document · Code · Archive | ✅ |
| Recursive subfolder search (FileManager, up to 1 000 results) | ✅ |
| Home-directory search via Spotlight | ✅ |
| Entire-disk search via Spotlight | ✅ |
| 300 ms debounce on async searches | ✅ |
| "Location" column shows parent folder in global search results | ✅ |
| "No Results" empty state with hint | ✅ |
| Reset button to restore default options | ✅ |
| Single-pane search bar in toolbar | ✅ |
| Per-pane search bar in dual-pane mode | ✅ |
| Search inside file contents (opt-in, not default) | 🔲 planned |

---

## 9. Toolbar

| Feature | Description | Status |
|---|---|---|
| Back / Forward buttons | Navigate pane history | ✅ |
| Go Up button | Navigate to parent | ✅ |
| Search field | Centered, adaptive (hidden in dual-pane mode) | ✅ |
| Hidden files toggle | Eye icon — persists across sessions | ✅ |
| Dual pane toggle | Grid icon — `⌘D` | ✅ |
| Swap panes button | Arrows icon — visible only in dual-pane mode | ✅ |

---

## 10. Preferences

Native macOS Settings window — open with `⌘,` or **BetterFinder → Settings…**

Stored in `AppPreferences` (`UserDefaults`-backed), persisted across sessions.

### General

| Preference | Default | Description |
|---|---|---|
| Show hidden files | `false` | Show dot files at 45 % opacity |
| Show path bar | `true` | Breadcrumb bar below toolbar |
| Show status bar | `true` | Item / selection count bar |
| Start in dual-pane mode | `false` | Open with two panes on launch |
| Open terminal by default | `false` | Show terminal drawer on launch |

### Search

| Preference | Default | Description |
|---|---|---|
| Default scope | This Folder | Which scope is pre-selected when searching |
| Default match mode | Name Contains | Which match mode is pre-selected |
| Default file kind | Any Kind | Which file kind filter is pre-selected |

### Shortcuts

All file-operation and view shortcuts are fully customisable. Click any recorder field and press the desired key combination to reassign it. Press **Esc** to cancel, **⌫** to clear. A "Reset" link restores the factory default.

| Action | Default |
|---|---|
| Rename | `⌘R` |
| New File | `⌘⌥N` |
| New Folder | `⌘⇧N` |
| Move to Trash | `⌘⌫` |
| Copy to Other Pane | `F5` |
| Move to Other Pane | `F6` |
| Toggle Hidden Files | `⌘⇧.` |
| Toggle Terminal | `F4` |
| Toggle Dual Pane | `⌘D` |

---

## 11. Planned / In Progress

Features not yet implemented, ordered by priority.

| Feature | Notes |
|---|---|
| FSEvents file watcher | Auto-refresh pane when files change on disk without manual reload |
| Column sorting | Click column headers to sort by name / date / size / kind |
| Quick Look | `Space` key preview with enhanced support for `.md`, `.json`, `.csv`, code files |
| Batch rename | Select multiple files → regex / prefix / suffix / sequential numbering |
| Folder diff & sync | Compare two panes side by side, sync in either direction |
| Size browser | Treemap visualization of disk usage for current folder |
| Git status badges | Show modified/staged/untracked indicators on files in git repos |
| Clipboard history | `⌘⇧V` popover with last N copied files |
| Permissions viewer | `rwxrwxrwx` display + quick chmod buttons in info panel |
| Tabs | Multiple browser tabs within a single window |
| Favorites editing | Drag to reorder, add/remove items in the Favorites sidebar section |
| Undo / Redo | Undo file operations (rename, move, trash) |

---

## Architecture

```
BetterFinder/
├── BetterFinderApp.swift        # Entry point, scene, menu commands, Settings scene
├── State/
│   ├── AppState.swift           # Global observable state, all file operations
│   ├── BrowserState.swift       # Per-pane navigation, selection, search state
│   └── AppPreferences.swift     # UserDefaults-backed preferences (view, startup, search, shortcuts)
├── Views/
│   ├── ContentView.swift        # Root layout: sidebar + single/dual pane
│   ├── Toolbar/                 # BrowserToolbar, search field
│   ├── Sidebar/                 # SidebarView, TreeRow
│   ├── FilePane/                # FilePaneView, FileTableView (NSTableView)
│   ├── PathBar/                 # PathBarView (breadcrumbs)
│   ├── StatusBar/               # StatusBarView (item/selection count)
│   ├── Terminal/                # TerminalPanelView, F4KeyMonitor
│   ├── Operations/              # OperationsBarView
│   ├── Search/                  # SearchFilterBar
│   └── Preferences/             # PreferencesView (3 tabs), ShortcutRecorderField
├── Models/
│   ├── FileItem.swift           # File metadata value type
│   ├── TreeNode.swift           # Sidebar tree node
│   ├── AppShortcut.swift        # Codable keyboard shortcut (keyCode + modifiers)
│   └── SearchOptions.swift      # Search scope / match mode / file kind
└── Services/
    ├── FileSystemService.swift  # Async directory loading
    ├── SearchService.swift      # Recursive + Spotlight search engine
    └── TreeController.swift     # Sidebar tree expand/collapse/flatten logic
```
