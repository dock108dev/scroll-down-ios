import SwiftUI
import XCTest
@testable import ScrollDownSports

@MainActor
final class EventAndScoreboardSnapshotTests: SnapshotTestCase {
    func testPlayRowsCoverImportanceScoringAndRawFeedStates() {
        let game = ComponentSnapshotFixtures.game(id: 5_130, status: "in_progress", awayScore: 3, homeScore: 4)
        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                PlayRow(
                    presentation: Self.normalizedPresentation(
                        game: game,
                        sportLabel: "MLB",
                        headline: "Julio Rodriguez turns a bases-loaded chance into the lead",
                        body: "Seattle gets the finished card copy from the backend.",
                        context: ["B8 1 out", "SEA", "Single"],
                        result: ["Lead change", "Bases loaded"],
                        scoreValue: "SEA 5, OAK 4",
                        rawFeedText: "single to center, runners on second and third score"
                    ),
                    importance: .critical,
                    rawFeedKey: "critical-score",
                    isRawFeedExpanded: false,
                    onRawFeedExpansionChange: { _, _ in }
                )
                PlayRow(
                    presentation: Self.normalizedPresentation(
                        game: game,
                        sportLabel: "NFL",
                        headline: "Bay Harbor finishes the drive with a short scoring run",
                        body: "The same card system carries the richer football context.",
                        context: ["Q4 01:18", "BAY", "Touchdown"],
                        result: ["Red zone", "Drive payoff"],
                        scoreValue: "BAY 27, NAR 24",
                        rawFeedText: "rush middle for 3 yards, touchdown confirmed by review"
                    ),
                    importance: .critical,
                    rawFeedKey: "critical-score",
                    isRawFeedExpanded: true,
                    onRawFeedExpansionChange: { _, _ in }
                )
                PlayRow(
                    presentation: Self.normalizedPresentation(
                        game: game,
                        sportLabel: "NHL",
                        visualImportance: .high,
                        headline: "North Arc forces a long attempt from the point",
                        body: "Standard density stays readable without a separate hockey layout.",
                        context: ["P2 04:17", "NAR", "Shot"],
                        result: ["Power play pressure"],
                        scoreValue: nil
                    ),
                    importance: .high,
                    rawFeedKey: nil,
                    isRawFeedExpanded: false,
                    onRawFeedExpansionChange: { _, _ in }
                )
                PlayRow(
                    presentation: Self.normalizedPresentation(
                        game: game,
                        sportLabel: "NBA",
                        visualImportance: .medium,
                        headline: "Bay Harbor resets after pressure",
                        body: "Basketball run context arrives as card text instead of local inference.",
                        context: ["Q3 06:45", "BAY", "Possession"],
                        result: ["Tempo settles"],
                        scoreValue: nil
                    ),
                    importance: .medium,
                    rawFeedKey: nil,
                    isRawFeedExpanded: false,
                    onRawFeedExpansionChange: { _, _ in }
                )
                PlayRow(
                    presentation: Self.normalizedPresentation(
                        game: game,
                        sportLabel: "NBA",
                        visualImportance: .low,
                        headline: "Line change settles the possession",
                        body: "All-play density remains quiet and compact.",
                        context: ["Q2 02:10"],
                        result: [],
                        scoreValue: nil
                    ),
                    importance: .low,
                    rawFeedKey: nil,
                    isRawFeedExpanded: false,
                    onRawFeedExpansionChange: { _, _ in }
                )
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "play-row-importance-states",
            width: .standard,
            height: 660
        )
    }

    func testPlayRowGeneratedHeadlineAndCompactWidth() {
        assertSwiftUISnapshot(
            of: PlayRow(
                presentation: ComponentSnapshotFixtures.eventPresentation(
                    clockText: "P2 00:38",
                    headline: "Generated headline prefers a readable scoring-chance summary instead of raw provider enum text",
                    detail: "The detail remains secondary and wraps without crowding the event label or score progression.",
                    eventLabel: "Chance",
                    teamAbbreviation: "BAY"
                ),
                importance: .medium,
                rawFeedKey: nil,
                isRawFeedExpanded: false,
                onRawFeedExpansionChange: { _, _ in }
            )
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "play-row-long-headline-compact",
            width: .compact,
            height: 190
        )
    }

    func testPlayRowSituationCollapsedRawFeed() {
        assertSwiftUISnapshot(
            of: PlayRow(
                presentation: Self.baseballSituationPresentation(),
                importance: .critical,
                rawFeedKey: "baseball-threat",
                isRawFeedExpanded: false,
                onRawFeedExpansionChange: { _, _ in }
            )
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "play-row-situation-collapsed-raw-feed",
            width: .standard,
            height: 380
        )
    }

    func testPlayRowSituationExpandedRawFeed() {
        assertSwiftUISnapshot(
            of: PlayRow(
                presentation: Self.baseballSituationPresentation(),
                importance: .critical,
                rawFeedKey: "baseball-threat",
                isRawFeedExpanded: true,
                onRawFeedExpansionChange: { _, _ in }
            )
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "play-row-situation-expanded-raw-feed",
            width: .standard,
            height: 500
        )
    }

    func testPlayRowSituationCompactWidth() {
        assertSwiftUISnapshot(
            of: PlayRow(
                presentation: Self.baseballSituationPresentation(
                    headline: "Jeff McNeil walks after a long plate appearance to load the bases",
                    detail: "The pressure keeps building with the go-ahead run now on second.",
                    situation: Self.baseballSituation(diagram: nil)
                ),
                importance: .high,
                rawFeedKey: nil,
                isRawFeedExpanded: false,
                onRawFeedExpansionChange: { _, _ in }
            )
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "play-row-situation-compact-width",
            width: .compact,
            height: 340
        )
    }

    func testPlayRowSituationNoCountVariant() {
        assertSwiftUISnapshot(
            of: PlayRow(
                presentation: Self.baseballSituationPresentation(
                    headline: "Cal Raleigh moves the tying run into scoring position",
                    detail: "The card keeps the bases and outs readable without inventing a pitch count.",
                    situation: Self.baseballSituation(
                        setupText: "Runners on corners · 2 outs",
                        contextLine: "Down 1 -> Tied",
                        pressureLine: "Rally threat",
                        diagram: .baseballDiamond(
                            BaseballSituationDiagram(
                                occupiedBases: [.first, .third],
                                batting: Self.baseballOwnership(),
                                outs: 2,
                                count: "4-2"
                            )
                        )
                    )
                ),
                importance: .high,
                rawFeedKey: nil,
                isRawFeedExpanded: false,
                onRawFeedExpansionChange: { _, _ in }
            )
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "play-row-situation-no-count",
            width: .standard,
            height: 360
        )
    }

    func testPlayRowSituationNoScoreDeltaVariant() {
        assertSwiftUISnapshot(
            of: PlayRow(
                presentation: Self.baseballSituationPresentation(
                    headline: "J.P. Crawford works the count with the bases loaded",
                    detail: nil,
                    situation: Self.baseballSituation(
                        setupText: "Bases loaded · 0 outs · 3-2 count",
                        contextLine: nil,
                        pressureLine: "Big chance",
                        diagram: .baseballDiamond(
                            BaseballSituationDiagram(
                                occupiedBases: [.first, .second, .third],
                                batting: Self.baseballOwnership(),
                                outs: 0,
                                count: "3-2"
                            )
                        )
                    )
                ),
                importance: .critical,
                rawFeedKey: nil,
                isRawFeedExpanded: false,
                onRawFeedExpansionChange: { _, _ in }
            )
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "play-row-situation-no-score-delta",
            width: .standard,
            height: 340
        )
    }

    func testScoreboardContentLayouts() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 14) {
                ScoreboardContent(presentation: ComponentSnapshotFixtures.segmentScoreboard(periodCount: 4))
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.segmentScoreboard(periodCount: 8))
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.simpleTotalScoreboard())
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.soccerScoreboard())
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.leaderboardScoreboard())
            }
            .padding(12)
            .background(SportsTheme.Colors.paperRaised, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card))
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "scoreboard-layouts",
            width: .standard,
            height: 760
        )
    }

    func testScoreboardContentWideWidthKeepsRowsDense() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 14) {
                ScoreboardContent(presentation: ComponentSnapshotFixtures.segmentScoreboard(periodCount: 4))
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.segmentScoreboard(periodCount: 8))
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.simpleTotalScoreboard())
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.leaderboardScoreboard())
            }
            .padding(12)
            .background(SportsTheme.Colors.paperRaised, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card))
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "scoreboard-layouts-wide",
            width: .tabletReadable,
            height: 560,
            device: .iPad11Portrait
        )
    }

    func testScoreboardAndEventHierarchyTogether() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                PlayRow(
                    presentation: ComponentSnapshotFixtures.scoringPlayPresentation(),
                    importance: .critical,
                    rawFeedKey: nil,
                    isRawFeedExpanded: false,
                    onRawFeedExpansionChange: { _, _ in }
                )
                ScoreboardContent(presentation: ComponentSnapshotFixtures.segmentScoreboard(periodCount: 4))
                    .padding(12)
                    .background(SportsTheme.Colors.paperRaised, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card))
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "event-scoreboard-hierarchy",
            width: .standard,
            height: 310
        )
    }

    func testBoxScoreHiddenAndRevealedStates() {
        let hiddenGame = ComponentSnapshotFixtures.game(
            id: 5_110,
            status: "in_progress",
            isFinal: false,
            awayScore: 7,
            homeScore: 6,
            periodLabel: "T8"
        )
        let renderer = SportRendererRegistry.renderer(for: hiddenGame)

        assertSwiftUISnapshot(
            of: VStack(spacing: 14) {
                BoxScoreSection(game: hiddenGame, renderer: renderer, scoreInitiallyRevealed: false)
                BoxScoreSection(game: hiddenGame, renderer: renderer, scoreInitiallyRevealed: true)
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "box-score-hidden-revealed",
            width: .standard,
            height: 540
        )
    }

    func testReadableDetailPlayStreamOnIPadLandscape() {
        let detail = VisualRegressionFixtures.detail()

        assertSwiftUISnapshot(
            of: PlayByPlaySection(
                game: detail.game,
                events: detail.events,
                renderer: SportRendererRegistry.renderer(for: detail.game),
                selectedMode: .full,
                expandedRawFeedKeys: [],
                onRawFeedExpansionChange: { _, _ in }
            )
            .sportsReadableContent(maxWidth: \.detailContentMaxWidth, horizontalInset: \.detailHorizontalInset)
            .padding(.vertical, 14)
            .background(SportsTheme.Colors.paper),
            named: "readable-detail-play-stream",
            width: .iPad11LandscapeFull,
            height: 720,
            device: .iPad11Landscape
        )
    }

    func testPlayRowPolicySuppressesPressureBoardMetricDuplicates() {
        let presentation = Self.baseballSituationPresentation()
        let suppressedText = PlayRowContentFilter.situationMetricSuppressionText(for: presentation)

        XCTAssertTrue(suppressedText.contains("Julio Rodriguez singles to center. Two runs score."))
        XCTAssertTrue(suppressedText.contains("B8 1 out"))
        XCTAssertTrue(suppressedText.contains("Lead change"))
        XCTAssertTrue(suppressedText.contains("Tied -> Up 1"))
    }

    private static func baseballSituationPresentation(
        headline: String = "Julio Rodriguez singles to center. Two runs score.",
        detail: String? = "Seattle turns a bases-loaded chance into the first lead of the inning.",
        situation: GameEventSituationPresentation = baseballSituation()
    ) -> GameEventPresentation {
        GameEventPresentation(
            clockText: "B8 1 out",
            headline: headline,
            detail: detail,
            eventLabel: "Single",
            teamAbbreviation: "SEA",
            teamLabel: "Seattle Mariners",
            scoringLabel: "Scoring play",
            scoreLabel: "SEA 5, OAK 4",
            rawFeedText: "single to center, runners on second and third score",
            rawFeedSource: "component-feed",
            accessibilityLabel: "Seattle scoring single. Seattle leads 5 to 4.",
            situation: situation,
            situationAccessibilityText: situation.accessibilitySummary
        )
    }

    private static func normalizedPresentation(
        game: Game,
        sportLabel: String,
        visualImportance: NormalizedPlayCardImportance = .critical,
        headline: String,
        body: String?,
        context: [String],
        result: [String],
        scoreValue: String?,
        rawFeedText: String? = nil
    ) -> GameEventPresentation {
        let contextItems = context.enumerated().map { index, text in
            NormalizedPlayCardContextItem(
                id: "\(sportLabel)-context-\(index)",
                kind: index == 0 ? .clock : index == 1 ? .teamBadge : .eventLabel,
                text: text,
                tone: index == 2 ? .context : .neutral,
                participantRole: index == 1 ? .home : nil,
                teamAbbreviation: index == 1 ? text : nil
            )
        }
        let resultItems = result.enumerated().map { index, text in
            NormalizedPlayCardResultItem(
                id: "\(sportLabel)-result-\(index)",
                text: text,
                tone: index == 0 ? .critical : .secondary,
                priority: index
            )
        }
        let card = NormalizedPlayCard(
            schemaVersion: 1,
            cardID: nil,
            visualImportance: visualImportance,
            accent: nil,
            clock: nil,
            headline: NormalizedPlayCardText(text: headline, tone: nil, maxLines: nil),
            body: body.map { NormalizedPlayCardText(text: $0, tone: .secondary, maxLines: nil) },
            contextItems: contextItems,
            resultItems: resultItems,
            score: scoreValue.map {
                NormalizedPlayCardScore(label: "Scoring", value: $0, isScoringPlay: true, spoilerPolicy: .hideUntilReveal)
            },
            team: nil,
            situation: nil,
            rawFeed: rawFeedText.map {
                NormalizedPlayCardRawFeed(text: $0, source: "component-feed", updatedAt: nil, disclosureTitle: nil)
            },
            accessibility: NormalizedPlayCardAccessibility(label: headline, value: sportLabel, hint: nil, situationSummary: nil)
        )
        return GameEventPresentation(card: card, game: game, scoreSpoilerPolicy: .revealed)
    }

    private static func baseballSituation(
        setupText: String = "Runners on 2nd and 3rd · 1 out · 2-1 count",
        contextLine: String? = "Tied -> Up 1",
        pressureLine: String? = "Lead change",
        diagram: GameEventSituationDiagram? = .baseballDiamond(
            BaseballSituationDiagram(
                occupiedBases: [.second, .third],
                batting: baseballOwnership(),
                outs: 1,
                count: "2-1"
            )
        )
    ) -> GameEventSituationPresentation {
        GameEventSituationPresentation(
            title: "Situation",
            periodText: "B8 1 out",
            setupText: setupText,
            contextLine: contextLine,
            pressureLine: pressureLine,
            sport: .baseball,
            layout: .baseball,
            ownership: baseballOwnership(),
            diagram: diagram,
            accent: GameEventSituationAccent(
                ownership: .home,
                teamAbbreviation: "SEA",
                teamLabel: "Seattle Mariners",
                tone: .critical
            ),
            dataConfidence: .explicitPreEvent
        )
    }

    private static func baseballOwnership() -> GameEventSituationOwnership {
        GameEventSituationOwnership(
            role: .batting,
            participantRole: .home,
            teamAbbreviation: "SEA",
            teamLabel: "Seattle Mariners",
            confidence: .explicit
        )
    }
}
