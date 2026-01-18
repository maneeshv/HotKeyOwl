import SwiftUI

/// General settings section containing hotkey and activation mode configuration
struct GeneralSettingsView: View {
    @Binding var workingConfig: AppPreferences.HotkeyConfiguration
    @Binding var workingHotkeyMode: HotkeyMode
    var onValidationError: (String) -> Void

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
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
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
            onValidationError: { _ in }
        )
        .frame(width: 400, height: 300)
    }
}
#endif
