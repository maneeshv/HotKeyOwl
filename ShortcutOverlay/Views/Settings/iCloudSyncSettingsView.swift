import SwiftUI

/// View for iCloud sync settings
struct iCloudSyncSettingsView: View {
    @ObservedObject var syncService: iCloudSyncService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("iCloud Sync")
                .font(.headline)

            // Main toggle
            Toggle("Enable iCloud Sync", isOn: $syncService.syncEnabled)
                .disabled(!syncService.iCloudAvailable)
                .toggleStyle(.switch)

            // Status indicator
            HStack(spacing: 8) {
                statusIcon
                statusText
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            // Sync Now button
            if syncService.syncEnabled && syncService.iCloudAvailable {
                HStack {
                    Button(action: {
                        syncService.triggerManualSync()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Now")
                        }
                    }
                    .disabled(syncService.syncState == .syncing)

                    Spacer()

                    // Last sync date
                    if let lastSync = syncService.lastSyncDate {
                        Text("Last sync: \(lastSync, formatter: Self.dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Warning if iCloud unavailable
            if !syncService.iCloudAvailable {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("iCloud is not available. Sign in to iCloud in System Settings to enable sync.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }

            // Info text
            if syncService.syncEnabled && syncService.iCloudAvailable {
                Text("Your hotkey settings and shortcuts will sync across all your Macs signed into the same iCloud account.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: - Status Icon

    @ViewBuilder
    private var statusIcon: some View {
        switch syncService.syncState {
        case .disabled:
            Image(systemName: "icloud.slash")
                .foregroundColor(.secondary)
        case .unavailable:
            Image(systemName: "icloud.slash")
                .foregroundColor(.orange)
        case .syncing:
            ProgressView()
                .scaleEffect(0.7)
        case .synced:
            Image(systemName: "checkmark.icloud")
                .foregroundColor(.green)
        case .error:
            Image(systemName: "exclamationmark.icloud")
                .foregroundColor(.red)
        }
    }

    // MARK: - Status Text

    private var statusText: Text {
        switch syncService.syncState {
        case .disabled:
            return Text("Sync disabled")
        case .unavailable:
            return Text("iCloud unavailable")
        case .syncing:
            return Text("Syncing...")
        case .synced:
            return Text("Up to date")
        case .error(let message):
            return Text("Error: \(message)")
        }
    }

    // MARK: - Date Formatter

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview

#if DEBUG
struct iCloudSyncSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        iCloudSyncSettingsView(syncService: iCloudSyncService())
            .frame(width: 400)
            .padding()
    }
}
#endif
