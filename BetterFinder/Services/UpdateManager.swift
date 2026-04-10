import Foundation
import Sparkle
import Observation

/// Manages automatic updates using Sparkle framework
@MainActor
@Observable
final class UpdateManager {
    
    // MARK: - Properties
    
    var canCheckForUpdates = false
    var automaticallyChecksForUpdates = true
    var automaticallyDownloadsUpdates = false
    var lastUpdateCheckDate: Date?
    
    // MARK: - Private Properties
    
    @ObservationIgnored private let updaterController: SPUStandardUpdaterController
    @ObservationIgnored private var observerTokens: [Any] = []
    
    // MARK: - Initialization
    
    init() {
        // Start the updater so its state is available immediately.
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Initialize published properties from the underlying updater
        canCheckForUpdates = updaterController.updater.canCheckForUpdates
        automaticallyChecksForUpdates = updaterController.updater.automaticallyChecksForUpdates
        automaticallyDownloadsUpdates = updaterController.updater.automaticallyDownloadsUpdates

        // Observe updater changes and retain tokens for later removal
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Manually check for updates
    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
    
    /// Check for updates in background without UI
    func checkForUpdatesInBackground() {
        updaterController.updater.checkForUpdatesInBackground()
    }
    
    /// Set whether to automatically check for updates
    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
        updaterController.updater.automaticallyChecksForUpdates = enabled
        automaticallyChecksForUpdates = enabled
    }
    
    /// Set whether to automatically download updates
    func setAutomaticallyDownloadsUpdates(_ enabled: Bool) {
        updaterController.updater.automaticallyDownloadsUpdates = enabled
        automaticallyDownloadsUpdates = enabled
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe changes to updater properties using block-based observers and retain tokens
        let center = NotificationCenter.default

        let token1 = center.addObserver(forName: NSApplication.didFinishRelaunchNotification, object: nil, queue: .main) { [weak self] _ in
            // App will relaunch after update
        }

        let token2 = center.addObserver(forName: SPUUpdater.updaterDidFinishLoadingAppCastNotification, object: updaterController.updater, queue: .main) { [weak self] _ in
            self?.lastUpdateCheckDate = Date()
            // Sync canCheckForUpdates from the underlying updater in case it changed
            self?.canCheckForUpdates = self?.updaterController.updater.canCheckForUpdates ?? false
        }

        observerTokens.append(token1)
        observerTokens.append(token2)
    }
    
    deinit {
        // Remove block-based observers using stored tokens
        let center = NotificationCenter.default
        for token in observerTokens {
            center.removeObserver(token)
        }
    }
}
