import SwiftUI
import AppKit

/// Header view displaying the app icon and name
struct AppHeaderView: View {
    let appInfo: AppInfo

    var body: some View {
        HStack(spacing: 12) {
            // App icon
            if let icon = appInfo.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 32, height: 32)
            }

            // App name
            Text(appInfo.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

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
            .background(Color.white.opacity(0.1))

        AppHeaderView(appInfo: AppInfo(
            bundleIdentifier: "com.apple.finder",
            name: "Finder",
            icon: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app")
        ))
    }
    .background(Color.black)
}
