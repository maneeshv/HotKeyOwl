import Foundation

/// Represents a single keyboard shortcut with its associated action
struct ShortcutItem: Identifiable, Codable, Hashable {
    let id: UUID
    var key: String                    // e.g., "C", "V", "Tab", "↩︎"
    var modifiers: [String]            // e.g., ["⌘", "⇧"]
    var description: String            // e.g., "Copy", "Paste"
    var category: String?              // Optional category for grouping

    init(
        id: UUID = UUID(),
        key: String,
        modifiers: [String],
        description: String,
        category: String? = nil
    ) {
        self.id = id
        self.key = key
        self.modifiers = modifiers
        self.description = description
        self.category = category
    }

    /// Formatted display of the keyboard shortcut
    var formattedShortcut: String {
        let modifierString = modifiers.joined(separator: "")
        return "\(modifierString)\(key)"
    }
}
