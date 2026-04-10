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
    
    // MARK: - Initialization
    
    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        // Initialize published properties
        canCheckForUpdates = updaterController.updater.canCheckForUpdates
        automaticallyChecksForUpdates = updaterController.updater.automaticallyChecksForUpdates
        automaticallyDownloadsUpdates = updaterController.updater.automaticallyDownloadsUpdates
        
        // Observe updater changes
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
        // Observe changes to updater properties
        NotificationCenter.default.addObserver(
            forName: .SUUpdaterDidRelaunchApplication,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // App will relaunch after update
        }
        
        NotificationCenter.default.addObserver(
            forName: .SUUpdaterDidFinishLoadingAppcast,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastUpdateCheckDate = Date()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let SUUpdaterDidRelaunchApplication = Notification.Name("SUUpdaterDidRelaunchApplication")
    static let SUUpdaterDidFinishLoadingAppcast = Notification.Name("SUUpdaterDidFinishLoadingAppcast")
}
