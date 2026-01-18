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
                    existingCategories: existingCategories,
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

    // MARK: - Computed Properties

    /// Group shortcuts by category for display
    private var groupedShortcuts: [(category: String, shortcuts: [ShortcutItem])] {
        let grouped = Dictionary(grouping: shortcuts) { shortcut in
            shortcut.category ?? "General"
        }
        // Sort categories alphabetically, but put "General" last
        return grouped.sorted { lhs, rhs in
            if lhs.key == "General" { return false }
            if rhs.key == "General" { return true }
            return lhs.key < rhs.key
        }.map { (category: $0.key, shortcuts: $0.value) }
    }

    /// Get unique categories from current shortcuts for suggestions
    private var existingCategories: [String] {
        let categories = Set(shortcuts.compactMap { $0.category })
        return categories.sorted()
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
                    ForEach(groupedShortcuts, id: \.category) { group in
                        Section(header: groupedShortcuts.count > 1 ? Text(group.category).font(.headline) : nil) {
                            ForEach(group.shortcuts) { shortcut in
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
    /// Input mode for shortcut entry
    enum InputMode: String, CaseIterable {
        case autoCapture = "Auto-capture"
        case manualEntry = "Manual Entry"
    }

    let appInfo: AppInfo
    let shortcut: ShortcutItem?
    let existingCategories: [String]
    let onSave: (ShortcutItem) -> Void
    let onCancel: () -> Void

    @State private var inputMode: InputMode = .autoCapture
    @State private var capturedShortcut: CapturedShortcut?
    @State private var manualInput: String = ""
    @State private var parseError: String?
    @State private var description: String = ""
    @State private var category: String = ""

    init(appInfo: AppInfo, shortcut: ShortcutItem?, existingCategories: [String] = [], onSave: @escaping (ShortcutItem) -> Void, onCancel: @escaping () -> Void) {
        self.appInfo = appInfo
        self.shortcut = shortcut
        self.existingCategories = existingCategories
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize with existing values if editing
        if let shortcut = shortcut {
            _description = State(initialValue: shortcut.description)
            _category = State(initialValue: shortcut.category ?? "")

            // Check if this looks like a manual entry (contains comma or has no modifiers with multi-char key)
            let isManualEntry = shortcut.key.contains(",") ||
                                shortcut.key.lowercased().contains(" then ") ||
                                (shortcut.modifiers.isEmpty && shortcut.key.count > 1)

            if isManualEntry {
                _inputMode = State(initialValue: .manualEntry)
                _manualInput = State(initialValue: shortcut.formattedShortcut)
            } else {
                // Create a CapturedShortcut from existing data
                _capturedShortcut = State(initialValue: CapturedShortcut(
                    key: shortcut.key,
                    modifiers: shortcut.modifiers,
                    keyCode: 0,  // We don't store keyCode in ShortcutItem
                    modifierFlags: CGEventFlags(rawValue: 0)  // We don't store flags in ShortcutItem
                ))
            }
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
                // Input mode picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input Mode")
                        .font(.headline)

                    Picker("", selection: $inputMode) {
                        Text("Auto-capture").tag(InputMode.autoCapture)
                        Text("Manual Entry").tag(InputMode.manualEntry)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .onChange(of: inputMode) { _ in
                        // Clear parse error when switching modes
                        parseError = nil
                    }

                    Text(inputModeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Shortcut section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shortcut")
                        .font(.headline)

                    if inputMode == .autoCapture {
                        ShortcutRecorderField(capturedShortcut: $capturedShortcut)
                    } else {
                        // Manual entry TextField
                        TextField("e.g., ⌘⇧N or Ctrl+B, C", text: $manualInput)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: manualInput) { newValue in
                                validateManualInput(newValue)
                            }

                        if let error = parseError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if !manualInput.isEmpty {
                            manualInputPreview
                        } else {
                            Text("Supports: ⌘⇧N, Cmd+Shift+N, Ctrl+B, C (prefix sequences)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Description section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    TextField("What does this shortcut do?", text: $description)
                        .textFieldStyle(.roundedBorder)
                }

                // Category section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)

                    HStack(spacing: 8) {
                        TextField("e.g., tmux, Neovim", text: $category)
                            .textFieldStyle(.roundedBorder)

                        if !existingCategories.isEmpty {
                            Menu {
                                ForEach(existingCategories, id: \.self) { existingCategory in
                                    Button(existingCategory) {
                                        category = existingCategory
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.down.circle")
                                    .foregroundColor(.secondary)
                            }
                            .menuStyle(.borderlessButton)
                            .frame(width: 24)
                            .help("Select from existing categories")
                        }
                    }

                    Text("Leave empty for General category")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                .disabled(!canSave)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 500, height: 480)
    }

    // MARK: - Computed Properties

    private var inputModeDescription: String {
        switch inputMode {
        case .autoCapture:
            return "Press keys to capture automatically"
        case .manualEntry:
            return "Type shortcuts manually (for complex sequences like tmux)"
        }
    }

    private var canSave: Bool {
        if inputMode == .autoCapture {
            return capturedShortcut != nil && !description.isEmpty
        } else {
            return !manualInput.isEmpty && parseError == nil && !description.isEmpty
        }
    }

    @ViewBuilder
    private var manualInputPreview: some View {
        let result = ShortcutParser.parse(manualInput)
        switch result {
        case .standard(let key, let modifiers):
            HStack(spacing: 4) {
                Text("Preview:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(modifiers, id: \.self) { modifier in
                    Text(modifier)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(3)
                }

                Text(key)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(3)
            }
        case .sequence(let displayText):
            HStack(spacing: 4) {
                Text("Sequence:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(displayText)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(3)
            }
        case .invalid:
            EmptyView()
        }
    }

    // MARK: - Methods

    private func validateManualInput(_ input: String) {
        if input.isEmpty {
            parseError = nil
            return
        }

        let result = ShortcutParser.parse(input)
        switch result {
        case .standard, .sequence:
            parseError = nil
        case .invalid(let error):
            parseError = error
        }
    }

    private func saveShortcut() {
        let newShortcut: ShortcutItem
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let categoryValue: String? = trimmedCategory.isEmpty ? nil : trimmedCategory

        if inputMode == .autoCapture {
            guard let captured = capturedShortcut else { return }
            newShortcut = ShortcutItem(
                id: shortcut?.id ?? UUID(),
                key: captured.key,
                modifiers: captured.modifiers,
                description: description,
                category: categoryValue
            )
        } else {
            let result = ShortcutParser.parse(manualInput)
            switch result {
            case .standard(let key, let modifiers):
                newShortcut = ShortcutItem(
                    id: shortcut?.id ?? UUID(),
                    key: key,
                    modifiers: modifiers,
                    description: description,
                    category: categoryValue
                )
            case .sequence(let displayText):
                // Store full sequence in key field, empty modifiers
                newShortcut = ShortcutItem(
                    id: shortcut?.id ?? UUID(),
                    key: displayText,
                    modifiers: [],
                    description: description,
                    category: categoryValue
                )
            case .invalid:
                return
            }
        }

        onSave(newShortcut)
    }
}
