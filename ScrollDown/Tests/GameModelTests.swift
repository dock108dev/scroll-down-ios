import XCTest
@testable import ScrollDown

final class GameModelTests: XCTestCase {

    func testScoreDisplayWithScores() {
        let game = TestFixtures.makeGame(homeScore: 112, awayScore: 108)
        XCTAssertEqual(game.scoreDisplay, "112 - 108")
    }

    func testScoreDisplayWithoutScores() {
        let game = TestFixtures.makeGame(homeScore: nil, awayScore: nil)
        XCTAssertEqual(game.scoreDisplay, "— vs —")
    }

    func testMatchupTitle() {
        let game = TestFixtures.makeGame(homeTeam: "Boston Celtics", awayTeam: "Los Angeles Lakers")
        XCTAssertEqual(game.matchupTitle, "Los Angeles Lakers at Boston Celtics")
    }

    func testParsedGameDateValid() {
        let game = TestFixtures.makeGame(gameDate: "2025-01-15T19:30:00Z")
        XCTAssertNotNil(game.parsedGameDate)
    }

    func testFormattedDateNotRawISO() {
        let game = TestFixtures.makeGame(gameDate: "2025-01-15T19:30:00Z")
        let formatted = game.formattedDate
        XCTAssertFalse(formatted.contains("T"))
    }
}
