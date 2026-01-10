import Foundation

/// Custom notification names for the ShortcutOverlay app
extension Notification.Name {
    /// Posted when the global hotkey is pressed and held
    static let showOverlay = Notification.Name("com.docketai.HotKeyOwl.showOverlay")

    /// Posted when the global hotkey is released
    static let hideOverlay = Notification.Name("com.docketai.HotKeyOwl.hideOverlay")

    /// Posted when the event tap needs to be re-enabled
    static let eventTapDisabled = Notification.Name("com.docketai.HotKeyOwl.eventTapDisabled")

    // MARK: - iCloud Sync Notifications

    /// Posted when the iCloud sync state changes
    static let iCloudSyncStateDidChange = Notification.Name("com.docketai.HotKeyOwl.iCloudSyncStateDidChange")

    /// Posted when preferences are updated from iCloud
    static let preferencesDidChangeRemotely = Notification.Name("com.docketai.HotKeyOwl.preferencesDidChangeRemotely")

    /// Posted when shortcuts are updated from iCloud
    static let shortcutsDidChangeRemotely = Notification.Name("com.docketai.HotKeyOwl.shortcutsDidChangeRemotely")
}
