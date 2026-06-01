import XCTest
@testable import ScrollDownSports

final class DecodingTests: XCTestCase {
    func testDecodesTaggedWebGameListShape() throws {
        let response = try JSONDecoder.sda.decode(SDAGameListResponseDTO.self, from: try SDAFixtures.gameList("live_mlb_two_games"))
        let games = SDADomainMapper.games(from: response)

        XCTAssertEqual(response.games.count, 2)
        XCTAssertEqual(games[0].scoreState.home, 2)
        XCTAssertEqual(games[0].scoreState.away, 1)
        XCTAssertTrue(games[0].status.isLive)
        XCTAssertEqual(games[0].sport, .mlb)
        XCTAssertEqual(games[0].participants.map(\.role), [.away, .home])
        XCTAssertEqual(games[0].participants.map(\.id), ["147", "136"])
        XCTAssertEqual(games[0].matchupText, "New York Yankees at Seattle Mariners")
        XCTAssertEqual(games[0].progress.eventCount, 12)
        XCTAssertEqual(games[0].progress.persistence?.storageKey, "game-504-progress")
    }

    func testListAndDetailFixturesPreserveCrossFlowIdentity() throws {
        let listResponse = try JSONDecoder.sda.decode(
            SDAGameListResponseDTO.self,
            from: try SDAFixtures.gameList("live_mlb_two_games")
        )
        let liveSummary = try XCTUnwrap(SDADomainMapper.games(from: listResponse).first { $0.id == 504 })
        let scheduledSummary = try XCTUnwrap(SDADomainMapper.games(from: listResponse).first { $0.id == 505 })
        let liveDetailResponse = try JSONDecoder.sda.decode(
            SDAGameDetailResponseDTO.self,
            from: try SDAFixtures.gameDetail("mlb_live_new_events")
        )
        let scheduledDetailResponse = try JSONDecoder.sda.decode(
            SDAGameDetailResponseDTO.self,
            from: try SDAFixtures.gameDetail("scheduled_no_pbp_missing_optional_presentation")
        )
        let liveDetail = SDADomainMapper.detail(from: liveDetailResponse)
        let scheduledDetail = SDADomainMapper.detail(from: scheduledDetailResponse)

        XCTAssertEqual(liveDetailResponse.detailContractVersion, 2)
        XCTAssertEqual(scheduledDetailResponse.detailContractVersion, 2)
        XCTAssertEqual(liveSummary.id, liveDetail.game.id)
        XCTAssertEqual(scheduledSummary.id, scheduledDetail.game.id)
        XCTAssertEqual(liveSummary.participants.map(\.role), liveDetail.game.participants.map(\.role))
        XCTAssertEqual(liveSummary.participants.map(\.name), liveDetail.game.participants.map(\.name))
        XCTAssertEqual(liveSummary.participants.map(\.id), liveDetail.game.participants.map(\.id))
        XCTAssertEqual(liveDetail.events.map(\.sourceEventID), ["sda-504-001", "sda-504-002", "sda-504-003"])
        XCTAssertTrue(liveDetail.game.availableFeatures.hasTimeline)
        XCTAssertFalse(scheduledDetail.game.availableFeatures.hasTimeline)
        XCTAssertNil(scheduledDetail.game.presentation)
        XCTAssertNil(scheduledDetail.game.scoreboard)
        XCTAssertFalse(scheduledDetail.game.scoreState.hasAnyScore)
    }

    func testDecodesGameDetailStatsAndPlays() throws {
        let response = try JSONDecoder.sda.decode(
            SDAGameDetailResponseDTO.self,
            from: try SDAFixtures.gameDetail("stats_with_mlb_box_score")
        )
        let detail = SDADomainMapper.detail(from: response)

        XCTAssertEqual(detail.game.scoreState.home, 6)
        XCTAssertEqual(detail.game.scoreState.away, 5)
        XCTAssertEqual(response.playerStats[0].rawStats["rbi"], .number(2))
        XCTAssertEqual(detail.events[0].headline, "Julio Rodriguez singles to center. Two runs score.")
        XCTAssertEqual(detail.events[0].clockText, "Bot 8")
        XCTAssertEqual(detail.mlbBatters?.first?.hits, 3)
    }

    func testFullPlayByPlayScoringProgressionMapsScoresAndModes() throws {
        let finalResponse = try JSONDecoder.sda.decode(
            SDAGameDetailResponseDTO.self,
            from: try SDAFixtures.gameDetail("mlb_final_full_pbp")
        )
        let progressionResponse = try JSONDecoder.sda.decode(
            SDAGameDetailResponseDTO.self,
            from: try SDAFixtures.gameDetail("mlb_scoring_progression")
        )
        let finalDetail = SDADomainMapper.detail(from: finalResponse)
        let progression = SDADomainMapper.detail(from: progressionResponse)
        let firstScoringPlay = try XCTUnwrap(progression.events.first)
        let finalPlay = try XCTUnwrap(finalDetail.events.last)

        XCTAssertEqual(finalResponse.detailContractVersion, 2)
        XCTAssertEqual(finalDetail.events.count, 3)
        XCTAssertTrue(finalDetail.game.status.isFinal)
        XCTAssertEqual(finalDetail.game.scoreboard?.layout, "inning_table")
        XCTAssertEqual(finalDetail.game.scoreboard?.competitors.map(\.side), [.away, .home])
        XCTAssertEqual(finalDetail.game.scoreboard?.segments.map(\.label), ["1", "5", "9"])
        XCTAssertEqual(firstScoringPlay.importance, .primary)
        XCTAssertEqual(firstScoringPlay.importanceMetadata?.bucket, "scoring_play")
        XCTAssertEqual(firstScoringPlay.scoreBefore?.away, 0)
        XCTAssertEqual(firstScoringPlay.scoreBefore?.home, 0)
        XCTAssertEqual(firstScoringPlay.scoreAfter.away, 2)
        XCTAssertEqual(firstScoringPlay.scoreAfter.home, 0)
        XCTAssertEqual(firstScoringPlay.scoreDelta?.participantRole, .away)
        XCTAssertEqual(firstScoringPlay.scoreDelta?.before, 0)
        XCTAssertEqual(firstScoringPlay.scoreDelta?.after, 2)
        XCTAssertEqual(firstScoringPlay.scoreDelta?.change, 2)
        XCTAssertEqual(DetailStreamMode.key.visibleEvents(in: progression.events).map(\.id), ["sda-520-001", "sda-520-002"])
        XCTAssertEqual(DetailStreamMode.full.visibleEvents(in: progression.events).count, 2)
        XCTAssertEqual(finalPlay.scoreAfter.away, 3)
        XCTAssertEqual(finalPlay.scoreAfter.home, 5)
    }

    func testMapsUnknownSafeSportAndCanonicalScoreObject() throws {
        let json = """
        {
          "games": [
            {
              "id": 77,
              "leagueCode": "pickleball",
              "gameDate": "2026-05-22T23:10:00Z",
              "status": "scheduled",
              "homeTeam": "Home Club",
              "awayTeam": "Away Club",
              "score": { "home": 3, "away": 4 }
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.sda.decode(SDAGameListResponseDTO.self, from: json)
        let game = try XCTUnwrap(SDADomainMapper.games(from: response).first)

        XCTAssertEqual(game.sport, .other("pickleball"))
        XCTAssertEqual(game.scoreState.home, 3)
        XCTAssertEqual(game.scoreState.away, 4)
        XCTAssertEqual(game.status.phase, .pregame)
    }

    func testGamePresentationFieldsDriveMappedPresentation() throws {
        let response = try JSONDecoder.sda.decode(
            SDAGameListResponseDTO.self,
            from: try SDAFixtures.gameList("presentation_scoreboard_game")
        )
        let game = try XCTUnwrap(SDADomainMapper.games(from: response).first)

        XCTAssertTrue(game.status.isLive)
        XCTAssertEqual(game.matchupText, "Yankees at Mariners")
        XCTAssertEqual(game.presentation?.headline, "Yankees rally in Seattle")
        XCTAssertEqual(game.presentation?.visualPriority, 92)
        XCTAssertEqual(game.presentation?.eventCount(for: .key), 4)
        XCTAssertEqual(game.presentation?.primaryActionLabel, "Catch up")
        XCTAssertEqual(game.presentation?.scoreboardPlacement, "bottom")
        XCTAssertEqual(game.presentation?.accessibilityLabel, "Yankees at Mariners. Top ninth. Yankees 7, Mariners 6.")
        XCTAssertEqual(game.progress.eventCount, 42)
        XCTAssertFalse(game.availableFeatures.hasTimeline)
        XCTAssertFalse(game.availableFeatures.hasStats)
        XCTAssertTrue(game.availableFeatures.hasScoreboard)
        XCTAssertEqual(game.scoreState.away, 7)
        XCTAssertEqual(game.scoreState.home, 6)
        XCTAssertEqual(game.scoreboard?.scoreline, "Yankees 7, Mariners 6")
        XCTAssertEqual(game.scoreboard?.segments.map(\.label), ["1", "2"])
        XCTAssertEqual(game.scoreboard?.totals?.away, "7")
    }

    func testScoreboardPreservesLeaderboardCompetitorsWithoutTeamSides() throws {
        let response = try JSONDecoder.sda.decode(
            SDAGameListResponseDTO.self,
            from: try SDAFixtures.gameList("leaderboard_scoreboard_game")
        )
        let game = try XCTUnwrap(SDADomainMapper.games(from: response).first)

        XCTAssertEqual(game.scoreboard?.layout, "leaderboard")
        XCTAssertEqual(game.scoreboard?.competitors.map(\.teamName), ["A. Stone", "B. Vale"])
        XCTAssertEqual(game.scoreboard?.competitors.first?.scoreText, "-12")
    }

    func testEventPresentationImportanceModesAndScoreStatePreferBackend() throws {
        let response = try JSONDecoder.sda.decode(
            SDAGameDetailResponseDTO.self,
            from: try SDAFixtures.gameDetail("nhl_event_presentation_importance")
        )
        let event = try XCTUnwrap(SDADomainMapper.detail(from: response).events.first)

        XCTAssertEqual(event.headline, "Vale ties it late")
        XCTAssertEqual(event.detail, "Mara Vale scores from the slot to make it 3-3.")
        XCTAssertEqual(event.rawText, "Provider raw goal text")
        XCTAssertEqual(event.rawFeedSource, "NHL feed")
        XCTAssertEqual(event.rawFeedUpdatedAt, "2026-05-22T23:41:00Z")
        XCTAssertEqual(event.clockText, "3rd 02:14")
        XCTAssertEqual(event.importance, .primary)
        XCTAssertEqual(event.importanceMetadata?.bucket, "scoring")
        XCTAssertEqual(event.scoreBefore?.away, 2)
        XCTAssertEqual(event.scoreAfter.away, 3)
        XCTAssertEqual(event.scoreDelta?.participantRole, .away)
        XCTAssertEqual(event.scoreDelta?.change, 1)
        XCTAssertTrue(event.usesBackendModeEligibility)
        XCTAssertEqual(DetailStreamMode.key.visibleEvents(in: [event]).map(\.id), ["goal-1"])
        XCTAssertEqual(DetailStreamMode.full.visibleEvents(in: [event]).map(\.id), ["goal-1"])
        XCTAssertEqual(event.presentation?.scoreLabel, "East Vale 3, North Harbor 3")
        XCTAssertEqual(event.sportMetadata["strength"], .string("even"))
    }

    func testFetchGameUsesNormalizedFeedWhenAvailable() async throws {
        let client = TestFixtures.makeAPIClient(
            responses: [.ok(TestFixtures.sdaCardFeedJSON(cardIDs: ["event-1", "event-2"]))],
            protocolClass: MockNormalizedFeedSuccessURLProtocol.self
        )

        let detail = try await client.fetchGame(id: 504)
        let requests = MockHTTPURLProtocol.requestURLs(for: MockNormalizedFeedSuccessURLProtocol.self)

        XCTAssertEqual(requests.map(\.path), ["/api/v1/feed/games/504/cards"])
        XCTAssertFalse(requests.map(\.path).contains("/api/v1/games/504"))
        XCTAssertEqual(requests.first?.query, "spoilerPolicy=pre_reveal")
        XCTAssertEqual(MockHTTPURLProtocol.requestTimeouts(for: MockNormalizedFeedSuccessURLProtocol.self), [60])
        XCTAssertEqual(detail.feedMetadata.source, .normalizedFeed)
        XCTAssertEqual(detail.feedMetadata.generationStatus, .ready)
        XCTAssertEqual(detail.feedMetadata.fallbackState, .none)
        XCTAssertEqual(detail.events.map(\.normalizedSourceEventID), ["event-1", "event-2"])
        XCTAssertEqual(detail.game.participants.map(\.id), ["147", "136"])
        XCTAssertNotNil(detail.events.first?.normalizedCard)
    }

    func testGameListKeepsDefaultTimeout() async throws {
        let client = TestFixtures.makeAPIClient(
            responses: [.ok(try SDAFixturePayloadFactory.gameList(ids: [504]))],
            protocolClass: MockGameListTimeoutURLProtocol.self
        )

        _ = try await client.fetchGamePage(
            window: .centeredOnToday(now: TestFixtures.fixedDate("2026-05-22T12:00:00Z")),
            limit: 1
        )

        XCTAssertEqual(MockHTTPURLProtocol.requestURLs(for: MockGameListTimeoutURLProtocol.self).map(\.path), ["/api/v1/games"])
        XCTAssertEqual(MockHTTPURLProtocol.requestTimeouts(for: MockGameListTimeoutURLProtocol.self), [12])
    }

    func testMLBImportantCardMapsStageSettingAsSingleContextLine() async throws {
        let leadIn = "Bottom 2 · SEA"
        let stageSetting = "Bottom 2, runners on 1st, 2 outs"
        let client = TestFixtures.makeAPIClient(
            responses: [
                .ok(TestFixtures.sdaCardFeedJSON(
                    gameId: 190584,
                    cardIDs: ["mlb-important-1"],
                    cardOverrides: [[
                        "leadIn": leadIn,
                        "stageSetting": stageSetting,
                        "headline": "Ketel Marte lifts a sacrifice fly.",
                        "description": "Gabriel Moreno scores from third.",
                        "renderType": "important_narrative",
                        "teamContext": "SEA batting",
                        "setupLine": "SEA down 2-0, runners on 1st, 2 outs.",
                        "playLine": "Ketel Marte lifts a sacrifice fly. Gabriel Moreno scores.",
                        "updateLine": "SEA scores 1 run. SEA down 2-1.",
                        "scoreBefore": ["away": 2, "home": 0, "scoreText": "NYY 2-0", "isTied": false, "leaderSide": "away"],
                        "scoreChange": ["home": 1, "away": 0],
                        "scoreAfter": ["away": 2, "home": 1, "scoreText": "NYY 2-1", "isTied": false, "leaderSide": "away"],
                        "tags": ["Sac fly"],
                        "visualImportance": "high",
                        "contentDepth": "extended"
                    ]]
                ))
            ],
            protocolClass: MockMLBStageSettingURLProtocol.self
        )

        let event = try await client.fetchGame(id: 190584).events[0]

        XCTAssertEqual(event.presentation?.primaryLabel, "Bottom 2 · SEA · SEA batting")
        XCTAssertEqual(event.presentation?.secondaryLabel, "Bottom 2, SEA down 2-0, runners on 1st, 2 outs")
        XCTAssertEqual(event.eventType, "Sac fly")
        XCTAssertEqual(event.contentDepth, .extended)
        XCTAssertEqual(event.normalizedCard?.renderType, .importantNarrative)
        XCTAssertEqual(event.normalizedCard?.narrative?.setupLine, "SEA down 2-0, runners on 1st, 2 outs.")
        XCTAssertEqual(event.normalizedCard?.narrative?.playLine, "Ketel Marte lifts a sacrifice fly. Gabriel Moreno scores.")
        XCTAssertEqual(event.normalizedCard?.narrative?.updateLine, "SEA scores 1 run. SEA down 2-1.")
        XCTAssertEqual(event.normalizedCard?.leadIn?.text, "Bottom 2 · SEA · SEA batting")
        XCTAssertEqual(event.normalizedCard?.headline.text, "Ketel Marte lifts a sacrifice fly.")
        XCTAssertEqual(event.normalizedCard?.contextItems.first?.text, "Bottom 2, SEA down 2-0, runners on 1st, 2 outs")
        XCTAssertEqual(event.normalizedCard?.resultItems.last?.text, "SEA cuts it to 2-1")
        XCTAssertNil(event.normalizedCard?.situation)
    }

    func testNHLLateGoalCardMapsBackendImportanceFields() async throws {
        let client = TestFixtures.makeAPIClient(
            responses: [
                .ok(TestFixtures.sdaCardFeedJSON(
                    gameId: 190552,
                    cardIDs: ["nhl-goal-1"],
                    cardOverrides: [[
                        "sport": "hockey",
                        "league": "NHL",
                        "period": ["ordinal": 3, "label": "P3", "type": "period"],
                        "displayTime": "P3 03:41",
                        "team": ["abbreviation": "CAR", "name": "Carolina Hurricanes", "side": "home"],
                        "leadIn": "P3 03:41 · CAR",
                        "stageSetting": "Carolina presses at even strength with the game tied late.",
                        "headline": "Carolina scores from the slot.",
                        "description": "The late goal swings the finish.",
                        "tags": ["Goal"],
                        "visualImportance": "critical",
                        "contentDepth": "extended",
                        "impact": "Go-ahead goal."
                    ]]
                ))
            ],
            protocolClass: MockNHLCardFeedURLProtocol.self
        )

        let event = try await client.fetchGame(id: 190552).events[0]

        XCTAssertEqual(event.periodLabel, "P3")
        XCTAssertEqual(event.clockLabel, "P3 03:41")
        XCTAssertEqual(event.teamAbbreviation, "CAR")
        XCTAssertEqual(event.eventType, "Goal")
        XCTAssertEqual(event.contentDepth, .extended)
        XCTAssertEqual(event.cardVisualImportance, .critical)
        XCTAssertEqual(event.normalizedCard?.resultItems.first?.text, "Go-ahead goal.")
    }

    func testNormalizedCardContentDepthDoesNotOverwriteEventType() async throws {
        let client = TestFixtures.makeAPIClient(
            responses: [
                .ok(TestFixtures.sdaCardFeedJSON(
                    cardIDs: ["routine-shot"],
                    cardOverrides: [[
                        "contentDepth": "brief",
                        "tags": ["Shot"],
                        "visualImportance": "low"
                    ]]
                ))
            ],
            protocolClass: MockContentDepthURLProtocol.self
        )

        let event = try await client.fetchGame(id: 504).events[0]

        XCTAssertEqual(event.contentDepth, .brief)
        XCTAssertEqual(event.eventType, "Shot")
    }

    func testAllModeExcludesBackendIneligibleCards() async throws {
        let client = TestFixtures.makeAPIClient(
            responses: [
                .ok(TestFixtures.sdaCardFeedJSON(
                    cardIDs: ["hidden-from-all", "visible-in-all"],
                    cardOverrides: [
                        ["modeEligibility": ["important": true, "standard": true, "all": false]],
                        ["modeEligibility": ["important": false, "standard": true, "all": true]]
                    ]
                ))
            ],
            protocolClass: MockAllEligibilityURLProtocol.self
        )

        let detail = try await client.fetchGame(id: 504)

        XCTAssertEqual(DetailStreamMode.full.visibleEvents(in: detail.events).map(\.id), ["visible-in-all"])
    }

    func testDuplicateLeadInStageSettingDoesNotCreateTwoVisibleSurfaces() async throws {
        let duplicate = "6th · SEA"
        let client = TestFixtures.makeAPIClient(
            responses: [
                .ok(TestFixtures.sdaCardFeedJSON(
                    cardIDs: ["duplicate-stage"],
                    cardOverrides: [[
                        "leadIn": duplicate,
                        "stageSetting": duplicate,
                        "situation": ["summary": duplicate, "raw": ["inning": 6]]
                    ]]
                ))
            ],
            protocolClass: MockDuplicateStageURLProtocol.self
        )

        let card = try await client.fetchGame(id: 504).events[0].normalizedCard

        XCTAssertEqual(card?.leadIn?.text, duplicate)
        XCTAssertFalse(card?.contextItems.contains { $0.text == duplicate } ?? true)
        XCTAssertNil(card?.situation)
    }

    func testNormalizedValidationBlockedReturnsSafeEmptyWithoutLegacyRequest() async throws {
        let client = TestFixtures.makeAPIClient(
            responses: [
                .ok(TestFixtures.sdaCardFeedJSON(status: "validation_blocked", cardIDs: []))
            ],
            protocolClass: MockNormalizedFallbackURLProtocol.self
        )

        let detail = try await client.fetchGame(id: 504)
        let requests = MockHTTPURLProtocol.requestURLs(for: MockNormalizedFallbackURLProtocol.self)

        XCTAssertEqual(requests.map(\.path), ["/api/v1/feed/games/504/cards"])
        XCTAssertEqual(detail.feedMetadata.source, .normalizedFeed)
        XCTAssertEqual(detail.feedMetadata.generationStatus, .validationBlocked)
        XCTAssertEqual(detail.feedMetadata.fallbackState, .safeEmpty)
        XCTAssertEqual(detail.events, [])
    }

    func testMalformedNormalizedFeedFailsWithoutLegacyRequest() async throws {
        let malformedFeed = #"{"contractVersion":1,"game":{"gameId":504},"cards":[]}"#.data(using: .utf8)!
        let client = TestFixtures.makeAPIClient(
            responses: [
                .ok(malformedFeed)
            ],
            protocolClass: MockMalformedNormalizedFeedURLProtocol.self
        )

        do {
            _ = try await client.fetchGame(id: 504)
            XCTFail("Expected malformed normalized feed to fail")
        } catch SDAApiError.incompleteNormalizedFeed {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        let requests = MockHTTPURLProtocol.requestURLs(for: MockMalformedNormalizedFeedURLProtocol.self)

        XCTAssertEqual(requests.map(\.path), ["/api/v1/feed/games/504/cards"])
    }

    func testOldNormalizedFeedContractFailsWithoutLegacyRequest() async throws {
        let oldContractFeed = try mutatedCardFeedJSON { payload in
            payload["contractVersion"] = 1
        }
        let client = TestFixtures.makeAPIClient(
            responses: [.ok(oldContractFeed)],
            protocolClass: MockOldNormalizedFeedContractURLProtocol.self
        )

        do {
            _ = try await client.fetchGame(id: 504)
            XCTFail("Expected old normalized feed contract to fail")
        } catch SDAApiError.incompleteNormalizedFeed {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(
            MockHTTPURLProtocol.requestURLs(for: MockOldNormalizedFeedContractURLProtocol.self).map(\.path),
            ["/api/v1/feed/games/504/cards"]
        )
    }

    func testNormalizedFeedMissingRenderTypeFailsWithoutLegacyRequest() async throws {
        let missingRenderTypeFeed = try mutatedCardFeedJSON { payload in
            var cards = payload["cards"] as? [[String: Any]] ?? []
            cards[0].removeValue(forKey: "renderType")
            payload["cards"] = cards
        }
        let client = TestFixtures.makeAPIClient(
            responses: [.ok(missingRenderTypeFeed)],
            protocolClass: MockMissingRenderTypeFeedURLProtocol.self
        )

        do {
            _ = try await client.fetchGame(id: 504)
            XCTFail("Expected missing card renderType to fail")
        } catch SDAApiError.incompleteNormalizedFeed {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(
            MockHTTPURLProtocol.requestURLs(for: MockMissingRenderTypeFeedURLProtocol.self).map(\.path),
            ["/api/v1/feed/games/504/cards"]
        )
    }

    func testImportantEligibleStandardPBPCardFailsWithoutLegacyRequest() async throws {
        let importantAsStandardFeed = try mutatedCardFeedJSON { payload in
            var cards = payload["cards"] as? [[String: Any]] ?? []
            cards[0]["renderType"] = "standard_pbp"
            cards[0].removeValue(forKey: "setupLine")
            cards[0].removeValue(forKey: "playLine")
            cards[0].removeValue(forKey: "updateLine")
            payload["cards"] = cards
        }
        let client = TestFixtures.makeAPIClient(
            responses: [.ok(importantAsStandardFeed)],
            protocolClass: MockImportantStandardPBPFeedURLProtocol.self
        )

        do {
            _ = try await client.fetchGame(id: 504)
            XCTFail("Expected important standard-PBP card to fail")
        } catch SDAApiError.incompleteNormalizedFeed {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(
            MockHTTPURLProtocol.requestURLs(for: MockImportantStandardPBPFeedURLProtocol.self).map(\.path),
            ["/api/v1/feed/games/504/cards"]
        )
    }

    func testCamelCaseRenderTypesPassNormalizedFeedContract() async throws {
        let camelCaseRenderTypesFeed = try mutatedCardFeedJSON { payload in
            var cards = payload["cards"] as? [[String: Any]] ?? []
            cards[0]["renderType"] = "importantNarrative"
            cards[1]["renderType"] = "standardPBP"
            payload["cards"] = cards
        }
        let client = TestFixtures.makeAPIClient(
            responses: [.ok(camelCaseRenderTypesFeed)],
            protocolClass: MockCamelCaseRenderTypeFeedURLProtocol.self
        )

        let detail = try await client.fetchGame(id: 504)

        XCTAssertEqual(detail.events.first?.normalizedCard?.renderType, .importantNarrative)
        XCTAssertEqual(detail.events.dropFirst().first?.normalizedCard?.renderType, .standardPBP)
        XCTAssertEqual(
            MockHTTPURLProtocol.requestURLs(for: MockCamelCaseRenderTypeFeedURLProtocol.self).map(\.path),
            ["/api/v1/feed/games/504/cards"]
        )
    }

    func testSportMetadataOnlySurvivesEventMapping() throws {
        let metadata = try mappedSportMetadata(
            sportMetadata: [
                "baseState": "runner_on_first",
                "count": ["balls": 2, "strikes": 1],
                "runners": ["first", "second"]
            ],
            playIndex: 12
        )

        XCTAssertEqual(metadata["baseState"], .string("runner_on_first"))
        XCTAssertEqual(metadata["count"], .object(["balls": .number(2), "strikes": .number(1)]))
        XCTAssertEqual(metadata["runners"], .array([.string("first"), .string("second")]))
        XCTAssertEqual(metadata["playIndex"], .number(12))
        XCTAssertEqual(metadata.count, 4)
    }

    func testMetadataOnlySurvivesEventMapping() throws {
        let metadata = try mappedSportMetadata(
            metadata: [
                "providerEventType": "single",
                "confidence": 0.97
            ],
            playIndex: 13
        )

        XCTAssertEqual(metadata["providerEventType"], .string("single"))
        XCTAssertEqual(metadata["confidence"], .number(0.97))
        XCTAssertEqual(metadata["playIndex"], .number(13))
        XCTAssertEqual(metadata.count, 3)
    }

    func testEmptyMetadataDoesNotReplaceSportMetadata() throws {
        let metadata = try mappedSportMetadata(
            sportMetadata: [
                "outs": 1,
                "baseState": "runners_on_corners"
            ],
            metadata: [:],
            playIndex: 14
        )

        XCTAssertEqual(metadata["outs"], .number(1))
        XCTAssertEqual(metadata["baseState"], .string("runners_on_corners"))
        XCTAssertEqual(metadata["playIndex"], .number(14))
        XCTAssertEqual(metadata.count, 3)
    }

    func testNonOverlappingMetadataSourcesMergePerKey() throws {
        let metadata = try mappedSportMetadata(
            sportMetadata: [
                "inning": 8,
                "baseState": "runner_on_second"
            ],
            metadata: [
                "providerEventType": "double",
                "review": ["source": "official"]
            ],
            playIndex: 15
        )

        XCTAssertEqual(metadata["inning"], .number(8))
        XCTAssertEqual(metadata["baseState"], .string("runner_on_second"))
        XCTAssertEqual(metadata["providerEventType"], .string("double"))
        XCTAssertEqual(metadata["review"], .object(["source": .string("official")]))
        XCTAssertEqual(metadata["playIndex"], .number(15))
        XCTAssertEqual(metadata.count, 5)
    }

    func testMetadataOverridesSportMetadataOnMatchingKeys() throws {
        let metadata = try mappedSportMetadata(
            sportMetadata: [
                "strength": "even",
                "playIndex": 999,
                "shot": ["type": "wrist"]
            ],
            metadata: [
                "strength": "power_play",
                "playIndex": NSNull(),
                "providerEventType": "goal"
            ],
            playIndex: 16
        )

        XCTAssertEqual(metadata["strength"], .string("power_play"))
        XCTAssertEqual(metadata["shot"], .object(["type": .string("wrist")]))
        XCTAssertEqual(metadata["providerEventType"], .string("goal"))
        XCTAssertEqual(metadata["playIndex"], .number(16))
        XCTAssertEqual(metadata.count, 4)
    }

    func testPartialPayloadsDegradeWithoutFabricatingScoresOrStats() throws {
        let response = try JSONDecoder.sda.decode(
            SDAGameDetailResponseDTO.self,
            from: try SDAFixtures.gameDetail("partial_degraded_payload")
        )
        let detail = SDADomainMapper.detail(from: response)
        let scoreboard = try XCTUnwrap(detail.game.scoreboard)

        XCTAssertEqual(detail.game.participants.map(\.role), [.away, .home])
        XCTAssertEqual(detail.game.awayParticipant?.name, "New York Yankees")
        XCTAssertEqual(detail.game.homeParticipant?.name, "")
        XCTAssertEqual(detail.game.matchupText, "New York Yankees at ")
        XCTAssertEqual(detail.game.scoreState.away, 2)
        XCTAssertNil(detail.game.scoreState.home)
        XCTAssertEqual(scoreboard.competitors.count, 1)
        XCTAssertEqual(scoreboard.competitors.first?.teamName, "New York Yankees")
        XCTAssertEqual(scoreboard.segments.map(\.label), ["1"])
        XCTAssertEqual(scoreboard.totals?.away, "2")
        XCTAssertNil(scoreboard.totals?.home)
        XCTAssertEqual(detail.teamStats.map(\.team), ["New York Yankees"])
        XCTAssertEqual(detail.playerStats.map(\.playerName), ["Cal Rios"])
        XCTAssertEqual(detail.events.first?.scoreAfter.away, 2)
        XCTAssertNil(detail.events.first?.scoreAfter.home)
    }

    func testRemovedStatusFlagsAreIgnored() throws {
        let json = """
        {
          "games": [
            {
              "id": 91,
              "leagueCode": "nba",
              "gameDate": "2026-05-22T23:30:00Z",
              "status": "scheduled",
              "homeTeam": "Boston Celtics",
              "awayTeam": "New York Knicks",
              "isLive": true,
              "isFinal": true
            }
          ]
        }
        """.data(using: .utf8)!

        let games = SDADomainMapper.games(from: try JSONDecoder.sda.decode(SDAGameListResponseDTO.self, from: json))

        XCTAssertEqual(games.first?.status.phase, .pregame)
        XCTAssertFalse(games.first?.status.isLive ?? true)
        XCTAssertFalse(games.first?.status.isFinal ?? true)
    }

    func testDetailRequiresV2Contract() async throws {
        _ = try JSONDecoder.sda.decode(
            SDAGameDetailResponseDTO.self,
            from: try SDAFixtures.malformed("wrong_detail_contract_version")
        )
        try await assertMalformedFixtureFailsAsIncompleteDetail(
            "wrong_detail_contract_version",
            protocolClass: MockWrongContractURLProtocol.self
        )
    }

    func testMalformedDetailFixturesFailAsControlledIncompleteData() async throws {
        try await assertMalformedFixtureFailsAsIncompleteDetail(
            "missing_all_usable_event_text",
            protocolClass: MockMissingTextURLProtocol.self
        )
        try await assertMalformedFixtureFailsAsIncompleteDetail(
            "missing_period_label",
            protocolClass: MockMissingPeriodURLProtocol.self
        )
        try await assertMalformedFixtureFailsAsIncompleteDetail(
            "missing_mode_eligibility",
            protocolClass: MockMissingEligibilityURLProtocol.self
        )
    }

    private func assertMalformedFixtureFailsAsIncompleteDetail(
        _ fixtureName: String,
        protocolClass: MockHTTPURLProtocol.Type,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let client = TestFixtures.makeAPIClient(
            responses: [.ok(try SDAFixtures.malformed(fixtureName))],
            protocolClass: protocolClass
        )

        do {
            _ = try await client.fetchGame(id: 900)
            XCTFail("Expected incomplete detail error", file: file, line: line)
        } catch SDAApiError.incompleteNormalizedFeed {
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }

    private func mutatedCardFeedJSON(
        _ mutate: (inout [String: Any]) -> Void
    ) throws -> Data {
        var payload = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: TestFixtures.sdaCardFeedJSON(cardIDs: ["event-1", "event-2"])
            ) as? [String: Any]
        )
        mutate(&payload)
        return try JSONSerialization.data(withJSONObject: payload)
    }

    private func mappedSportMetadata(
        sportMetadata: [String: Any]? = nil,
        metadata: [String: Any]? = nil,
        playIndex: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [String: JSONValue] {
        var play: [String: Any] = [
            "eventId": "metadata-\(playIndex)",
            "playIndex": playIndex,
            "displayType": "Play",
            "periodLabel": "Q1",
            "description": "Mapped event",
            "score": ["home": 0, "away": 0],
            "importance": [
                "schemaVersion": 1,
                "level": "contextual",
                "rank": 10,
                "bucket": "context",
                "reasons": [],
                "isKeyMoment": false,
                "isScoringPlay": false,
                "isLeadChange": false,
                "isTyingPlay": false,
                "isLateGame": false,
                "isFinalPlay": false,
                "isRunEnding": false
            ],
            "modeEligibility": ["important": false, "standard": true, "all": true]
        ]
        if let sportMetadata {
            play["sportMetadata"] = sportMetadata
        }
        if let metadata {
            play["metadata"] = metadata
        }

        let payload: [String: Any] = [
            "detailContractVersion": 2,
            "game": [
                "id": 99,
                "leagueCode": "mlb",
                "gameDate": "2026-05-22T23:30:00Z",
                "status": "in_progress",
                "homeTeam": "Home Club",
                "awayTeam": "Away Club",
                "homeTeamAbbr": "HOM",
                "awayTeamAbbr": "AWY",
                "score": ["home": 0, "away": 0]
            ],
            "teamStats": [],
            "playerStats": [],
            "plays": [play]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let response = try JSONDecoder.sda.decode(SDAGameDetailResponseDTO.self, from: data)
        let event = try XCTUnwrap(SDADomainMapper.detail(from: response).events.first, file: file, line: line)
        return event.sportMetadata
    }

}

private final class MockWrongContractURLProtocol: MockHTTPURLProtocol {}
private final class MockMissingTextURLProtocol: MockHTTPURLProtocol {}
private final class MockMissingPeriodURLProtocol: MockHTTPURLProtocol {}
private final class MockMissingEligibilityURLProtocol: MockHTTPURLProtocol {}
private final class MockNormalizedFeedSuccessURLProtocol: MockHTTPURLProtocol {}
private final class MockGameListTimeoutURLProtocol: MockHTTPURLProtocol {}
private final class MockMLBStageSettingURLProtocol: MockHTTPURLProtocol {}
private final class MockNHLCardFeedURLProtocol: MockHTTPURLProtocol {}
private final class MockContentDepthURLProtocol: MockHTTPURLProtocol {}
private final class MockAllEligibilityURLProtocol: MockHTTPURLProtocol {}
private final class MockDuplicateStageURLProtocol: MockHTTPURLProtocol {}
private final class MockNormalizedFallbackURLProtocol: MockHTTPURLProtocol {}
private final class MockMalformedNormalizedFeedURLProtocol: MockHTTPURLProtocol {}
private final class MockOldNormalizedFeedContractURLProtocol: MockHTTPURLProtocol {}
private final class MockMissingRenderTypeFeedURLProtocol: MockHTTPURLProtocol {}
private final class MockImportantStandardPBPFeedURLProtocol: MockHTTPURLProtocol {}
private final class MockCamelCaseRenderTypeFeedURLProtocol: MockHTTPURLProtocol {}
