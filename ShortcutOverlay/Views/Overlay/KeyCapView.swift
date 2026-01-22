import SwiftUI

/// A view that displays a single keyboard key with styling
struct KeyCapView: View {
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        return Text(text)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundColor(theme.keyCapText)
            .shadow(color: theme.keyCapShadow, radius: 1, x: 0, y: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .keyCapGlassStyle()
    }
}

#Preview {
    VStack(spacing: 10) {
        KeyCapView(text: "⌘")
        KeyCapView(text: "⇧")
        KeyCapView(text: "C")
        HStack(spacing: 4) {
            KeyCapView(text: "⌘")
            KeyCapView(text: "⇧")
            KeyCapView(text: "P")
        }
    }
    .padding()
    .background(Color.black)
}
