//
//  BetterFinderTests.swift
//  BetterFinderTests
//
//  Created by Francesco Albano on 26/03/26.
//

import XCTest
@testable import BetterFinder

struct BetterFinderTests {
    
    @Test func testAppShortcutToggleTerminal() throws {
        let shortcut = AppShortcut.toggleTerminal
        #expect(shortcut.keyCode == 118)
        #expect(shortcut.modifiers == 0)
        #expect(shortcut.displayString == "F4")
    }
    
    @Test func testAppShortcutClearTerminal() throws {
        let shortcut = AppShortcut.clearTerminal
        #expect(shortcut.keyCode == 40)
        #expect(shortcut.modifiers == 1048576)
        #expect(shortcut.displayString == "⌘K")
    }
    
    @Test func testAppShortcutFocusTerminal() throws {
        let shortcut = AppShortcut.focusTerminal
        #expect(shortcut.keyCode == 17)
        #expect(shortcut.modifiers == 1048640)
        #expect(shortcut.displayString == "⌘⇧T")
    }
    
    @Test func testAppShortcutMatching() throws {
        let toggleTerminal = AppShortcut.toggleTerminal
        let clearTerminal = AppShortcut.clearTerminal
        
        let toggleEvent = createMockEvent(keyCode: 118, modifiers: 0)
        let clearEvent = createMockEvent(keyCode: 40, modifiers: 1048576)
        
        #expect(toggleTerminal.matches(toggleEvent))
        #expect(!toggleTerminal.matches(clearEvent))
        #expect(clearTerminal.matches(clearEvent))
        #expect(!clearTerminal.matches(toggleEvent))
    }
    
    @Test func testExternalTerminalBundleIdentifiers() throws {
        #expect(AppPreferences.ExternalTerminal.terminal.bundleIdentifier == "com.apple.Terminal")
        #expect(AppPreferences.ExternalTerminal.iTerm2.bundleIdentifier == "com.googlecode.iterm2")
        #expect(AppPreferences.ExternalTerminal.warp.bundleIdentifier == "dev.warp.Warp-Stable")
        #expect(AppPreferences.ExternalTerminal.ghostty.bundleIdentifier == "com.mitchellh.ghostty")
        #expect(AppPreferences.ExternalTerminal.wezterm.bundleIdentifier == "com.github.wez.wezterm")
        #expect(AppPreferences.ExternalTerminal.alacritty.bundleIdentifier == "org.alacritty")
    }
    
    @Test func testExternalTerminalLabels() throws {
        #expect(AppPreferences.ExternalTerminal.terminal.label == "Terminal")
        #expect(AppPreferences.ExternalTerminal.iTerm2.label == "iTerm")
        #expect(AppPreferences.ExternalTerminal.warp.label == "Warp")
        #expect(AppPreferences.ExternalTerminal.ghostty.label == "Ghostty")
        #expect(AppPreferences.ExternalTerminal.wezterm.label == "WezTerm")
        #expect(AppPreferences.ExternalTerminal.alacritty.label == "Alacritty")
    }
    
    @Test func testShellTypeDisplayName() throws {
        #expect(ShellType.zsh.displayName == "zsh")
        #expect(ShellType.bash.displayName == "bash")
        #expect(ShellType.fish.displayName == "fish")
        #expect(ShellType.other("custom").displayName == "custom")
    }
    
    @Test func testShellTypeEquatable() throws {
        #expect(ShellType.zsh == ShellType.zsh)
        #expect(ShellType.zsh != ShellType.bash)
        #expect(ShellType.bash == ShellType.bash)
        #expect(ShellType.fish == ShellType.fish)
        #expect(ShellType.other("test") == ShellType.other("test"))
    }
    
    @Test func testAppPreferencesDefaults() throws {
        let prefs = AppPreferences()
        
        #expect(prefs.showHiddenFiles == false)
        #expect(prefs.foldersFirst == false)
        #expect(prefs.viewMode == .list)
        #expect(prefs.showPathBar == true)
        #expect(prefs.showStatusBar == true)
        #expect(prefs.startInDualPane == false)
        #expect(prefs.openTerminalByDefault == false)
        #expect(prefs.externalTerminal == .terminal)
        #expect(prefs.showPreviewPanel == false)
        #expect(prefs.maxRecentFolders == 10)
    }
    
    @Test func testAppPreferencesShortcuts() throws {
        let prefs = AppPreferences()
        
        #expect(prefs.shortcutToggleTerminal == .toggleTerminal)
        #expect(prefs.shortcutClearTerminal == .clearTerminal)
        #expect(prefs.shortcutFocusTerminal == .focusTerminal)
        #expect(prefs.shortcutToggleDualPane == .toggleDualPane)
    }
    
    @Test func testAppShortcutDisplayStrings() throws {
        #expect(AppShortcut.toggleTerminal.displayString == "F4")
        #expect(AppShortcut.clearTerminal.displayString == "⌘K")
        #expect(AppShortcut.focusTerminal.displayString == "⌘⇧T")
        #expect(AppShortcut.toggleDualPane.displayString == "⌘D")
    }
    
    @Test func testAppShortcutMenuKeyEquivalent() throws {
        #expect(AppShortcut.toggleTerminal.menuKeyEquivalent == "")
        #expect(AppShortcut.clearTerminal.menuKeyEquivalent == "k")
        #expect(AppShortcut.focusTerminal.menuKeyEquivalent == "t")
        #expect(AppShortcut.toggleDualPane.menuKeyEquivalent == "d")
    }
    
    @Test func testAppShortcutMenuModifierMask() throws {
        #expect(AppShortcut.toggleTerminal.menuModifierMask.rawValue == 0)
        #expect(AppShortcut.clearTerminal.menuModifierMask.rawValue == 1048576)
        #expect(AppShortcut.focusTerminal.menuModifierMask.rawValue == 1048640)
        #expect(AppShortcut.toggleDualPane.menuModifierMask.rawValue == 1048576)
    }
    
    private func createMockEvent(keyCode: UInt16, modifiers: UInt) -> NSEvent {
        return NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint(x: 0, y: 0),
            modifierFlags: NSEvent.ModifierFlags(rawValue: modifiers),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: keyCode
        )!
    }
}