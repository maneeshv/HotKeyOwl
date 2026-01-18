import Foundation

/// Utility for parsing manually entered keyboard shortcuts
struct ShortcutParser {
    /// Result of parsing a shortcut string
    enum ParseResult {
        /// Standard shortcut with key and modifiers (e.g., "Cmd+Shift+N")
        case standard(key: String, modifiers: [String])
        /// Prefix sequence like tmux shortcuts (e.g., "C-b, c")
        case sequence(displayText: String)
        /// Invalid input with error message
        case invalid(error: String)
    }

    /// Mapping of text modifiers to symbols
    private static let textToSymbol: [String: String] = [
        "cmd": "⌘",
        "command": "⌘",
        "ctrl": "⌃",
        "control": "⌃",
        "alt": "⌥",
        "option": "⌥",
        "opt": "⌥",
        "shift": "⇧"
    ]

    /// Symbol modifiers in order
    private static let symbolModifiers: [Character] = ["⌘", "⌃", "⌥", "⇧"]

    /// Parses a manually entered shortcut string
    /// - Parameter input: The shortcut string to parse
    /// - Returns: A ParseResult indicating the type and content of the shortcut
    static func parse(_ input: String) -> ParseResult {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            return .invalid(error: "Shortcut cannot be empty")
        }

        // Check if this is a prefix sequence (contains comma or " then ")
        if trimmed.contains(",") || trimmed.lowercased().contains(" then ") {
            return .sequence(displayText: trimmed)
        }

        // Try parsing as symbol format (e.g., "⌘⇧N")
        if let result = parseSymbolFormat(trimmed) {
            return result
        }

        // Try parsing as text format (e.g., "Cmd+Shift+N" or "Ctrl-B")
        if let result = parseTextFormat(trimmed) {
            return result
        }

        // Single character or key name
        if trimmed.count == 1 || isSpecialKeyName(trimmed) {
            return .standard(key: trimmed.uppercased(), modifiers: [])
        }

        return .invalid(error: "Could not parse shortcut format")
    }

    /// Attempts to parse symbol format shortcuts (e.g., "⌘⇧N")
    private static func parseSymbolFormat(_ input: String) -> ParseResult? {
        var modifiers: [String] = []
        var remaining = input

        // Extract leading modifier symbols
        while let firstChar = remaining.first, symbolModifiers.contains(firstChar) {
            modifiers.append(String(firstChar))
            remaining.removeFirst()
        }

        // If we found modifiers and there's a key remaining
        if !modifiers.isEmpty && !remaining.isEmpty {
            let key = remaining.uppercased()
            return .standard(key: key, modifiers: modifiers)
        }

        // Only modifiers, no key
        if !modifiers.isEmpty && remaining.isEmpty {
            return .invalid(error: "Shortcut must include a key after modifiers")
        }

        return nil
    }

    /// Attempts to parse text format shortcuts (e.g., "Cmd+Shift+N" or "Ctrl-B")
    private static func parseTextFormat(_ input: String) -> ParseResult? {
        // Split by + or - (but be careful with single - at the end which might be the key)
        let components: [String]

        if input.contains("+") {
            components = input.components(separatedBy: "+").map { $0.trimmingCharacters(in: .whitespaces) }
        } else if input.contains("-") {
            // Handle cases like "Ctrl-B" or "C-b"
            components = input.components(separatedBy: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            return nil
        }

        guard components.count >= 2 else {
            return nil
        }

        var modifiers: [String] = []
        var key: String?

        for (index, component) in components.enumerated() {
            let lowercased = component.lowercased()

            // Check if it's a modifier
            if let symbol = textToSymbol[lowercased] {
                modifiers.append(symbol)
            } else if lowercased == "c" && index < components.count - 1 {
                // "C" at the start is often Control in Unix notation (e.g., "C-b")
                modifiers.append("⌃")
            } else if lowercased == "m" && index < components.count - 1 {
                // "M" is often Meta/Alt in Unix notation
                modifiers.append("⌥")
            } else if lowercased == "s" && index < components.count - 1 && components.count > 2 {
                // "S" is sometimes Shift in Unix notation (but only if there are more components)
                modifiers.append("⇧")
            } else {
                // It's the key
                key = component.uppercased()
            }
        }

        if let finalKey = key {
            return .standard(key: finalKey, modifiers: modifiers)
        }

        return nil
    }

    /// Checks if a string is a known special key name
    private static func isSpecialKeyName(_ input: String) -> Bool {
        let specialKeys: Set<String> = [
            "space", "tab", "return", "enter", "escape", "esc",
            "delete", "backspace", "up", "down", "left", "right",
            "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
            "home", "end", "pageup", "pagedown"
        ]
        return specialKeys.contains(input.lowercased())
    }
}
