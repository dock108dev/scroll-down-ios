import BackgroundTasks
import Foundation

@MainActor
final class BackgroundDataScheduler {
    static let shared = BackgroundDataScheduler()

    private let identifier = "com.dock108.scrolldownsports.refresh"
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
                _ = try await SDAApiClient.shared.fetchGames(window: GameWindow.current())
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            operation.cancel()
        }
    }
}
