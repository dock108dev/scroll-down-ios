import XCTest
@testable import ScrollDownSports

final class SDAUITestHomeFixturePayloadsTests: XCTestCase {
    func testCriticalFixtureSummariesCoverPlayableLiveScheduledAndPlaceholderRows() throws {
        let games = SDAUITestHomeFixturePayloads.gameSummaries(for: "critical-final-game")

        XCTAssertEqual(games.count, 6)
        XCTAssertEqual(games.compactMap { $0["id"] as? Int }, [9001, 9002, 9003, 9004, 9005, 9099])

        let finalGame = try XCTUnwrap(games.first { $0["id"] as? Int == 9001 })
        XCTAssertEqual(finalGame["status"] as? String, "final")
        XCTAssertEqual(finalGame["currentPeriodLabel"] as? String, "Final")
        XCTAssertEqual(finalGame["score"] as? [String: Int], ["away": 5, "home": 3])
        let finalPresentation = try XCTUnwrap(finalGame["presentation"] as? [String: Any])
        XCTAssertEqual(finalPresentation["displayState"] as? String, "final")
        XCTAssertEqual(finalPresentation["primaryLabel"] as? String, "Catch up")
        XCTAssertEqual(finalPresentation["scoreboardPlacement"] as? String, "bottom")

        let liveGame = try XCTUnwrap(games.first { $0["id"] as? Int == 9004 })
        XCTAssertEqual(liveGame["status"] as? String, "in_progress")
        XCTAssertEqual(liveGame["currentPeriodLabel"] as? String, "3rd")
        XCTAssertEqual(liveGame["gameClock"] as? String, "12:44")
        let livePresentation = try XCTUnwrap(liveGame["presentation"] as? [String: Any])
        XCTAssertEqual(livePresentation["displayState"] as? String, "live")

        let scheduledGame = try XCTUnwrap(games.first { $0["id"] as? Int == 9005 })
        XCTAssertNil(scheduledGame["score"])
        XCTAssertNil(scheduledGame["scoreboard"])
        let scheduledEligibility = try XCTUnwrap(scheduledGame["eligibility"] as? [String: Any])
        XCTAssertEqual((scheduledEligibility["playByPlay"] as? [String: Bool])?["isEligible"], false)
        XCTAssertEqual((scheduledEligibility["boxScore"] as? [String: Bool])?["isEligible"], true)

        let placeholder = try XCTUnwrap(games.first { $0["id"] as? Int == 9099 })
        let placeholderPresentation = try XCTUnwrap(placeholder["presentation"] as? [String: Any])
        XCTAssertEqual(placeholderPresentation["headline"] as? String, "")
        XCTAssertEqual(placeholderPresentation["accessibilityLabel"] as? String, "")
        XCTAssertEqual(placeholder["homeTeam"] as? String, "Team TBD")
    }

    func testFutureBlankAndUnknownFixtureSummaries() throws {
        let futureGames = SDAUITestHomeFixturePayloads.gameSummaries(for: "future-game")

        let futureGame = try XCTUnwrap(futureGames.first)
        XCTAssertEqual(futureGames.count, 1)
        XCTAssertEqual(futureGame["id"] as? Int, 9101)
        XCTAssertEqual(futureGame["status"] as? String, "scheduled")
        XCTAssertNil(futureGame["score"])
        let futureEligibility = try XCTUnwrap(futureGame["eligibility"] as? [String: Any])
        XCTAssertEqual((futureEligibility["boxScore"] as? [String: Bool])?["isEligible"], false)

        XCTAssertEqual(SDAUITestHomeFixturePayloads.gameSummaries(for: "blank-home").count, 0)
        XCTAssertEqual(SDAUITestHomeFixturePayloads.gameSummaries(for: "unrecognized").count, 0)
    }
}
