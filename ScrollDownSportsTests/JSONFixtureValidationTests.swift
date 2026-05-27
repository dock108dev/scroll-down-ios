import XCTest
@testable import ScrollDownSports

final class JSONFixtureValidationTests: XCTestCase {
    func testGameListFixturesDecode() throws {
        for name in [
            "live_mlb_two_games",
            "scheduled_real_teams",
            "placeholder_tbd",
            "pinned_real_empty",
            "home_72h_timeline",
            "presentation_scoreboard_game",
            "leaderboard_scoreboard_game"
        ] {
            _ = try JSONDecoder.sda.decode(SDAGameListResponseDTO.self, from: try SDAFixtures.gameList(name))
        }
    }

    func testGameDetailFixturesDecode() throws {
        for name in [
            "mlb_final_full_pbp",
            "mlb_scoring_progression",
            "mlb_live_new_events",
            "stats_with_mlb_box_score",
            "nhl_event_presentation_importance",
            "scheduled_no_pbp_missing_optional_presentation",
            "partial_degraded_payload"
        ] {
            _ = try JSONDecoder.sda.decode(SDAGameDetailResponseDTO.self, from: try SDAFixtures.gameDetail(name))
        }
    }

    func testPresentationAndScoreboardFixturesDecode() throws {
        _ = try JSONDecoder.sda.decode(SDAMobilePresentationDTO.self, from: try SDAFixtures.presentation("full_mobile_presentation"))
        _ = try JSONDecoder.sda.decode(SDAScoreboardDTO.self, from: try SDAFixtures.scoreboard("mlb_inning_line_score"))
    }

    func testMalformedFixturesAreLoadableButFailExpectedContracts() throws {
        XCTAssertThrowsError(
            try JSONDecoder.sda.decode(
                SDAGameDetailResponseDTO.self,
                from: try SDAFixtures.malformed("missing_required_importance")
            )
        )
        XCTAssertThrowsError(
            try JSONDecoder.sda.decode(
                SDAGameDetailResponseDTO.self,
                from: try SDAFixtures.malformed("missing_mode_eligibility")
            )
        )

        for name in [
            "wrong_detail_contract_version",
            "missing_all_usable_event_text",
            "missing_period_label"
        ] {
            _ = try JSONDecoder.sda.decode(SDAGameDetailResponseDTO.self, from: try SDAFixtures.malformed(name))
        }
    }

    func testMalformedFixtureResponsesUseControlledClientErrors() async throws {
        for (name, protocolClass) in [
            ("wrong_detail_contract_version", MockWrongVersionFixtureURLProtocol.self),
            ("missing_all_usable_event_text", MockMissingTextFixtureURLProtocol.self),
            ("missing_period_label", MockMissingPeriodFixtureURLProtocol.self),
            ("missing_mode_eligibility", MockMissingModeFixtureURLProtocol.self)
        ] as [(String, MockHTTPURLProtocol.Type)] {
            let client = TestFixtures.makeAPIClient(
                responses: [.ok(try SDAFixtures.malformed(name))],
                protocolClass: protocolClass
            )

            do {
                _ = try await client.fetchGame(id: 900)
                XCTFail("Expected incomplete detail error for \(name)")
            } catch SDAApiError.incompleteDetail {
            } catch {
                XCTFail("Unexpected error for \(name): \(error)")
            }
        }
    }

    func testFixtureResponsesCanBackMockHTTPQueue() throws {
        let response = try MockHTTPResponse.gameList("live_mlb_two_games")
        guard case .ok(let data) = response else {
            return XCTFail("Expected an OK fixture response")
        }

        let decoded = try JSONDecoder.sda.decode(SDAGameListResponseDTO.self, from: data)

        XCTAssertEqual(decoded.games.map(\.id), [504, 505])
    }

    func testDomainBuildersRemainAvailableForCompactObjects() {
        let game = TestFixtures.makeGame(id: 42)
        let event = TestFixtures.makeEvent(sequence: 1, importance: .primary)
        let detail = TestFixtures.makeDetail(game: game, events: [event])

        XCTAssertEqual(detail.game.id, 42)
        XCTAssertEqual(detail.events.map(\.id), ["event-1"])
    }

    func testPayloadHelpersAreBackedByNamedFixtures() throws {
        let list = try JSONDecoder.sda.decode(
            SDAGameListResponseDTO.self,
            from: TestFixtures.sdaGameListJSON(ids: [701, 702])
        )
        let detail = try JSONDecoder.sda.decode(
            SDAGameDetailResponseDTO.self,
            from: TestFixtures.sdaGameDetailJSON(gameId: 703, playIDs: ["play-1", "play-2"])
        )

        XCTAssertEqual(list.games.map(\.id), [701, 702])
        XCTAssertEqual(detail.game.id, 703)
        XCTAssertEqual(detail.plays.map(\.id), ["play-1", "play-2"])
    }

    func testFixturesAreNotBundledWithProductionAppResources() {
        let appBundle = Bundle(for: AppDelegate.self)

        XCTAssertNil(appBundle.url(forResource: "home_72h_timeline", withExtension: "json"))
        XCTAssertNil(
            appBundle.url(
                forResource: "home_72h_timeline",
                withExtension: "json",
                subdirectory: "api/v2/game-list"
            )
        )
    }
}

private final class MockWrongVersionFixtureURLProtocol: MockHTTPURLProtocol {}
private final class MockMissingTextFixtureURLProtocol: MockHTTPURLProtocol {}
private final class MockMissingPeriodFixtureURLProtocol: MockHTTPURLProtocol {}
private final class MockMissingModeFixtureURLProtocol: MockHTTPURLProtocol {}
