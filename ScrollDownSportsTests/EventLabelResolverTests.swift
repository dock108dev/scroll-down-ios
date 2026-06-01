import XCTest
@testable import ScrollDownSports

final class EventLabelResolverTests: XCTestCase {
    func testKnownRawEventTypesMapToCustomerFacingLabels() {
        let labels = [
            "HOME_RUN": "Home run",
            "FIELD_OUT": "Out",
            "FORCE_OUT": "Force out",
            "STRIKEOUT": "Strikeout",
            "SINGLE": "Single",
            "DOUBLE": "Double",
            "WALK": "Walk"
        ]

        for (raw, expected) in labels {
            XCTAssertEqual(EventLabelResolver.customerLabel(from: raw), expected)
        }
    }

    func testUnknownRawEventTypesDoNotRenderVerbatim() {
        let event = TestFixtures.makeEvent(
            sequence: 1,
            headline: "Game update",
            eventType: "SOME_UNKNOWN_EVENT",
            presentation: TestFixtures.eventPresentation(
                timeLabel: "Q1 10:00",
                accessibilityLabel: "SOME_UNKNOWN_EVENT",
                eventTypeLabel: "SOME_UNKNOWN_EVENT"
            )
        )

        let presentation = GenericSportRenderer(leagueCode: "nba").eventPresentation(for: event)

        XCTAssertEqual(presentation.headline, "Game update")
        XCTAssertNil(presentation.eventLabel)
        XCTAssertFalse((presentation.accessibilityLabel ?? "").contains("SOME_UNKNOWN_EVENT"))
    }

    func testClientRejectsLegacyDetailPayloadAsNonSSOT() async throws {
        let client = TestFixtures.makeAPIClient(
            responses: [.ok(try SDAFixtures.gameDetail("mlb_live_new_events"))],
            protocolClass: MockRawEventURLProtocol.self
        )

        do {
            _ = try await client.fetchGame(id: 504)
            XCTFail("Expected normalized feed contract failure")
        } catch SDAApiError.incompleteNormalizedFeed {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class MockRawEventURLProtocol: MockHTTPURLProtocol {}
