import SwiftUI

/// iCloud settings section wrapper
struct iCloudSettingsView: View {
    @ObservedObject var syncService: iCloudSyncService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("iCloud")
                    .font(.title2)
                    .bold()

                iCloudSyncSettingsView(syncService: syncService)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
