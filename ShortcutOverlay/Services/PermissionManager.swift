import Foundation
import AppKit
import ApplicationServices

/// Manages accessibility permission checks and requests
class PermissionManager {
    static let shared = PermissionManager()

    private init() {}

    // MARK: - Permission Checks

    /// Check if the app has accessibility permission (without prompting)
    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Request accessibility permission (will show system prompt)
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Check permission and request if not granted
    @discardableResult
    func ensureAccessibilityPermission() -> Bool {
        if checkAccessibilityPermission() {
            return true
        } else {
            requestAccessibilityPermission()
            return false
        }
    }

    // MARK: - User Guidance

    /// Show alert explaining why permission is needed
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Permission Required"
        alert.informativeText = """
        \(AppConstants.appName) needs Accessibility permission to monitor keyboard input \
        for the global hotkey.

        Please grant permission in:
        System Settings > Privacy & Security > Accessibility

        The app will need to restart after granting permission.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openSystemSettings()
        }
    }

    /// Show alert when permission is denied and hotkey won't work
    func showPermissionDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Not Granted"
        alert.informativeText = """
        Without Accessibility permission, \(AppConstants.appName) cannot detect the \
        global hotkey.

        You can still use the app to manage shortcuts, but the overlay won't \
        appear automatically.

        To enable the hotkey:
        1. Open System Settings > Privacy & Security > Accessibility
        2. Enable \(AppConstants.appName)
        3. Restart the app
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Continue Without Hotkey")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openSystemSettings()
        }
    }

    // MARK: - System Settings

    /// Open System Settings to Accessibility privacy pane
    private func openSystemSettings() {
        // macOS 13+ uses new System Settings app
        if #available(macOS 13.0, *) {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        } else {
            // Fallback for older versions
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Helper

    /// Get current permission status as string
    var permissionStatus: String {
        checkAccessibilityPermission() ? "Granted" : "Not Granted"
    }
}
