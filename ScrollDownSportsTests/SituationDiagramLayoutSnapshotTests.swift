import SwiftUI
@testable import ScrollDownSports

@MainActor
final class SituationDiagramLayoutSnapshotTests: SnapshotTestCase {
    func testSituationRowsCompactWidth() {
        assertSwiftUISnapshot(
            of: Self.situationRows()
                .padding(12)
                .background(SportsTheme.Colors.paper),
            named: "situation-rows-compact-width",
            width: .compact,
            height: 620
        )
    }

    func testSituationRowsStandardAccessibilityType() {
        assertSwiftUISnapshot(
            of: Self.situationRows()
                .padding(12)
                .background(SportsTheme.Colors.paper),
            named: "situation-rows-standard-accessibility",
            width: .standard,
            height: 980,
            dynamicTypeSize: .accessibility3
        )
    }

    func testSituationRowsTabletReadableWidth() {
        assertSwiftUISnapshot(
            of: Self.situationRows()
                .sportsReadableContent(maxWidth: \.detailContentMaxWidth, horizontalInset: \.detailHorizontalInset)
                .padding(.vertical, 14)
                .background(SportsTheme.Colors.paper),
            named: "situation-rows-tablet-readable",
            width: .tabletReadable,
            height: 620,
            device: .iPad11Portrait
        )
    }

    func testSituationRowsIPadLandscapeWidth() {
        assertSwiftUISnapshot(
            of: Self.situationRows()
                .sportsReadableContent(maxWidth: \.detailContentMaxWidth, horizontalInset: \.detailHorizontalInset)
                .padding(.vertical, 14)
                .background(SportsTheme.Colors.paper),
            named: "situation-rows-ipad-landscape",
            width: .iPad11LandscapeFull,
            height: 620,
            device: .iPad11Landscape
        )
    }

    func testRichReservedSportDiagramRowsStandardWidth() {
        assertSwiftUISnapshot(
            of: Self.richReservedSportDiagramRows()
                .padding(12)
                .background(SportsTheme.Colors.paper),
            named: "rich-reserved-sport-diagrams-standard",
            width: .standard,
            height: 760
        )
    }

    func testRichReservedSportDiagramRowsCompactWidth() {
        assertSwiftUISnapshot(
            of: Self.richReservedSportDiagramRows()
                .padding(12)
                .background(SportsTheme.Colors.paper),
            named: "rich-reserved-sport-diagrams-compact",
            width: .compact,
            height: 900
        )
    }

    func testRichReservedSportDiagramRowsAccessibilityWidth() {
        assertSwiftUISnapshot(
            of: Self.richReservedSportDiagramRows()
                .padding(12)
                .background(SportsTheme.Colors.paper),
            named: "rich-reserved-sport-diagrams-accessibility",
            width: .standard,
            height: 1120,
            dynamicTypeSize: .accessibility3
        )
    }

    private static func situationRows() -> some View {
        VStack(spacing: 12) {
            PlayRow(
                presentation: baseballPresentation(),
                importance: .critical,
                rawFeedKey: nil,
                isRawFeedExpanded: false,
                onRawFeedExpansionChange: { _, _ in }
            )
            PlayRow(
                presentation: pressureBoardPresentation(),
                importance: .high,
                rawFeedKey: nil,
                isRawFeedExpanded: false,
                onRawFeedExpansionChange: { _, _ in }
            )
        }
    }

    private static func richReservedSportDiagramRows() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SituationSummaryPanel(situation: footballSituation())
            ForEach(Array(hockeySituations().enumerated()), id: \.offset) { _, situation in
                SituationSummaryPanel(situation: situation)
            }
            SituationSummaryPanel(situation: basketballSituationPanel())
            SituationSummaryPanel(situation: soccerSituationPanel())
        }
    }

    private static func baseballPresentation() -> GameEventPresentation {
        let situation = baseballSituation()
        return GameEventPresentation(
            clockText: "B8 1 out",
            headline: "Julio Rodriguez singles after a long plate appearance and two runners score",
            detail: "Seattle keeps the inning moving while the row remains compact enough to read as a feed.",
            eventLabel: "Run-scoring single",
            teamAbbreviation: "SEATTLE",
            teamLabel: "Seattle Mariners",
            scoringLabel: "Scoring play",
            scoreLabel: "SEA 5, OAK 4",
            rawFeedText: nil,
            rawFeedSource: nil,
            accessibilityLabel: "Seattle scoring single",
            situation: situation,
            situationAccessibilityText: situation.accessibilitySummary
        )
    }

    private static func pressureBoardPresentation() -> GameEventPresentation {
        let situation = pressureBoardSituation()
        return GameEventPresentation(
            clockText: "Q4 01:42",
            headline: "Bay Harbor keeps the drive alive near the goal line",
            detail: "The next snap carries the highest leverage of the possession.",
            eventLabel: "Extended red-zone chance",
            teamAbbreviation: "BAYHARBOR",
            teamLabel: "Bay Harbor Lights",
            scoringLabel: nil,
            scoreLabel: "NAR 24, BAY 21",
            rawFeedText: nil,
            rawFeedSource: nil,
            accessibilityLabel: "Bay Harbor red-zone chance",
            situation: situation,
            situationAccessibilityText: situation.accessibilitySummary
        )
    }

    private static func baseballSituation() -> GameEventSituationPresentation {
        GameEventSituationPresentation(
            title: "Situation",
            periodText: "B8 1 out",
            setupText: "Runners on 2nd and 3rd with a full count after a long at-bat",
            contextLine: "Tied to up 1",
            pressureLine: "Lead-change pressure",
            sport: .baseball,
            layout: .baseball,
            ownership: baseballOwnership(),
            diagram: .baseballDiamond(
                BaseballSituationDiagram(
                    occupiedBases: [.second, .third],
                    batting: baseballOwnership(),
                    outs: 1,
                    count: "3-2"
                )
            ),
            accent: GameEventSituationAccent(
                ownership: .home,
                teamAbbreviation: "SEA",
                teamLabel: "Seattle Mariners",
                tone: .critical
            ),
            dataConfidence: .explicitPreEvent
        )
    }

    private static func pressureBoardSituation() -> GameEventSituationPresentation {
        let ownership = GameEventSituationOwnership(
            role: .possession,
            participantRole: .home,
            teamAbbreviation: "BAYHARBOR",
            teamLabel: "Bay Harbor Lights",
            confidence: .explicit
        )
        return GameEventSituationPresentation(
            title: "Situation",
            periodText: "Q4 01:42",
            setupText: "Red-zone chance with a long field-position label",
            contextLine: "Down 3 with one timeout",
            pressureLine: "Very high leverage",
            sport: .football,
            layout: .pressureBoardFallback,
            ownership: ownership,
            diagram: .pressureBoardFallback(
                PressureBoardSituationDiagram(
                    associations: [ownership],
                    metrics: [
                        PressureBoardSituationMetric(label: "Down", value: "3rd", emphasis: .primary),
                        PressureBoardSituationMetric(label: "To Go", value: "4", emphasis: .secondary),
                        PressureBoardSituationMetric(label: "Field", value: "Opp 18 goal-line edge", emphasis: .pressure),
                        PressureBoardSituationMetric(label: "Clock", value: "1:42 remaining", emphasis: .secondary)
                    ]
                )
            ),
            accent: GameEventSituationAccent(
                ownership: .home,
                teamAbbreviation: "BAY",
                teamLabel: "Bay Harbor Lights",
                tone: .critical
            ),
            dataConfidence: .explicitGenericEventContext
        )
    }

    private static func footballSituation() -> GameEventSituationPresentation {
        let ownership = GameEventSituationOwnership(
            role: .possession,
            participantRole: .home,
            teamAbbreviation: "BAY",
            teamLabel: "Bay Harbor Lights",
            confidence: .explicit
        )
        return GameEventSituationPresentation(
            title: "Field position",
            periodText: "Q4 01:42",
            setupText: "3rd & 4 at OPP 18",
            contextLine: "Red-zone possession",
            pressureLine: "Goal-line pressure",
            sport: .football,
            layout: .football,
            ownership: ownership,
            diagram: .footballFieldStrip(
                FootballFieldStripDiagram(
                    downDistanceText: "3rd & 4",
                    yardLineText: "OPP 18",
                    possessionText: "BAY",
                    lineOfScrimmageX: 82,
                    firstDownX: 86,
                    offenseDirection: .leftToRight,
                    eventTypeText: "Pass",
                    isRedZone: true
                )
            ),
            accent: GameEventSituationAccent(ownership: .home, teamAbbreviation: "BAY", teamLabel: "Bay Harbor Lights", tone: .critical),
            dataConfidence: .explicitPreEvent
        )
    }

    private static func hockeySituations() -> [GameEventSituationPresentation] {
        let variants: [(HockeyRinkZone, HockeyPuckLocation, String)] = [
            (.offensive, .slot, "SEA"),
            (.neutral, .highSlot, "SEA"),
            (.defensive, .leftCircle, "VAN"),
            (.offensive, .rightCircle, "SEA"),
            (.neutral, .point, "SEA"),
            (.defensive, .crease, "VAN"),
            (.offensive, .behindNet, "SEA")
        ]
        return variants.enumerated().map { index, variant in
            GameEventSituationPresentation(
                title: "Rink pressure",
                periodText: "P3 02:1\(index)",
                setupText: variant.0.label,
                contextLine: "Sustained possession",
                pressureLine: "High-danger chance",
                sport: .hockey,
                layout: .hockey,
                ownership: nil,
                diagram: .hockeyRinkStrip(
                    HockeyRinkStripDiagram(
                        zone: variant.0,
                        puckLocation: variant.1,
                        attackingTeamAbbreviation: variant.2
                    )
                ),
                accent: GameEventSituationAccent(ownership: .home, teamAbbreviation: variant.2, teamLabel: nil, tone: .critical),
                dataConfidence: .explicitPreEvent
            )
        }
    }

    private static func basketballSituationPanel() -> GameEventSituationPresentation {
        let ownership = GameEventSituationOwnership(
            role: .possession,
            participantRole: .home,
            teamAbbreviation: "SEA",
            teamLabel: "Seattle",
            confidence: .explicit
        )
        return GameEventSituationPresentation(
            title: "Clock pressure",
            periodText: "Q4 00:42",
            setupText: "6 on clock · Right corner",
            contextLine: "Down 2",
            pressureLine: "Late clock",
            sport: .basketball,
            layout: .basketball,
            ownership: ownership,
            diagram: .basketballHalfCourt(
                BasketballHalfCourtDiagram(
                    possessionText: "SEA ball",
                    clockText: "Q4 00:42",
                    shotClockText: "6",
                    scoreText: "Down 2",
                    bonusText: "In bonus",
                    shotText: "3PT made",
                    locationText: "Right corner",
                    freeThrowText: nil,
                    shotLocation: BasketballDiagramShotLocation(x: 0.82, y: 0.32, label: "Right corner"),
                    pressure: 0.74
                )
            ),
            accent: GameEventSituationAccent(ownership: .home, teamAbbreviation: "SEA", teamLabel: "Seattle", tone: .critical),
            dataConfidence: .explicitPreEvent
        )
    }

    private static func soccerSituationPanel() -> GameEventSituationPresentation {
        let ownership = GameEventSituationOwnership(
            role: .attackingSide,
            participantRole: .away,
            teamAbbreviation: "POR",
            teamLabel: "Portland",
            confidence: .explicit
        )
        return GameEventSituationPresentation(
            title: "Set piece",
            periodText: "88'",
            setupText: "Corner · Left channel",
            contextLine: "Late equalizer chance",
            pressureLine: "Box loaded",
            sport: .soccer,
            layout: .soccer,
            ownership: ownership,
            diagram: .soccerPitchStrip(
                SoccerPitchStripDiagram(
                    setPieceText: "Corner",
                    locationText: "Left channel",
                    attackingTeamAbbreviation: "POR",
                    ballX: 0.91,
                    ballY: 0.18,
                    highlightsGoalArea: true
                )
            ),
            accent: GameEventSituationAccent(ownership: .away, teamAbbreviation: "POR", teamLabel: "Portland", tone: .critical),
            dataConfidence: .explicitPreEvent
        )
    }

    private static func baseballOwnership() -> GameEventSituationOwnership {
        GameEventSituationOwnership(
            role: .batting,
            participantRole: .home,
            teamAbbreviation: "SEATTLE",
            teamLabel: "Seattle Mariners",
            confidence: .explicit
        )
    }
}
