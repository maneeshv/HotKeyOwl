import SwiftUI

/// Main overlay view displaying app shortcuts
struct OverlayView: View {
    let appInfo: AppInfo
    let shortcuts: [ShortcutItem]

    @StateObject private var viewModel: OverlayViewModel
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    init(appInfo: AppInfo, shortcuts: [ShortcutItem]) {
        self.appInfo = appInfo
        self.shortcuts = shortcuts
        _viewModel = StateObject(wrappedValue: OverlayViewModel(shortcuts: shortcuts))
    }

    var body: some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        return VStack(spacing: 0) {
            // App header with icon and name
            AppHeaderView(appInfo: appInfo)

            // Glass divider with gradient glow
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: theme.dividerGradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Search bar with add button
            searchBarWithAddButton
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            // Shortcuts list, empty state, or no results state
            if viewModel.isEmpty {
                emptyState
            } else if viewModel.hasNoResults {
                noResultsState
            } else {
                shortcutsList
            }
        }
        .frame(maxWidth: .infinity)
        .glassStyle(cornerRadius: 16)
        .shadow(color: theme.panelShadow, radius: 30, x: 0, y: 15)
        .onAppear {
            // Auto-focus search bar with small delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
        .background(
            // Handle ⌘N keyboard shortcut to open editor
            KeyboardShortcutHandler(
                key: "n",
                modifiers: .command,
                action: requestOpenEditor
            )
        )
    }

    // MARK: - Private Methods

    /// Hides the overlay and posts a notification to open the shortcut editor for this app
    private func requestOpenEditor() {
        NotificationCenter.default.post(name: .hideOverlay, object: nil)
        NotificationCenter.default.post(
            name: .openEditorFromOverlay,
            object: nil,
            userInfo: ["bundleIdentifier": appInfo.bundleIdentifier]
        )
    }

    // MARK: - Subviews

    private var shortcutsList: some View {
        ScrollView {
            if viewModel.groupedShortcuts.count == 1 {
                // Single category: full-width vertical list
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.groupedShortcuts[0].shortcuts) { shortcut in
                        ShortcutRowView(shortcut: shortcut)
                    }
                }
                .padding(16)
            } else {
                // Multiple categories: 2-column grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), alignment: .top),
                    GridItem(.flexible(), alignment: .top)
                ], alignment: .leading, spacing: 16) {
                    ForEach(viewModel.groupedShortcuts, id: \.category) { group in
                        categorySectionView(category: group.category, shortcuts: group.shortcuts)
                    }
                }
                .padding(16)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func categorySectionView(category: String, shortcuts: [ShortcutItem]) -> some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        return VStack(alignment: .leading, spacing: 8) {
            // Section header with subtle backdrop
            Text(category.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.categoryLabel)
                .tracking(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.categoryBackground, in: RoundedRectangle(cornerRadius: 4))
                .padding(.bottom, 4)

            // Shortcuts in this category
            ForEach(shortcuts) { shortcut in
                ShortcutRowView(shortcut: shortcut)
            }
        }
    }

    private var emptyState: some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        return VStack(spacing: 12) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundColor(theme.emptyIcon)

            Text("No Shortcuts Configured")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.emptyTitle)

            Text("Click the menu bar icon to add shortcuts for this app")
                .font(.system(size: 13))
                .foregroundColor(theme.emptySubtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(height: 200)
        .padding()
    }

    private var noResultsState: some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        return VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(theme.emptyIcon)

            Text("No Matching Shortcuts")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.emptyTitle)

            Text("Try a different search term")
                .font(.system(size: 13))
                .foregroundColor(theme.emptySubtitle)
        }
        .frame(height: 200)
        .padding()
    }

    private var searchBarWithAddButton: some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        return HStack(spacing: 12) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(theme.searchPlaceholder)

                TextField("Search shortcuts...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(theme.searchText)
                    .focused($isSearchFocused)

                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(theme.clearButton)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .searchBarGlassStyle()

            // Add button - opens editor
            Button(action: requestOpenEditor) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(theme.addButton)
            }
            .buttonStyle(.plain)
            .help("Add Shortcut (⌘N)")
        }
    }
}

#Preview("With Shortcuts") {
    OverlayView(
        appInfo: AppInfo(
            bundleIdentifier: "com.apple.Safari",
            name: "Safari",
            icon: NSWorkspace.shared.icon(forFile: "/Applications/Safari.app")
        ),
        shortcuts: [
            ShortcutItem(key: "T", modifiers: ["⌘"], description: "New Tab"),
            ShortcutItem(key: "W", modifiers: ["⌘"], description: "Close Tab"),
            ShortcutItem(key: "R", modifiers: ["⌘"], description: "Reload Page"),
            ShortcutItem(key: "L", modifiers: ["⌘"], description: "Focus URL Bar"),
            ShortcutItem(key: "T", modifiers: ["⌘", "⇧"], description: "Reopen Closed Tab"),
            ShortcutItem(key: "[", modifiers: ["⌘"], description: "Back"),
            ShortcutItem(key: "]", modifiers: ["⌘"], description: "Forward"),
            ShortcutItem(key: "N", modifiers: ["⌘"], description: "New Window")
        ]
    )
    .preferredColorScheme(.dark)
}

#Preview("With Shortcuts - Light") {
    OverlayView(
        appInfo: AppInfo(
            bundleIdentifier: "com.apple.Safari",
            name: "Safari",
            icon: NSWorkspace.shared.icon(forFile: "/Applications/Safari.app")
        ),
        shortcuts: [
            ShortcutItem(key: "T", modifiers: ["⌘"], description: "New Tab"),
            ShortcutItem(key: "W", modifiers: ["⌘"], description: "Close Tab"),
            ShortcutItem(key: "R", modifiers: ["⌘"], description: "Reload Page"),
            ShortcutItem(key: "L", modifiers: ["⌘"], description: "Focus URL Bar"),
            ShortcutItem(key: "T", modifiers: ["⌘", "⇧"], description: "Reopen Closed Tab"),
            ShortcutItem(key: "[", modifiers: ["⌘"], description: "Back"),
            ShortcutItem(key: "]", modifiers: ["⌘"], description: "Forward"),
            ShortcutItem(key: "N", modifiers: ["⌘"], description: "New Window")
        ]
    )
    .preferredColorScheme(.light)
}

#Preview("With Categories - Grid") {
    OverlayView(
        appInfo: AppInfo(
            bundleIdentifier: "dev.warp.Warp-Stable",
            name: "Warp",
            icon: NSWorkspace.shared.icon(forFile: "/Applications/Warp.app")
        ),
        shortcuts: [
            // Warp shortcuts
            ShortcutItem(key: "T", modifiers: ["⌘"], description: "New Tab", category: "Warp"),
            ShortcutItem(key: "W", modifiers: ["⌘"], description: "Close Tab", category: "Warp"),
            ShortcutItem(key: "K", modifiers: ["⌘"], description: "Clear Terminal", category: "Warp"),
            // tmux shortcuts
            ShortcutItem(key: "Ctrl+B, C", modifiers: [], description: "New Window", category: "tmux"),
            ShortcutItem(key: "Ctrl+B, N", modifiers: [], description: "Next Window", category: "tmux"),
            ShortcutItem(key: "Ctrl+B, %", modifiers: [], description: "Split Horizontal", category: "tmux"),
            // Neovim shortcuts
            ShortcutItem(key: "i", modifiers: [], description: "Insert Mode", category: "Neovim"),
            ShortcutItem(key: "v", modifiers: [], description: "Visual Mode", category: "Neovim"),
            ShortcutItem(key: ":w", modifiers: [], description: "Save File", category: "Neovim")
        ]
    )
}

#Preview("With 4+ Categories - Grid") {
    OverlayView(
        appInfo: AppInfo(
            bundleIdentifier: "dev.warp.Warp-Stable",
            name: "Warp",
            icon: NSWorkspace.shared.icon(forFile: "/Applications/Warp.app")
        ),
        shortcuts: [
            // Warp shortcuts
            ShortcutItem(key: "T", modifiers: ["⌘"], description: "New Tab", category: "Warp"),
            ShortcutItem(key: "W", modifiers: ["⌘"], description: "Close Tab", category: "Warp"),
            ShortcutItem(key: "K", modifiers: ["⌘"], description: "Clear Terminal", category: "Warp"),
            // tmux shortcuts
            ShortcutItem(key: "Ctrl+B, C", modifiers: [], description: "New Window", category: "tmux"),
            ShortcutItem(key: "Ctrl+B, N", modifiers: [], description: "Next Window", category: "tmux"),
            ShortcutItem(key: "Ctrl+B, %", modifiers: [], description: "Split Horizontal", category: "tmux"),
            ShortcutItem(key: "Ctrl+B, \"", modifiers: [], description: "Split Vertical", category: "tmux"),
            // Neovim shortcuts
            ShortcutItem(key: "i", modifiers: [], description: "Insert Mode", category: "Neovim"),
            ShortcutItem(key: "v", modifiers: [], description: "Visual Mode", category: "Neovim"),
            ShortcutItem(key: ":w", modifiers: [], description: "Save File", category: "Neovim"),
            ShortcutItem(key: ":q", modifiers: [], description: "Quit", category: "Neovim"),
            // Git shortcuts
            ShortcutItem(key: "gs", modifiers: [], description: "Git Status", category: "Git"),
            ShortcutItem(key: "gc", modifiers: [], description: "Git Commit", category: "Git"),
            ShortcutItem(key: "gp", modifiers: [], description: "Git Push", category: "Git")
        ]
    )
}

#Preview("Empty State") {
    OverlayView(
        appInfo: AppInfo(
            bundleIdentifier: "com.apple.Terminal",
            name: "Terminal",
            icon: NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Terminal.app")
        ),
        shortcuts: []
    )
}

// MARK: - Keyboard Shortcut Handler

/// A view that captures keyboard shortcuts using NSView event monitoring
struct KeyboardShortcutHandler: NSViewRepresentable {
    let key: String
    let modifiers: NSEvent.ModifierFlags
    let action: () -> Void

    func makeNSView(context: Context) -> KeyboardShortcutNSView {
        let view = KeyboardShortcutNSView()
        view.targetKey = key.lowercased()
        view.targetModifiers = modifiers
        view.action = action
        return view
    }

    func updateNSView(_ nsView: KeyboardShortcutNSView, context: Context) {
        nsView.targetKey = key.lowercased()
        nsView.targetModifiers = modifiers
        nsView.action = action
    }
}

/// NSView that monitors for keyboard shortcuts
class KeyboardShortcutNSView: NSView {
    var targetKey: String = ""
    var targetModifiers: NSEvent.ModifierFlags = []
    var action: (() -> Void)?

    private var localMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
        guard localMonitor == nil else { return }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            let keyPressed = event.charactersIgnoringModifiers?.lowercased() ?? ""
            let modifiersMatch = event.modifierFlags.intersection([.command, .control, .option, .shift]) == self.targetModifiers

            if keyPressed == self.targetKey && modifiersMatch {
                self.action?()
                return nil // Consume the event
            }
            return event
        }
    }

    private func stopMonitoring() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    deinit {
        stopMonitoring()
    }
}
