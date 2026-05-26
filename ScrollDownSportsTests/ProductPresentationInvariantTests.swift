import XCTest
@testable import ScrollDownSports

@MainActor
final class ProductPresentationInvariantTests: XCTestCase {
    func testHomeCardHidesScoresFromTopRegionsUntilScoreboardPayoff() {
        let game = TestFixtures.makeGame(
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 7,
            homeScore: 6,
            presentation: scoreRichPresentation()
        )
        let item = HomeGameItem(game: game, isPinned: false, pinnedRecord: nil, progress: nil)
        let state = HomeGameCardState(item: item)
        let presentation = SportRendererRegistry.renderer(for: game).gameCardPresentation(for: game)

        XCTAssertEqual(state.scoreCueText, "score at bottom")
        XCTAssertFalse(state.showsScoreRows)
        XCTAssertEqual(state.statusText, "Final")
        XCTAssertEqual(state.primaryActionLabel, "Catch up")
        XCTAssertEqual(presentation.matchupLabel, "New York Yankees at Seattle Mariners")
        assertNoScoreLeak(
            texts: [
                presentation.accessibilityLabel,
                presentation.leagueLabel,
                presentation.sportLabel,
                presentation.statusText,
                presentation.headline,
                presentation.matchupLabel,
                state.metadataText,
                state.contextText,
                state.statusText,
                state.statusBadgeText,
                state.primaryActionLabel
            ],
            forbidden: scoreLeakTerms
        )
    }

    func testDetailHeaderKeepsScoreOutOfHeaderAndScoreboardPresentationContainsResult() {
        let scoreboard = GameScoreboardData(
            layout: "inning_table",
            clockLabel: nil,
            periodLabel: "Final",
            statusLabel: "Final",
            scoreline: "Yankees 7, Mariners 6",
            competitors: [
                ScoreboardCompetitorData(
                    id: "away",
                    side: .away,
                    teamName: "New York Yankees",
                    teamAbbreviation: "NYY",
                    score: 7,
                    scoreText: "7",
                    isWinner: true,
                    recordText: nil
                ),
                ScoreboardCompetitorData(
                    id: "home",
                    side: .home,
                    teamName: "Seattle Mariners",
                    teamAbbreviation: "SEA",
                    score: 6,
                    scoreText: "6",
                    isWinner: false,
                    recordText: nil
                )
            ],
            segments: [ScoreboardSegmentData(label: "9", away: "1", home: "0")],
            totals: ScoreboardTotalsData(away: "7", home: "6")
        )
        let game = TestFixtures.makeGame(
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 7,
            homeScore: 6,
            presentation: scoreRichPresentation(),
            scoreboard: scoreboard
        )
        let renderer = SportRendererRegistry.renderer(for: game)

        let header = renderer.gameHeaderPresentation(for: game)
        assertNoScoreLeak(
            texts: [
                header.accessibilityLabel,
                header.leagueLabel,
                header.sportLabel,
                header.statusText,
                header.playCountText,
                header.headline,
                header.matchupLabel,
                header.secondaryText
            ],
            forbidden: scoreLeakTerms
        )

        let scoreboardPresentation = renderer.scoreboardPresentation(for: game)
        XCTAssertEqual(scoreboardPresentation.title, "Line Score")
        XCTAssertEqual(scoreboardPresentation.layout, .segmentTable)
        XCTAssertEqual(scoreboardPresentation.stateText, "Yankees 7, Mariners 6")
        XCTAssertEqual(scoreboardPresentation.rows.map(\.totalText), ["7", "6"])
        XCTAssertEqual(scoreboardPresentation.revealTitle, "Score hidden")
    }

    func testScoreboardReachPersistsOnlyAfterMeaningfulViewportEntry() {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })
        let viewModel = GameDetailViewModel(gameId: 900, gameStateStore: store)
        let viewport = CGRect(x: 0, y: 0, width: 390, height: 800)

        if hasScoreboardEnteredViewport(
            itemFrame: CGRect(x: 0, y: 784, width: 390, height: 240),
            viewportFrame: viewport
        ) {
            viewModel.setReachedScoreboard(true)
        }
        XCTAssertFalse(store.progress(for: 900)?.reachedScoreboard == true)

        if hasScoreboardEnteredViewport(
            itemFrame: CGRect(x: 0, y: 700, width: 390, height: 240),
            viewportFrame: viewport
        ) {
            viewModel.setReachedScoreboard(true)
        }
        XCTAssertTrue(store.progress(for: 900)?.reachedScoreboard == true)

        let readGame = TestFixtures.makeGame(
            id: 900,
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 7,
            homeScore: 6,
            presentation: scoreRichPresentation()
        )
        let readItem = HomeGameItem(game: readGame, isPinned: false, pinnedRecord: nil, progress: store.progress(for: 900))
        let readState = HomeGameCardState(item: readItem)
        XCTAssertTrue(readState.showsScoreRows)
        XCTAssertEqual(readState.scoreRows.map(\.scoreText), ["7", "6"])

        let unreadGame = TestFixtures.makeGame(id: 901, status: "final", isLive: false, isFinal: true, awayScore: 5, homeScore: 4)
        let unreadItem = HomeGameItem(game: unreadGame, isPinned: false, pinnedRecord: nil, progress: store.progress(for: 901))
        XCTAssertFalse(HomeGameCardState(item: unreadItem).showsScoreRows)

        let header = SportRendererRegistry.renderer(for: readGame).gameHeaderPresentation(for: readGame)
        assertNoScoreLeak(
            texts: [
                header.accessibilityLabel,
                header.statusText,
                header.headline,
                header.matchupLabel,
                header.secondaryText
            ],
            forbidden: scoreLeakTerms
        )
    }

    func testScoringPlayScoreLabelUsesBackendThenScoreAfterFallbackOnlyForScoringPlays() {
        let renderer = GenericSportRenderer(leagueCode: "mlb")
        let scoringMetadata = EventImportanceData(
            level: "primary",
            rank: 90,
            bucket: "scoring_play",
            reasons: ["scoring play"],
            isKeyMoment: true,
            isScoringPlay: true,
            isLeadChange: nil,
            isTyingPlay: nil,
            winProbabilityDelta: nil
        )
        let scoreDelta = ScoreDelta(participantID: "home", participantRole: .home, before: 2, after: 4, change: 2)

        let backendLabel = TestFixtures.makeEvent(
            sequence: 1,
            scoreDelta: scoreDelta,
            presentation: TestFixtures.eventPresentation(scoreLabel: "SEA 4, NYY 3"),
            importanceMetadata: scoringMetadata,
            homeScore: 4,
            awayScore: 3
        )
        XCTAssertEqual(renderer.eventPresentation(for: backendLabel).scoreLabel, "SEA 4, NYY 3")

        let fallbackLabel = TestFixtures.makeEvent(
            sequence: 2,
            scoreDelta: scoreDelta,
            importanceMetadata: scoringMetadata,
            homeScore: 4,
            awayScore: 3
        )
        XCTAssertEqual(renderer.eventPresentation(for: fallbackLabel).scoreLabel, "3-4")

        let nonScoring = TestFixtures.makeEvent(sequence: 3, homeScore: 4, awayScore: 3)
        XCTAssertNil(renderer.eventPresentation(for: nonScoring).scoreLabel)

        let incompleteScoreAfter = TestFixtures.makeEvent(
            sequence: 4,
            scoreDelta: scoreDelta,
            importanceMetadata: scoringMetadata,
            homeScore: nil,
            awayScore: 3
        )
        XCTAssertNil(renderer.eventPresentation(for: incompleteScoreAfter).scoreLabel)
    }

    func testFinalGameWithoutScoreboardDataKeepsTopRegionsScorelessAndAllowsNoScorePayoff() {
        let game = TestFixtures.makeGame(
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: nil,
            homeScore: nil,
            eventCount: nil,
            hasTimeline: false,
            hasScoreboard: true,
            presentation: scoreRichPresentation()
        )
        let item = HomeGameItem(game: game, isPinned: false, pinnedRecord: nil, progress: nil)
        let state = HomeGameCardState(item: item)
        let renderer = SportRendererRegistry.renderer(for: game)
        let header = renderer.gameHeaderPresentation(for: game)
        let scoreboard = renderer.scoreboardPresentation(for: game)

        XCTAssertNil(state.scoreCueText)
        XCTAssertFalse(state.showsScoreRows)
        XCTAssertNil(state.progressText)
        XCTAssertEqual(state.primaryActionLabel, "Open box score")
        XCTAssertEqual(scoreboard.stateText, "Final")
        XCTAssertEqual(scoreboard.rows.map(\.totalText), ["-", "-"])
        assertNoScoreLeak(
            texts: [
                header.accessibilityLabel,
                header.statusText,
                header.headline,
                header.matchupLabel,
                state.statusText,
                state.contextText,
                state.primaryActionLabel
            ],
            forbidden: scoreLeakTerms
        )
    }

    func testStreamModesAndEventLabelsUseCustomerLanguage() {
        XCTAssertEqual(DetailStreamMode.allCases.map(\.title), ["Important", "Standard", "All Plays"])

        let homeRun = TestFixtures.makeEvent(sequence: 1, eventType: "Home run")
        let fieldOut = TestFixtures.makeEvent(sequence: 2, eventType: "Out")
        let renderer = GenericSportRenderer(leagueCode: "mlb")

        XCTAssertEqual(renderer.eventPresentation(for: homeRun).eventLabel, "Home run")
        XCTAssertEqual(renderer.eventPresentation(for: fieldOut).eventLabel, "Out")
        XCTAssertEqual(homeRun.visualImportance.title, "")

        let duplicatedClock = TestFixtures.makeEvent(
            sequence: 3,
            periodLabel: "6th",
            clockLabel: "6th"
        )
        XCTAssertEqual(duplicatedClock.clockText, "6th")
    }

    func testBaseballEventsUseSituationContextWithoutRepeatingPlayerName() {
        let event = TestFixtures.makeEvent(
            sequence: 1,
            headline: "Jeff McNeil walks.",
            detail: "Jeff McNeil",
            clockLabel: "8th",
            eventType: "Walk",
            presentation: TestFixtures.eventPresentation(timeLabel: "8th"),
            importanceMetadata: EventImportanceData(
                level: "secondary",
                rank: 40,
                bucket: "base_runner",
                reasons: ["runner aboard"],
                isKeyMoment: false,
                isScoringPlay: false,
                isLeadChange: false,
                isTyingPlay: false,
                winProbabilityDelta: nil
            ),
            sportMetadata: [
                "baseState": .string("runner_on_first"),
                "outs": .number(1),
                "balls": .number(3),
                "strikes": .number(1)
            ]
        )

        let presentation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "8th")

        XCTAssertEqual(presentation.detail, "Runner on 1st · 1 out · 3-1 count")
        XCTAssertFalse(presentation.detail?.contains("Jeff McNeil") == true)
    }

    func testBaseballEventsPreserveNonDuplicateDetailWithSituationContext() {
        let event = TestFixtures.makeEvent(
            sequence: 2,
            headline: "Shea Langeliers strikes out swinging.",
            detail: "Leaves two aboard",
            clockLabel: "2 outs",
            eventType: "Strikeout",
            sportMetadata: [
                "baseState": .string("runners_on_second_and_third"),
                "count": .string("1-2")
            ]
        )

        let presentation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "9th")

        XCTAssertEqual(presentation.detail, "Leaves two aboard · Runners on 2nd and 3rd · 2 outs · 1-2 count")
    }

    private func assertNoScoreLeak(texts: [String?], forbidden: [String], file: StaticString = #filePath, line: UInt = #line) {
        let combined = texts.compactMap { $0 }.joined(separator: " | ")
        for value in forbidden {
            XCTAssertFalse(combined.localizedCaseInsensitiveContains(value), "\(value) leaked through \(combined)", file: file, line: line)
        }
    }

    private var scoreLeakTerms: [String] {
        ["7-6", "6-7", "Yankees 7", "Mariners 6", "NYY 7", "SEA 6", "won", "lost", "winner"]
    }

    private func scoreRichPresentation() -> GamePresentationData {
        GamePresentationData(
            headline: "Yankees 7, Mariners 6",
            shortHeadline: "NYY 7-6",
            subheadline: "NYY 7 at SEA 6",
            matchupLabel: "NYY 7 at SEA 6",
            primaryLabel: "Yankees won 7-6",
            secondaryLabel: "Mariners lost 7-6",
            tertiaryLabel: nil,
            accessibilityLabel: "Yankees won 7-6 over Mariners",
            displayState: nil,
            visualPriority: nil,
            sortBucket: nil,
            accentRole: nil,
            statusTone: nil,
            eventCounts: nil,
            statusLabel: "Final: NYY 7, SEA 6",
            primaryActionLabel: "Open Yankees 7-6 win",
            secondaryContextLabel: nil,
            scoreboardPlacement: "bottom"
        )
    }

    func testScoreboardReachIgnoresAreaBehindBottomAffordance() {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })
        let viewModel = GameDetailViewModel(gameId: 901, gameStateStore: store)
        let viewport = scoreboardReachViewportFrame(width: 390, height: 800, obscuredBottomHeight: 86)

        if hasScoreboardEnteredViewport(
            itemFrame: CGRect(x: 0, y: 700, width: 390, height: 240),
            viewportFrame: viewport
        ) {
            viewModel.setReachedScoreboard(true)
        }
        XCTAssertFalse(store.progress(for: 901)?.reachedScoreboard == true)

        if hasScoreboardEnteredViewport(
            itemFrame: CGRect(x: 0, y: 640, width: 390, height: 240),
            viewportFrame: viewport
        ) {
            viewModel.setReachedScoreboard(true)
        }
        XCTAssertTrue(store.progress(for: 901)?.reachedScoreboard == true)
    }

}
