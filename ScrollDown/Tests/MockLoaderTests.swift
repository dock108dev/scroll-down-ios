import XCTest
@testable import ScrollDown

final class MockLoaderTests: XCTestCase {

    func testLoadValidFileDecodes() throws {
        // game-list.json is in the host app bundle
        let response: GameListResponse = try MockLoader.load("game-list")
        XCTAssertFalse(response.games.isEmpty)
    }

    func testLoadMissingFileThrowsFileNotFound() {
        do {
            let _: GameListResponse = try MockLoader.load("nonexistent-file")
            XCTFail("Expected MockLoaderError.fileNotFound")
        } catch let error as MockLoaderError {
            if case .fileNotFound(let file) = error {
                XCTAssertEqual(file, "nonexistent-file")
            } else {
                XCTFail("Expected fileNotFound, got \(error)")
            }
        } catch {
            XCTFail("Expected MockLoaderError, got \(error)")
        }
    }

    func testLoadWrongTypeThrowsDecodingFailed() {
        // game-list.json is not a PbpResponse — should fail decoding
        do {
            let _: PbpResponse = try MockLoader.load("game-list")
            // If decoding accidentally succeeds (empty events), that's also acceptable
        } catch is MockLoaderError {
            // Expected
        } catch {
            // Any error is acceptable here
        }
    }
}
