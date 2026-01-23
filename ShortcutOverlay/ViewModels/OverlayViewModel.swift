import Foundation

@MainActor
final class OverlayViewModel: ObservableObject {
    @Published var searchText: String = ""

    private let shortcuts: [ShortcutItem]

    init(shortcuts: [ShortcutItem]) {
        self.shortcuts = shortcuts
    }

    var filteredShortcuts: [ShortcutItem] {
        guard !searchText.isEmpty else { return shortcuts }
        return shortcuts.filter { shortcut in
            shortcut.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedShortcuts: [(category: String, shortcuts: [ShortcutItem])] {
        ShortcutGrouping.group(filteredShortcuts)
    }

    var isEmpty: Bool {
        shortcuts.isEmpty
    }

    var hasNoResults: Bool {
        !searchText.isEmpty && filteredShortcuts.isEmpty
    }
}
