import XCTest
@testable import ScrollDown

final class GameSummaryTests: XCTestCase {

    // MARK: - inferredStatus

    func testInferredStatusScheduledNoPlays() {
        let game = TestFixtures.makeGameSummary(playCount: 0)
        XCTAssertEqual(game.inferredStatus, .scheduled)
    }

    func testInferredStatusInProgressWithPlays() {
        let game = TestFixtures.makeGameSummary(playCount: 12)
        XCTAssertEqual(game.inferredStatus, .inProgress)
    }

    func testInferredStatusCompletedWithScores() {
        let game = TestFixtures.makeGameSummary(homeScore: 3, awayScore: 2)
        XCTAssertEqual(game.inferredStatus, .completed)
    }

    func testInferredStatusExplicitOverridesInference() {
        let game = TestFixtures.makeGameSummary(status: .postponed)
        XCTAssertEqual(game.inferredStatus, .postponed)
    }

    // MARK: - Computed Properties

    func testHomeTeamName() {
        let game = TestFixtures.makeGameSummary(homeTeam: "Boston Celtics")
        XCTAssertEqual(game.homeTeamName, "Boston Celtics")
    }

    func testAwayTeamName() {
        let game = TestFixtures.makeGameSummary(awayTeam: "Los Angeles Lakers")
        XCTAssertEqual(game.awayTeamName, "Los Angeles Lakers")
    }

    func testLeague() {
        let game = TestFixtures.makeGameSummary(leagueCode: "NHL")
        XCTAssertEqual(game.league, "NHL")
    }

    func testScoreDisplayWithScores() {
        let game = TestFixtures.makeGameSummary(homeScore: 112, awayScore: 108)
        XCTAssertEqual(game.scoreDisplay, "112 - 108")
    }

    func testScoreDisplayWithoutScores() {
        let game = TestFixtures.makeGameSummary()
        XCTAssertEqual(game.scoreDisplay, "— vs —")
    }

    // MARK: - parsedGameDate

    func testParsedGameDateValid() {
        let game = TestFixtures.makeGameSummary(gameDate: "2025-01-15T19:30:00Z")
        XCTAssertNotNil(game.parsedGameDate)
    }

    func testFormattedDateReturnsReadableString() {
        let game = TestFixtures.makeGameSummary(gameDate: "2025-01-15T19:30:00Z")
        let formatted = game.formattedDate
        // Should be a readable date string, not the raw ISO8601
        XCTAssertFalse(formatted.contains("T"))
    }
}
