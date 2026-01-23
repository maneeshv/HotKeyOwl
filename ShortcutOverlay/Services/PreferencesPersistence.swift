import Foundation

actor PreferencesPersistence {
    enum SaveOutcome {
        case saved
        case canceled
    }

    private let defaults: UserDefaults
    private let key: String
    private var pendingSaveTask: Task<Void, Error>?

    init(defaults: UserDefaults = .standard, key: String) {
        self.defaults = defaults
        self.key = key
    }

    func scheduleSave(_ preferences: AppPreferences, debounceInterval: TimeInterval) async throws -> SaveOutcome {
        pendingSaveTask?.cancel()

        let defaults = defaults
        let key = key

        let task = Task.detached(priority: .utility) {
            try await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            if Task.isCancelled {
                throw CancellationError()
            }

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encoded = try encoder.encode(preferences)
            defaults.set(encoded, forKey: key)
        }

        pendingSaveTask = task

        do {
            try await task.value
            if let pendingSaveTask, pendingSaveTask == task {
                self.pendingSaveTask = nil
            }
            return .saved
        } catch is CancellationError {
            if let pendingSaveTask, pendingSaveTask == task {
                self.pendingSaveTask = nil
            }
            return .canceled
        }
    }
}
