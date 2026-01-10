import Foundation

/// Metadata for tracking iCloud sync state
struct SyncMetadata: Codable {
    /// Last successful sync date
    var lastSyncDate: Date?

    /// Device identifier that performed the last sync
    var deviceIdentifier: String?

    /// Sync schema version for future migrations
    var syncVersion: Int

    /// Initialize with default values
    init(lastSyncDate: Date? = nil, deviceIdentifier: String? = nil, syncVersion: Int = 1) {
        self.lastSyncDate = lastSyncDate
        self.deviceIdentifier = deviceIdentifier
        self.syncVersion = syncVersion
    }

    /// Current device identifier
    static var currentDeviceIdentifier: String {
        return Host.current().localizedName ?? ProcessInfo.processInfo.hostName
    }

    /// Create metadata for current device
    static func current() -> SyncMetadata {
        return SyncMetadata(
            lastSyncDate: Date(),
            deviceIdentifier: currentDeviceIdentifier,
            syncVersion: 1
        )
    }
}
