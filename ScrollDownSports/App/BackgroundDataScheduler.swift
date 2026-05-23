import BackgroundTasks
import Foundation

@MainActor
final class BackgroundDataScheduler {
    static let shared = BackgroundDataScheduler()

    private let identifier = "com.dock108.scrolldownsports.refresh"
    weak var gameStateStore: (any GameStateStore)?

    private init() {}

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            self.handle(task: task)
        }
    }

    func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // iOS may reject scheduling on simulator, low power, or missing entitlement contexts.
        }
    }

    func cancelPendingRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
    }

    private func handle(task: BGTask) {
        scheduleRefresh()

        let operation = Task {
            do {
                let store = gameStateStore ?? UserDefaultsGameStateStore()
                let service = BackgroundRefreshService(apiClient: .shared, gameStateStore: store)
                try await service.refreshForBackground()
                task.setTaskCompleted(success: true)
            } catch is CancellationError {
                task.setTaskCompleted(success: false)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            operation.cancel()
        }
    }
}
