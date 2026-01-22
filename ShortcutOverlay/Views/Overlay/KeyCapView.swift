import SwiftUI

/// A view that displays a single keyboard key with styling
struct KeyCapView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundColor(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
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
