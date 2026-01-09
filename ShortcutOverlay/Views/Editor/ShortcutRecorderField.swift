import SwiftUI
import AppKit
import Carbon

/// Interactive shortcut recorder field for capturing keyboard shortcuts in the editor
struct ShortcutRecorderField: View {
    @Binding var capturedShortcut: CapturedShortcut?
    @State private var isRecording = false
    @State private var temporaryDisplay: String?
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Recorder field
            RecorderField(
                isRecording: $isRecording,
                displayString: displayText,
                onCapture: { keyCode, modifiers, keyString, modifierStrings in
                    // Validate the shortcut
                    if !validateShortcut(keyCode: keyCode, modifiers: modifiers) {
                        errorMessage = "Shortcut must have at least one modifier key (⌘⌃⌥⇧) or be a function key (F1-F12)"
                        showError = true
                        return
                    }

                    if isSystemShortcut(keyCode: keyCode, modifiers: modifiers) {
                        errorMessage = "This is a reserved system shortcut. Please choose a different combination."
                        showError = true
                        return
                    }

                    // Create captured shortcut
                    capturedShortcut = CapturedShortcut(
                        key: keyString,
                        modifiers: modifierStrings,
                        keyCode: keyCode,
                        modifierFlags: modifiers
                    )
                    temporaryDisplay = nil
                    showError = false
                },
                onTemporaryDisplay: { display in
                    temporaryDisplay = display
                }
            )
            .frame(height: 32)

            // Display captured shortcut or error
            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            } else if let shortcut = capturedShortcut {
                HStack(spacing: 4) {
                    Text("Captured:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(shortcut.modifiers, id: \.self) { modifier in
                        Text(modifier)
                            .font(.system(size: 11, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(3)
                    }

                    Text(shortcut.key)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(3)
                }
            } else {
                Text("Click the field above and press the shortcut keys")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Clear button
            if capturedShortcut != nil && !isRecording {
                Button("Clear") {
                    capturedShortcut = nil
                    temporaryDisplay = nil
                    showError = false
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                .font(.caption)
            }
        }
    }

    private var displayText: String {
        if isRecording {
            return temporaryDisplay ?? "Press keys..."
        } else if let shortcut = capturedShortcut {
            return (shortcut.modifiers + [shortcut.key]).joined()
        } else {
            return "Click to record..."
        }
    }

    private func validateShortcut(keyCode: CGKeyCode, modifiers: CGEventFlags) -> Bool {
        let hasModifiers = modifiers.contains(.maskCommand) ||
                          modifiers.contains(.maskControl) ||
                          modifiers.contains(.maskAlternate) ||
                          modifiers.contains(.maskShift)

        let isFunctionKey = (keyCode >= 122 && keyCode <= 133)  // F1-F12

        return hasModifiers || isFunctionKey
    }

    private func isSystemShortcut(keyCode: CGKeyCode, modifiers: CGEventFlags) -> Bool {
        let commandOnly = modifiers.contains(.maskCommand) &&
                         !modifiers.contains(.maskControl) &&
                         !modifiers.contains(.maskAlternate) &&
                         !modifiers.contains(.maskShift)

        if commandOnly {
            // Q (Quit), W (Close), Tab (Switcher), H (Hide), M (Minimize)
            let reservedKeys: Set<CGKeyCode> = [12, 13, 48, 4, 46]
            return reservedKeys.contains(keyCode)
        }

        return false
    }
}

/// Captured shortcut data structure
struct CapturedShortcut {
    var key: String
    var modifiers: [String]
    var keyCode: CGKeyCode
    var modifierFlags: CGEventFlags
}

/// NSView wrapper for capturing keyboard events
private struct RecorderField: NSViewRepresentable {
    @Binding var isRecording: Bool
    let displayString: String
    let onCapture: (CGKeyCode, CGEventFlags, String, [String]) -> Void
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
        let onCapture: (CGKeyCode, CGEventFlags, String, [String]) -> Void
        let onTemporaryDisplay: (String) -> Void

        init(isRecording: Binding<Bool>, onCapture: @escaping (CGKeyCode, CGEventFlags, String, [String]) -> Void, onTemporaryDisplay: @escaping (String) -> Void) {
            self._isRecording = isRecording
            self.onCapture = onCapture
            self.onTemporaryDisplay = onTemporaryDisplay
        }
    }
}

/// Custom NSView for capturing keyboard shortcuts
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

        let textSize = displayString.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        displayString.draw(in: textRect, withAttributes: attributes)
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
        if keyCode == 53 {  // Escape
            coordinator.isRecording = false
            return
        }

        // Get key string and modifier strings
        let keyString = keyCodeToString(keyCode)
        let modifierStrings = modifiersToArray(modifiers)

        // Capture the shortcut
        coordinator.onCapture(CGKeyCode(keyCode), modifiers, keyString, modifierStrings)
        coordinator.isRecording = false
    }

    override func flagsChanged(with event: NSEvent) {
        guard let coordinator = coordinator, coordinator.isRecording else {
            super.flagsChanged(with: event)
            return
        }

        // Show current modifiers
        let modifiers = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
        let modifiersString = modifiersToArray(modifiers).joined()

        if !modifiersString.isEmpty {
            coordinator.onTemporaryDisplay(modifiersString + "+")
        } else {
            coordinator.onTemporaryDisplay("Press keys...")
        }
    }

    private func modifiersToArray(_ modifiers: CGEventFlags) -> [String] {
        var parts: [String] = []

        if modifiers.contains(.maskCommand) {
            parts.append("⌘")
        }
        if modifiers.contains(.maskControl) {
            parts.append("⌃")
        }
        if modifiers.contains(.maskAlternate) {
            parts.append("⌥")
        }
        if modifiers.contains(.maskShift) {
            parts.append("⇧")
        }

        return parts
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
                    0,
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
