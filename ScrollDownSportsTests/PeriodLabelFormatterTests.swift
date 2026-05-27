import XCTest
@testable import ScrollDownSports

final class PeriodLabelFormatterTests: XCTestCase {
    func testFormatterSeparatesBaseballHalfInningsAndStableKeys() {
        let topFirst = PeriodLabelFormatter.output(
            sport: .mlb,
            leagueCode: "MLB",
            periodOrdinal: 1,
            periodLabel: "T1",
            clockLabel: "T1"
        )
        let bottomSixth = PeriodLabelFormatter.output(
            sport: .mlb,
            leagueCode: "MLB",
            periodOrdinal: 6,
            periodLabel: "B6",
            clockLabel: "B6 1 out"
        )

        XCTAssertEqual(topFirst.groupLabel, "Top 1st")
        XCTAssertEqual(topFirst.rowClockText, "")
        XCTAssertEqual(topFirst.combinedText, "Top 1st")
        XCTAssertEqual(topFirst.situationText, "Top 1st")
        XCTAssertEqual(topFirst.resumeText, "Top 1st")
        XCTAssertEqual(topFirst.groupKey, "mlb:inning:1:top")
        XCTAssertEqual(bottomSixth.groupLabel, "Bottom 6th")
        XCTAssertEqual(bottomSixth.rowClockText, "1 out")
        XCTAssertEqual(bottomSixth.combinedText, "Bottom 6th · 1 out")
        XCTAssertEqual(bottomSixth.situationText, "Bottom 6th 1 out")
        XCTAssertEqual(bottomSixth.groupKey, "mlb:inning:6:bottom")
    }

    func testFormatterNormalizesQuarterClockPeriodAndSoccerMinuteText() {
        let nflSecond = PeriodLabelFormatter.output(
            sport: .nfl,
            leagueCode: "NFL",
            periodOrdinal: 2,
            periodLabel: "2nd Quarter",
            clockLabel: "Q2 08:14"
        )
        let nbaThird = PeriodLabelFormatter.output(
            sport: .nba,
            leagueCode: "NBA",
            periodOrdinal: 3,
            periodLabel: "Q3",
            clockLabel: "Q3 10:00"
        )
        let nhlThird = PeriodLabelFormatter.output(
            sport: .nhl,
            leagueCode: "NHL",
            periodOrdinal: 3,
            periodLabel: "3rd Period",
            clockLabel: "3rd 02:14"
        )
        let soccerStoppage = PeriodLabelFormatter.output(
            sport: .soccer,
            leagueCode: "EPL",
            periodOrdinal: 1,
            periodLabel: "1st Half",
            clockLabel: "45+2"
        )

        XCTAssertEqual(nflSecond.groupLabel, "Q2")
        XCTAssertEqual(nflSecond.rowClockText, "08:14")
        XCTAssertEqual(nflSecond.combinedText, "Q2 · 08:14")
        XCTAssertEqual(nflSecond.situationText, "Q2 08:14")
        XCTAssertEqual(nbaThird.groupLabel, "Q3")
        XCTAssertEqual(nbaThird.rowClockText, "10:00")
        XCTAssertEqual(nbaThird.combinedText, "Q3 · 10:00")
        XCTAssertEqual(nbaThird.situationText, "Q3 10:00")
        XCTAssertEqual(nhlThird.groupLabel, "3rd")
        XCTAssertEqual(nhlThird.rowClockText, "02:14")
        XCTAssertEqual(nhlThird.combinedText, "3rd · 02:14")
        XCTAssertEqual(nhlThird.situationText, "3rd 02:14")
        XCTAssertEqual(soccerStoppage.groupLabel, "1st Half")
        XCTAssertEqual(soccerStoppage.rowClockText, "45'+2'")
        XCTAssertEqual(soccerStoppage.combinedText, "1st Half · 45'+2'")
        XCTAssertEqual(soccerStoppage.situationText, "45'+2'")
    }

    func testFormatterCollapsesDuplicatePeriodLabels() {
        let hockeyDuplicate = PeriodLabelFormatter.output(
            sport: .nhl,
            leagueCode: "NHL",
            periodOrdinal: 1,
            periodLabel: "1st",
            clockLabel: "1st 1st"
        )
        let baseballDuplicate = PeriodLabelFormatter.output(
            sport: .mlb,
            leagueCode: "MLB",
            periodOrdinal: 6,
            periodLabel: "6th",
            clockLabel: "6th 6th"
        )
        let quarterDuplicate = PeriodLabelFormatter.output(
            sport: .nba,
            leagueCode: "NBA",
            periodOrdinal: 2,
            periodLabel: "Q2",
            clockLabel: "Q2 Q2"
        )

        XCTAssertEqual(hockeyDuplicate.combinedText, "1st")
        XCTAssertEqual(baseballDuplicate.combinedText, "6th")
        XCTAssertEqual(quarterDuplicate.combinedText, "Q2")
    }

    func testRendererUsesSemanticBaseballGroups() {
        let renderer = SportRendererRegistry.renderer(for: "mlb")
        let top = TestFixtures.makeEvent(
            sequence: 1,
            periodOrdinal: 1,
            periodLabel: "T1",
            clockLabel: "T1"
        )
        let bottom = TestFixtures.makeEvent(
            sequence: 2,
            periodOrdinal: 1,
            periodLabel: "B1",
            clockLabel: "B1"
        )

        let groups = renderer.periodGroups(for: [bottom, top])

        XCTAssertEqual(groups.map(\.id), ["mlb:inning:1:top", "mlb:inning:1:bottom"])
        XCTAssertEqual(groups.map(\.label), ["Top 1st", "Bottom 1st"])
    }
}
