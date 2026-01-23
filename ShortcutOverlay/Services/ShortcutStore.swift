import Foundation
import Combine

/// Manages storage and retrieval of keyboard shortcuts for applications
class ShortcutStore: ObservableObject {
    @Published private(set) var allShortcuts: [String: AppShortcuts] = [:]

    private let fileManager = FileManager.default
    private let storageURL: URL
    private let persistence = ShortcutsPersistence()
    private let saveDebounceInterval: TimeInterval = 0.4

    // MARK: - iCloud Sync Integration

    /// Reference to the sync service (set by AppDelegate)
    weak var syncService: iCloudSyncService?

    /// Flag to prevent triggering sync during remote update
    private var isApplyingRemote = false

    init() {
        // Get Application Support directory
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent(AppConstants.appSupportDirectoryName, isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        storageURL = appDirectory.appendingPathComponent("shortcuts.json")

        // Load existing data
        load()

    }

    // MARK: - Persistence

    func load() {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            // Load default shortcuts for common apps
            loadDefaults()
            return
        }

        Task {
            do {
                let loaded = try await persistence.load(from: storageURL)
                await MainActor.run {
                    self.allShortcuts = loaded
                }
            } catch {
                print("Failed to load shortcuts: \(error)")
                await MainActor.run {
                    self.loadDefaults()
                }
            }
        }
    }

    func save() {
        let snapshot = allShortcuts
        let shouldSync = !isApplyingRemote

        Task { [weak self] in
            guard let self else { return }

            do {
                let outcome = try await persistence.scheduleSave(
                    snapshot,
                    to: storageURL,
                    debounceInterval: saveDebounceInterval
                )

                if outcome == .saved, shouldSync {
                    await MainActor.run {
                        self.syncService?.syncShortcutsToCloud()
                    }
                }
            } catch {
                print("Failed to save shortcuts: \(error)")
            }
        }
    }

    // MARK: - iCloud Sync Methods

    /// Get all shortcuts for sync
    func getAllShortcuts() -> [String: AppShortcuts] {
        return allShortcuts
    }

    /// Replace all shortcuts (used when applying remote data)
    func replaceAllShortcuts(_ shortcuts: [String: AppShortcuts]) {
        isApplyingRemote = true
        allShortcuts = shortcuts
        save()
        isApplyingRemote = false
        objectWillChange.send()
        print("☁️ Replaced all shortcuts from iCloud")
    }

    /// Reload shortcuts from cloud
    func reloadFromCloud() {
        Task { @MainActor in
            syncService?.pullShortcutsFromCloud()
        }
    }

    // MARK: - CRUD Operations

    func getShortcuts(for bundleIdentifier: String) -> [ShortcutItem] {
        return allShortcuts[bundleIdentifier]?.shortcuts ?? []
    }

    func getCategories(for bundleIdentifier: String) -> [String] {
        let shortcuts = getShortcuts(for: bundleIdentifier)
        let categories = Set(shortcuts.compactMap { $0.category })
        return Array(categories).sorted()
    }

    func getAppShortcuts(for bundleIdentifier: String) -> AppShortcuts? {
        return allShortcuts[bundleIdentifier]
    }

    func setShortcuts(_ shortcuts: [ShortcutItem], for bundleIdentifier: String, appName: String) {
        allShortcuts[bundleIdentifier] = AppShortcuts(
            bundleIdentifier: bundleIdentifier,
            appName: appName,
            shortcuts: shortcuts
        )
        save()
    }

    func addShortcut(_ shortcut: ShortcutItem, for bundleIdentifier: String, appName: String) {
        if var appShortcuts = allShortcuts[bundleIdentifier] {
            appShortcuts.shortcuts.append(shortcut)
            appShortcuts.touch()
            allShortcuts[bundleIdentifier] = appShortcuts
        } else {
            allShortcuts[bundleIdentifier] = AppShortcuts(
                bundleIdentifier: bundleIdentifier,
                appName: appName,
                shortcuts: [shortcut]
            )
        }
        save()
    }

    func updateShortcut(_ shortcut: ShortcutItem, for bundleIdentifier: String) {
        guard var appShortcuts = allShortcuts[bundleIdentifier] else { return }

        if let index = appShortcuts.shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            appShortcuts.shortcuts[index] = shortcut
            appShortcuts.touch()
            allShortcuts[bundleIdentifier] = appShortcuts
            save()
        }
    }

    func deleteShortcut(id: UUID, for bundleIdentifier: String) {
        guard var appShortcuts = allShortcuts[bundleIdentifier] else { return }

        appShortcuts.shortcuts.removeAll { $0.id == id }
        appShortcuts.touch()
        allShortcuts[bundleIdentifier] = appShortcuts
        save()
    }

    func deleteAllShortcuts(for bundleIdentifier: String) {
        allShortcuts.removeValue(forKey: bundleIdentifier)
        save()
    }

    // MARK: - Default Shortcuts

    private func loadDefaults() {
        allShortcuts = [
            "com.apple.Safari": AppShortcuts(
                bundleIdentifier: "com.apple.Safari",
                appName: "Safari",
                shortcuts: [
                    ShortcutItem(key: "T", modifiers: ["⌘"], description: "New Tab"),
                    ShortcutItem(key: "W", modifiers: ["⌘"], description: "Close Tab"),
                    ShortcutItem(key: "R", modifiers: ["⌘"], description: "Reload Page"),
                    ShortcutItem(key: "L", modifiers: ["⌘"], description: "Focus URL Bar"),
                    ShortcutItem(key: "T", modifiers: ["⌘", "⇧"], description: "Reopen Closed Tab"),
                    ShortcutItem(key: "[", modifiers: ["⌘"], description: "Back"),
                    ShortcutItem(key: "]", modifiers: ["⌘"], description: "Forward"),
                    ShortcutItem(key: "N", modifiers: ["⌘"], description: "New Window"),
                    ShortcutItem(key: "+", modifiers: ["⌘"], description: "Zoom In"),
                    ShortcutItem(key: "-", modifiers: ["⌘"], description: "Zoom Out"),
                ]
            ),
            "com.apple.finder": AppShortcuts(
                bundleIdentifier: "com.apple.finder",
                appName: "Finder",
                shortcuts: [
                    ShortcutItem(key: "N", modifiers: ["⌘"], description: "New Finder Window"),
                    ShortcutItem(key: "⌫", modifiers: ["⌘"], description: "Move to Trash"),
                    ShortcutItem(key: "I", modifiers: ["⌘"], description: "Get Info"),
                    ShortcutItem(key: "D", modifiers: ["⌘"], description: "Duplicate"),
                    ShortcutItem(key: "N", modifiers: ["⌘", "⇧"], description: "New Folder"),
                    ShortcutItem(key: ".", modifiers: ["⌘", "⇧"], description: "Show Hidden Files"),
                    ShortcutItem(key: "G", modifiers: ["⌘", "⇧"], description: "Go to Folder"),
                    ShortcutItem(key: "↓", modifiers: ["⌘"], description: "Open Selected Item"),
                ]
            ),
            "com.google.Chrome": AppShortcuts(
                bundleIdentifier: "com.google.Chrome",
                appName: "Chrome",
                shortcuts: [
                    ShortcutItem(key: "T", modifiers: ["⌘"], description: "New Tab"),
                    ShortcutItem(key: "W", modifiers: ["⌘"], description: "Close Tab"),
                    ShortcutItem(key: "R", modifiers: ["⌘"], description: "Reload Page"),
                    ShortcutItem(key: "L", modifiers: ["⌘"], description: "Focus Omnibox"),
                    ShortcutItem(key: "T", modifiers: ["⌘", "⇧"], description: "Reopen Closed Tab"),
                    ShortcutItem(key: "N", modifiers: ["⌘", "⇧"], description: "New Incognito Window"),
                    ShortcutItem(key: "Y", modifiers: ["⌘"], description: "Open History"),
                    ShortcutItem(key: "J", modifiers: ["⌘", "⌥"], description: "Open DevTools"),
                    ShortcutItem(key: "[", modifiers: ["⌘"], description: "Back"),
                    ShortcutItem(key: "]", modifiers: ["⌘"], description: "Forward"),
                ]
            ),
            "com.microsoft.VSCode": AppShortcuts(
                bundleIdentifier: "com.microsoft.VSCode",
                appName: "VS Code",
                shortcuts: [
                    ShortcutItem(key: "P", modifiers: ["⌘"], description: "Quick Open File"),
                    ShortcutItem(key: "P", modifiers: ["⌘", "⇧"], description: "Command Palette"),
                    ShortcutItem(key: "B", modifiers: ["⌘"], description: "Toggle Sidebar"),
                    ShortcutItem(key: "J", modifiers: ["⌘"], description: "Toggle Terminal"),
                    ShortcutItem(key: "S", modifiers: ["⌘", "K"], description: "Keyboard Shortcuts"),
                    ShortcutItem(key: "F", modifiers: ["⌥", "⇧"], description: "Format Document"),
                    ShortcutItem(key: "F", modifiers: ["⌘"], description: "Find"),
                    ShortcutItem(key: "H", modifiers: ["⌘", "⇧"], description: "Replace"),
                    ShortcutItem(key: "/", modifiers: ["⌘"], description: "Toggle Comment"),
                    ShortcutItem(key: "S", modifiers: ["⌘"], description: "Save"),
                ]
            )
        ]
        save()
    }

    // MARK: - Utility

    var configuredApps: [AppInfo] {
        allShortcuts.values
            .map { AppInfo(bundleIdentifier: $0.bundleIdentifier, name: $0.appName, icon: AppInfo.icon(for: $0.bundleIdentifier)) }
            .sorted { $0.name < $1.name }
    }

    // MARK: - Import/Export

    /// Export all shortcuts to a file
    func exportAll(to url: URL) throws {
        let configManager = ConfigurationManager()
        try configManager.exportAll(shortcuts: allShortcuts, to: url)
    }

    /// Export shortcuts for a specific app
    func exportApp(bundleIdentifier: String, to url: URL) throws {
        guard let appShortcuts = allShortcuts[bundleIdentifier] else {
            throw NSError(domain: "ShortcutStore", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "No shortcuts found for app"
            ])
        }

        let configManager = ConfigurationManager()
        try configManager.exportApp(appShortcuts, to: url)
    }

    /// Import shortcuts from a file
    func importConfiguration(from url: URL, strategy: ConfigurationManager.MergeStrategy) throws {
        let configManager = ConfigurationManager()
        let imported = try configManager.importConfiguration(from: url, mergeStrategy: strategy)
        let merged = configManager.merge(imported: imported, existing: allShortcuts, strategy: strategy)

        allShortcuts = merged
        save()
    }

    /// Export to clipboard
    func exportToClipboard() throws -> String {
        let configManager = ConfigurationManager()
        return try configManager.exportToClipboard(shortcuts: allShortcuts)
    }

    /// Import from clipboard
    func importFromClipboard(_ jsonString: String, strategy: ConfigurationManager.MergeStrategy) throws {
        let configManager = ConfigurationManager()
        let imported = try configManager.importFromClipboard(jsonString)
        let merged = configManager.merge(imported: imported, existing: allShortcuts, strategy: strategy)

        allShortcuts = merged
        save()
    }

    /// Get the storage directory URL
    var storageDirectory: URL {
        return storageURL.deletingLastPathComponent()
    }
}
