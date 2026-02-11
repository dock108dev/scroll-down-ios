import XCTest
@testable import ScrollDown

final class SharpBookConfigTests: XCTestCase {

    func testSharpBooksForNBA() {
        let books = SharpBookConfig.sharpBooks(for: "nba")
        XCTAssertTrue(books.contains("pinnacle"))
        XCTAssertTrue(books.contains("circa"))
        XCTAssertTrue(books.contains("betcris"))
    }

    func testSharpBooksForUnknownSport() {
        let books = SharpBookConfig.sharpBooks(for: "curling")
        // Should fall back to default
        XCTAssertTrue(books.contains("pinnacle"))
        XCTAssertTrue(books.contains("circa"))
    }

    func testIsSharpPinnacleForNBA() {
        XCTAssertTrue(SharpBookConfig.isSharp("pinnacle", sport: "nba"))
    }

    func testIsSharpRandomBookNotSharp() {
        XCTAssertFalse(SharpBookConfig.isSharp("fanduel", sport: "nba"))
    }

    func testCaseInsensitivity() {
        let booksLower = SharpBookConfig.sharpBooks(for: "nba")
        let booksUpper = SharpBookConfig.sharpBooks(for: "NBA")
        XCTAssertEqual(booksLower, booksUpper)
    }
}
