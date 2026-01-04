import XCTest
@testable import ScrollDown

final class GameDetailViewModelTests: XCTestCase {
    @MainActor
    func testScoreMarkerUsesHalftimeLabelForSecondQuarterEnd() {
        let play = PlayEntry(
            playIndex: 12,
            quarter: 2,
            gameClock: "0:00",
            playType: .periodEnd,
            teamAbbreviation: nil,
            playerName: nil,
            description: nil,
            homeScore: 54,
            awayScore: 50
        )
        let viewModel = GameDetailViewModel()

        let marker = viewModel.scoreMarker(for: play)

        XCTAssertEqual(marker?.label, "Halftime")
        XCTAssertEqual(marker?.score, "50 - 54")
    }

    @MainActor
    func testScoreMarkerUsesPeriodEndLabelForOtherQuarters() {
        let play = PlayEntry(
            playIndex: 22,
            quarter: 1,
            gameClock: "0:00",
            playType: .periodEnd,
            teamAbbreviation: nil,
            playerName: nil,
            description: nil,
            homeScore: 26,
            awayScore: 28
        )
        let viewModel = GameDetailViewModel()

        let marker = viewModel.scoreMarker(for: play)

        XCTAssertEqual(marker?.label, "Period End")
        XCTAssertEqual(marker?.score, "28 - 26")
    }

    @MainActor
    func testLiveScoreMarkerUsesLatestPlayScore() {
        let game = Game(
            id: 1,
            leagueCode: "NBA",
            season: 2024,
            seasonType: "regular",
            gameDate: "2024-11-12T00:00:00Z",
            homeTeam: "HOME",
            awayTeam: "AWAY",
            homeScore: 12,
            awayScore: 10,
            status: .inProgress,
            scrapeVersion: nil,
            lastScrapedAt: nil,
            hasBoxscore: nil,
            hasPlayerStats: nil,
            hasOdds: nil,
            hasSocial: nil,
            hasPbp: nil,
            playCount: nil,
            socialPostCount: nil,
            homeTeamXHandle: nil,
            awayTeamXHandle: nil
        )
        let plays = [
            PlayEntry(
                playIndex: 1,
                quarter: 1,
                gameClock: "10:00",
                playType: .madeShot,
                teamAbbreviation: nil,
                playerName: nil,
                description: nil,
                homeScore: 2,
                awayScore: 0
            ),
            PlayEntry(
                playIndex: 2,
                quarter: 1,
                gameClock: "05:00",
                playType: .madeShot,
                teamAbbreviation: nil,
                playerName: nil,
                description: nil,
                homeScore: 18,
                awayScore: 20
            )
        ]
        let detail = GameDetailResponse(
            game: game,
            teamStats: [],
            playerStats: [],
            odds: [],
            socialPosts: [],
            plays: plays,
            compactMoments: nil,
            derivedMetrics: [:],
            rawPayloads: [:]
        )
        let viewModel = GameDetailViewModel(detail: detail)

        let marker = viewModel.liveScoreMarker

        XCTAssertEqual(marker?.label, "Live Score")
        XCTAssertEqual(marker?.score, "20 - 18")
    }
}
