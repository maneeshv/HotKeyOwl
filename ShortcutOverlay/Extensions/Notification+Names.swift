import Foundation

/// Custom notification names for the ShortcutOverlay app
extension Notification.Name {
    /// Posted when the global hotkey is pressed and held
    static let showOverlay = Notification.Name("com.docketai.ShortcutOverlay.showOverlay")

    /// Posted when the global hotkey is released
    static let hideOverlay = Notification.Name("com.docketai.ShortcutOverlay.hideOverlay")

    /// Posted when the event tap needs to be re-enabled
    static let eventTapDisabled = Notification.Name("com.docketai.ShortcutOverlay.eventTapDisabled")
}
