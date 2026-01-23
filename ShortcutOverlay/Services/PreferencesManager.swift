import Foundation
import Combine
import Carbon

/// Manages application preferences with persistence via UserDefaults
class PreferencesManager: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var preferences: AppPreferences

    // MARK: - Private Properties

    private let defaults = UserDefaults.standard
    private let preferencesKey = "appPreferences"
    private let persistence: PreferencesPersistence
    private let saveDebounceInterval: TimeInterval = 0.4

    // MARK: - iCloud Sync Integration

    /// Reference to the sync service (set by AppDelegate)
    weak var syncService: iCloudSyncService?

    /// Flag to prevent triggering sync during remote update
    private var isApplyingRemote = false

    // MARK: - Initialization

    init() {
        persistence = PreferencesPersistence(defaults: defaults, key: preferencesKey)

        // Load from UserDefaults or use default
        if let data = defaults.data(forKey: preferencesKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode(AppPreferences.self, from: data) {
                self.preferences = decoded
                print("✅ Loaded preferences from UserDefaults")
            } else {
                self.preferences = .default
                print("ℹ️ Using default preferences (decode failed)")
            }
        } else {
            self.preferences = .default
            print("ℹ️ Using default preferences")
        }
    }

    // MARK: - Public Methods

    /// Save current preferences to UserDefaults
    func save() {
        let shouldSync = !isApplyingRemote
        let preferencesToSave = preferences

        Task { [weak self] in
            guard let self else { return }

            do {
                let outcome = try await persistence.scheduleSave(
                    preferencesToSave,
                    debounceInterval: saveDebounceInterval
                )

                if outcome == .saved, shouldSync {
                    await MainActor.run {
                        self.syncService?.syncPreferencesToCloud()
                    }
                }
            } catch {
                print("❌ Failed to encode preferences: \(error)")
            }
        }
    }

    /// Apply preferences received from iCloud
    func applyRemotePreferences(_ remotePreferences: AppPreferences) {
        isApplyingRemote = true
        preferences = remotePreferences
        save()
        isApplyingRemote = false
        print("☁️ Applied remote preferences")
    }

    /// Reset preferences to default values
    func reset() {
        preferences = .default
        save()
        print("🔄 Reset preferences to default")
    }

    /// Update the global hotkey
    func updateGlobalHotkey(_ config: AppPreferences.HotkeyConfiguration) {
        updatePreferences { current in
            current.globalHotkey = config
        }
    }

    /// Update the hotkey mode
    func updateHotkeyMode(_ mode: HotkeyMode) {
        updatePreferences { current in
            current.hotkeyMode = mode
        }
    }

    /// Update the appearance mode
    func updateAppearanceMode(_ mode: AppearanceMode) {
        updatePreferences { current in
            current.appearanceMode = mode
        }
    }

    /// Update multiple preferences at once
    func updatePreferences(_ update: (inout AppPreferences) -> Void) {
        var updated = preferences
        update(&updated)
        if !isApplyingRemote {
            updated.lastModified = Date()
        }
        preferences = updated
        save()
    }

    /// Get the current global hotkey configuration
    var globalHotkey: AppPreferences.HotkeyConfiguration {
        return preferences.globalHotkey
    }

    /// Get the current hotkey mode
    var hotkeyMode: HotkeyMode {
        return preferences.hotkeyMode
    }

    /// Get the current appearance mode
    var appearanceMode: AppearanceMode {
        return preferences.appearanceMode
    }

    /// Validate hotkey configuration
    func validate(keyCode: CGKeyCode, modifiers: CGEventFlags) -> Bool {
        let modifierMasks: [CGEventFlags] = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
        let hasModifiers = modifierMasks.contains { modifiers.contains($0) }
        let isFunctionKey = (122...133).contains(keyCode)  // F1-F12 keys

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
