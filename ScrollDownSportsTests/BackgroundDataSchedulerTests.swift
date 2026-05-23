import BackgroundTasks
import XCTest
@testable import ScrollDownSports

@MainActor
final class BackgroundDataSchedulerTests: XCTestCase {
    func testScheduleRefreshSubmitsAppRefreshRequest() {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let client = FakeBGTaskSchedulingClient()
        let scheduler = BackgroundDataScheduler(client: client, identifier: "refresh.test", now: { now })

        scheduler.scheduleRefresh()

        XCTAssertEqual(client.submittedRequests.map(\.identifier), ["refresh.test"])
        XCTAssertEqual(client.submittedRequests.first?.earliestBeginDate, now.addingTimeInterval(5 * 60))
    }

    func testScheduleRefreshSwallowsSubmitRejection() {
        let client = FakeBGTaskSchedulingClient(submitError: URLError(.cannotWriteToFile))
        let scheduler = BackgroundDataScheduler(client: client, identifier: "refresh.test")

        scheduler.scheduleRefresh()

        XCTAssertEqual(client.submittedRequests.map(\.identifier), ["refresh.test"])
    }

    func testCancelPendingRefreshCancelsByIdentifier() {
        let client = FakeBGTaskSchedulingClient()
        let scheduler = BackgroundDataScheduler(client: client, identifier: "refresh.test")

        scheduler.cancelPendingRefresh()

        XCTAssertEqual(client.cancelledIdentifiers, ["refresh.test"])
    }

    func testRunRefreshTaskSchedulesNextRefreshAndCompletesSuccessfully() async {
        let store = InMemoryGameStateStore()
        let client = FakeBGTaskSchedulingClient()
        let refresh = FakeBackgroundRefreshTaskRunner(result: .success(()))
        let scheduler = BackgroundDataScheduler(
            client: client,
            identifier: "refresh.test",
            makeRefreshService: { _ in refresh }
        )
        scheduler.gameStateStore = store
        let task = FakeBackgroundTaskCompletion()

        await scheduler.runRefreshTask(task).value

        XCTAssertEqual(client.submittedRequests.map(\.identifier), ["refresh.test"])
        XCTAssertEqual(task.completedValues, [true])
    }

    func testRunRefreshTaskCompletesFailureWhenRefreshThrows() async {
        let store = InMemoryGameStateStore()
        let client = FakeBGTaskSchedulingClient()
        let refresh = FakeBackgroundRefreshTaskRunner(result: .failure(URLError(.badServerResponse)))
        let scheduler = BackgroundDataScheduler(
            client: client,
            makeRefreshService: { _ in refresh }
        )
        scheduler.gameStateStore = store
        let task = FakeBackgroundTaskCompletion()

        await scheduler.runRefreshTask(task).value

        XCTAssertEqual(task.completedValues, [false])
    }

    func testRunRefreshTaskExpirationCancelsOperationAndCompletesFailure() async {
        let store = InMemoryGameStateStore()
        let refreshStarted = expectation(description: "refresh started")
        let client = FakeBGTaskSchedulingClient()
        let refresh = FakeBackgroundRefreshTaskRunner(result: .suspend, onStart: {
            refreshStarted.fulfill()
        })
        let scheduler = BackgroundDataScheduler(
            client: client,
            makeRefreshService: { _ in refresh }
        )
        scheduler.gameStateStore = store
        let task = FakeBackgroundTaskCompletion()

        let operation = scheduler.runRefreshTask(task)
        await fulfillment(of: [refreshStarted], timeout: 1)
        task.expirationHandler?()
        await operation.value

        XCTAssertEqual(task.completedValues, [false])
    }
}

@MainActor
private final class FakeBGTaskSchedulingClient: BGTaskSchedulingClient {
    private(set) var registeredIdentifiers: [String] = []
    private(set) var submittedRequests: [(identifier: String, earliestBeginDate: Date)] = []
    private(set) var cancelledIdentifiers: [String] = []
    private let submitError: Error?

    init(submitError: Error? = nil) {
        self.submitError = submitError
    }

    func register(identifier: String, launchHandler: @escaping @MainActor (BGTask) -> Void) {
        registeredIdentifiers.append(identifier)
    }

    func submitAppRefresh(identifier: String, earliestBeginDate: Date) throws {
        submittedRequests.append((identifier, earliestBeginDate))
        if let submitError {
            throw submitError
        }
    }

    func cancel(identifier: String) {
        cancelledIdentifiers.append(identifier)
    }
}

@MainActor
private final class FakeBackgroundRefreshTaskRunner: BackgroundRefreshTaskRunning {
    enum ResultValue {
        case success(Void)
        case failure(Error)
        case suspend
    }

    private let result: ResultValue
    private let onStart: () -> Void

    init(result: ResultValue, onStart: @escaping () -> Void = {}) {
        self.result = result
        self.onStart = onStart
    }

    func refreshForBackground() async throws {
        onStart()
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        case .suspend:
            try await Task.sleep(nanoseconds: 60_000_000_000)
        }
    }
}

@MainActor
private final class FakeBackgroundTaskCompletion: BackgroundTaskCompletion {
    var expirationHandler: (() -> Void)?
    private(set) var completedValues: [Bool] = []

    func setTaskCompleted(success: Bool) {
        completedValues.append(success)
    }
}
