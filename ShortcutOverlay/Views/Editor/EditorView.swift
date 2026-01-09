import SwiftUI

/// Main editor view for managing keyboard shortcuts
struct EditorView: View {
    @ObservedObject var shortcutStore: ShortcutStore
    @ObservedObject var appMonitorService: AppMonitorService

    @State private var selectedBundleId: String?
    @State private var selectedApp: AppInfo?
    @State private var shortcuts: [ShortcutItem] = []
    @State private var showingAddSheet = false
    @State private var editingShortcut: ShortcutItem?

    init(shortcutStore: ShortcutStore, appMonitorService: AppMonitorService, selectedBundleId: String? = nil) {
        self.shortcutStore = shortcutStore
        self.appMonitorService = appMonitorService
        self._selectedBundleId = State(initialValue: selectedBundleId)
    }

    var body: some View {
        VStack(spacing: 0) {
            // App selector
            appSelectorSection

            Divider()

            if let selectedApp = selectedApp {
                // Shortcuts list
                shortcutsListSection
            } else {
                // Empty state
                emptyStateSection
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $showingAddSheet) {
            if let selectedApp = selectedApp {
                ShortcutFormSheet(
                    appInfo: selectedApp,
                    shortcut: editingShortcut,
                    onSave: { shortcut in
                        saveShortcut(shortcut)
                    },
                    onCancel: {
                        showingAddSheet = false
                        editingShortcut = nil
                    }
                )
            }
        }
        .onAppear {
            loadSelectedApp()
        }
    }

    // MARK: - Sections

    private var appSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Application")
                .font(.headline)

            Picker("Application", selection: $selectedBundleId) {
                Text("Choose an app...").tag(nil as String?)

                ForEach(appMonitorService.runningApps) { app in
                    Text(app.name).tag(app.bundleIdentifier as String?)
                }
            }
            .labelsHidden()
            .onChange(of: selectedBundleId) { newValue in
                loadSelectedApp()
            }
        }
        .padding()
    }

    private var shortcutsListSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(shortcuts.count) Shortcut\(shortcuts.count == 1 ? "" : "s")")
                    .font(.headline)

                Spacer()

                Button(action: {
                    editingShortcut = nil
                    showingAddSheet = true
                }) {
                    Label("Add Shortcut", systemImage: "plus")
                }
            }
            .padding()

            Divider()

            // Shortcuts list
            if shortcuts.isEmpty {
                noShortcutsState
            } else {
                List {
                    ForEach(shortcuts) { shortcut in
                        ShortcutListRow(
                            shortcut: shortcut,
                            onEdit: {
                                editingShortcut = shortcut
                                showingAddSheet = true
                            },
                            onDelete: {
                                deleteShortcut(shortcut)
                            }
                        )
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.dashed")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Select an Application")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Choose an app from the dropdown to view and edit its keyboard shortcuts")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noShortcutsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Shortcuts Yet")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("Click \"Add Shortcut\" to create your first keyboard shortcut")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadSelectedApp() {
        guard let bundleId = selectedBundleId else {
            selectedApp = nil
            shortcuts = []
            return
        }

        // Find app info
        if let app = appMonitorService.runningApps.first(where: { $0.bundleIdentifier == bundleId }) {
            selectedApp = app
        } else {
            // Create basic app info if not running
            if let appShortcuts = shortcutStore.getAppShortcuts(for: bundleId) {
                selectedApp = AppInfo(
                    bundleIdentifier: bundleId,
                    name: appShortcuts.appName,
                    icon: AppInfo.icon(for: bundleId)
                )
            }
        }

        // Load shortcuts
        shortcuts = shortcutStore.getShortcuts(for: bundleId)
    }

    private func saveShortcut(_ shortcut: ShortcutItem) {
        guard let selectedApp = selectedApp else { return }

        if let existingIndex = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            // Update existing
            shortcuts[existingIndex] = shortcut
            shortcutStore.updateShortcut(shortcut, for: selectedApp.bundleIdentifier)
        } else {
            // Add new
            shortcuts.append(shortcut)
            shortcutStore.addShortcut(shortcut, for: selectedApp.bundleIdentifier, appName: selectedApp.name)
        }

        showingAddSheet = false
        editingShortcut = nil
    }

    private func deleteShortcut(_ shortcut: ShortcutItem) {
        guard let selectedApp = selectedApp else { return }

        shortcuts.removeAll { $0.id == shortcut.id }
        shortcutStore.deleteShortcut(id: shortcut.id, for: selectedApp.bundleIdentifier)
    }
}

// MARK: - Shortcut List Row

struct ShortcutListRow: View {
    let shortcut: ShortcutItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            // Keys
            HStack(spacing: 4) {
                ForEach(shortcut.modifiers, id: \.self) { modifier in
                    Text(modifier)
                        .font(.system(size: 14, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                Text(shortcut.key)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            .frame(width: 150, alignment: .leading)

            // Description
            Text(shortcut.description)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Actions
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shortcut Form Sheet

struct ShortcutFormSheet: View {
    let appInfo: AppInfo
    let shortcut: ShortcutItem?
    let onSave: (ShortcutItem) -> Void
    let onCancel: () -> Void

    @State private var capturedShortcut: CapturedShortcut?
    @State private var description: String = ""

    init(appInfo: AppInfo, shortcut: ShortcutItem?, onSave: @escaping (ShortcutItem) -> Void, onCancel: @escaping () -> Void) {
        self.appInfo = appInfo
        self.shortcut = shortcut
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize with existing values if editing
        if let shortcut = shortcut {
            _description = State(initialValue: shortcut.description)
            // Create a CapturedShortcut from existing data
            _capturedShortcut = State(initialValue: CapturedShortcut(
                key: shortcut.key,
                modifiers: shortcut.modifiers,
                keyCode: 0,  // We don't store keyCode in ShortcutItem
                modifierFlags: CGEventFlags(rawValue: 0)  // We don't store flags in ShortcutItem
            ))
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(shortcut == nil ? "Add Shortcut" : "Edit Shortcut")
                .font(.title2)
                .bold()

            Text("for \(appInfo.name)")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                // Shortcut section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shortcut")
                        .font(.headline)
                    ShortcutRecorderField(capturedShortcut: $capturedShortcut)
                }

                // Description section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    TextField("What does this shortcut do?", text: $description)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    saveShortcut()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(capturedShortcut == nil || description.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 500, height: 380)
    }

    private func saveShortcut() {
        guard let captured = capturedShortcut else { return }

        let newShortcut = ShortcutItem(
            id: shortcut?.id ?? UUID(),
            key: captured.key,
            modifiers: captured.modifiers,
            description: description
        )

        onSave(newShortcut)
    }
}
