import Foundation
import Combine

/// iCloud sync state enumeration
enum iCloudSyncState: Equatable {
    case disabled
    case unavailable
    case syncing
    case synced
    case error(String)
}

@MainActor
class iCloudSyncService: ObservableObject {

    // MARK: - Published Properties

    /// Current sync state
    @Published private(set) var syncState: iCloudSyncState = .disabled

    /// Whether iCloud is available on this device
    @Published private(set) var iCloudAvailable: Bool = false

    /// Whether sync is enabled by the user (persisted in UserDefaults)
    @Published var syncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(syncEnabled, forKey: Self.syncEnabledKey)
            if syncEnabled {
                startSync()
            } else {
                stopSync()
            }
        }
    }


    /// Last sync date for display
    @Published private(set) var lastSyncDate: Date?

    // MARK: - Private Properties

    private let keyValueStore = NSUbiquitousKeyValueStore.default
    private var keyValueObserver: NSObjectProtocol?
    private var metadataQuery: NSMetadataQuery?
    private let coordinator = iCloudSyncCoordinator()
    private let pipeline = iCloudSyncPipeline()

    // References to managers (set by AppDelegate)
    weak var preferencesManager: PreferencesManager?
    weak var shortcutStore: ShortcutStore?

    // MARK: - Constants

    private static let syncEnabledKey = "iCloudSyncEnabled"
    private static let preferencesCloudKey = "preferences_v1"
    private static let shortcutsFileName = "shortcuts.json"
    private static let lastSyncDateKey = "lastSyncDate"

    // MARK: - Initialization

    init() {
        self.syncEnabled = UserDefaults.standard.bool(forKey: Self.syncEnabledKey)
        self.lastSyncDate = UserDefaults.standard.object(forKey: Self.lastSyncDateKey) as? Date

        checkiCloudAvailability()

        // Observe iCloud account changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudAccountDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: keyValueStore
        )

        if syncEnabled && iCloudAvailable {
            Task { [weak self] in
                guard let self else { return }
                self.startSync()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// Check if iCloud is available
    func checkiCloudAvailability() {
        iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        print("☁️ iCloud available: \(iCloudAvailable)")

        if !iCloudAvailable {
            syncState = .unavailable
        } else if !syncEnabled {
            syncState = .disabled
        }
    }

    /// Start syncing
    func startSync() {
        guard iCloudAvailable else {
            syncState = .unavailable
            return
        }

        guard syncEnabled else {
            syncState = .disabled
            return
        }

        print("☁️ Starting iCloud sync...")
        syncState = .syncing

        // Setup key-value store observer for preferences
        setupKeyValueStoreObserver()

        // Setup file metadata query for shortcuts
        setupFileMetadataQuery()

        Task { [weak self] in
            guard let self else { return }
            await performFullSync()
        }
    }

    /// Stop syncing
    func stopSync() {
        print("☁️ Stopping iCloud sync...")

        Task { [weak self] in
            guard let self else { return }
            await coordinator.cancelAll()
            await pipeline.cancelPending()
        }

        // Remove key-value observer
        if let observer = keyValueObserver {
            NotificationCenter.default.removeObserver(observer)
            keyValueObserver = nil
        }

        // Remove metadata query observer and stop query
        if let query = metadataQuery {
            NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: query)
            query.stop()
            metadataQuery = nil
        }

        syncState = .disabled
        NotificationCenter.default.post(name: .iCloudSyncStateDidChange, object: self)
    }

    /// Trigger a manual sync
    func triggerManualSync() {
        guard iCloudAvailable && syncEnabled else { return }

        syncState = .syncing
        print("☁️ Manual sync triggered...")

        Task { [weak self] in
            guard let self else { return }
            await performFullSync()
        }
    }

    private func enqueueSyncOperation(_ operation: @escaping @Sendable () async -> Void) {
        Task { [weak self] in
            guard let self else { return }
            await pipeline.enqueue {
                await operation()
            }
        }
    }

    // MARK: - Preferences Sync

    /// Sync local preferences to iCloud
    func syncPreferencesToCloud() {
        enqueueSyncOperation { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.syncPreferencesToCloudInternal()
            }
        }
    }

    /// Pull preferences from iCloud
    func pullPreferencesFromCloud() {
        enqueueSyncOperation { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.pullPreferencesFromCloudInternal()
            }
        }
    }

    private func syncPreferencesToCloudInternal() {
        guard syncEnabled, let preferences = preferencesManager?.preferences else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(preferences)

            if let jsonString = String(data: data, encoding: .utf8) {
                keyValueStore.set(jsonString, forKey: Self.preferencesCloudKey)
                keyValueStore.synchronize()
                print("☁️ Preferences synced to iCloud")
            }
        } catch {
            print("☁️ Error syncing preferences to cloud: \(error)")
            syncState = .error("Failed to sync preferences")
        }
    }

    private func pullPreferencesFromCloudInternal() {
        guard syncEnabled else { return }

        if let jsonString = keyValueStore.string(forKey: Self.preferencesCloudKey),
           let data = jsonString.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let remotePreferences = try decoder.decode(AppPreferences.self, from: data)

                // Compare timestamps - last write wins
                if let localPreferences = preferencesManager?.preferences {
                    if remotePreferences.lastModified > localPreferences.lastModified {
                        print("☁️ Applying remote preferences (newer)")
                        preferencesManager?.applyRemotePreferences(remotePreferences)
                        NotificationCenter.default.post(name: .preferencesDidChangeRemotely, object: nil)
                    } else {
                        print("☁️ Local preferences are newer, keeping local")
                    }
                } else {
                    // No local preferences, apply remote
                    preferencesManager?.applyRemotePreferences(remotePreferences)
                    NotificationCenter.default.post(name: .preferencesDidChangeRemotely, object: nil)
                }
            } catch {
                print("☁️ Error decoding remote preferences: \(error)")
            }
        }
    }

    // MARK: - Shortcuts Sync

    /// Get the iCloud container URL for shortcuts
    private var iCloudShortcutsURL: URL? {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            return nil
        }
        let documentsURL = containerURL.appendingPathComponent("Documents")

        // Ensure Documents directory exists
        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        }

        return documentsURL.appendingPathComponent(Self.shortcutsFileName)
    }

    /// Sync local shortcuts to iCloud
    func syncShortcutsToCloud() {
        enqueueSyncOperation { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.syncShortcutsToCloudInternal()
            }
        }
    }

    /// Pull shortcuts from iCloud
    func pullShortcutsFromCloud() {
        enqueueSyncOperation { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.pullShortcutsFromCloudInternal()
            }
        }
    }

    private func syncShortcutsToCloudInternal() {
        guard syncEnabled, let shortcutStore = shortcutStore, let cloudURL = iCloudShortcutsURL else { return }

        let coordinator = NSFileCoordinator()
        var error: NSError?

        coordinator.coordinate(writingItemAt: cloudURL, options: .forReplacing, error: &error) { url in
            do {
                let allShortcuts = shortcutStore.getAllShortcuts()
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(allShortcuts)
                try data.write(to: url, options: .atomic)
                print("☁️ Shortcuts synced to iCloud: \(url.path)")
            } catch {
                print("☁️ Error syncing shortcuts to cloud: \(error)")
                DispatchQueue.main.async {
                    self.syncState = .error("Failed to sync shortcuts")
                }
            }
        }

        if let error = error {
            print("☁️ File coordination error: \(error)")
            syncState = .error("File coordination failed")
        }
    }

    private func pullShortcutsFromCloudInternal() {
        guard syncEnabled, let shortcutStore = shortcutStore, let cloudURL = iCloudShortcutsURL else { return }

        // Check if cloud file exists
        guard FileManager.default.fileExists(atPath: cloudURL.path) else {
            print("☁️ No cloud shortcuts file exists yet")
            return
        }

        let coordinator = NSFileCoordinator()
        var error: NSError?

        coordinator.coordinate(readingItemAt: cloudURL, options: [], error: &error) { url in
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let remoteShortcuts = try decoder.decode([String: AppShortcuts].self, from: data)

                // Merge using last-write-wins per app
                let localShortcuts = shortcutStore.getAllShortcuts()
                let merged = mergeShortcuts(local: localShortcuts, remote: remoteShortcuts)

                // Apply merged shortcuts
                shortcutStore.replaceAllShortcuts(merged)
                print("☁️ Shortcuts pulled and merged from iCloud")

                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .shortcutsDidChangeRemotely, object: nil)
                }
            } catch {
                print("☁️ Error pulling shortcuts from cloud: \(error)")
            }
        }

        if let error = error {
            print("☁️ File coordination error: \(error)")
        }
    }

    /// Merge shortcuts using last-write-wins per app
    private func mergeShortcuts(local: [String: AppShortcuts], remote: [String: AppShortcuts]) -> [String: AppShortcuts] {
        var merged = local

        for (bundleId, remoteApp) in remote {
            if let localApp = local[bundleId] {
                // Keep whichever was modified more recently
                if remoteApp.lastModified > localApp.lastModified {
                    merged[bundleId] = remoteApp
                    print("☁️ Using remote shortcuts for \(bundleId) (newer)")
                } else {
                    print("☁️ Keeping local shortcuts for \(bundleId) (newer)")
                }
            } else {
                // App only exists remotely, add it
                merged[bundleId] = remoteApp
                print("☁️ Adding remote app \(bundleId)")
            }
        }

        return merged
    }

    // MARK: - Observers

    private func setupKeyValueStoreObserver() {
        // Remove existing observer
        if let observer = keyValueObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        keyValueObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: keyValueStore,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyValueStoreChange(notification)
        }

        // Initial sync
        keyValueStore.synchronize()
    }

    private func handleKeyValueStoreChange(_ notification: Notification) {
        guard syncEnabled else { return }

        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }

        switch reason {
        case NSUbiquitousKeyValueStoreServerChange, NSUbiquitousKeyValueStoreInitialSyncChange:
            print("☁️ Key-value store changed externally")
            Task { [weak self] in
                guard let self else { return }
                await coordinator.debounceKeyValueUpdates { [weak self] in
                    guard let self else { return }
                    await MainActor.run {
                        self.pullPreferencesFromCloud()
                    }
                }
            }
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            print("☁️ iCloud quota exceeded")
            syncState = .error("iCloud quota exceeded")
        case NSUbiquitousKeyValueStoreAccountChange:
            print("☁️ iCloud account changed")
            checkiCloudAvailability()
        default:
            break
        }
    }

    private func setupFileMetadataQuery() {
        // Remove existing observer and stop query to prevent accumulation
        if let existingQuery = metadataQuery {
            NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: existingQuery)
            existingQuery.stop()
        }

        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, Self.shortcutsFileName)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidUpdate),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )

        metadataQuery = query
        query.start()
    }

    @objc private func metadataQueryDidUpdate(_ notification: Notification) {
        guard syncEnabled else { return }

        print("☁️ iCloud shortcuts file changed")
        Task { [weak self] in
            guard let self else { return }
            await coordinator.debounceMetadataUpdates { [weak self] in
                guard let self else { return }
                await MainActor.run {
                    self.pullShortcutsFromCloud()
                }
            }
        }
    }

    @objc private func iCloudAccountDidChange(_ notification: Notification) {
        checkiCloudAvailability()

        if !iCloudAvailable && syncEnabled {
            syncState = .unavailable
        }
    }

    // MARK: - Helpers

    private func updateLastSyncDate() {
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: Self.lastSyncDateKey)
    }

    private func performFullSync() async {
        await pipeline.enqueue { [weak self] in
            guard let self else { return }

            await MainActor.run {
                self.keyValueStore.synchronize()
                self.syncPreferencesToCloudInternal()
                self.syncShortcutsToCloudInternal()
                self.pullPreferencesFromCloudInternal()
                self.pullShortcutsFromCloudInternal()
            }

            await MainActor.run {
                self.syncState = .synced
                self.updateLastSyncDate()
                NotificationCenter.default.post(name: .iCloudSyncStateDidChange, object: self)
            }
        }
    }
}
