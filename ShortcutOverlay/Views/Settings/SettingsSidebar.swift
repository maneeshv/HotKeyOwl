import SwiftUI

/// Sidebar navigation for settings sections
struct SettingsSidebar: View {
    @Binding var selection: SettingsSection?

    var body: some View {
        List(SettingsSection.allCases, selection: $selection) { section in
            Label(section.rawValue, systemImage: section.icon)
                .tag(section)
        }
        .listStyle(.sidebar)
    }
}
