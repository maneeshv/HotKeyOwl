import Foundation
import ServiceManagement

/// Manages the Launch at Login functionality using SMAppService
class LaunchAtLoginService {
    static let shared = LaunchAtLoginService()

    private init() {}

    /// Returns whether the app is currently registered to launch at login
    /// Always reads from SMAppService to reflect actual system state
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Enable or disable launch at login
    /// - Parameter enabled: Whether the app should launch at login
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }
}
