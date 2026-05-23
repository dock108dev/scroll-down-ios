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
            presentation: EventPresentationData(
                headline: nil,
                shortHeadline: nil,
                body: nil,
                primaryLabel: nil,
                secondaryLabel: nil,
                tertiaryLabel: nil,
                timeLabel: "Q1 10:00",
                accessibilityLabel: "SOME_UNKNOWN_EVENT",
                eventTypeLabel: "SOME_UNKNOWN_EVENT",
                teamLabel: nil,
                playerLabel: nil,
                scoreLabel: nil
            )
        )

        let presentation = GenericSportRenderer(leagueCode: "nba").eventPresentation(for: event)

        XCTAssertEqual(presentation.headline, "Game update")
        XCTAssertNil(presentation.eventLabel)
        XCTAssertFalse((presentation.accessibilityLabel ?? "").contains("SOME_UNKNOWN_EVENT"))
    }

    func testClientAcceptsRawDisplayTypeAndMapperUsesSafeFallbacks() async throws {
        let payload = try rawDetailPayload(displayType: "SOME_UNKNOWN_EVENT", description: "Provider supplied readable play text.")
        let client = TestFixtures.makeAPIClient(
            responses: [.ok(payload)],
            protocolClass: MockRawEventURLProtocol.self
        )

        let detail = try await client.fetchGame(id: 504)
        let event = try XCTUnwrap(detail.events.first)
        let presentation = GenericSportRenderer(leagueCode: "mlb").eventPresentation(for: event)

        XCTAssertEqual(event.headline, "Provider supplied readable play text.")
        XCTAssertFalse(event.headline.contains("SOME_UNKNOWN_EVENT"))
        XCTAssertNil(presentation.eventLabel)
        XCTAssertFalse((presentation.accessibilityLabel ?? "").contains("SOME_UNKNOWN_EVENT"))
    }

    func testClientStillRejectsStructurallyUnusableDetail() async throws {
        let payload = try rawDetailPayload(displayType: "SINGLE", description: "A single.", periodLabel: "")
        let client = TestFixtures.makeAPIClient(
            responses: [.ok(payload)],
            protocolClass: MockMalformedPeriodURLProtocol.self
        )

        do {
            _ = try await client.fetchGame(id: 504)
            XCTFail("Expected incomplete detail error")
        } catch SDAApiError.incompleteDetail(_) {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func rawDetailPayload(displayType: String, description: Any, periodLabel: String = "T4") throws -> Data {
        var root = try jsonObject(from: SDAFixtures.gameDetail("mlb_live_new_events"))
        var plays = try XCTUnwrap(root["plays"] as? [[String: Any]])
        var firstPlay = try XCTUnwrap(plays.first)
        firstPlay["displayType"] = displayType
        firstPlay["description"] = description
        firstPlay["presentation"] = NSNull()
        firstPlay["periodLabel"] = periodLabel
        plays[0] = firstPlay
        root["plays"] = [firstPlay]
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    private func jsonObject(from data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

private final class MockRawEventURLProtocol: MockHTTPURLProtocol {}
private final class MockMalformedPeriodURLProtocol: MockHTTPURLProtocol {}
