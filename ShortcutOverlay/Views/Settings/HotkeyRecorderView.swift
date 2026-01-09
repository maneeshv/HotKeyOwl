import SwiftUI
import AppKit
import Carbon

/// Interactive hotkey recorder view for capturing keyboard shortcuts
struct HotkeyRecorderView: View {
    @Binding var config: AppPreferences.HotkeyConfiguration
    @State private var isRecording = false
    @State private var temporaryDisplay: String?

    let onValidationError: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Global Hotkey")
                .font(.headline)

            HStack {
                // Recorder field
                RecorderField(
                    isRecording: $isRecording,
                    displayString: isRecording ? (temporaryDisplay ?? "Press keys...") : config.displayString,
                    onCapture: { keyCode, modifiers, displayString in
                        // Validate the hotkey
                        if !PreferencesManager().validate(keyCode: keyCode, modifiers: modifiers) {
                            onValidationError("Hotkey must have at least one modifier key (⌘⌃⌥⇧) or be a function key (F1-F12)")
                            return
                        }

                        if PreferencesManager().isSystemShortcut(keyCode: keyCode, modifiers: modifiers) {
                            onValidationError("This is a reserved system shortcut. Please choose a different combination.")
                            return
                        }

                        // Update configuration
                        config = AppPreferences.HotkeyConfiguration(
                            keyCode: keyCode,
                            modifiers: modifiers,
                            displayString: displayString
                        )
                        temporaryDisplay = nil
                    },
                    onTemporaryDisplay: { display in
                        temporaryDisplay = display
                    }
                )
                .frame(height: 32)
                .frame(maxWidth: .infinity)

                // Clear button
                if !isRecording {
                    Button("Reset") {
                        config = AppPreferences.default.globalHotkey
                    }
                    .buttonStyle(.bordered)
                }
            }

            Text("Click the field above and press your desired hotkey combination")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

/// NSView wrapper for capturing keyboard events
private struct RecorderField: NSViewRepresentable {
    @Binding var isRecording: Bool
    let displayString: String
    let onCapture: (CGKeyCode, CGEventFlags, String) -> Void
    let onTemporaryDisplay: (String) -> Void

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        nsView.displayString = displayString
        nsView.isRecording = isRecording
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isRecording: $isRecording,
            onCapture: onCapture,
            onTemporaryDisplay: onTemporaryDisplay
        )
    }

    class Coordinator {
        @Binding var isRecording: Bool
        let onCapture: (CGKeyCode, CGEventFlags, String) -> Void
        let onTemporaryDisplay: (String) -> Void

        init(isRecording: Binding<Bool>, onCapture: @escaping (CGKeyCode, CGEventFlags, String) -> Void, onTemporaryDisplay: @escaping (String) -> Void) {
            self._isRecording = isRecording
            self.onCapture = onCapture
            self.onTemporaryDisplay = onTemporaryDisplay
        }
    }
}

/// Custom NSView that captures keyboard events
private class RecorderNSView: NSView {
    var coordinator: RecorderField.Coordinator?
    var displayString: String = "" {
        didSet { needsDisplay = true }
    }
    var isRecording: Bool = false {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 6
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Background
        if isRecording {
            NSColor.systemRed.withAlphaComponent(0.1).setFill()
        } else {
            NSColor.controlBackgroundColor.setFill()
        }
        NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6).fill()

        // Border
        if isRecording {
            NSColor.systemRed.setStroke()
        } else {
            NSColor.separatorColor.setStroke()
        }
        let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
        borderPath.lineWidth = 1
        borderPath.stroke()

        // Text
        let textColor: NSColor = isRecording ? .labelColor : .secondaryLabelColor
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: textColor
        ]

        let text = displayString.isEmpty ? "Click to record..." : displayString
        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        coordinator?.isRecording = true
    }

    override func keyDown(with event: NSEvent) {
        guard let coordinator = coordinator, coordinator.isRecording else {
            super.keyDown(with: event)
            return
        }

        let keyCode = event.keyCode
        let modifiers = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))

        // Cancel on Escape
        if keyCode == 53 {  // Escape key
            coordinator.isRecording = false
            return
        }

        // Build display string
        let displayString = buildDisplayString(keyCode: keyCode, modifiers: modifiers)

        // Capture the hotkey
        coordinator.onCapture(CGKeyCode(keyCode), modifiers, displayString)
        coordinator.isRecording = false
    }

    override func flagsChanged(with event: NSEvent) {
        guard let coordinator = coordinator, coordinator.isRecording else {
            super.flagsChanged(with: event)
            return
        }

        // Show current modifiers while recording
        let modifiers = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
        let modifiersString = modifiersToString(modifiers)

        if !modifiersString.isEmpty {
            coordinator.onTemporaryDisplay(modifiersString + "+")
        } else {
            coordinator.onTemporaryDisplay("Press keys...")
        }
    }

    private func buildDisplayString(keyCode: UInt16, modifiers: CGEventFlags) -> String {
        var parts: [String] = []

        // Add modifiers in standard order
        if modifiers.contains(.maskControl) {
            parts.append("⌃")
        }
        if modifiers.contains(.maskAlternate) {
            parts.append("⌥")
        }
        if modifiers.contains(.maskShift) {
            parts.append("⇧")
        }
        if modifiers.contains(.maskCommand) {
            parts.append("⌘")
        }

        // Add key
        parts.append(keyCodeToString(keyCode))

        return parts.joined()
    }

    private func modifiersToString(_ modifiers: CGEventFlags) -> String {
        var parts: [String] = []

        if modifiers.contains(.maskControl) {
            parts.append("⌃")
        }
        if modifiers.contains(.maskAlternate) {
            parts.append("⌥")
        }
        if modifiers.contains(.maskShift) {
            parts.append("⇧")
        }
        if modifiers.contains(.maskCommand) {
            parts.append("⌘")
        }

        return parts.joined()
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String {
        // Special keys
        switch keyCode {
        case 36: return "↩"  // Return
        case 48: return "⇥"  // Tab
        case 49: return "Space"
        case 51: return "⌫"  // Delete
        case 53: return "⎋"  // Escape
        case 117: return "⌦"  // Forward Delete
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default:
            // Try to get character representation
            let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
            let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)

            if layoutData != nil {
                let dataRef = unsafeBitCast(layoutData, to: CFData.self)
                let keyLayout = unsafeBitCast(CFDataGetBytePtr(dataRef), to: UnsafePointer<UCKeyboardLayout>.self)

                var deadKeyState: UInt32 = 0
                var length = 0
                var chars = [UniChar](repeating: 0, count: 4)

                let error = UCKeyTranslate(
                    keyLayout,
                    keyCode,
                    UInt16(kUCKeyActionDisplay),
                    0,  // No modifiers for display
                    UInt32(LMGetKbdType()),
                    UInt32(kUCKeyTranslateNoDeadKeysMask),
                    &deadKeyState,
                    4,
                    &length,
                    &chars
                )

                if error == noErr && length > 0 {
                    return String(utf16CodeUnits: chars, count: length).uppercased()
                }
            }

            return String(keyCode)
        }
    }
}
