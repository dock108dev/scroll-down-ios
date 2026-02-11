import XCTest
@testable import ScrollDown

final class FlowAdapterTests: XCTestCase {

    func testEmptyResponseProducesEmptyModels() {
        let response = GameFlowResponse(gameId: 1, sport: "NBA")
        let models = FlowAdapter.convertToDisplayModels(from: response)
        XCTAssertTrue(models.isEmpty)
    }

    func testSingleBlockConvertsCorrectly() {
        let play = FlowPlay(
            playId: 1, playIndex: 0, period: 1,
            clock: "10:00", playType: "made_shot",
            description: "J. Tatum makes shot",
            team: "BOS", playerName: "Jayson Tatum",
            homeScore: 2, awayScore: 0
        )
        let block = FlowBlock(
            blockIndex: 0,
            role: .setup,
            momentIndices: [],
            periodStart: 1,
            periodEnd: 1,
            scoreBefore: [0, 0],
            scoreAfter: [0, 2],
            playIds: [1],
            keyPlayIds: [1],
            narrative: "Opening run",
            miniBox: nil,
            embeddedSocialPostId: nil
        )
        let response = GameFlowResponse(
            gameId: 1,
            sport: "NBA",
            plays: [play],
            blocks: [block]
        )

        let models = FlowAdapter.convertToDisplayModels(from: response)

        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models[0].narrative, "Opening run")
        XCTAssertEqual(models[0].startScore.home, 0)
        XCTAssertEqual(models[0].endScore.home, 2)
        XCTAssertEqual(models[0].periodStart, 1)
    }

    func testSocialPostEmbedding() {
        let post = TestFixtures.makeSocialPost(id: 42, tweetText: "Embedded post")
        let block = FlowBlock(
            blockIndex: 0,
            role: .momentumShift,
            momentIndices: [],
            periodStart: 2,
            periodEnd: 2,
            scoreBefore: [40, 42],
            scoreAfter: [45, 50],
            playIds: [],
            keyPlayIds: [],
            narrative: "Momentum shift",
            miniBox: nil,
            embeddedSocialPostId: 42
        )
        let response = GameFlowResponse(
            gameId: 1,
            sport: "NBA",
            plays: [],
            blocks: [block]
        )

        let models = FlowAdapter.convertToDisplayModels(
            from: response,
            socialPosts: [post]
        )

        XCTAssertEqual(models.count, 1)
        XCTAssertNotNil(models[0].embeddedSocialPost)
        XCTAssertEqual(models[0].embeddedSocialPost?.id, 42)
    }

    func testMultiBlockOrdering() {
        let blocks = (0..<3).map { i in
            FlowBlock(
                blockIndex: i,
                role: .setup,
                momentIndices: [],
                periodStart: 1,
                periodEnd: 1,
                scoreBefore: [i * 10, i * 10 + 2],
                scoreAfter: [(i + 1) * 10, (i + 1) * 10 + 2],
                playIds: [],
                keyPlayIds: [],
                narrative: "Block \(i)",
                miniBox: nil,
                embeddedSocialPostId: nil
            )
        }
        let response = GameFlowResponse(
            gameId: 1,
            sport: "NBA",
            plays: [],
            blocks: blocks
        )

        let models = FlowAdapter.convertToDisplayModels(from: response)

        XCTAssertEqual(models.count, 3)
        XCTAssertEqual(models[0].narrative, "Block 0")
        XCTAssertEqual(models[2].narrative, "Block 2")
    }
}
