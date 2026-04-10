import Foundation
import AppKit

let bundle = "com.apple.Terminal"
if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) {
    let config = NSWorkspace.OpenConfiguration()
    config.createsNewApplicationInstance = false
    NSWorkspace.shared.open([URL(fileURLWithPath: "/tmp")], withApplicationAt: appURL, configuration: config) { _, error in
        if let error = error { print("Error: \(error)") }
        else { print("Success") }
        exit(0)
    }
} else {
    print("Not found")
    exit(1)
}
RunLoop.main.run()
