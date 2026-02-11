import XCTest
@testable import ScrollDown

final class FairOddsCalculatorTests: XCTestCase {

    // MARK: - Confidence Levels

    func testConfidenceHighWithTwoSharpBooks() {
        let betGroup = makeBetGroupWithSharpBooks(sharpBookCount: 2)
        let result = FairOddsCalculator.computeFairOdds(for: betGroup)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.confidence, .high)
    }

    func testConfidenceMediumWithOneSharpBook() {
        let betGroup = makeBetGroupWithSharpBooks(sharpBookCount: 1)
        let result = FairOddsCalculator.computeFairOdds(for: betGroup)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.confidence, .medium)
    }

    func testNilWithNoSharpBooks() {
        let betGroup = makeBetGroupWithSharpBooks(sharpBookCount: 0)
        let result = FairOddsCalculator.computeFairOdds(for: betGroup)
        XCTAssertNil(result)
    }

    // MARK: - calculateEdge

    func testCalculateEdgePositive() {
        // Book price implies lower probability than fair → positive edge
        let edge = FairOddsCalculator.calculateEdge(bookPrice: 100, fairProbability: 0.55)
        XCTAssertGreaterThan(edge, 0)
    }

    func testCalculateEdgeNegative() {
        // Book price implies higher probability than fair → negative edge
        let edge = FairOddsCalculator.calculateEdge(bookPrice: -200, fairProbability: 0.5)
        XCTAssertLessThan(edge, 0)
    }

    // MARK: - calculateEVPercent

    func testCalculateEVPercent() {
        let ev = FairOddsCalculator.calculateEVPercent(bookPrice: 100, fairProbability: 0.55)
        // fairProb/bookImplied - 1 = 0.55/0.5 - 1 = 0.10 → 10%
        XCTAssertEqual(ev, 10.0, accuracy: 0.1)
    }

    // MARK: - Helpers

    private func makeBetGroupWithSharpBooks(sharpBookCount: Int) -> BetGroup {
        let sharpBooks = ["pinnacle", "circa", "betcris"]
        let observedAt = Date()

        var homePrices: [GroupBookPrice] = []
        var awayPrices: [GroupBookPrice] = []

        for i in 0..<sharpBookCount {
            let bookKey = sharpBooks[i]
            homePrices.append(GroupBookPrice(bookKey: bookKey, price: -110, observedAt: observedAt))
            awayPrices.append(GroupBookPrice(bookKey: bookKey, price: -110, observedAt: observedAt))
        }

        if sharpBookCount == 0 {
            // Add non-sharp book so the group has some data
            homePrices.append(GroupBookPrice(bookKey: "randombook", price: -115, observedAt: observedAt))
            awayPrices.append(GroupBookPrice(bookKey: "randombook", price: -105, observedAt: observedAt))
        }

        return BetGroupFactory.createMoneyline(
            gameId: "nba:2025-01-15:LAL-BOS",
            homeTeam: "BOS",
            awayTeam: "LAL",
            homePrices: homePrices,
            awayPrices: awayPrices
        )
    }
}
