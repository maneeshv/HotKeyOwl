import Foundation
import Carbon

/// Application preferences model
struct AppPreferences: Codable {
    var globalHotkey: HotkeyConfiguration

    /// Hotkey configuration for the global overlay trigger
    struct HotkeyConfiguration: Codable {
        var keyCode: UInt16  // CGKeyCode as UInt16 for Codable
        var modifierFlags: UInt64  // CGEventFlags raw value for Codable
        var displayString: String

        /// Initialize from CGKeyCode and CGEventFlags
        init(keyCode: CGKeyCode, modifiers: CGEventFlags, displayString: String) {
            self.keyCode = UInt16(keyCode)
            self.modifierFlags = modifiers.rawValue
            self.displayString = displayString
        }

        /// Get CGKeyCode
        var cgKeyCode: CGKeyCode {
            return CGKeyCode(keyCode)
        }

        /// Get CGEventFlags
        var cgModifiers: CGEventFlags {
            return CGEventFlags(rawValue: modifierFlags)
        }
    }

    /// Default preferences with Ctrl+Option+Cmd+0
    static let `default` = AppPreferences(
        globalHotkey: HotkeyConfiguration(
            keyCode: 29,  // "0" key
            modifiers: [.maskControl, .maskAlternate, .maskCommand],
            displayString: "⌃⌥⌘0"
        )
    )
}
