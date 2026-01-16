import Foundation
import Combine
import Carbon

/// Manages global keyboard monitoring for the hotkey
class HotkeyService: ObservableObject {
    // MARK: - Properties

    @Published private(set) var isHotkeyHeld = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Press state
    private var isCurrentlyPressed = false
    private var overlayShown = false

    // Target hotkey (configurable)
    private var targetKeyCode: CGKeyCode
    private var requiredModifiers: CGEventFlags
    private let preferencesManager: PreferencesManager

    // Hotkey mode
    private var hotkeyMode: HotkeyMode

    // MARK: - Initialization

    init(preferencesManager: PreferencesManager) {
        self.preferencesManager = preferencesManager
        let hotkey = preferencesManager.globalHotkey
        self.targetKeyCode = hotkey.cgKeyCode
        self.requiredModifiers = hotkey.cgModifiers
        self.hotkeyMode = preferencesManager.hotkeyMode
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Monitoring Control

    func startMonitoring() {
        // Check accessibility permission
        guard PermissionManager.shared.checkAccessibilityPermission() else {
            print("⚠️ Accessibility permission not granted. Cannot monitor keyboard.")
            PermissionManager.shared.showPermissionAlert()
            return
        }

        // Create event tap
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                       (1 << CGEventType.keyUp.rawValue) |
                       (1 << CGEventType.flagsChanged.rawValue)

        let selfPtr = Unmanaged.passRetained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }

                let service = Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue()
                return service.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: selfPtr
        )

        guard let eventTap = eventTap else {
            print("❌ Failed to create event tap")
            return
        }

        // Add to run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("✅ Hotkey monitoring started")
    }

    func stopMonitoring() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }

        print("🛑 Hotkey monitoring stopped")
    }

    // MARK: - Event Handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle tap being disabled
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            print("⚠️ Event tap disabled, re-enabling...")
            if let eventTap = eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            NotificationCenter.default.post(name: .eventTapDisabled, object: nil)
            return Unmanaged.passRetained(event)
        }

        // Process keyboard events
        if type == .keyDown {
            handleKeyDown(event)
        } else if type == .keyUp {
            handleKeyUp(event)
        } else if type == .flagsChanged {
            handleFlagsChanged(event)
        }

        // Pass event through to system
        return Unmanaged.passRetained(event)
    }

    private func handleKeyDown(_ event: CGEvent) {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // Handle Escape key in toggle mode to hide overlay
        if hotkeyMode == .toggle && keyCode == 53 && overlayShown {
            hideOverlay()
            return
        }

        // Check if it's our target key with correct modifiers
        guard keyCode == targetKeyCode else { return }
        guard flags.contains(.maskControl) && flags.contains(.maskAlternate) && flags.contains(.maskCommand) else { return }

        // Ignore if already processing (for hold mode)
        guard !isCurrentlyPressed else { return }

        isCurrentlyPressed = true

        switch hotkeyMode {
        case .hold:
            // Show overlay immediately on press
            triggerOverlay()
        case .toggle:
            // Toggle overlay state
            if overlayShown {
                hideOverlay()
            } else {
                triggerOverlay()
            }
        }
    }

    private func handleKeyUp(_ event: CGEvent) {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        // Check if it's our target key
        guard keyCode == targetKeyCode else { return }
        guard isCurrentlyPressed else { return }

        // Key released
        isCurrentlyPressed = false

        // In hold mode, hide overlay on key release
        // In toggle mode, do nothing (overlay stays until toggled or Esc)
        if hotkeyMode == .hold && overlayShown {
            hideOverlay()
        }
    }

    private func handleFlagsChanged(_ event: CGEvent) {
        let flags = event.flags

        // In hold mode: if modifiers are released while overlay is shown, hide it
        // In toggle mode: do nothing (user can release modifiers freely)
        if hotkeyMode == .hold && overlayShown {
            let hasRequiredModifiers = flags.contains(.maskControl) && flags.contains(.maskAlternate) && flags.contains(.maskCommand)
            if !hasRequiredModifiers {
                hideOverlay()
            }
        }
    }

    // MARK: - Overlay Control

    private func triggerOverlay() {
        guard !overlayShown else { return }

        overlayShown = true
        isHotkeyHeld = true

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .showOverlay, object: nil)
        }

        print("🎯 Hotkey held - showing overlay")
    }

    private func hideOverlay() {
        guard overlayShown else { return }

        overlayShown = false
        isHotkeyHeld = false

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .hideOverlay, object: nil)
        }

        print("🎯 Hotkey released - hiding overlay")
    }

    // MARK: - Public API

    /// Test if the hotkey would trigger with current modifiers
    func isHotkeyActive() -> Bool {
        return isCurrentlyPressed
    }

    /// Get the hotkey description
    var hotkeyDescription: String {
        return preferencesManager.globalHotkey.displayString
    }

    /// Update hotkey configuration (called when user changes settings)
    func updateHotkey(_ config: AppPreferences.HotkeyConfiguration) {
        targetKeyCode = config.cgKeyCode
        requiredModifiers = config.cgModifiers
        print("🔄 Updated hotkey to: \(config.displayString)")
    }

    /// Update hotkey mode (called when user changes settings)
    func updateHotkeyMode(_ mode: HotkeyMode) {
        hotkeyMode = mode
        print("🔄 Updated hotkey mode to: \(mode.rawValue)")
    }
}
