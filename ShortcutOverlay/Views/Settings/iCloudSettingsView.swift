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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#if DEBUG
struct iCloudSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        iCloudSettingsView(syncService: iCloudSyncService())
            .frame(width: 400)
    }
}
#endif
