import SwiftUI

/// Main settings view for configuring application preferences
struct SettingsView: View {
    @ObservedObject var preferencesManager: PreferencesManager
    let hotkeyService: HotkeyService
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var workingConfig: AppPreferences.HotkeyConfiguration
    @State private var showAlert = false
    @State private var alertMessage = ""

    init(preferencesManager: PreferencesManager, hotkeyService: HotkeyService, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.preferencesManager = preferencesManager
        self.hotkeyService = hotkeyService
        self.onSave = onSave
        self.onCancel = onCancel
        self._workingConfig = State(initialValue: preferencesManager.globalHotkey)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("ShortcutOverlay Settings")
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
                    // Hotkey Configuration
                    HotkeyRecorderView(
                        config: $workingConfig,
                        onValidationError: { message in
                            alertMessage = message
                            showAlert = true
                        }
                    )

                    Divider()

                    // Future settings placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Other Settings")
                            .font(.headline)

                        Text("More settings coming soon...")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Future: Launch at login, Show in Dock, etc.
                    }
                    .padding()
                }
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

    private func saveSettings() {
        // Update preferences
        preferencesManager.updateGlobalHotkey(workingConfig)

        // Update hotkey service
        hotkeyService.updateHotkey(workingConfig)

        // Call save callback
        onSave()
    }
}
