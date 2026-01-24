import Foundation

/// Custom notification names for the ShortcutOverlay app
extension Notification.Name {
    /// Posted when the global hotkey is pressed and held
    static let showOverlay = Notification.Name("com.docketai.HotKeyOwl.showOverlay")

    /// Posted when the global hotkey is released
    static let hideOverlay = Notification.Name("com.docketai.HotKeyOwl.hideOverlay")

    // MARK: - iCloud Sync Notifications

    /// Posted when the iCloud sync state changes
    static let iCloudSyncStateDidChange = Notification.Name("com.docketai.HotKeyOwl.iCloudSyncStateDidChange")

    /// Posted when preferences are updated from iCloud
    static let preferencesDidChangeRemotely = Notification.Name("com.docketai.HotKeyOwl.preferencesDidChangeRemotely")

    /// Posted when shortcuts are updated from iCloud
    static let shortcutsDidChangeRemotely = Notification.Name("com.docketai.HotKeyOwl.shortcutsDidChangeRemotely")

    /// Posted when the user requests to open the shortcut editor from the overlay
    static let openEditorFromOverlay = Notification.Name("com.docketai.HotKeyOwl.openEditorFromOverlay")
}
