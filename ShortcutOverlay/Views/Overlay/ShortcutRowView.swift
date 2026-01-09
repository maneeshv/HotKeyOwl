import SwiftUI

/// A row displaying a keyboard shortcut and its description
struct ShortcutRowView: View {
    let shortcut: ShortcutItem

    var body: some View {
        HStack(spacing: 16) {
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
                .foregroundColor(.white.opacity(0.9))
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
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
