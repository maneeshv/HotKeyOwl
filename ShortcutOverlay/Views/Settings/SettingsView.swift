import SwiftUI

/// Settings section for sidebar navigation
enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case icloud = "iCloud"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .icloud: return "icloud"
        }
    }
}

/// Main settings view for configuring application preferences
struct SettingsView: View {
    @ObservedObject var preferencesManager: PreferencesManager
    @ObservedObject var syncService: iCloudSyncService
    let hotkeyService: HotkeyService
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var workingConfig: AppPreferences.HotkeyConfiguration
    @State private var workingHotkeyMode: HotkeyMode
    @State private var workingAppearanceMode: AppearanceMode
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedSection: SettingsSection? = .general

    init(preferencesManager: PreferencesManager, syncService: iCloudSyncService, hotkeyService: HotkeyService, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.preferencesManager = preferencesManager
        self.syncService = syncService
        self.hotkeyService = hotkeyService
        self.onSave = onSave
        self.onCancel = onCancel
        self._workingConfig = State(initialValue: preferencesManager.globalHotkey)
        self._workingHotkeyMode = State(initialValue: preferencesManager.hotkeyMode)
        self._workingAppearanceMode = State(initialValue: preferencesManager.appearanceMode)
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                SettingsSidebar(selection: $selectedSection)
                    .navigationSplitViewColumnWidth(min: 150, ideal: 180)
            } detail: {
                Group {
                    switch selectedSection {
                    case .general:
                        GeneralSettingsView(
                            workingConfig: $workingConfig,
                            workingHotkeyMode: $workingHotkeyMode,
                            workingAppearanceMode: $workingAppearanceMode,
                            onValidationError: { message in
                                alertMessage = message
                                showAlert = true
                            }
                        )
                    case .icloud:
                        iCloudSettingsView(syncService: syncService)
                    case .none:
                        Text("Select a section")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationSplitViewStyle(.balanced)

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
        .frame(width: 600, height: 450)
        .alert("Invalid Hotkey", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func saveSettings() {
        // Update preferences
        preferencesManager.updatePreferences { current in
            current.globalHotkey = workingConfig
            current.hotkeyMode = workingHotkeyMode
            current.appearanceMode = workingAppearanceMode
        }

        // Update hotkey service
        hotkeyService.updateHotkey(workingConfig)
        hotkeyService.updateHotkeyMode(workingHotkeyMode)

        // Call save callback
        onSave()
    }
}
