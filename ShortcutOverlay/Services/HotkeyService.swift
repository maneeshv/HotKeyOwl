import Foundation
import Combine
import Carbon

/// Global callback function for Carbon Hot Key events
private func hotkeyCallback(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event = event, let userData = userData else {
        return OSStatus(eventNotHandledErr)
    }

    // Extract the hotkey ID from the event to verify it's ours
    var hotkeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )

    guard status == noErr else {
        return OSStatus(eventNotHandledErr)
    }

    // Verify this is our hotkey (not another app's or a future hotkey we might add)
    guard hotkeyID.signature == HotkeyService.hotkeySignature,
          hotkeyID.id == HotkeyService.hotkeyID else {
        return OSStatus(eventNotHandledErr)
    }

    let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
    service.handleHotkeyPressed()

    return noErr
}

/// Manages global keyboard monitoring for the hotkey using Carbon Hot Key API
class HotkeyService: ObservableObject {
    // MARK: - Properties

    @Published private(set) var isOverlayShown = false

    // Carbon Hot Key references
    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    static let hotkeySignature = OSType(0x484B5759)  // "HKWY"
    static let hotkeyID: UInt32 = 1

    // Target hotkey (configurable)
    private var targetKeyCode: CGKeyCode
    private var targetModifiers: CGEventFlags
    private let preferencesManager: PreferencesManager

    // Debouncing to prevent rapid triggers
    private var lastTriggerTime: Date = .distantPast
    private let minimumTriggerInterval: TimeInterval = 0.3

    // MARK: - Initialization

    init(preferencesManager: PreferencesManager) {
        self.preferencesManager = preferencesManager
        let hotkey = preferencesManager.globalHotkey
        self.targetKeyCode = hotkey.cgKeyCode
        self.targetModifiers = hotkey.cgModifiers

        // Observe external overlay dismissals to keep state in sync
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalOverlayHide),
            name: .hideOverlay,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopMonitoring()
    }

    /// Sync state when overlay is hidden externally (e.g., clicked outside)
    @objc private func handleExternalOverlayHide() {
        isOverlayShown = false
    }

    // MARK: - Monitoring Control

    func startMonitoring() {
        // Guard against repeated calls - clean up existing registration first
        if hotkeyRef != nil {
            print("⚠️ Hot key already registered, stopping before restart")
            stopMonitoring()
        }

        // Install event handler for hotkey events
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            hotkeyCallback,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            print("❌ Failed to install event handler: \(installStatus)")
            return
        }

        // Register the hotkey
        registerHotkey()

        print("✅ Hotkey monitoring started (Carbon Hot Key API)")
    }

    func stopMonitoring() {
        // Unregister hotkey
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }

        // Remove event handler
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }

        print("🛑 Hotkey monitoring stopped")
    }

    private func registerHotkey() {
        // Unregister existing hotkey if any
        if let existingRef = hotkeyRef {
            UnregisterEventHotKey(existingRef)
            hotkeyRef = nil
        }

        var hotkeyID = EventHotKeyID(
            signature: Self.hotkeySignature,
            id: Self.hotkeyID
        )

        let carbonMods = carbonModifiers(from: targetModifiers)

        let registerStatus = RegisterEventHotKey(
            UInt32(targetKeyCode),
            carbonMods,
            hotkeyID,
            GetEventDispatcherTarget(),
            0,
            &hotkeyRef
        )

        if registerStatus == noErr {
            print("✅ Registered hotkey: \(preferencesManager.globalHotkey.displayString)")
        } else {
            print("❌ Failed to register hotkey: \(registerStatus)")
        }
    }

    // MARK: - Modifier Conversion

    private func carbonModifiers(from cgFlags: CGEventFlags) -> UInt32 {
        var carbonMods: UInt32 = 0

        if cgFlags.contains(.maskCommand) {
            carbonMods |= UInt32(cmdKey)
        }
        if cgFlags.contains(.maskAlternate) {
            carbonMods |= UInt32(optionKey)
        }
        if cgFlags.contains(.maskControl) {
            carbonMods |= UInt32(controlKey)
        }
        if cgFlags.contains(.maskShift) {
            carbonMods |= UInt32(shiftKey)
        }

        return carbonMods
    }

    // MARK: - Event Handling

    /// Called when the hotkey is pressed - toggles overlay visibility
    /// Note: Called from hotkeyCallback, needs to be internal for file-scope access
    fileprivate func handleHotkeyPressed() {
        // Debounce rapid triggers
        let now = Date()
        guard now.timeIntervalSince(lastTriggerTime) >= minimumTriggerInterval else {
            print("⏳ Debouncing hotkey trigger")
            return
        }
        lastTriggerTime = now

        // Toggle overlay state
        if isOverlayShown {
            hideOverlay()
        } else {
            showOverlay()
        }
    }

    // MARK: - Overlay Control

    private func showOverlay() {
        guard !isOverlayShown else { return }

        isOverlayShown = true

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .showOverlay, object: nil)
        }

        print("🎯 Hotkey pressed - showing overlay")
    }

    private func hideOverlay() {
        guard isOverlayShown else { return }

        isOverlayShown = false

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .hideOverlay, object: nil)
        }

        print("🎯 Hotkey pressed - hiding overlay")
    }

    // MARK: - Public API

    /// Get the hotkey description
    var hotkeyDescription: String {
        return preferencesManager.globalHotkey.displayString
    }

    /// Update hotkey configuration (called when user changes settings)
    func updateHotkey(_ config: AppPreferences.HotkeyConfiguration) {
        targetKeyCode = config.cgKeyCode
        targetModifiers = config.cgModifiers

        // Re-register with new hotkey
        if eventHandlerRef != nil {
            registerHotkey()
        }

        print("🔄 Updated hotkey to: \(config.displayString)")
    }
}
