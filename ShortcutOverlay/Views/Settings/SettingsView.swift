import SwiftUI

/// Main settings view for configuring application preferences
struct SettingsView: View {
    @ObservedObject var preferencesManager: PreferencesManager
    @ObservedObject var syncService: iCloudSyncService
    let hotkeyService: HotkeyService
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var workingConfig: AppPreferences.HotkeyConfiguration
    @State private var workingHotkeyMode: HotkeyMode
    @State private var showAlert = false
    @State private var alertMessage = ""

    init(preferencesManager: PreferencesManager, syncService: iCloudSyncService, hotkeyService: HotkeyService, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.preferencesManager = preferencesManager
        self.syncService = syncService
        self.hotkeyService = hotkeyService
        self.onSave = onSave
        self.onCancel = onCancel
        self._workingConfig = State(initialValue: preferencesManager.globalHotkey)
        self._workingHotkeyMode = State(initialValue: preferencesManager.hotkeyMode)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("\(AppConstants.appName) Settings")
                    .font(.title2)
                    .bold()

                Text("Configure your global hotkey and preferences")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HotkeyRecorderView(
                        config: $workingConfig,
                        onValidationError: { message in
                            alertMessage = message
                            showAlert = true
                        }
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

                    Divider()

                    iCloudSyncSettingsView(syncService: syncService)
                }
                .padding()
            }

            Divider()

            // Footer buttons
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    saveSettings()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .alert("Invalid Hotkey", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
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

    private func saveSettings() {
        // Update preferences
        preferencesManager.updateGlobalHotkey(workingConfig)
        preferencesManager.updateHotkeyMode(workingHotkeyMode)

        // Update hotkey service
        hotkeyService.updateHotkey(workingConfig)
        hotkeyService.updateHotkeyMode(workingHotkeyMode)

        // Call save callback
        onSave()
    }
}
