import Foundation
import AppKit
import Combine

/// Monitors the frontmost (active) application
class AppMonitorService: ObservableObject {
    @Published private(set) var currentApp: AppInfo?

    private let workspace: NSWorkspace
    private var cachedRunningApps: [AppInfo] = []

    init() {
        workspace = NSWorkspace.shared
        refreshRunningApps()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        // Get initial frontmost app
        updateCurrentApp()
        refreshRunningApps()

        // Observe app activation
        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )

        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(appDidTerminate(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
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

    @objc private func appDidLaunch(_ notification: Notification) {
        refreshRunningApps()
    }

    @objc private func appDidTerminate(_ notification: Notification) {
        refreshRunningApps()
    }

    private func updateCurrentApp() {
        guard let frontmost = workspace.frontmostApplication else {
            currentApp = nil
            return
        }

        currentApp = AppInfo.from(runningApp: frontmost)
    }

    private func refreshRunningApps() {
        cachedRunningApps = workspace.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { AppInfo.from(runningApp: $0) }
            .sorted { $0.name < $1.name }
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Utility

    /// Get all running applications (filtered to regular apps)
    var runningApps: [AppInfo] {
        cachedRunningApps
    }
}
