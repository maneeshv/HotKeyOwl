import Foundation
import Combine
import Carbon

/// Manages global keyboard monitoring for the hotkey
class HotkeyService: ObservableObject {
    // MARK: - Properties

    @Published private(set) var isHotkeyHeld = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var eventTapThread: Thread?
    private var eventTapRunLoop: CFRunLoop?

    // Press state
    private var isCurrentlyPressed = false
    private var overlayShown = false

    // Target hotkey (configurable)
    private var targetKeyCode: CGKeyCode
    private var requiredModifiers: CGEventFlags
    private let preferencesManager: PreferencesManager

    // Hotkey mode
    private var hotkeyMode: HotkeyMode

    // Debouncing to prevent rapid triggers that can freeze the system
    private var lastTriggerTime: Date = .distantPast
    private let minimumTriggerInterval: TimeInterval = 0.3

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
        // Guard against repeated calls - clean up existing tap first
        if eventTap != nil {
            print("⚠️ Event tap already exists, stopping before restart")
            stopMonitoring()
        }

        // Check accessibility permission
        guard PermissionManager.shared.checkAccessibilityPermission() else {
            print("⚠️ Accessibility permission not granted. Cannot monitor keyboard.")
            PermissionManager.shared.showPermissionAlert()
            return
        }

        let thread = Thread { [weak self] in
            guard let self else { return }

            // Create event tap
            let eventMask = (1 << CGEventType.keyDown.rawValue) |
                           (1 << CGEventType.keyUp.rawValue) |
                           (1 << CGEventType.flagsChanged.rawValue)

            // Use passUnretained since HotkeyService is a singleton that lives for app lifetime
            // Using passRetained would create a memory leak as stopMonitoring() doesn't release it
            let selfPtr = Unmanaged.passUnretained(self).toOpaque()

            self.eventTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(eventMask),
                callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                    guard let refcon = refcon else {
                        return Unmanaged.passUnretained(event)
                    }

                    let service = Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue()
                    return service.handleEvent(proxy: proxy, type: type, event: event)
                },
                userInfo: selfPtr
            )

            guard let eventTap = self.eventTap else {
                print("❌ Failed to create event tap")
                return
            }

            // Add to run loop
            let currentRunLoop = CFRunLoopGetCurrent()
            self.eventTapRunLoop = currentRunLoop
            self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(currentRunLoop, self.runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)

            print("✅ Hotkey monitoring started")
            CFRunLoopRun()
        }

        eventTapThread = thread
        thread.name = "HotkeyService.EventTap"
        thread.start()
    }

    func stopMonitoring() {
        if let runLoopSource = runLoopSource, let runLoop = eventTapRunLoop {
            CFRunLoopRemoveSource(runLoop, runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }

        if eventTapThread != nil {
            if let runLoop = eventTapRunLoop {
                CFRunLoopStop(runLoop)
            }
            eventTapRunLoop = nil
            eventTapThread = nil
        }

        print("🛑 Hotkey monitoring stopped")
    }

    // MARK: - Event Handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle tap being disabled
        // IMPORTANT: Don't re-enable immediately in the callback - this can cause an infinite loop
        // where the system disables the tap, we re-enable, system disables again, etc.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            print("⚠️ Event tap disabled, will re-enable after delay...")

            // Defer re-enabling to break potential infinite loop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, let eventTap = self.eventTap else { return }
                CGEvent.tapEnable(tap: eventTap, enable: true)
                print("✅ Event tap re-enabled after delay")
            }

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .eventTapDisabled, object: nil)
            }

            return Unmanaged.passUnretained(event)
        }

        // Process keyboard events
        if type == .keyDown {
            handleKeyDown(event)
        } else if type == .keyUp {
            handleKeyUp(event)
        } else if type == .flagsChanged {
            handleFlagsChanged(event)
        }

        // Pass event through to system (use passUnretained since we didn't create this event)
        return Unmanaged.passUnretained(event)
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
        guard flags.isSuperset(of: requiredModifiers) else { return }

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
            let hasRequiredModifiers = flags.isSuperset(of: requiredModifiers)
            if !hasRequiredModifiers {
                hideOverlay()
            }
        }
    }

    // MARK: - Overlay Control

    private func triggerOverlay() {
        guard !overlayShown else { return }

        // Debounce rapid triggers to prevent system freeze from event queue backup
        let now = Date()
        guard now.timeIntervalSince(lastTriggerTime) >= minimumTriggerInterval else {
            print("⏳ Debouncing overlay trigger")
            return
        }
        lastTriggerTime = now

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
