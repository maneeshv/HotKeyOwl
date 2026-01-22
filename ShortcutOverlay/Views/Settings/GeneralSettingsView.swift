import SwiftUI

/// General settings section containing hotkey and activation mode configuration
struct GeneralSettingsView: View {
    @Binding var workingConfig: AppPreferences.HotkeyConfiguration
    @Binding var workingHotkeyMode: HotkeyMode
    @Binding var workingAppearanceMode: AppearanceMode
    var onValidationError: (String) -> Void

    @State private var launchAtLogin = LaunchAtLoginService.shared.isEnabled

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("General")
                    .font(.title2)
                    .bold()

                HotkeyRecorderView(
                    config: $workingConfig,
                    onValidationError: onValidationError
                )

                // Hotkey Mode Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activation Mode")
                        .font(.headline)

                    Picker("", selection: $workingHotkeyMode) {
                        Text("Hold to show").tag(HotkeyMode.hold)
                        Text("Press to toggle").tag(HotkeyMode.toggle)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    Text(modeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Appearance Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance")
                        .font(.headline)

                    Picker("", selection: $workingAppearanceMode) {
                        Text("Automatic").tag(AppearanceMode.automatic)
                        Text("Light").tag(AppearanceMode.light)
                        Text("Dark").tag(AppearanceMode.dark)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    Text("Match the system appearance or override it for the app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Launch at Login Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Startup")
                        .font(.headline)

                    Toggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            LaunchAtLoginService.shared.setEnabled(newValue)
                        }

                    Text("Automatically start ShortcutOverlay when you log in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            // Refresh from system state in case user changed it in System Settings
            launchAtLogin = LaunchAtLoginService.shared.isEnabled
        }
    }

    private var modeDescription: String {
        switch workingHotkeyMode {
        case .hold:
            return "Press and hold the hotkey to show the overlay. Release to hide."
        case .toggle:
            return "Press the hotkey to show the overlay. Press again or Esc to hide."
        }
    }
}

#if DEBUG
struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView(
            workingConfig: .constant(AppPreferences.default.globalHotkey),
            workingHotkeyMode: .constant(.hold),
            workingAppearanceMode: .constant(.automatic),
            onValidationError: { _ in }
        )
        .frame(width: 400, height: 300)
    }
}
#endif
