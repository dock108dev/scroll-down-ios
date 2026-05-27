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
