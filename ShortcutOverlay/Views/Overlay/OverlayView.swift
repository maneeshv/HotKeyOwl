import SwiftUI

/// Main overlay view displaying app shortcuts
struct OverlayView: View {
    let appInfo: AppInfo
    let shortcuts: [ShortcutItem]

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
        .frame(width: 400)
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
            LazyVStack(spacing: 8) {
                ForEach(shortcuts) { shortcut in
                    ShortcutRowView(shortcut: shortcut)
                }
            }
            .padding(16)
        }
        .frame(maxHeight: 450)
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
