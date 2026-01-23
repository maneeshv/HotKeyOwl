import Foundation

struct ShortcutGrouping {
    static func group(_ shortcuts: [ShortcutItem]) -> [(category: String, shortcuts: [ShortcutItem])] {
        var categoryOrder: [String] = []
        var grouped: [String: [ShortcutItem]] = [:]

        for shortcut in shortcuts {
            let category = shortcut.category ?? "General"
            if grouped[category] == nil {
                categoryOrder.append(category)
            }
            grouped[category, default: []].append(shortcut)
        }

        categoryOrder.sort { lhs, rhs in
            if lhs == "General" { return false }
            if rhs == "General" { return true }
            return lhs < rhs
        }

        return categoryOrder.compactMap { category in
            guard let shortcuts = grouped[category] else { return nil }
            return (category: category, shortcuts: shortcuts)
        }
    }
}
