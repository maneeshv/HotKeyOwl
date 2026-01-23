import Foundation

actor iCloudSyncCoordinator {
    struct DebounceConfig {
        let interval: TimeInterval
    }

    private var metadataDebounceTask: Task<Void, Never>?
    private var keyValueDebounceTask: Task<Void, Never>?
    private let metadataConfig = DebounceConfig(interval: 0.6)
    private let keyValueConfig = DebounceConfig(interval: 0.4)

    func debounceMetadataUpdates(_ action: @escaping @Sendable () async -> Void) {
        metadataDebounceTask?.cancel()
        metadataDebounceTask = Task { [metadataConfig] in
            try? await Task.sleep(nanoseconds: UInt64(metadataConfig.interval * 1_000_000_000))
            if Task.isCancelled { return }
            await action()
        }
    }

    func debounceKeyValueUpdates(_ action: @escaping @Sendable () async -> Void) {
        keyValueDebounceTask?.cancel()
        keyValueDebounceTask = Task { [keyValueConfig] in
            try? await Task.sleep(nanoseconds: UInt64(keyValueConfig.interval * 1_000_000_000))
            if Task.isCancelled { return }
            await action()
        }
    }

    func cancelAll() {
        metadataDebounceTask?.cancel()
        keyValueDebounceTask?.cancel()
        metadataDebounceTask = nil
        keyValueDebounceTask = nil
    }
}
