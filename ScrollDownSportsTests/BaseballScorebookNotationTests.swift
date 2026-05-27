import XCTest
@testable import ScrollDownSports

final class BaseballScorebookNotationTests: XCTestCase {
    func testNormalizesActiveOutCounts() {
        XCTAssertEqual(BaseballScorebookNotation.normalizedOuts(0), 0)
        XCTAssertEqual(BaseballScorebookNotation.normalizedOuts(1), 1)
        XCTAssertEqual(BaseballScorebookNotation.normalizedOuts(2), 2)
        XCTAssertNil(BaseballScorebookNotation.normalizedOuts(3))
        XCTAssertNil(BaseballScorebookNotation.normalizedOuts(-1))
        XCTAssertNil(BaseballScorebookNotation.normalizedOuts(nil))
    }

    func testNormalizesOnlyValidPitchCounts() {
        XCTAssertEqual(BaseballScorebookNotation.normalizedCount("2-1"), "2-1")
        XCTAssertEqual(BaseballScorebookNotation.normalizedCount(" 3 - 2 "), "3-2")
        XCTAssertNil(BaseballScorebookNotation.normalizedCount(nil))
        XCTAssertNil(BaseballScorebookNotation.normalizedCount(""))
        XCTAssertNil(BaseballScorebookNotation.normalizedCount("4-2"))
        XCTAssertNil(BaseballScorebookNotation.normalizedCount("3-3"))
        XCTAssertNil(BaseballScorebookNotation.normalizedCount("full count"))
    }

    func testDerivesOnlyCompactScoreDeltaNotation() {
        XCTAssertEqual(BaseballScorebookNotation.scoreDelta(from: "Tied -> Up 1"), "UP 1")
        XCTAssertEqual(BaseballScorebookNotation.scoreDelta(from: "Down 1 -> Up 1"), "+2")
        XCTAssertEqual(BaseballScorebookNotation.scoreDelta(from: "Down 2 -> Tied"), "+2")
        XCTAssertNil(BaseballScorebookNotation.scoreDelta(from: nil))
        XCTAssertNil(BaseballScorebookNotation.scoreDelta(from: "Lead change"))
        XCTAssertNil(BaseballScorebookNotation.scoreDelta(from: "Up 2 -> Up 1"))
    }
}
