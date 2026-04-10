import SwiftUI

// MARK: - Updates Preferences Tab

// Note: UpdateManager depends on Sparkle framework. This error will resolve
// automatically when you open the project in Xcode and it downloads the SPM dependencies.

struct UpdatesPreferencesView: View {
    @Bindable var updateManager: UpdateManager

    var body: some View {
        Form {
            Section {
                Toggle("Automatically check for updates",
                       isOn: Binding(
                           get: { updateManager.automaticallyChecksForUpdates },
                           set: { updateManager.setAutomaticallyChecksForUpdates($0) }
                       ))

                Toggle("Automatically download updates",
                       isOn: Binding(
                           get: { updateManager.automaticallyDownloadsUpdates },
                           set: { updateManager.setAutomaticallyDownloadsUpdates($0) }
                       ))

                Button("Check for Updates…") {
                    updateManager.checkForUpdates()
                }
                .disabled(!updateManager.canCheckForUpdates)
            } header: {
                Text("Update Settings")
            }

            Section {
                HStack {
                    Text("Last checked:")
                    Spacer()
                    if let lastChecked = updateManager.lastUpdateCheckDate {
                        Text(lastChecked, style: .relative)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Never")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Update Status")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BetterFinder uses Sparkle for automatic updates.")
                        .font(.caption)
                    Text("Updates are signed and verified before installation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About Updates")
            }
        }
        .formStyle(.grouped)
        .padding(.top, 4)
    }
}
