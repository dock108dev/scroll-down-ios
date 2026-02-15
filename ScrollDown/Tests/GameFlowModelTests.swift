import XCTest
@testable import ScrollDown

final class GameFlowModelTests: XCTestCase {

    // MARK: - FlowBlock Computed Properties

    func testFlowBlockStartScore() {
        let block = makeFlowBlock(scoreBefore: [80, 85])  // [away, home]
        XCTAssertEqual(block.startScore.away, 80)
        XCTAssertEqual(block.startScore.home, 85)
    }

    func testFlowBlockEndScore() {
        let block = makeFlowBlock(scoreAfter: [90, 95])
        XCTAssertEqual(block.endScore.away, 90)
        XCTAssertEqual(block.endScore.home, 95)
    }

    func testFlowBlockPeriodDisplaySamePeriod() {
        let block = makeFlowBlock(periodStart: 3, periodEnd: 3)
        XCTAssertEqual(block.periodDisplay, "Q3")
    }

    func testFlowBlockPeriodDisplayCrossingPeriods() {
        let block = makeFlowBlock(periodStart: 1, periodEnd: 2)
        XCTAssertEqual(block.periodDisplay, "Q1-Q2")
    }

    // MARK: - BlockRole Decoding

    func testBlockRoleDecodingAllCases() throws {
        for role in BlockRole.allCases {
            let json = "\"\(role.rawValue)\"".data(using: .utf8)!
            let decoded = try JSONDecoder().decode(BlockRole.self, from: json)
            XCTAssertEqual(decoded, role)
        }
    }

    func testBlockRoleDecodingUnknown() throws {
        let json = "\"SOMETHING_NEW\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(BlockRole.self, from: json)
        XCTAssertEqual(decoded, .unknown)
    }

    // MARK: - BlockPlayerStat

    func testBasketballStatLine() {
        let stat = BlockPlayerStat(
            name: "Jayson Tatum",
            pts: 15, reb: 4, ast: 6, threePm: nil,
            deltaPts: 7, deltaReb: 2, deltaAst: nil,
            goals: nil, assists: nil, sog: nil, plusMinus: nil,
            deltaGoals: nil, deltaAssists: nil
        )
        let line = stat.basketballStatLine
        XCTAssertTrue(line.contains("15p"))
        XCTAssertTrue(line.contains("4r"))
        XCTAssertTrue(line.contains("6a"))
        XCTAssertTrue(line.contains("+7p"))
        XCTAssertTrue(line.contains("+2r"))
    }

    func testHockeyStatLine() {
        let stat = BlockPlayerStat(
            name: "Connor McDavid",
            pts: nil, reb: nil, ast: nil, threePm: nil,
            deltaPts: nil, deltaReb: nil, deltaAst: nil,
            goals: 2, assists: 1, sog: 5, plusMinus: 2,
            deltaGoals: 1, deltaAssists: nil
        )
        let line = stat.hockeyStatLine
        XCTAssertTrue(line.contains("2g"))
        XCTAssertTrue(line.contains("1a"))
        XCTAssertTrue(line.contains("+1g"))
    }

    // MARK: - BlockMiniBox

    func testIsBlockStar() {
        let miniBox = BlockMiniBox(
            home: BlockTeamMiniBox(team: "BOS", players: []),
            away: BlockTeamMiniBox(team: "LAL", players: []),
            blockStars: ["Jayson Tatum", "LeBron James"]
        )
        XCTAssertTrue(miniBox.isBlockStar("Jayson Tatum"))
        XCTAssertFalse(miniBox.isBlockStar("Unknown Player"))
    }

    // MARK: - CamelCase Delta Decoding

    func testCamelCaseDeltaDecodingBasketball() throws {
        let json = """
        {
            "name": "Jayson Tatum",
            "pts": 22, "reb": 6, "ast": 4, "3pm": 3,
            "deltaPts": 8, "deltaReb": 2, "deltaAst": 1
        }
        """.data(using: .utf8)!
        let stat = try JSONDecoder().decode(BlockPlayerStat.self, from: json)
        XCTAssertEqual(stat.name, "Jayson Tatum")
        XCTAssertEqual(stat.pts, 22)
        XCTAssertEqual(stat.threePm, 3)
        XCTAssertEqual(stat.deltaPts, 8)
        XCTAssertEqual(stat.deltaReb, 2)
        XCTAssertEqual(stat.deltaAst, 1)
    }

    func testCamelCaseDeltaDecodingHockey() throws {
        let json = """
        {
            "name": "Connor McDavid",
            "goals": 2, "assists": 1, "sog": 5, "plusMinus": 2,
            "deltaGoals": 1, "deltaAssists": 1
        }
        """.data(using: .utf8)!
        let stat = try JSONDecoder().decode(BlockPlayerStat.self, from: json)
        XCTAssertEqual(stat.name, "Connor McDavid")
        XCTAssertEqual(stat.goals, 2)
        XCTAssertEqual(stat.deltaGoals, 1)
        XCTAssertEqual(stat.deltaAssists, 1)
    }

    func testDeltaFieldsMissingDecodeAsNil() throws {
        let json = """
        {
            "name": "Role Player",
            "pts": 5, "reb": 2, "ast": 0
        }
        """.data(using: .utf8)!
        let stat = try JSONDecoder().decode(BlockPlayerStat.self, from: json)
        XCTAssertEqual(stat.name, "Role Player")
        XCTAssertEqual(stat.pts, 5)
        XCTAssertNil(stat.deltaPts)
        XCTAssertNil(stat.deltaReb)
        XCTAssertNil(stat.deltaAst)
    }

    // MARK: - FlowMoment Decoding

    func testFlowMomentDecoding() throws {
        let json = """
        {
            "playIds": [101, 102, 103],
            "explicitlyNarratedPlayIds": [101],
            "period": 2,
            "startClock": "8:45",
            "endClock": "6:12",
            "scoreBefore": [45, 50],
            "scoreAfter": [52, 55]
        }
        """.data(using: .utf8)!
        let moment = try JSONDecoder().decode(FlowMoment.self, from: json)
        XCTAssertEqual(moment.playIds, [101, 102, 103])
        XCTAssertEqual(moment.explicitlyNarratedPlayIds, [101])
        XCTAssertEqual(moment.period, 2)
        XCTAssertEqual(moment.startClock, "8:45")
        XCTAssertEqual(moment.endClock, "6:12")
        XCTAssertEqual(moment.scoreBefore, [45, 50])
        XCTAssertEqual(moment.scoreAfter, [52, 55])
    }

    // MARK: - Helpers

    private func makeFlowBlock(
        periodStart: Int = 1,
        periodEnd: Int = 1,
        scoreBefore: [Int] = [0, 0],
        scoreAfter: [Int] = [10, 12]
    ) -> FlowBlock {
        FlowBlock(
            blockIndex: 0,
            role: .setup,
            momentIndices: [],
            periodStart: periodStart,
            periodEnd: periodEnd,
            scoreBefore: scoreBefore,
            scoreAfter: scoreAfter,
            playIds: [1, 2, 3],
            keyPlayIds: [1],
            narrative: "Test narrative",
            miniBox: nil,
            embeddedSocialPostId: nil
        )
    }
}
