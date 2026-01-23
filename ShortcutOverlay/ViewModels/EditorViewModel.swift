import Foundation
import Combine

@MainActor
final class EditorViewModel: ObservableObject {
    typealias ShortcutGroup = (category: String, shortcuts: [ShortcutItem])
    @Published private(set) var selectedBundleId: String?
    @Published private(set) var selectedApp: AppInfo?
    @Published private(set) var shortcuts: [ShortcutItem] = []

    private let shortcutStore: ShortcutStore
    private let appMonitorService: AppMonitorService
    private var cancellables = Set<AnyCancellable>()

    init(shortcutStore: ShortcutStore, appMonitorService: AppMonitorService, selectedBundleId: String? = nil) {
        self.shortcutStore = shortcutStore
        self.appMonitorService = appMonitorService
        self.selectedBundleId = selectedBundleId

        shortcutStore.$allShortcuts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (_: [String: AppShortcuts]) in
                self?.reloadShortcuts()
            }
            .store(in: &cancellables)

        reloadSelection()
    }

    var groupedShortcuts: [(category: String, shortcuts: [ShortcutItem])] {
        ShortcutGrouping.group(shortcuts)
    }

    var existingCategories: [String] {
        let categories = Set(shortcuts.compactMap { $0.category })
        return categories.sorted()
    }

    func selectBundleId(_ bundleId: String?) {
        selectedBundleId = bundleId
        reloadSelection()
    }

    func reloadSelection() {
        reloadSelectedApp()
        reloadShortcuts()
    }

    func saveShortcut(_ shortcut: ShortcutItem) {
        guard let selectedApp else { return }

        if let existingIndex = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            shortcuts[existingIndex] = shortcut
            shortcutStore.updateShortcut(shortcut, for: selectedApp.bundleIdentifier)
        } else {
            shortcuts.append(shortcut)
            shortcutStore.addShortcut(shortcut, for: selectedApp.bundleIdentifier, appName: selectedApp.name)
        }
    }

    func deleteShortcut(_ shortcut: ShortcutItem) {
        guard let selectedApp else { return }

        shortcuts.removeAll { $0.id == shortcut.id }
        shortcutStore.deleteShortcut(id: shortcut.id, for: selectedApp.bundleIdentifier)
    }

    func moveShortcuts(from indices: IndexSet, to newOffset: Int, inCategory category: String) {
        guard let selectedApp else { return }

        var categoryShortcuts: [(globalIndex: Int, shortcut: ShortcutItem)] = []
        for (index, shortcut) in shortcuts.enumerated() {
            let shortcutCategory = shortcut.category ?? "General"
            if shortcutCategory == category {
                categoryShortcuts.append((globalIndex: index, shortcut: shortcut))
            }
        }

        var categoryItems = categoryShortcuts.map { $0.shortcut }
        categoryItems.move(fromOffsets: indices, toOffset: newOffset)

        var newShortcuts: [ShortcutItem] = []
        var categoryIndex = 0

        for shortcut in shortcuts {
            let shortcutCategory = shortcut.category ?? "General"
            if shortcutCategory == category {
                newShortcuts.append(categoryItems[categoryIndex])
                categoryIndex += 1
            } else {
                newShortcuts.append(shortcut)
            }
        }

        shortcuts = newShortcuts
        shortcutStore.setShortcuts(newShortcuts, for: selectedApp.bundleIdentifier, appName: selectedApp.name)
    }

    private func reloadSelectedApp() {
        guard let bundleId = selectedBundleId else {
            selectedApp = nil
            return
        }

        if let app = appMonitorService.runningApps.first(where: { $0.bundleIdentifier == bundleId }) {
            selectedApp = app
        } else if let appShortcuts = shortcutStore.getAppShortcuts(for: bundleId) {
            selectedApp = AppInfo(
                bundleIdentifier: bundleId,
                name: appShortcuts.appName,
                icon: AppInfo.icon(for: bundleId)
            )
        } else {
            selectedApp = nil
        }
    }

    private func reloadShortcuts() {
        guard let bundleId = selectedBundleId else {
            shortcuts = []
            return
        }

        shortcuts = shortcutStore.getShortcuts(for: bundleId)
    }
}
