import Foundation
import AppKit

/// Information about an application
struct AppInfo: Identifiable {
    private static let iconCache = NSCache<NSString, NSImage>()

    let id: String                     // Bundle identifier
    let bundleIdentifier: String
    let name: String
    let icon: NSImage?

    init(bundleIdentifier: String, name: String, icon: NSImage? = nil) {
        self.id = bundleIdentifier
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.icon = icon
    }

    /// Creates AppInfo from an NSRunningApplication
    static func from(runningApp: NSRunningApplication) -> AppInfo? {
        guard let bundleId = runningApp.bundleIdentifier,
              let name = runningApp.localizedName else {
            return nil
        }

        return AppInfo(
            bundleIdentifier: bundleId,
            name: name,
            icon: runningApp.icon
        )
    }

    /// Get icon for an application by bundle identifier
    static func icon(for bundleIdentifier: String) -> NSImage? {
        if let cached = iconCache.object(forKey: bundleIdentifier as NSString) {
            return cached
        }

        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            iconCache.setObject(icon, forKey: bundleIdentifier as NSString)
            return icon
        }

        return nil
    }
}
