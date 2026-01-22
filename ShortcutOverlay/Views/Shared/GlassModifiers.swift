import SwiftUI

// MARK: - Glass Background Component

/// Adaptive glass background that simulates Liquid Glass on macOS 13+
/// and uses native glassEffect on macOS 26+ when available
struct GlassBackground<S: Shape>: View {
    let shape: S
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(in shape: S, cornerRadius: CGFloat = 16) {
        self.shape = shape
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        ZStack {
            // Base blur layer using NSVisualEffectView
            VisualEffectBlur(
                material: theme.glassMaterial,
                blendingMode: .behindWindow,
                state: .active
            )
            .clipShape(shape)

            // Subtle specular highlight (top edge glow)
            LinearGradient(
                colors: theme.glassHighlightGradient,
                startPoint: .top,
                endPoint: .center
            )
            .clipShape(shape)

            // Gradient border for glass edge effect
            shape
                .stroke(
                    LinearGradient(
                        colors: theme.glassBorderGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
    }
}

// Convenience initializer for RoundedRectangle
extension GlassBackground where S == RoundedRectangle {
    init(cornerRadius: CGFloat) {
        self.init(in: RoundedRectangle(cornerRadius: cornerRadius), cornerRadius: cornerRadius)
    }
}

// MARK: - Glass Style View Modifier

struct GlassStyleModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                GlassBackground(cornerRadius: cornerRadius)
            )
    }
}

extension View {
    /// Apply glass effect with rounded rectangle
    func glassStyle(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassStyleModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Key Cap Glass Modifier

struct KeyCapGlassModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(keyCapBackground)
            .overlay(keyCapBorder)
    }

    private var keyCapBackground: some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        return ZStack {
            // Frosted base using thin material
            RoundedRectangle(cornerRadius: 5)
                .fill(.ultraThinMaterial)

            // Inner glow gradient
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: theme.keyCapInnerGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var keyCapBorder: some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        return RoundedRectangle(cornerRadius: 5)
            .stroke(
                LinearGradient(
                    colors: theme.keyCapBorderGradient,
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
    }
}

extension View {
    /// Apply glass styling to keyboard key caps
    func keyCapGlassStyle() -> some View {
        modifier(KeyCapGlassModifier())
    }
}

// MARK: - Search Bar Glass Modifier

struct SearchBarGlassModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        return content
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.searchBarBorder, lineWidth: 0.5)
            )
    }
}

extension View {
    /// Apply glass styling to search bars
    func searchBarGlassStyle() -> some View {
        modifier(SearchBarGlassModifier())
    }
}

// MARK: - Previews

#Preview("Glass Background") {
    ZStack {
        // Colorful background to see glass effect
        LinearGradient(
            colors: [.blue, .purple, .pink, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        VStack(spacing: 20) {
            Text("Content behind glass")
                .font(.title)
                .foregroundColor(.white)

            // Glass panel
            VStack(spacing: 16) {
                Text("Glass Panel")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("This is inside the frosted glass")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(24)
            .glassStyle(cornerRadius: 16)
        }
    }
    .frame(width: 400, height: 300)
    .preferredColorScheme(.dark)
}

#Preview("Key Cap Glass") {
    ZStack {
        Color.black

        HStack(spacing: 6) {
            Text("⌘")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .keyCapGlassStyle()

            Text("⇧")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .keyCapGlassStyle()

            Text("P")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .keyCapGlassStyle()
        }
    }
    .frame(width: 300, height: 100)
    .preferredColorScheme(.dark)
}

#Preview("Search Bar Glass") {
    ZStack {
        Color.black

        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))

            Text("Search shortcuts...")
                .foregroundColor(.white.opacity(0.5))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 280)
        .searchBarGlassStyle()
    }
    .frame(width: 400, height: 100)
    .preferredColorScheme(.dark)
}
