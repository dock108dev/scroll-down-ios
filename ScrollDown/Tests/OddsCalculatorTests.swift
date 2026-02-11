import XCTest
@testable import ScrollDown

final class OddsCalculatorTests: XCTestCase {

    // MARK: - americanToProb

    func testAmericanToProbFavorite() {
        let prob = OddsCalculator.americanToProb(-150)
        XCTAssertEqual(prob, 0.6, accuracy: 0.001)
    }

    func testAmericanToProbUnderdog() {
        let prob = OddsCalculator.americanToProb(200)
        XCTAssertEqual(prob, 1.0 / 3.0, accuracy: 0.001)
    }

    func testAmericanToProbEvenMoney() {
        let prob = OddsCalculator.americanToProb(100)
        XCTAssertEqual(prob, 0.5, accuracy: 0.001)
    }

    func testAmericanToProbMinusMoney() {
        let prob = OddsCalculator.americanToProb(-100)
        XCTAssertEqual(prob, 0.5, accuracy: 0.001)
    }

    // MARK: - probToAmerican

    func testProbToAmericanFavorite() {
        let odds = OddsCalculator.probToAmerican(0.6)
        XCTAssertEqual(odds, -150)
    }

    func testProbToAmericanUnderdog() {
        let odds = OddsCalculator.probToAmerican(1.0 / 3.0)
        XCTAssertEqual(odds, 200)
    }

    func testProbToAmericanRoundTrip() {
        let original = -110
        let prob = OddsCalculator.americanToProb(original)
        let roundTripped = OddsCalculator.probToAmerican(prob)
        XCTAssertEqual(roundTripped, original)
    }

    func testProbToAmericanBoundaryClamp() {
        // Invalid probability should return even money
        XCTAssertEqual(OddsCalculator.probToAmerican(0.0), 100)
        XCTAssertEqual(OddsCalculator.probToAmerican(1.0), 100)
    }

    // MARK: - isValidAmericanOdds

    func testIsValidAmericanOddsValid() {
        XCTAssertTrue(OddsCalculator.isValidAmericanOdds(-110))
        XCTAssertTrue(OddsCalculator.isValidAmericanOdds(150))
        XCTAssertTrue(OddsCalculator.isValidAmericanOdds(-500))
        XCTAssertTrue(OddsCalculator.isValidAmericanOdds(100))
        XCTAssertTrue(OddsCalculator.isValidAmericanOdds(-100))
    }

    func testIsValidAmericanOddsInvalid() {
        XCTAssertFalse(OddsCalculator.isValidAmericanOdds(0))
        XCTAssertFalse(OddsCalculator.isValidAmericanOdds(50))
        XCTAssertFalse(OddsCalculator.isValidAmericanOdds(-99))
    }

    // MARK: - decimalOdds

    func testDecimalOddsUnderdog() {
        let decimal = OddsCalculator.decimalOdds(for: AmericanOdds(200))
        XCTAssertEqual(decimal, 3.0, accuracy: 0.01)
    }

    func testDecimalOddsFavorite() {
        let decimal = OddsCalculator.decimalOdds(for: AmericanOdds(-200))
        XCTAssertEqual(decimal, 1.5, accuracy: 0.01)
    }

    // MARK: - formattedOdds

    func testFormattedOddsAmerican() {
        let formatted = OddsCalculator.formattedOdds(AmericanOdds(150), format: .american)
        XCTAssertEqual(formatted, "+150")
    }

    func testFormattedOddsDecimal() {
        let formatted = OddsCalculator.formattedOdds(AmericanOdds(200), format: .decimal)
        XCTAssertEqual(formatted, "3.00")
    }
}
