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

    private func baseballSituation() -> GameEventSituationPresentation {
        GameEventSituationPresentation(
            title: "Situation",
            periodText: "B8 1 out",
            setupText: "Runners on 2nd and 3rd · 1 out · 2-1 count",
            contextLine: "Tied -> Up 1",
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
