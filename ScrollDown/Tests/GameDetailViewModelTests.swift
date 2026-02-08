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
            derivedMetrics: [:],
            rawPayloads: [:]
        )
        let viewModel = GameDetailViewModel(detail: detail)

        let marker = viewModel.liveScoreMarker

        XCTAssertEqual(marker?.label, "Live Score")
        XCTAssertEqual(marker?.score, "20 - 18")
    }

    @MainActor
    func testLoadMarksUnavailableWhenIdsMismatch() async {
        let game = Game(
            id: 999,
            leagueCode: "NBA",
            season: 2024,
            seasonType: "regular",
            gameDate: "2024-11-12T00:00:00Z",
            homeTeam: "HOME",
            awayTeam: "AWAY",
            homeScore: nil,
            awayScore: nil,
            status: .scheduled,
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
        let detail = GameDetailResponse(
            game: game,
            teamStats: [],
            playerStats: [],
            odds: [],
            socialPosts: [],
            plays: [],
            derivedMetrics: [:],
            rawPayloads: [:]
        )
        let service = StubGameService(detail: detail)
        let viewModel = GameDetailViewModel()

        await viewModel.load(gameId: 1, league: "NBA", service: service)

        XCTAssertNil(viewModel.detail)
        XCTAssertTrue(viewModel.isUnavailable)
    }
}

private struct StubGameService: GameService {
    let detail: GameDetailResponse

    func fetchGame(id: Int) async throws -> GameDetailResponse {
        detail
    }

    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse {
        GameListResponse(
            range: range.rawValue,
            games: [],
            total: 0,
            nextOffset: nil,
            withBoxscoreCount: 0,
            withPlayerStatsCount: 0,
            withOddsCount: 0,
            withSocialCount: 0,
            withPbpCount: 0,
            lastUpdatedAt: nil
        )
    }

    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        PbpResponse(events: [])
    }

    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse {
        SocialPostListResponse(posts: [], total: 0)
    }

    func fetchTimeline(gameId: Int) async throws -> TimelineArtifactResponse {
        TimelineArtifactResponse(
            gameId: gameId,
            sport: nil,
            timelineVersion: nil,
            generatedAt: nil,
            timelineJson: nil,
            gameAnalysisJson: nil,
            summaryJson: nil
        )
    }

    func fetchStory(gameId: Int) async throws -> GameStoryResponse {
        GameStoryResponse(gameId: gameId, sport: "NBA")
    }
}
