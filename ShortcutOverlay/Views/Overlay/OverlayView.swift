import SwiftUI

/// Main overlay view displaying app shortcuts
struct OverlayView: View {
    let appInfo: AppInfo
    let shortcuts: [ShortcutItem]

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

    var body: some View {
        VStack(spacing: 0) {
            // App header with icon and name
            AppHeaderView(appInfo: appInfo)

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 16)

            // Shortcuts list or empty state
            if shortcuts.isEmpty {
                emptyState
            } else {
                shortcutsList
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    // MARK: - Subviews

    private var shortcutsList: some View {
        ScrollView {
            if groupedShortcuts.count == 1 {
                // Single category: full-width vertical list
                LazyVStack(spacing: 8) {
                    ForEach(groupedShortcuts[0].shortcuts) { shortcut in
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
                    ForEach(groupedShortcuts, id: \.category) { group in
                        categorySectionView(category: group.category, shortcuts: group.shortcuts)
                    }
                }
                .padding(16)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func categorySectionView(category: String, shortcuts: [ShortcutItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text(category.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1)
                .padding(.bottom, 4)

            // Shortcuts in this category
            ForEach(shortcuts) { shortcut in
                ShortcutRowView(shortcut: shortcut)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))

            Text("No Shortcuts Configured")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Text("Click the menu bar icon to add shortcuts for this app")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(height: 200)
        .padding()
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
            ShortcutItem(key: "N", modifiers: ["⌘"], description: "New Window"),
        ]
    )
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
            ShortcutItem(key: ":w", modifiers: [], description: "Save File", category: "Neovim"),
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
            ShortcutItem(key: "gp", modifiers: [], description: "Git Push", category: "Git"),
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
