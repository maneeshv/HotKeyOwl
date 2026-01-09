import SwiftUI

/// A view that displays a single keyboard key with styling
struct KeyCapView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
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
