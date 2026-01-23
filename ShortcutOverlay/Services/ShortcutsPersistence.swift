import Foundation

actor ShortcutsPersistence {
    enum SaveOutcome {
        case saved
        case canceled
    }

    private var pendingSaveTask: Task<Void, Error>?

    func load(from url: URL) async throws -> [String: AppShortcuts] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([String: AppShortcuts].self, from: data)
    }

    func scheduleSave(
        _ shortcuts: [String: AppShortcuts],
        to url: URL,
        debounceInterval: TimeInterval
    ) async throws -> SaveOutcome {
        pendingSaveTask?.cancel()

        let task = Task.detached(priority: .utility) {
            try await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            if Task.isCancelled {
                throw CancellationError()
            }

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(shortcuts)
            try data.write(to: url, options: .atomic)
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
