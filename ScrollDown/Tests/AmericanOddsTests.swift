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

    // MARK: - displayString

    func testDisplayStringPositive() {
        XCTAssertEqual(AmericanOdds(150).displayString, "+150")
    }

    func testDisplayStringNegative() {
        XCTAssertEqual(AmericanOdds(-110).displayString, "-110")
    }
}
