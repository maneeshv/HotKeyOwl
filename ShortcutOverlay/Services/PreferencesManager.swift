import Foundation
import Combine
import Carbon

/// Manages application preferences with persistence via UserDefaults
class PreferencesManager: ObservableObject {
    // MARK: - Published Properties

    @Published var preferences: AppPreferences {
        didSet {
            save()
        }
    }

    // MARK: - Private Properties

    private let defaults = UserDefaults.standard
    private let preferencesKey = "appPreferences"

    // MARK: - Initialization

    init() {
        // Load from UserDefaults or use default
        if let data = defaults.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(AppPreferences.self, from: data) {
            self.preferences = decoded
            print("✅ Loaded preferences from UserDefaults")
        } else {
            self.preferences = .default
            print("ℹ️ Using default preferences")
        }
    }

    // MARK: - Public Methods

    /// Save current preferences to UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            defaults.set(encoded, forKey: preferencesKey)
            print("✅ Saved preferences to UserDefaults")
        } else {
            print("❌ Failed to encode preferences")
        }
    }

    /// Reset preferences to default values
    func reset() {
        preferences = .default
        print("🔄 Reset preferences to default")
    }

    /// Update the global hotkey
    func updateGlobalHotkey(_ config: AppPreferences.HotkeyConfiguration) {
        preferences.globalHotkey = config
    }

    /// Get the current global hotkey configuration
    var globalHotkey: AppPreferences.HotkeyConfiguration {
        return preferences.globalHotkey
    }

    /// Validate hotkey configuration
    func validate(keyCode: CGKeyCode, modifiers: CGEventFlags) -> Bool {
        // Must have at least one modifier or be a function key (F1-F12)
        let hasModifiers = modifiers.contains(.maskCommand) ||
                          modifiers.contains(.maskControl) ||
                          modifiers.contains(.maskAlternate) ||
                          modifiers.contains(.maskShift)

        let isFunctionKey = (keyCode >= 122 && keyCode <= 133)  // F1-F12 keys

        return hasModifiers || isFunctionKey
    }

    /// Check if a hotkey combination is a reserved system shortcut
    func isSystemShortcut(keyCode: CGKeyCode, modifiers: CGEventFlags) -> Bool {
        // Common system shortcuts to avoid
        let commandOnly = modifiers.contains(.maskCommand) &&
                         !modifiers.contains(.maskControl) &&
                         !modifiers.contains(.maskAlternate) &&
                         !modifiers.contains(.maskShift)

        if commandOnly {
            // Q (Quit), W (Close Window), Tab (App Switcher), H (Hide)
            let reservedKeys: Set<CGKeyCode> = [12, 13, 48, 4]  // Q, W, Tab, H
            return reservedKeys.contains(keyCode)
        }

        return false
    }
}
