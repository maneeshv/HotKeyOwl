import Foundation
import AppKit
import Combine

/// Monitors the frontmost (active) application
class AppMonitorService: ObservableObject {
    @Published private(set) var currentApp: AppInfo?

    private var workspace: NSWorkspace

    init() {
        workspace = NSWorkspace.shared
    }

    // MARK: - Monitoring

    func startMonitoring() {
        // Get initial frontmost app
        updateCurrentApp()

        // Observe app activation
        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    func stopMonitoring() {
        workspace.notificationCenter.removeObserver(self)
    }

    // MARK: - Private

    @objc private func appDidActivate(_ notification: Notification) {
        updateCurrentApp()
    }

    private func updateCurrentApp() {
        guard let frontmost = workspace.frontmostApplication else {
            currentApp = nil
            return
        }

        currentApp = AppInfo.from(runningApp: frontmost)
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Utility

    /// Get all running applications (filtered to regular apps)
    var runningApps: [AppInfo] {
        workspace.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { AppInfo.from(runningApp: $0) }
            .sorted { $0.name < $1.name }
    }
}
