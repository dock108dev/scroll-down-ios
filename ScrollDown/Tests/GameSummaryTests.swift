import XCTest
@testable import ScrollDown

final class GameSummaryTests: XCTestCase {

    // MARK: - status

    func testStatusNilWhenMissing() {
        let game = TestFixtures.makeGameSummary()
        XCTAssertNil(game.status)
    }

    func testStatusFromExplicitValue() {
        let game = TestFixtures.makeGameSummary(status: .postponed)
        XCTAssertEqual(game.status, .postponed)
    }

    func testStatusCompleted() {
        let game = TestFixtures.makeGameSummary(status: .completed)
        XCTAssertEqual(game.status, .completed)
    }

    func testStatusInProgress() {
        let game = TestFixtures.makeGameSummary(status: .inProgress)
        XCTAssertEqual(game.status, .inProgress)
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
