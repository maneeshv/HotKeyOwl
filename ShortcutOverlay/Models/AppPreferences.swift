import Foundation
import Carbon

/// Hotkey activation mode
enum HotkeyMode: String, Codable, CaseIterable {
    case hold = "hold"      // Show while holding, hide on release
    case toggle = "toggle"  // Press to show, press again or Esc to hide
}

/// Application preferences model
struct AppPreferences: Codable {
    var globalHotkey: HotkeyConfiguration
    var hotkeyMode: HotkeyMode
    var lastModified: Date

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

    /// Initialize with hotkey, mode, and current timestamp
    init(globalHotkey: HotkeyConfiguration, hotkeyMode: HotkeyMode = .hold, lastModified: Date = Date()) {
        self.globalHotkey = globalHotkey
        self.hotkeyMode = hotkeyMode
        self.lastModified = lastModified
    }

    /// Default preferences with Ctrl+Option+Cmd+0
    static let `default` = AppPreferences(
        globalHotkey: HotkeyConfiguration(
            keyCode: 29,  // "0" key
            modifiers: [.maskControl, .maskAlternate, .maskCommand],
            displayString: "⌃⌥⌘0"
        ),
        lastModified: Date()
    )
}
