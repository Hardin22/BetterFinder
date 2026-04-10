import SwiftUI
import AppKit

struct TerminalSetupView: View {
    let browser: BrowserState
    
    @State private var isInstallingHomebrew = false
    @State private var isInstallingAutocomplete = false
    @State private var isInstallingCopilot = false

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
                    action: {
                        installHomebrew()
                    }
                )
                
                ToolRow(
                    title: "Zsh Autocomplete",
                    description: "Fish-like fast/unobtrusive autosuggestions for zsh.",
                    icon: "text.cursor",
                    isWorking: isInstallingAutocomplete,
                    action: {
                        installAutocomplete()
                    }
                )
                
                ToolRow(
                    title: "Claude Code",
                    description: "An AI coding assistant right in your terminal.",
                    icon: "sparkles",
                    isWorking: isInstallingCopilot,
                    action: {
                        installCopilot()
                    }
                )
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: 320)
    }
    
    private func installHomebrew() {
        isInstallingHomebrew = true
        let script = "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        browser.terminalSendText?(script + "\r")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isInstallingHomebrew = false
        }
    }
    
    private func installAutocomplete() {
        isInstallingAutocomplete = true
        // Clone the zsh-autosuggestions repo to .zsh/zsh-autosuggestions and add to .zshrc
        let script = "git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions && echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc && source ~/.zshrc"
        browser.terminalSendText?(script + "\r")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isInstallingAutocomplete = false
        }
    }
    
    private func installCopilot() {
        isInstallingCopilot = true
        let script = "npm install -g @anthropic-ai/claude-code"
        browser.terminalSendText?(script + "\r")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isInstallingCopilot = false
        }
    }
}

private struct ToolRow: View {
    let title: String
    let description: String
    let icon: String
    let isWorking: Bool
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
