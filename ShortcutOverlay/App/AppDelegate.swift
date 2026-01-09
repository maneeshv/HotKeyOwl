import AppKit
import SwiftUI

/// Main application delegate coordinating all services and UI
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var overlayWindow: OverlayWindow?

    // Services
    private let preferencesManager = PreferencesManager()
    private lazy var hotkeyService = HotkeyService(preferencesManager: preferencesManager)
    private let appMonitorService = AppMonitorService()
    private let shortcutStore = ShortcutStore()

    // Window references
    private var editorWindow: NSWindow?
    private var settingsWindow: NSWindow?

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 ShortcutOverlay starting...")

        // Setup menu bar
        setupMenuBar()

        // Start services
        appMonitorService.startMonitoring()
        hotkeyService.startMonitoring()

        // Listen for overlay notifications
        setupNotifications()

        print("✅ ShortcutOverlay ready!")
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService.stopMonitoring()
        appMonitorService.stopMonitoring()
        print("👋 ShortcutOverlay terminating")
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Use simple text for menu bar visibility
            button.title = "⌘"
            print("✅ Menu bar button created with title: \(button.title ?? "none")")
        } else {
            print("❌ Failed to create menu bar button")
        }

        updateMenu()
    }

    private func updateMenu() {
        let menu = NSMenu()

        // Info item (use dynamic hotkey)
        let hotkeyText = hotkeyService.hotkeyDescription
        let infoItem = NSMenuItem(
            title: "Hold \(hotkeyText) to Show Shortcuts",
            action: nil,
            keyEquivalent: ""
        )
        infoItem.isEnabled = false
        menu.addItem(infoItem)

        menu.addItem(NSMenuItem.separator())

        // Permission status
        let permissionStatus = PermissionManager.shared.checkAccessibilityPermission() ? "✓ Granted" : "✗ Not Granted"
        let permissionItem = NSMenuItem(
            title: "Accessibility: \(permissionStatus)",
            action: #selector(requestPermission),
            keyEquivalent: ""
        )
        if !PermissionManager.shared.checkAccessibilityPermission() {
            permissionItem.attributedTitle = NSAttributedString(
                string: "Accessibility: \(permissionStatus)",
                attributes: [.foregroundColor: NSColor.systemRed]
            )
        }
        menu.addItem(permissionItem)

        menu.addItem(NSMenuItem.separator())

        // Choose App submenu
        let chooseAppItem = NSMenuItem(title: "Choose App…", action: nil, keyEquivalent: "")
        let chooseAppMenu = NSMenu()

        let runningApps = appMonitorService.runningApps
        if !runningApps.isEmpty {
            for app in runningApps.prefix(15) {  // Limit to 15 apps
                let item = NSMenuItem(
                    title: app.name,
                    action: #selector(selectApp(_:)),
                    keyEquivalent: ""
                )
                item.representedObject = app.bundleIdentifier
                chooseAppMenu.addItem(item)
            }
        } else {
            let item = NSMenuItem(title: "No apps running", action: nil, keyEquivalent: "")
            item.isEnabled = false
            chooseAppMenu.addItem(item)
        }

        chooseAppItem.submenu = chooseAppMenu
        menu.addItem(chooseAppItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        menu.addItem(NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))

        // Edit Shortcuts
        menu.addItem(NSMenuItem(
            title: "Edit Shortcuts…",
            action: #selector(openEditor),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem.separator())

        // Import Configuration
        menu.addItem(NSMenuItem(
            title: "Import Configuration…",
            action: #selector(importConfiguration),
            keyEquivalent: ""
        ))

        // Export Configuration
        menu.addItem(NSMenuItem(
            title: "Export Configuration…",
            action: #selector(exportConfiguration),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(
            title: "Quit ShortcutOverlay",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu
    }

    // MARK: - Notification Setup

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showOverlay),
            name: .showOverlay,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideOverlay),
            name: .hideOverlay,
            object: nil
        )
    }

    // MARK: - Overlay Management

    @objc private func showOverlay() {
        // Already showing
        guard overlayWindow == nil else { return }

        // Get current app
        guard let frontmostApp = appMonitorService.currentApp else {
            print("⚠️ No frontmost app detected")
            return
        }

        // Get shortcuts for app
        let shortcuts = shortcutStore.getShortcuts(for: frontmostApp.bundleIdentifier)

        // Always show overlay, even if empty (to provide feedback)
        print("📱 Showing overlay for: \(frontmostApp.name)")

        // Create overlay view
        let overlayView = OverlayView(
            appInfo: frontmostApp,
            shortcuts: shortcuts
        )

        // Create and show overlay window
        overlayWindow = OverlayWindow(contentView: overlayView)
        overlayWindow?.centerOnActiveScreen()
        overlayWindow?.show(animated: true)
    }

    @objc private func hideOverlay() {
        guard let window = overlayWindow else { return }

        print("🔍 Hiding overlay")

        window.hide(animated: true)

        // Clean up reference after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.overlayWindow = nil
        }
    }

    // MARK: - Menu Actions

    @objc private func requestPermission() {
        PermissionManager.shared.showPermissionAlert()
    }

    @objc private func selectApp(_ sender: NSMenuItem) {
        guard let bundleId = sender.representedObject as? String else { return }
        openEditor(for: bundleId)
    }

    @objc private func openEditor() {
        openEditor(for: nil)
    }

    private func openEditor(for bundleIdentifier: String? = nil) {
        // If editor window already exists, bring it to front
        if let existingWindow = editorWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create editor view
        let editorView = EditorView(
            shortcutStore: shortcutStore,
            appMonitorService: appMonitorService,
            selectedBundleId: bundleIdentifier
        )

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Edit Shortcuts"
        window.contentView = NSHostingView(rootView: editorView)
        window.center()
        window.setFrameAutosaveName("EditorWindow")
        window.minSize = NSSize(width: 600, height: 400)
        window.isReleasedWhenClosed = false

        // Store reference
        editorWindow = window

        // Handle window close
        var closeObserver: NSObjectProtocol?
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.editorWindow = nil
            if let observer = closeObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        // If settings window already exists, bring it to front
        if let existingWindow = settingsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create settings view
        let settingsView = SettingsView(
            preferencesManager: preferencesManager,
            hotkeyService: hotkeyService,
            onSave: { [weak self] in
                self?.settingsWindow?.close()
                // Update menu bar to reflect new hotkey
                self?.updateMenu()
            },
            onCancel: { [weak self] in
                self?.settingsWindow?.close()
            }
        )

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false

        // Store reference
        settingsWindow = window

        // Handle window close
        var closeObserver: NSObjectProtocol?
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.settingsWindow = nil
            if let observer = closeObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Import/Export

    @objc private func importConfiguration() {
        let panel = NSOpenPanel()
        panel.title = "Import Shortcuts Configuration"
        panel.message = "Select a JSON configuration file to import"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }

            // Ask for merge strategy
            self?.showMergeStrategyDialog { strategy in
                do {
                    try self?.shortcutStore.importConfiguration(from: url, strategy: strategy)
                    self?.showAlert(
                        title: "Import Successful",
                        message: "Shortcuts have been imported successfully.",
                        style: .informational
                    )
                } catch {
                    self?.showAlert(
                        title: "Import Failed",
                        message: "Failed to import configuration: \(error.localizedDescription)",
                        style: .critical
                    )
                }
            }
        }
    }

    @objc private func exportConfiguration() {
        let panel = NSSavePanel()
        panel.title = "Export Shortcuts Configuration"
        panel.message = "Choose where to save your shortcuts configuration"
        panel.nameFieldStringValue = "shortcuts-\(Date().ISO8601Format()).json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }

            do {
                try self?.shortcutStore.exportAll(to: url)
                self?.showAlert(
                    title: "Export Successful",
                    message: "Shortcuts have been exported to:\n\(url.path)",
                    style: .informational
                )
            } catch {
                self?.showAlert(
                    title: "Export Failed",
                    message: "Failed to export configuration: \(error.localizedDescription)",
                    style: .critical
                )
            }
        }
    }

    private func showMergeStrategyDialog(completion: @escaping (ConfigurationManager.MergeStrategy) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Import Strategy"
        alert.informativeText = "How would you like to merge the imported shortcuts?"
        alert.alertStyle = .informational

        alert.addButton(withTitle: "Replace All")
        alert.addButton(withTitle: "Merge")
        alert.addButton(withTitle: "Append")
        alert.addButton(withTitle: "Cancel")

        // Add detailed descriptions
        let descriptions = """
        Replace All: Replace all existing shortcuts with imported ones
        Merge: Keep existing shortcuts for unlisted apps, replace apps in import
        Append: Add imported shortcuts to existing ones (may create duplicates)
        """

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 350, height: 60))
        textView.string = descriptions
        textView.isEditable = false
        textView.font = NSFont.systemFont(ofSize: 11)
        textView.textColor = .secondaryLabelColor
        alert.accessoryView = textView

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            completion(.replace)
        case .alertSecondButtonReturn:
            completion(.merge)
        case .alertThirdButtonReturn:
            completion(.append)
        default:
            break
        }
    }

    private func showAlert(title: String, message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
