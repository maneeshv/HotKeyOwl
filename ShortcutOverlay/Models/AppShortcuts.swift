import Foundation

/// Collection of shortcuts for a specific application
struct AppShortcuts: Codable {
    let bundleIdentifier: String
    var appName: String
    var shortcuts: [ShortcutItem]
    var lastModified: Date

    init(
        bundleIdentifier: String,
        appName: String,
        shortcuts: [ShortcutItem] = []
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.shortcuts = shortcuts
        self.lastModified = Date()
    }

    /// Get shortcuts grouped by category
    var groupedShortcuts: [String: [ShortcutItem]] {
        Dictionary(grouping: shortcuts) { shortcut in
            shortcut.category ?? "General"
        }
    }

    /// Get shortcuts sorted by category
    var sortedShortcuts: [ShortcutItem] {
        shortcuts.sorted { lhs, rhs in
            let lhsCategory = lhs.category ?? "General"
            let rhsCategory = rhs.category ?? "General"

            if lhsCategory == rhsCategory {
                return lhs.description < rhs.description
            }
            return lhsCategory < rhsCategory
        }
    }
}
