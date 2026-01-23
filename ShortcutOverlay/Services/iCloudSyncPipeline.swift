import Foundation

actor iCloudSyncPipeline {
    private var pendingTask: Task<Void, Never>?

    func enqueue(_ operation: @escaping @Sendable () async -> Void) async {
        let previousTask = pendingTask
        let task = Task {
            if let previousTask {
                await previousTask.value
            }
            await operation()
        }
        pendingTask = task
        await task.value
    }

    func cancelPending() {
        pendingTask?.cancel()
        pendingTask = nil
    }
}
