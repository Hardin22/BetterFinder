import SwiftUI
import AppKit
import Foundation

struct TerminalSetupView: View {
    let browser: BrowserState
    
    @State private var isInstallingHomebrew = false
    @State private var isInstallingAutocomplete = false
    @State private var isInstallingKilocode = false
    
    @State private var isHomebrewInstalled = false
    @State private var isAutocompleteInstalled = false
    @State private var isKilocodeInstalled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Terminal Extras")
                .font(.headline)
            
            Text("Enhance your integrated terminal with these essential developer tools.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                ToolRow(
                    title: "Homebrew",
                    description: "The missing package manager for macOS.",
                    icon: "cup.and.saucer",
                    isWorking: isInstallingHomebrew,
                    isInstalled: isHomebrewInstalled,
                    action: {
                        installHomebrew()
                    }
                )
                
                ToolRow(
                    title: "Zsh Autocomplete",
                    description: "Fish-like fast/unobtrusive autosuggestions for zsh.",
                    icon: "text.cursor",
                    isWorking: isInstallingAutocomplete,
                    isInstalled: isAutocompleteInstalled,
                    action: {
                        installAutocomplete()
                    }
                )
                
                ToolRow(
                    title: "Kilocode CLI",
                    description: "Open-source AI coding assistant for your terminal.",
                    icon: "sparkles",
                    isWorking: isInstallingKilocode,
                    isInstalled: isKilocodeInstalled,
                    action: {
                        installKilocode()
                    }
                )
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            checkInstalledTools()
        }
    }
    
    private func checkInstalledTools() {
        isHomebrewInstalled = checkCommandExists("brew")
        isAutocompleteInstalled = checkAutocompleteInstalled()
        isKilocodeInstalled = checkCommandExists("kilocode")
    }
    
    private func checkAutocompleteInstalled() -> Bool {
        // Check manual installation
        if checkDirectoryExists("~/.zsh/zsh-autosuggestions") {
            return true
        }
        
        // Check Homebrew installation
        let homebrewPaths = [
            "/opt/homebrew/share/zsh-autosuggestions",
            "/usr/local/share/zsh-autosuggestions",
            "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh",
            "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
        ]
        
        return homebrewPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) != nil
    }
    
    private func checkCommandExists(_ command: String) -> Bool {
        // First try with which
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = [command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                return true
            }
        } catch {
            // Fall through to alternative checks
        }
        
        // If which failed, try common installation paths
        switch command {
        case "brew":
            // Check common Homebrew locations
            let paths = [
                "/opt/homebrew/bin/brew",
                "/usr/local/bin/brew",
                "/usr/bin/brew"
            ]
            return paths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) != nil
            
        case "kilocode":
            // Check common npm global locations
            let paths = [
                "/opt/homebrew/bin/kilocode",
                "/usr/local/bin/kilocode",
                "/usr/bin/kilocode"
            ]
            return paths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) != nil
            
        default:
            return false
        }
    }
    
    private func checkDirectoryExists(_ path: String) -> Bool {
        let expandedPath = NSString(string: path).expandingTildeInPath
        return FileManager.default.fileExists(atPath: expandedPath)
    }
    
    private func installHomebrew() {
        isInstallingHomebrew = true
        let script = "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        browser.terminalSendText?(script + "\r")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isInstallingHomebrew = false
            checkInstalledTools()
        }
    }
    
    private func installAutocomplete() {
        isInstallingAutocomplete = true
        // Try Homebrew first, fall back to manual installation
        let script = "brew install zsh-autosuggestions 2>/dev/null || (git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions && echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc && source ~/.zshrc)"
        browser.terminalSendText?(script + "\r")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isInstallingAutocomplete = false
            checkInstalledTools()
        }
    }
    
    private func installKilocode() {
        isInstallingKilocode = true
        // Install Kilocode CLI via npm
        let script = "npm install -g @kilocode/cli"
        browser.terminalSendText?(script + "\r")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isInstallingKilocode = false
            checkInstalledTools()
        }
    }
}

private struct ToolRow: View {
    let title: String
    let description: String
    let icon: String
    let isWorking: Bool
    let isInstalled: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(description).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isInstalled {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Installed")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.green)
            } else {
                Button {
                    action()
                } label: {
                    if isWorking {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Install")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.accentColor.opacity(0.05) : Color.clear)
        )
        .onHover { hover in
            isHovering = hover
        }
    }
}