import XCTest
@testable import ScrollDown

final class AmericanOddsTests: XCTestCase {

    // MARK: - Init Auto-Correction

    func testInitAutoCorrectNegative99() {
        let odds = AmericanOdds(-99)
        XCTAssertEqual(odds.value, -100)
    }

    func testInitAutoCorrectPositive99() {
        let odds = AmericanOdds(99)
        XCTAssertEqual(odds.value, 100)
    }

    func testInitAutoCorrectZero() {
        let odds = AmericanOdds(0)
        XCTAssertEqual(odds.value, 100)
    }

    func testInitValidValuesUnchanged() {
        XCTAssertEqual(AmericanOdds(-110).value, -110)
        XCTAssertEqual(AmericanOdds(150).value, 150)
        XCTAssertEqual(AmericanOdds(100).value, 100)
        XCTAssertEqual(AmericanOdds(-100).value, -100)
    }

    // MARK: - impliedProbability

    func testImpliedProbabilityFavorite() {
        let odds = AmericanOdds(-200)
        XCTAssertEqual(odds.impliedProbability, 2.0 / 3.0, accuracy: 0.001)
    }

    func testImpliedProbabilityUnderdog() {
        let odds = AmericanOdds(200)
        XCTAssertEqual(odds.impliedProbability, 1.0 / 3.0, accuracy: 0.001)
    }

    // MARK: - decimalOdds

    func testDecimalOddsFavorite() {
        let odds = AmericanOdds(-200)
        XCTAssertEqual(odds.decimalOdds, 1.5, accuracy: 0.01)
    }

    func testDecimalOddsUnderdog() {
        let odds = AmericanOdds(200)
        XCTAssertEqual(odds.decimalOdds, 3.0, accuracy: 0.01)
    }

    // MARK: - displayString

    func testDisplayStringPositive() {
        XCTAssertEqual(AmericanOdds(150).displayString, "+150")
    }

    func testDisplayStringNegative() {
        XCTAssertEqual(AmericanOdds(-110).displayString, "-110")
    }

    // MARK: - isValid

    func testIsValidTrue() {
        XCTAssertTrue(AmericanOdds(-110).isValid)
        XCTAssertTrue(AmericanOdds(100).isValid)
        XCTAssertTrue(AmericanOdds(500).isValid)
    }

    // MARK: - Factory methods

    func testFromDecimal() {
        let odds = AmericanOdds.fromDecimal(2.0)
        // Decimal 2.0 = even money, implementation may return +100 or -100
        XCTAssertTrue(odds.value == 100 || odds.value == -100)
    }

    func testFromProbability() {
        let odds = AmericanOdds.fromProbability(0.5)
        // 0.5 is right at the boundary, should be either +100 or -100
        XCTAssertTrue(odds.value == 100 || odds.value == -100)
    }
}
