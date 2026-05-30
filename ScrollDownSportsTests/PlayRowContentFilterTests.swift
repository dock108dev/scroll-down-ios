import XCTest
@testable import ScrollDownSports

final class PlayRowContentFilterTests: XCTestCase {
    func testSituationDetailSuppressesPlayerOnlyHeadlineSubject() {
        let presentation = baseballPresentation(
            headline: "Jeff McNeil walks after a long plate appearance.",
            detail: "Jeff McNeil"
        )

        XCTAssertNil(PlayRowContentFilter.visibleDetailText(for: presentation))
    }

    func testSituationDetailSuppressesDuplicatesFromSituationAndRawCopy() {
        let setupDuplicate = baseballPresentation(
            detail: "Runners on 2nd and 3rd, 1 out, 2-1 count"
        )
        let rawDuplicate = baseballPresentation(
            detail: "single to center, runners on second and third score"
        )

        XCTAssertNil(PlayRowContentFilter.visibleDetailText(for: setupDuplicate))
        XCTAssertNil(PlayRowContentFilter.visibleDetailText(for: rawDuplicate))
    }

    func testSituationDetailPreservesMeaningfulConsequence() {
        let presentation = baseballPresentation(
            detail: "Leaves two aboard after the inning-ending strikeout."
        )

        XCTAssertEqual(
            PlayRowContentFilter.visibleDetailText(for: presentation),
            "Leaves two aboard after the inning-ending strikeout."
        )
    }

    func testEventLabelSuppressesSemanticHeadlineDuplicateForBaseball() {
        let presentation = baseballPresentation(
            headline: "Gunnar Henderson homers. Three runs score.",
            detail: nil
        )
        var duplicate = presentation
        duplicate.eventLabel = "Three-run home run"

        XCTAssertNil(PlayRowContentFilter.visibleEventLabel(for: duplicate))
    }

    func testEventLabelKeepsNonBaseballContextThatAddsMeaning() {
        let presentation = GameEventPresentation(
            clockText: "P2 04:17",
            headline: "Mara Ellis scores on a wrist shot.",
            detail: nil,
            eventLabel: "Power play",
            teamAbbreviation: "SEA",
            teamLabel: "Seattle",
            scoringLabel: "Scoring play",
            scoreLabel: "SEA 2, POR 2",
            rawFeedText: nil,
            rawFeedSource: nil,
            accessibilityLabel: nil,
            situation: nil,
            situationAccessibilityText: nil
        )

        XCTAssertEqual(PlayRowContentFilter.visibleEventLabel(for: presentation), "Power play")
    }

    func testDetailSuppressesDuplicatesAcrossVisibleRowFieldsWithoutSituation() {
        let presentation = GameEventPresentation(
            clockText: "P3 02:11",
            headline: "Ira Frost saves the shot from the slot.",
            detail: "Save",
            eventLabel: "Save",
            teamAbbreviation: "EV",
            teamLabel: nil,
            scoringLabel: nil,
            scoreLabel: nil,
            rawFeedText: nil,
            rawFeedSource: nil,
            accessibilityLabel: nil,
            situation: nil,
            situationAccessibilityText: nil
        )

        XCTAssertNil(PlayRowContentFilter.visibleDetailText(for: presentation))
    }

    func testResultContextSuppressesDuplicatePressureAlreadyInMovementLine() {
        let resultContext = PlayRowContentFilter.visibleResultContext(
            for: baseballSituation(contextLine: "Down 2 -> Up 1 · Lead change")
        )

        XCTAssertNil(resultContext.pressureLine)
        XCTAssertEqual(resultContext.contextLine, "Down 2 -> Up 1 · Lead change")
    }

    func testContextTeamBadgeIsSuppressedWhenSituationAlreadyNamesTeam() {
        XCTAssertFalse(
            PlayRowContentFilter.shouldShowContextTeamBadge("SEA", situation: baseballSituation())
        )
    }

    func testContextTeamBadgeRemainsVisibleWhenItAddsDifferentTeamContext() {
        XCTAssertTrue(
            PlayRowContentFilter.shouldShowContextTeamBadge(
                "OAK",
                situation: baseballSituation()
            )
        )
    }

    func testResultContextWaitsUntilAfterPlayText() {
        XCTAssertNil(PlayRowContentFilter.prePlaySituationText("Down 3 -> Tied"))
        XCTAssertEqual(PlayRowContentFilter.resultContextText("Down 3 -> Tied"), "Down 3 -> Tied")
        XCTAssertNil(PlayRowContentFilter.prePlaySituationText("Lead change"))
        XCTAssertEqual(PlayRowContentFilter.resultContextText("Lead change"), "Lead change")
    }

    func testPrePlaySportContextCanRenderBeforePlayText() {
        XCTAssertEqual(PlayRowContentFilter.prePlaySituationText("Third down"), "Third down")
        XCTAssertEqual(PlayRowContentFilter.prePlaySituationText("Power play"), "Power play")
        XCTAssertEqual(PlayRowContentFilter.prePlaySituationText("Down 2"), "Down 2")
        XCTAssertNil(PlayRowContentFilter.resultContextText("Third down"))
    }

    func testLeaderboardMovementWaitsUntilAfterPlayText() {
        let movementContext = "Rank T2 · To par -11 · 1 back · Up 2"

        XCTAssertNil(PlayRowContentFilter.prePlaySituationText(movementContext))
        XCTAssertEqual(PlayRowContentFilter.resultContextText(movementContext), movementContext)
    }

    private func baseballPresentation(
        headline: String = "Julio Rodriguez singles to center. Two runs score.",
        detail: String? = "Seattle turns a bases-loaded chance into the first lead of the inning."
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
            accessibilityLabel: nil,
            situation: baseballSituation(),
            situationAccessibilityText: nil
        )
    }

    private func baseballSituation(contextLine: String? = "Tied -> Up 1") -> GameEventSituationPresentation {
        GameEventSituationPresentation(
            title: "Situation",
            periodText: "B8 1 out",
            setupText: "Runners on 2nd and 3rd · 1 out · 2-1 count",
            contextLine: contextLine,
            pressureLine: "Lead change",
            sport: .baseball,
            layout: .baseball,
            ownership: GameEventSituationOwnership(
                role: .batting,
                participantRole: .home,
                teamAbbreviation: "SEA",
                teamLabel: "Seattle Mariners",
                confidence: .explicit
            ),
            diagram: nil,
            accent: GameEventSituationAccent(
                ownership: .home,
                teamAbbreviation: "SEA",
                teamLabel: "Seattle Mariners",
                tone: .critical
            ),
            dataConfidence: .explicitPreEvent
        )
    }
}
