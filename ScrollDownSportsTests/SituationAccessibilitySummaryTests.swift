import XCTest
@testable import ScrollDownSports

@MainActor
final class SituationAccessibilitySummaryTests: XCTestCase {
    func testWalkWithRunnerSpeaksSetupAsOneRowSupplement() {
        let situation = baseballSituation(
            occupiedBases: [.first],
            setupText: "Runner on 1st · 1 out · 3-1 count",
            outs: 1,
            count: "3-1"
        )

        XCTAssertEqual(
            situation.accessibilitySummary,
            "Seattle Mariners batting. Runner on first. 1 out. 3-1 count"
        )
    }

    func testStrikeoutThreatSpeaksOccupiedBasesOutsAndCount() {
        let situation = baseballSituation(
            occupiedBases: [.second, .third],
            setupText: "Runners on 2nd and 3rd · 2 outs · 1-2 count",
            outs: 2,
            count: "1-2"
        )

        XCTAssertEqual(
            situation.accessibilitySummary,
            "Seattle Mariners batting. Runners on second and third. 2 outs. 1-2 count"
        )
    }

    func testScoringHitSpeaksSetupBeforeResultPressure() {
        let situation = baseballSituation(
            occupiedBases: [.second],
            setupText: "Runner on 2nd · 1 out",
            outs: 1,
            count: nil,
            contextLine: "Tied -> Up 1",
            pressureLine: "Lead change"
        )

        XCTAssertEqual(
            situation.accessibilitySummary,
            "Seattle Mariners batting. Runner on second. 1 out. Lead change. Tied to up 1"
        )
    }

    func testPressureBoardSpeaksMetricsAndAssociationsWithoutPossessionClaim() {
        let ownership = GameEventSituationOwnership(
            role: .possession,
            participantRole: .home,
            teamAbbreviation: "SEA",
            teamLabel: "Seattle",
            confidence: .eventFallback
        )
        let situation = GameEventSituationPresentation(
            title: "Context",
            periodText: nil,
            setupText: "3rd and 7",
            contextLine: "Down 4",
            pressureLine: "High leverage",
            sport: .football,
            layout: .pressureBoardFallback,
            ownership: ownership,
            diagram: .pressureBoardFallback(
                PressureBoardSituationDiagram(
                    associations: [ownership],
                    metrics: [
                        PressureBoardSituationMetric(label: "Field", value: "Opponent 42", emphasis: .primary),
                        PressureBoardSituationMetric(label: "Win chance", value: "38%", emphasis: .pressure)
                    ]
                )
            ),
            accent: GameEventSituationAccent(
                ownership: .home,
                teamAbbreviation: "SEA",
                teamLabel: "Seattle",
                tone: .neutral
            ),
            dataConfidence: .fallback
        )

        XCTAssertEqual(
            situation.accessibilitySummary,
            "Associated with Seattle. 3rd and 7. High leverage. Down 4. Field: Opponent 42. Win chance: 38 percent"
        )
        XCTAssertFalse(situation.accessibilitySummary?.localizedCaseInsensitiveContains("possession") == true)
    }

    func testDuplicateSituationAccessibilityIsSuppressedFromRowValue() {
        let summary = "Seattle Mariners batting. Runner on second. 1 out"
        let duplicate = rowPresentation(
            detail: "Seattle Mariners batting. Runner on second. 1 out",
            situationAccessibilityText: summary
        )
        let unique = rowPresentation(
            detail: "Line drive to right.",
            situationAccessibilityText: summary
        )

        XCTAssertEqual(PlayRowContentFilter.situationAccessibilityValue(for: duplicate), "")
        XCTAssertEqual(PlayRowContentFilter.situationAccessibilityValue(for: unique), summary)
    }

    func testRenderedSituationDiagramsStayDecorativeToAccessibility() throws {
        let diagramSource = try repoFile("ScrollDownSports/Views/SituationDiagramViews.swift")
        let rowSource = try repoFile("ScrollDownSports/Views/PlayRow.swift")

        XCTAssertTrue(diagramSource.contains("struct SituationSummaryPanel: View"))
        XCTAssertTrue(diagramSource.contains(".accessibilityHidden(true)"))
        XCTAssertTrue(rowSource.contains(".accessibilityElement(children: .combine)"))
        XCTAssertTrue(rowSource.contains(".accessibilityValue(rowAccessibilityValue)"))
        XCTAssertTrue(rowSource.contains("PlayRowContentFilter.situationAccessibilityValue(for: presentation)"))
    }

    private func baseballSituation(
        occupiedBases: Set<BaseballBase>,
        setupText: String,
        outs: Int?,
        count: String?,
        contextLine: String? = nil,
        pressureLine: String? = nil
    ) -> GameEventSituationPresentation {
        let ownership = GameEventSituationOwnership(
            role: .batting,
            participantRole: .home,
            teamAbbreviation: "SEA",
            teamLabel: "Seattle Mariners",
            confidence: .explicit
        )
        return GameEventSituationPresentation(
            title: "Situation",
            periodText: nil,
            setupText: setupText,
            contextLine: contextLine,
            pressureLine: pressureLine,
            sport: .baseball,
            layout: .baseball,
            ownership: ownership,
            diagram: .baseballDiamond(
                BaseballSituationDiagram(
                    occupiedBases: occupiedBases,
                    batting: ownership,
                    outs: outs,
                    count: count
                )
            ),
            accent: GameEventSituationAccent(
                ownership: .home,
                teamAbbreviation: "SEA",
                teamLabel: "Seattle Mariners",
                tone: .neutral
            ),
            dataConfidence: .explicitPreEvent
        )
    }

    private func rowPresentation(
        detail: String?,
        situationAccessibilityText: String
    ) -> GameEventPresentation {
        GameEventPresentation(
            clockText: "B9 1 out",
            headline: "Julio Rodriguez doubles.",
            detail: detail,
            eventLabel: "Double",
            teamAbbreviation: "SEA",
            teamLabel: "Seattle Mariners",
            scoringLabel: nil,
            scoreLabel: nil,
            rawFeedText: nil,
            rawFeedSource: nil,
            accessibilityLabel: nil,
            situation: nil,
            situationAccessibilityText: situationAccessibilityText
        )
    }

    private func repoFile(_ path: String) throws -> String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repoRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = repoRoot.appendingPathComponent(path)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }
}
