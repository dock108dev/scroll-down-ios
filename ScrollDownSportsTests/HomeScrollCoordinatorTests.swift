import XCTest
@testable import ScrollDownSports

final class HomeScrollCoordinatorTests: XCTestCase {
    func testVisibleCountRefreshDoesNotRepeatInitialAnchorScroll() {
        var coordinator = HomeScrollCoordinator()
        let initial = coordinator.initialRequest(
            anchorID: "timeline-yesterday",
            visibleCount: 4,
            filterSignature: "All|"
        )

        XCTAssertNotNil(initial)
        XCTAssertEqual(initial?.position, .bottom)
        XCTAssertNil(
            coordinator.visibleCountChanged(
                anchorID: "timeline-yesterday",
                visibleCount: 5,
                filterSignature: "All|"
            )
        )

        let currentKey = coordinator.validationKey(
            reason: "initial",
            anchorID: "timeline-yesterday",
            visibleCount: 5,
            filterSignature: "All|"
        )
        XCTAssertFalse(coordinator.isCurrent(try XCTUnwrap(initial), currentValidationKey: currentKey))
    }

    func testFilterChangeUsesGenerationToCancelOlderRequests() throws {
        var coordinator = HomeScrollCoordinator()
        let initial = try XCTUnwrap(
            coordinator.initialRequest(
                anchorID: "timeline-yesterday",
                visibleCount: 4,
                filterSignature: "All|"
            )
        )

        let filtered = try XCTUnwrap(
            coordinator.filterChanged(
                to: "NBA|",
                anchorID: "timeline-later-today",
                visibleCount: 1
            )
        )

        let initialKey = coordinator.validationKey(
            reason: "initial",
            anchorID: "timeline-yesterday",
            visibleCount: 4,
            filterSignature: "All|"
        )
        let filteredKey = coordinator.validationKey(
            reason: "filter",
            anchorID: "timeline-later-today",
            visibleCount: 1,
            filterSignature: "NBA|"
        )

        XCTAssertFalse(coordinator.isCurrent(initial, currentValidationKey: initialKey))
        XCTAssertTrue(coordinator.isCurrent(filtered, currentValidationKey: filteredKey))
    }

    func testFilterClearedToEmptyResultsCancelsPendingRequest() throws {
        var coordinator = HomeScrollCoordinator()
        let initial = try XCTUnwrap(
            coordinator.initialRequest(
                anchorID: "timeline-yesterday",
                visibleCount: 4,
                filterSignature: "All|"
            )
        )

        XCTAssertNil(
            coordinator.filterChanged(
                to: "MLB|missing",
                anchorID: nil,
                visibleCount: 0
            )
        )

        let initialKey = coordinator.validationKey(
            reason: "initial",
            anchorID: "timeline-yesterday",
            visibleCount: 4,
            filterSignature: "All|"
        )
        XCTAssertFalse(coordinator.isCurrent(initial, currentValidationKey: initialKey))
    }

    func testInitialAnchorCanMoveFromStalePastSnapshotToCurrentSlate() throws {
        var coordinator = HomeScrollCoordinator()
        _ = try XCTUnwrap(
            coordinator.initialRequest(
                anchorID: "timeline-game-4101",
                visibleCount: 6,
                filterSignature: "All|"
            )
        )

        let refreshed = try XCTUnwrap(
            coordinator.initialRequest(
                anchorID: "timeline-game-4109",
                visibleCount: 18,
                filterSignature: "All|"
            )
        )

        XCTAssertEqual(refreshed.anchorID, "timeline-game-4109")
        XCTAssertEqual(refreshed.position, .bottom)
    }
}
