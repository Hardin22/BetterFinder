import Foundation
import AppKit

extension AppPreferences {
    enum ExternalTerminal: String, CaseIterable {
        case terminal = "Terminal"
        case iTerm2 = "iTerm"
        case warp = "Warp"
        case ghostty = "Ghostty"
        case wezterm = "WezTerm"
        case alacritty = "Alacritty"

        var label: String { rawValue }

        var bundleIdentifier: String {
            switch self {
            case .terminal: return "com.apple.Terminal"
            case .iTerm2: return "com.googlecode.iterm2"
            case .warp: return "dev.warp.Warp-Stable"
            case .ghostty: return "com.mitchellh.ghostty"
            case .wezterm: return "com.github.wez.wezterm"
            case .alacritty: return "org.alacritty"
            }
        }

        func open(url: URL) {
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
                // Fallback to default terminal if the requested app is not installed
                if self != .terminal {
                    ExternalTerminal.terminal.open(url: url)
                } else {
                    NSWorkspace.shared.open(url)
                }
                return
            }

            let config = NSWorkspace.OpenConfiguration()
            config.createsNewApplicationInstance = false
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: config) { _, error in
                if let error = error {
                    print("Failed to open \(label): \(error.localizedDescription)")
                }
            }
        }
    }
}
