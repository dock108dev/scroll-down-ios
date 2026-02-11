import XCTest
@testable import ScrollDown

final class SocialPostTests: XCTestCase {

    // MARK: - SocialPostResponse.isSafeToShow

    func testIsSafeToShowPreRevealAlwaysSafe() {
        let post = TestFixtures.makeSocialPostResponse(revealLevel: .pre)
        XCTAssertTrue(post.isSafeToShow(outcomeRevealed: false))
        XCTAssertTrue(post.isSafeToShow(outcomeRevealed: true))
    }

    func testIsSafeToShowPostRevealOnlyWhenRevealed() {
        let post = TestFixtures.makeSocialPostResponse(revealLevel: .post)
        XCTAssertFalse(post.isSafeToShow(outcomeRevealed: false))
        XCTAssertTrue(post.isSafeToShow(outcomeRevealed: true))
    }

    func testIsSafeToShowNilRevealLevel() {
        let post = TestFixtures.makeSocialPostResponse(revealLevel: nil)
        // nil revealLevel → uses outcomeRevealed parameter
        XCTAssertFalse(post.isSafeToShow(outcomeRevealed: false))
        XCTAssertTrue(post.isSafeToShow(outcomeRevealed: true))
    }

    // MARK: - SocialPostEntry.hasContent

    func testHasContentWithTweetText() {
        let post = TestFixtures.makeSocialPost(tweetText: "Great game!", imageUrl: nil)
        XCTAssertTrue(post.hasContent)
    }

    func testHasContentWithImageUrl() {
        let post = SocialPostEntry(
            id: 1,
            postUrl: "https://x.com/test",
            postedAt: "2025-01-15T19:00:00Z",
            hasVideo: false,
            teamAbbreviation: "BOS",
            imageUrl: "https://example.com/img.jpg"
        )
        XCTAssertTrue(post.hasContent)
    }

    func testHasContentWithVideoUrl() {
        let post = SocialPostEntry(
            id: 1,
            postUrl: "https://x.com/test",
            postedAt: "2025-01-15T19:00:00Z",
            hasVideo: true,
            teamAbbreviation: "BOS",
            videoUrl: "https://example.com/vid.mp4"
        )
        XCTAssertTrue(post.hasContent)
    }

    func testHasContentEmpty() {
        let post = SocialPostEntry(
            id: 1,
            postUrl: "https://x.com/test",
            postedAt: "2025-01-15T19:00:00Z",
            hasVideo: false,
            teamAbbreviation: "BOS"
        )
        XCTAssertFalse(post.hasContent)
    }
}
