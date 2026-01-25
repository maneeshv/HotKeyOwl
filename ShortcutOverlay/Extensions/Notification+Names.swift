import Foundation

/// Custom notification names for the ShortcutOverlay app
extension Notification.Name {
    /// Posted when the global hotkey is pressed and held
    static let showOverlay = Notification.Name("io.hotkeyowl.HotKeyOwl.showOverlay")

    /// Posted when the global hotkey is released
    static let hideOverlay = Notification.Name("io.hotkeyowl.HotKeyOwl.hideOverlay")

    // MARK: - iCloud Sync Notifications

    /// Posted when the iCloud sync state changes
    static let iCloudSyncStateDidChange = Notification.Name("io.hotkeyowl.HotKeyOwl.iCloudSyncStateDidChange")

    /// Posted when preferences are updated from iCloud
    static let preferencesDidChangeRemotely = Notification.Name("io.hotkeyowl.HotKeyOwl.preferencesDidChangeRemotely")

    /// Posted when shortcuts are updated from iCloud
    static let shortcutsDidChangeRemotely = Notification.Name("io.hotkeyowl.HotKeyOwl.shortcutsDidChangeRemotely")

    /// Posted when the user requests to open the shortcut editor from the overlay
    static let openEditorFromOverlay = Notification.Name("io.hotkeyowl.HotKeyOwl.openEditorFromOverlay")
}
