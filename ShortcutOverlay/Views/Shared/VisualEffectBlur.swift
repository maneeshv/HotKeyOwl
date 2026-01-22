import SwiftUI
import AppKit

/// NSViewRepresentable wrapper for NSVisualEffectView
/// Provides frosted glass background for macOS 13+
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State

    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

#Preview {
    ZStack {
        // Background content to see blur effect
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        VStack {
            Text("Behind the blur")
                .font(.largeTitle)
                .foregroundColor(.white)
        }

        // Blurred overlay
        RoundedRectangle(cornerRadius: 16)
            .fill(.clear)
            .background(
                VisualEffectBlur(material: .hudWindow)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(width: 300, height: 200)
    }
    .frame(width: 500, height: 400)
}
