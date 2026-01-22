import SwiftUI

/// A row displaying a keyboard shortcut and its description
struct ShortcutRowView: View {
    let shortcut: ShortcutItem

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        return HStack(spacing: 16) {
            // Keyboard shortcut display
            HStack(spacing: 4) {
                ForEach(shortcut.modifiers, id: \.self) { modifier in
                    KeyCapView(text: modifier)
                }
                KeyCapView(text: shortcut.key)
            }
            .frame(minWidth: 100, alignment: .leading)

            // Description
            Text(shortcut.description)
                .foregroundColor(theme.primaryText)
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.rowBackground)
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        ShortcutRowView(shortcut: ShortcutItem(
            key: "C",
            modifiers: ["⌘"],
            description: "Copy"
        ))

        ShortcutRowView(shortcut: ShortcutItem(
            key: "V",
            modifiers: ["⌘"],
            description: "Paste"
        ))

        ShortcutRowView(shortcut: ShortcutItem(
            key: "N",
            modifiers: ["⌘", "⇧"],
            description: "New Window"
        ))

        ShortcutRowView(shortcut: ShortcutItem(
            key: "T",
            modifiers: ["⌘", "⌥", "⇧"],
            description: "Reopen Closed Tab"
        ))
    }
    .padding()
    .background(Color.black)
}
