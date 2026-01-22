import SwiftUI
import AppKit

struct OverlayTheme {
    let colorScheme: ColorScheme

    var isDark: Bool {
        colorScheme == .dark
    }

    var primaryText: Color {
        isDark ? .white : Color.black.opacity(0.85)
    }

    var secondaryText: Color {
        isDark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }

    var tertiaryText: Color {
        isDark ? Color.white.opacity(0.6) : Color.black.opacity(0.5)
    }

    var mutedText: Color {
        isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.45)
    }

    var iconMuted: Color {
        isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.35)
    }

    var icon: Color {
        isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.5)
    }

    var dividerGradientColors: [Color] {
        isDark
            ? [Color.white.opacity(0.0), Color.white.opacity(0.15), Color.white.opacity(0.0)]
            : [Color.black.opacity(0.0), Color.black.opacity(0.12), Color.black.opacity(0.0)]
    }

    var categoryLabel: Color {
        isDark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }

    var categoryBackground: Color {
        isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.06)
    }

    var rowBackground: Color {
        isDark ? Color.white.opacity(0.03) : Color.black.opacity(0.05)
    }

    var keyCapText: Color {
        isDark ? Color.white.opacity(0.95) : Color.black.opacity(0.85)
    }

    var keyCapShadow: Color {
        isDark ? Color.black.opacity(0.3) : Color.black.opacity(0.15)
    }

    var headerShadow: Color {
        isDark ? Color.black.opacity(0.3) : Color.black.opacity(0.15)
    }

    var searchPlaceholder: Color {
        isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.45)
    }

    var searchText: Color {
        isDark ? .white : Color.black.opacity(0.85)
    }

    var clearButton: Color {
        isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.45)
    }

    var addButton: Color {
        isDark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }

    var emptyIcon: Color {
        isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.35)
    }

    var emptyTitle: Color {
        isDark ? Color.white.opacity(0.8) : Color.black.opacity(0.75)
    }

    var emptySubtitle: Color {
        isDark ? Color.white.opacity(0.6) : Color.black.opacity(0.5)
    }

    var panelShadow: Color {
        isDark ? Color.black.opacity(0.4) : Color.black.opacity(0.2)
    }

    var glassHighlightGradient: [Color] {
        isDark
            ? [Color.white.opacity(0.15), Color.white.opacity(0.05), Color.clear]
            : [Color.white.opacity(0.75), Color.white.opacity(0.25), Color.clear]
    }

    var glassBorderGradient: [Color] {
        isDark
            ? [Color.white.opacity(0.3), Color.white.opacity(0.1)]
            : [Color.black.opacity(0.12), Color.black.opacity(0.04)]
    }

    var keyCapInnerGradient: [Color] {
        isDark
            ? [Color.white.opacity(0.15), Color.white.opacity(0.03)]
            : [Color.black.opacity(0.08), Color.black.opacity(0.02)]
    }

    var keyCapBorderGradient: [Color] {
        isDark
            ? [Color.white.opacity(0.35), Color.white.opacity(0.12)]
            : [Color.black.opacity(0.2), Color.black.opacity(0.08)]
    }

    var searchBarBorder: Color {
        isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.1)
    }

    var glassMaterial: NSVisualEffectView.Material {
        isDark ? .hudWindow : .sidebar
    }
}
