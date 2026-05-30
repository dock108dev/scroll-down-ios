import XCTest
@testable import ScrollDownSports

final class SituationContextChipTests: XCTestCase {
    func testBaseballChipsUseStructuredDiamondState() {
        let ownership = ownership(role: .batting, team: "SEA")
        let situation = presentation(
            periodText: "B8 1 out",
            setupText: "Runners on 2nd and 3rd with a full count after a long at-bat",
            contextLine: "Tied -> Up 1",
            pressureLine: "Lead change",
            sport: .baseball,
            layout: .baseball,
            ownership: ownership,
            diagram: .baseballDiamond(
                BaseballSituationDiagram(
                    occupiedBases: [.second, .third],
                    batting: ownership,
                    outs: 1,
                    count: "3-2"
                )
            )
        )

        XCTAssertEqual(
            chipTexts(for: situation),
            ["B8", "Batting SEA", "Runners on 2nd and 3rd", "1 out", "3-2 count"]
        )
    }

    func testFootballChipsPreferFieldStripState() {
        let situation = presentation(
            periodText: "Q4 01:42",
            setupText: "3rd & 4 at OPP 18",
            contextLine: "Down 3",
            pressureLine: "Goal-line pressure",
            sport: .football,
            layout: .football,
            ownership: ownership(role: .offense, team: "BAY"),
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
            )
        )

        XCTAssertEqual(
            chipTexts(for: situation),
            ["Q4 01:42", "Offense BAY", "3rd & 4", "OPP 18", "Red zone", "Goal-line pressure", "Down 3"]
        )
    }

    func testNonFieldSportsSplitCompactSetupContext() {
        let basketball = presentation(
            periodText: "Q4 00:42",
            setupText: "Inbound · 6 on clock · Right corner",
            contextLine: "Down 2",
            pressureLine: "Late clock",
            sport: .basketball,
            layout: .basketball,
            ownership: ownership(role: .possession, team: "SEA")
        )
        let golf = presentation(
            periodText: nil,
            setupText: "Round 4 · Hole 17",
            contextLine: "Rank T2 · To par -11",
            pressureLine: "For lead",
            sport: .golf,
            layout: .pressureBoardFallback,
            ownership: nil
        )
        let tennis = presentation(
            periodText: nil,
            setupText: "Set 2 · 4-4",
            contextLine: "Server pressure",
            pressureLine: "Break chance",
            sport: .tennis,
            layout: .pressureBoardFallback,
            ownership: ownership(role: .association, team: "Mira")
        )
        let generic = presentation(
            periodText: "P3 02:11",
            setupText: "Key stretch",
            contextLine: "Tied",
            pressureLine: "High leverage",
            sport: .generic,
            layout: .pressureBoardFallback,
            ownership: nil
        )

        XCTAssertEqual(
            chipTexts(for: basketball),
            ["Q4 00:42", "Possession SEA", "Inbound", "6 on clock", "Right corner", "Down 2"]
        )
        XCTAssertEqual(chipTexts(for: golf), ["Round 4", "Hole 17", "For lead", "Rank T2 · To par -11"])
        XCTAssertEqual(chipTexts(for: tennis), ["Team Mira", "Set 2", "4-4", "Break chance", "Server pressure"])
        XCTAssertEqual(chipTexts(for: generic), ["P3 02:11", "Key stretch", "High leverage", "Tied"])
    }

    private func chipTexts(for situation: GameEventSituationPresentation) -> [String] {
        SituationContextChipBuilder.chips(for: situation).map(\.text)
    }

    private func ownership(
        role: GameEventSituationOwnershipRole,
        team: String
    ) -> GameEventSituationOwnership {
        GameEventSituationOwnership(
            role: role,
            participantRole: .home,
            teamAbbreviation: team,
            teamLabel: team,
            confidence: .explicit
        )
    }

    private func presentation(
        periodText: String?,
        setupText: String?,
        contextLine: String?,
        pressureLine: String?,
        sport: GameEventSituationSport,
        layout: GameEventSituationLayout,
        ownership: GameEventSituationOwnership?,
        diagram: GameEventSituationDiagram? = nil
    ) -> GameEventSituationPresentation {
        GameEventSituationPresentation(
            title: "Situation",
            periodText: periodText,
            setupText: setupText,
            contextLine: contextLine,
            pressureLine: pressureLine,
            sport: sport,
            layout: layout,
            ownership: ownership,
            diagram: diagram,
            accent: GameEventSituationAccent(
                ownership: .home,
                teamAbbreviation: ownership?.teamAbbreviation,
                teamLabel: ownership?.teamLabel,
                tone: .neutral
            ),
            dataConfidence: .explicitPreEvent
        )
    }
}
