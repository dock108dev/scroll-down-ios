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

    func testNormalizedCardDecodingPreservesBackendAuthoredSlots() throws {
        let json = """
        {
          "detailContractVersion": 2,
          "game": {
            "id": 7,
            "leagueCode": "nba",
            "gameDate": "2026-05-22T23:30:00Z",
            "status": "in_progress",
            "homeTeam": "Bay Harbor",
            "awayTeam": "North Arc",
            "homeTeamAbbr": "BAY",
            "awayTeamAbbr": "NAR",
            "score": { "home": 100, "away": 99 }
          },
          "teamStats": [],
          "playerStats": [],
          "plays": [{
            "eventId": "play-card-1",
            "playIndex": 24,
            "displayType": "three_point_field_goal",
            "periodLabel": "Q4",
            "clockLabel": "00:38",
            "description": "legacy raw description",
            "score": { "home": 100, "away": 99 },
            "importance": {
              "schemaVersion": 1,
              "level": "tertiary",
              "rank": 5,
              "bucket": "routine",
              "reasons": [],
              "isKeyMoment": false,
              "isScoringPlay": false,
              "isLeadChange": false,
              "isTyingPlay": false,
              "isLateGame": false
            },
            "modeEligibility": { "important": false, "standard": true, "all": true },
            "sportMetadata": { "runLabel": "client should not use this" },
            "card": {
              "schemaVersion": 1,
              "visualImportance": "critical",
              "clock": { "text": "Q4 00:38" },
              "leadIn": { "text": "Fourth quarter begins after 12 earlier plays.", "tone": "secondary" },
              "headline": { "text": "Backend headline controls the card" },
              "body": { "text": "Backend body controls the card." },
              "contextItems": [
                { "id": "clock", "kind": "clock", "text": "Q4 00:38" },
                { "id": "team", "kind": "teamBadge", "text": "BAY", "teamAbbreviation": "BAY" }
              ],
              "resultItems": [{ "id": "impact", "text": "Backend impact", "tone": "critical", "priority": 10 }],
              "score": { "label": "Scoring", "value": "BAY 100, NAR 99", "isScoringPlay": true, "spoilerPolicy": "hide_until_reveal" },
              "rawFeed": { "text": "provider payload", "source": "SDA", "disclosureTitle": "Original feed" },
              "accessibility": { "label": "Backend card accessibility", "value": "Backend card value" }
            }
          }]
        }
        """.data(using: .utf8)!

        let detail = SDADomainMapper.detail(from: try JSONDecoder.sda.decode(SDAGameDetailResponseDTO.self, from: json))
        let event = try XCTUnwrap(detail.events.first)
        let card = try XCTUnwrap(event.normalizedCard)

        XCTAssertEqual(card.headline.text, "Backend headline controls the card")
        XCTAssertEqual(card.leadIn?.text, "Fourth quarter begins after 12 earlier plays.")
        XCTAssertEqual(card.visualImportance, .critical)
        XCTAssertEqual(event.cardVisualImportance, .critical)
        XCTAssertEqual(card.contextItems.map(\.text), ["Q4 00:38", "BAY"])
        XCTAssertEqual(card.resultItems.map(\.text), ["Backend impact"])
        XCTAssertEqual(event.displayRawFeedText, "provider payload")
        XCTAssertEqual(event.headline, "legacy raw description")
        XCTAssertEqual(event.sportMetadata["runLabel"], .string("client should not use this"))
    }

    func testNormalizedCardScoreTextHidesUntilReveal() {
        let game = TestFixtures.makeGame(
            id: 9,
            leagueCode: "nba",
            status: "in_progress",
            awayName: "North Arc",
            awayAbbreviation: "NAR",
            homeName: "Bay Harbor",
            homeAbbreviation: "BAY",
            awayScore: 99,
            homeScore: 100
        )
        let card = NormalizedPlayCard(
            schemaVersion: 1,
            cardID: nil,
            visualImportance: .high,
            accent: nil,
            clock: nil,
            headline: NormalizedPlayCardText(text: "Bay Harbor answers", tone: nil, maxLines: nil),
            body: NormalizedPlayCardText(text: "The run continues.", tone: nil, maxLines: nil),
            contextItems: [],
            resultItems: [],
            score: NormalizedPlayCardScore(label: "Scoring", value: "BAY 100, NAR 99", isScoringPlay: true, spoilerPolicy: .hideUntilReveal),
            team: nil,
            situation: nil,
            rawFeed: nil,
            accessibility: NormalizedPlayCardAccessibility(label: "Bay Harbor answers", value: nil, hint: nil, situationSummary: nil)
        )

        XCTAssertNil(GameEventPresentation(card: card, game: game, scoreSpoilerPolicy: .hideAbsoluteScores).scoreLabel)
        XCTAssertEqual(GameEventPresentation(card: card, game: game, scoreSpoilerPolicy: .revealed).scoreLabel, "BAY 100, NAR 99")
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
