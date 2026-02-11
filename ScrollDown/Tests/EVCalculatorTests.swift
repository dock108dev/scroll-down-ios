import XCTest
@testable import ScrollDown

final class EVCalculatorTests: XCTestCase {

    // MARK: - computeBookEV

    func testComputeBookEVPositive() {
        // Fair prob 0.55, odds +100 → positive EV
        let result = EVCalculator.computeBookEV(bookKey: "draftkings", americanOdds: 100, pFair: 0.55)
        XCTAssertGreaterThan(result.ev, 0)
        XCTAssertTrue(result.hasPositiveEV)
    }

    func testComputeBookEVNegative() {
        // Fair prob 0.4, odds -200 → negative EV
        let result = EVCalculator.computeBookEV(bookKey: "draftkings", americanOdds: -200, pFair: 0.4)
        XCTAssertLessThan(result.ev, 0)
        XCTAssertFalse(result.hasPositiveEV)
    }

    func testComputeBookEVBreakEven() {
        // Fair prob 0.5, odds +100 → ~0 EV
        let result = EVCalculator.computeBookEV(bookKey: "draftkings", americanOdds: 100, pFair: 0.5)
        XCTAssertEqual(result.ev, 0, accuracy: 0.001)
    }

    func testComputeBookEVWithFee() {
        // novig has 2% fee on winnings
        let result = EVCalculator.computeBookEV(bookKey: "novig", americanOdds: 100, pFair: 0.55)
        XCTAssertTrue(result.feeApplied)
        XCTAssertEqual(result.feeRate, 0.02, accuracy: 0.001)
        XCTAssertLessThan(result.netProfit, result.grossProfit)
    }

    // MARK: - americanToProfit

    func testAmericanToProfitUnderdog() {
        let profit = EVCalculator.americanToProfit(200)
        XCTAssertEqual(profit, 2.0, accuracy: 0.001)
    }

    func testAmericanToProfitFavorite() {
        let profit = EVCalculator.americanToProfit(-200)
        XCTAssertEqual(profit, 0.5, accuracy: 0.001)
    }

    func testAmericanToProfitZero() {
        let profit = EVCalculator.americanToProfit(0)
        XCTAssertEqual(profit, 0, accuracy: 0.001)
    }

    // MARK: - computeMarketProbability

    func testComputeMarketProbabilitySinglePrice() {
        let prob = EVCalculator.computeMarketProbability(from: [-150])
        XCTAssertNotNil(prob)
        XCTAssertEqual(prob!, 0.6, accuracy: 0.001)
    }

    func testComputeMarketProbabilityMultiplePrices() {
        let prob = EVCalculator.computeMarketProbability(from: [-110, -120, -100])
        XCTAssertNotNil(prob)
        // Median of implied probs: americanToProb(-100)=0.5, americanToProb(-110)≈0.524, americanToProb(-120)≈0.545
        // Sorted: 0.5, 0.524, 0.545 → median ≈ 0.524
        XCTAssertEqual(prob!, OddsCalculator.americanToProb(-110), accuracy: 0.001)
    }

    func testComputeMarketProbabilityEmpty() {
        let prob = EVCalculator.computeMarketProbability(from: [])
        XCTAssertNil(prob)
    }
}
