import SwiftUI
import AppKit

/// Header view displaying the app icon and name
struct AppHeaderView: View {
    let appInfo: AppInfo

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = OverlayTheme(colorScheme: colorScheme)

        return HStack(spacing: 12) {
            // App icon
            if let icon = appInfo.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.rowBackground)
                    .frame(width: 32, height: 32)
            }

            // App name with subtle shadow for depth
            Text(appInfo.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.primaryText)
                .shadow(color: theme.headerShadow, radius: 2, x: 0, y: 1)

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 0) {
        AppHeaderView(appInfo: AppInfo(
            bundleIdentifier: "com.apple.Safari",
            name: "Safari",
            icon: NSWorkspace.shared.icon(forFile: "/Applications/Safari.app")
        ))

        Divider()

        AppHeaderView(appInfo: AppInfo(
            bundleIdentifier: "com.apple.finder",
            name: "Finder",
            icon: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app")
        ))
    }
    .padding()
}
