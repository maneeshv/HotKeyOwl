import Foundation
import Carbon

/// Appearance preference for the app
enum AppearanceMode: String, Codable, CaseIterable {
    case automatic = "automatic"
    case light = "light"
    case dark = "dark"
}

/// Application preferences model
struct AppPreferences: Codable {
    var globalHotkey: HotkeyConfiguration
    var appearanceMode: AppearanceMode
    var lastModified: Date

    private enum CodingKeys: String, CodingKey {
        case globalHotkey
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

    /// Initialize with hotkey, appearance, and current timestamp
    init(
        globalHotkey: HotkeyConfiguration,
        appearanceMode: AppearanceMode = .automatic,
        lastModified: Date = Date()
    ) {
        self.globalHotkey = globalHotkey
        self.appearanceMode = appearanceMode
        self.lastModified = lastModified
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        globalHotkey = try container.decode(HotkeyConfiguration.self, forKey: .globalHotkey)
        appearanceMode = try container.decodeIfPresent(AppearanceMode.self, forKey: .appearanceMode) ?? .automatic
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(globalHotkey, forKey: .globalHotkey)
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
