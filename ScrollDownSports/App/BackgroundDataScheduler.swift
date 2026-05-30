import BackgroundTasks
import Foundation
import OSLog

@MainActor
protocol BackgroundRefreshTaskRunning {
    func refreshForBackground() async throws
}

extension BackgroundRefreshService: BackgroundRefreshTaskRunning {}

@MainActor
protocol BackgroundTaskCompletion: AnyObject {
    var expirationHandler: (() -> Void)? { get set }
    func setTaskCompleted(success: Bool)
}

extension BGTask: BackgroundTaskCompletion {}

@MainActor
protocol BGTaskSchedulingClient: AnyObject {
    func register(identifier: String, launchHandler: @escaping @MainActor (BGTask) -> Void)
    func submitAppRefresh(identifier: String, earliestBeginDate: Date) throws
    func cancel(identifier: String)
}

@MainActor
final class SystemBGTaskSchedulingClient: BGTaskSchedulingClient {
    func register(identifier: String, launchHandler: @escaping @MainActor (BGTask) -> Void) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            Task { @MainActor in
                launchHandler(task)
            }
        }
    }

    func submitAppRefresh(identifier: String, earliestBeginDate: Date) throws {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = earliestBeginDate
        try BGTaskScheduler.shared.submit(request)
    }

    func cancel(identifier: String) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
    }
}

@MainActor
final class BackgroundDataScheduler: BackgroundRefreshScheduling {
    static let shared = BackgroundDataScheduler(client: SystemBGTaskSchedulingClient())
    private static let logger = Logger(
        subsystem: "com.dock108.scrolldownsports",
        category: "BackgroundDataScheduler"
    )

    private let client: any BGTaskSchedulingClient
    private let identifier: String
    private let now: () -> Date
    private let makeRefreshService: (any GameStateStore) -> any BackgroundRefreshTaskRunning
    weak var gameStateStore: (any GameStateStore)?

    init(
        client: any BGTaskSchedulingClient,
        identifier: String = "com.dock108.scrolldownsports.refresh",
        now: @escaping () -> Date = Date.init,
        makeRefreshService: @escaping (any GameStateStore) -> any BackgroundRefreshTaskRunning = {
            BackgroundRefreshService(apiClient: SDAApiClient.shared, gameStateStore: $0)
        }
    ) {
        self.client = client
        self.identifier = identifier
        self.now = now
        self.makeRefreshService = makeRefreshService
    }

    func register() {
        client.register(identifier: identifier) { task in
            self.handle(task: task)
        }
    }

    func scheduleRefresh() {
        do {
            try client.submitAppRefresh(identifier: identifier, earliestBeginDate: now().addingTimeInterval(5 * 60))
        } catch {
            Self.logger.warning(
                "Background refresh schedule rejected: \(error.localizedDescription, privacy: .private)"
            )
        }
    }

    func cancelPendingRefresh() {
        client.cancel(identifier: identifier)
    }

    private func handle(task: BGTask) {
        runRefreshTask(task)
    }

    @discardableResult
    func runRefreshTask(_ task: any BackgroundTaskCompletion) -> Task<Void, Never> {
        scheduleRefresh()
        let operation = Task {
            do {
                let store = gameStateStore ?? UserDefaultsGameStateStore()
                let service = makeRefreshService(store)
                try await service.refreshForBackground()
                task.setTaskCompleted(success: true)
            } catch is CancellationError {
                Self.logger.info("Background refresh task cancelled")
                task.setTaskCompleted(success: false)
            } catch {
                Self.logger.error(
                    "Background refresh task failed: \(error.localizedDescription, privacy: .private)"
                )
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            Self.logger.warning("Background refresh task expired")
            operation.cancel()
        }
        return operation
    }
}
