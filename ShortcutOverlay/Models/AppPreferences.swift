import Foundation
import Carbon

/// Hotkey activation mode
enum HotkeyMode: String, Codable, CaseIterable {
    case hold = "hold"      // Show while holding, hide on release
    case toggle = "toggle"  // Press to show, press again or Esc to hide
}

/// Appearance preference for the app
enum AppearanceMode: String, Codable, CaseIterable {
    case automatic = "automatic"
    case light = "light"
    case dark = "dark"
}

/// Application preferences model
struct AppPreferences: Codable {
    var globalHotkey: HotkeyConfiguration
    var hotkeyMode: HotkeyMode
    var appearanceMode: AppearanceMode
    var lastModified: Date

    private enum CodingKeys: String, CodingKey {
        case globalHotkey
        case hotkeyMode
        case appearanceMode
        case lastModified
    }

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

    /// Initialize with hotkey, mode, appearance, and current timestamp
    init(
        globalHotkey: HotkeyConfiguration,
        hotkeyMode: HotkeyMode = .hold,
        appearanceMode: AppearanceMode = .automatic,
        lastModified: Date = Date()
    ) {
        self.globalHotkey = globalHotkey
        self.hotkeyMode = hotkeyMode
        self.appearanceMode = appearanceMode
        self.lastModified = lastModified
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        globalHotkey = try container.decode(HotkeyConfiguration.self, forKey: .globalHotkey)
        hotkeyMode = try container.decodeIfPresent(HotkeyMode.self, forKey: .hotkeyMode) ?? .hold
        appearanceMode = try container.decodeIfPresent(AppearanceMode.self, forKey: .appearanceMode) ?? .automatic
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(globalHotkey, forKey: .globalHotkey)
        try container.encode(hotkeyMode, forKey: .hotkeyMode)
        try container.encode(appearanceMode, forKey: .appearanceMode)
        try container.encode(lastModified, forKey: .lastModified)
    }

    /// Default preferences with Ctrl+Option+Cmd+0
    static let `default` = AppPreferences(
        globalHotkey: HotkeyConfiguration(
            keyCode: 29,  // "0" key
            modifiers: [.maskControl, .maskAlternate, .maskCommand],
            displayString: "⌃⌥⌘0"
        ),
        appearanceMode: .automatic,
        lastModified: Date()
    )
}
