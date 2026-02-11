import XCTest
@testable import ScrollDown

final class BetPairingTests: XCTestCase {

    private func makeAPIBet(
        gameId: Int = 1,
        homeTeam: String = "Boston Celtics",
        awayTeam: String = "Los Angeles Lakers",
        marketKey: String = "h2h",
        selectionKey: String = "team:boston_celtics",
        lineValue: Double? = nil,
        books: [BookPrice] = []
    ) -> APIBet {
        APIBet(
            gameId: gameId,
            leagueCode: "NBA",
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            gameDate: Date(),
            marketKey: marketKey,
            selectionKey: selectionKey,
            lineValue: lineValue,
            books: books
        )
    }

    // MARK: - pairingKey

    func testPairingKeyConsistency() {
        let bet1 = makeAPIBet(selectionKey: "team:boston_celtics")
        let bet2 = makeAPIBet(selectionKey: "team:los_angeles_lakers")
        // Both bets in same market should have same pairing key
        XCTAssertEqual(
            BetPairingService.pairingKey(for: bet1),
            BetPairingService.pairingKey(for: bet2)
        )
    }

    func testPairingKeyDifferentMarkets() {
        let bet1 = makeAPIBet(marketKey: "h2h")
        let bet2 = makeAPIBet(marketKey: "spreads", lineValue: 5.5)
        XCTAssertNotEqual(
            BetPairingService.pairingKey(for: bet1),
            BetPairingService.pairingKey(for: bet2)
        )
    }

    // MARK: - oppositeSelection

    func testOppositeSelectionMoneyline() {
        let homeBet = makeAPIBet(selectionKey: "team:boston_celtics")
        let opposite = BetPairingService.oppositeSelection(for: homeBet)
        XCTAssertEqual(opposite, "Los Angeles Lakers")
    }

    func testOppositeSelectionTotals() {
        let overBet = makeAPIBet(marketKey: "totals", selectionKey: "total:over")
        let opposite = BetPairingService.oppositeSelection(for: overBet)
        XCTAssertEqual(opposite, "Under")
    }

    // MARK: - pairBets

    func testPairBetsMatchesPairs() {
        let homeBet = makeAPIBet(
            selectionKey: "team:boston_celtics",
            books: [BookPrice(book: "draftkings", priceValue: -150, observedAt: Date())]
        )
        let awayBet = makeAPIBet(
            selectionKey: "team:los_angeles_lakers",
            books: [BookPrice(book: "draftkings", priceValue: 130, observedAt: Date())]
        )

        let pairs = BetPairingService.pairBets([homeBet, awayBet])
        XCTAssertNotNil(pairs[homeBet.id])
        XCTAssertNotNil(pairs[awayBet.id])
    }

    func testPairBetsUnmatchedAlone() {
        let bet = makeAPIBet(
            selectionKey: "team:boston_celtics",
            books: [BookPrice(book: "draftkings", priceValue: -150, observedAt: Date())]
        )
        let pairs = BetPairingService.pairBets([bet])
        XCTAssertTrue(pairs.isEmpty)
    }
}
