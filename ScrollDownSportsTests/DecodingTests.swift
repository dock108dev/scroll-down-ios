import XCTest
@testable import ScrollDownSports

final class DecodingTests: XCTestCase {
    func testDecodesTaggedWebGameListShape() throws {
        let json = """
        {
          "games": [
            {
              "id": 42,
              "leagueCode": "mlb",
              "gameDate": "2026-05-22T23:10:00Z",
              "localGameDate": "2026-05-22",
              "status": "in_progress",
              "homeTeam": "Seattle Mariners",
              "awayTeam": "New York Yankees",
              "homeTeamAbbr": "SEA",
              "awayTeamAbbr": "NYY",
              "score": { "home": 2, "away": 1 },
              "playCount": 98,
              "isLive": true
            }
          ],
          "total": 1
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.sda.decode(SDAGameListResponseDTO.self, from: json)
        let games = SDADomainMapper.games(from: response)

        XCTAssertEqual(response.games.count, 1)
        XCTAssertEqual(games[0].scoreState.home, 2)
        XCTAssertEqual(games[0].scoreState.away, 1)
        XCTAssertTrue(games[0].status.isLive)
        XCTAssertEqual(games[0].sport, .mlb)
        XCTAssertEqual(games[0].participants.map(\.role), [.away, .home])
        XCTAssertEqual(games[0].matchupText, "New York Yankees at Seattle Mariners")
        XCTAssertEqual(games[0].progress.eventCount, 98)
        XCTAssertEqual(games[0].progress.persistence?.storageKey, "game-42-progress")
    }

    func testDecodesGameDetailStatsAndPlays() throws {
        let json = """
        {
          "game": {
            "id": 42,
            "leagueCode": "nba",
            "gameDate": "2026-05-22T23:30:00Z",
            "status": "final",
            "homeTeam": "Boston Celtics",
            "awayTeam": "New York Knicks",
            "score": { "home": 104, "away": 99 }
          },
          "teamStats": [
            { "team": "Boston Celtics", "isHome": true, "stats": { "rebounds": 42 } }
          ],
          "playerStats": [
            { "team": "Boston Celtics", "playerName": "Example Player", "points": 28, "rawStats": { "assists": 6 } }
          ],
          "plays": [
            { "playIndex": 1, "periodLabel": "Q1", "gameClock": "11:42", "description": "Made jumper" }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.sda.decode(SDAGameDetailResponseDTO.self, from: json)
        let detail = SDADomainMapper.detail(from: response)

        XCTAssertEqual(detail.game.scoreState.home, 104)
        XCTAssertEqual(detail.game.scoreState.away, 99)
        XCTAssertEqual(response.playerStats[0].points, 28)
        XCTAssertEqual(detail.events[0].headline, "Made jumper")
        XCTAssertEqual(detail.events[0].clockText, "Q1 11:42")
    }

    func testMapsUnknownSafeSportAndLegacyScores() throws {
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
              "homeScore": 3,
              "awayScore": 4
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

    func testGamePresentationFieldsOverrideLegacyFallbacks() throws {
        let json = """
        {
          "games": [
            {
              "id": 88,
              "leagueCode": "mlb",
              "gameDate": "2026-05-22T23:10:00Z",
              "status": "scheduled",
              "homeTeam": "Seattle Mariners",
              "awayTeam": "New York Yankees",
              "score": { "home": 0, "away": 0 },
              "playCount": 1,
              "isLive": false,
              "presentation": {
                "schemaVersion": 1,
                "headline": "Yankees rally in Seattle",
                "shortHeadline": "Yankees 7, Mariners 6",
                "matchupLabel": "Yankees at Mariners",
                "primaryLabel": "Top 9",
                "secondaryLabel": "One-run game",
                "accessibilityLabel": "Yankees at Mariners. Top ninth. Yankees 7, Mariners 6.",
                "displayState": "live",
                "visualPriority": 92,
                "eventCounts": { "key": 4, "flow": 12, "full": 42 },
                "displayLabels": { "status": "Top 9", "primaryAction": "Catch up", "secondaryContext": "42 plays" },
                "scoreboardPlacement": "bottom"
              },
              "eligibility": {
                "schemaVersion": 1,
                "playByPlay": { "isEligible": false, "reason": "data_pending" },
                "boxScore": { "isEligible": true, "reason": "available" },
                "teamStats": { "isEligible": false, "reason": "stats_unavailable" },
                "playerStats": { "isEligible": false, "reason": "stats_unavailable" }
              },
              "scoreboard": {
                "schemaVersion": 1,
                "layout": "inning_table",
                "statusLabel": "Top 9",
                "scoreline": "Yankees 7, Mariners 6",
                "competitors": [
                  { "side": "away", "teamName": "New York Yankees", "teamAbbreviation": "NYY", "score": 7, "scoreText": "7" },
                  { "side": "home", "teamName": "Seattle Mariners", "teamAbbreviation": "SEA", "score": 6, "scoreText": "6" }
                ],
                "segments": [
                  { "label": "1", "away": "2", "home": "0" },
                  { "label": "2", "away": "0", "home": "1" }
                ],
                "totals": { "away": "7", "home": "6" }
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.sda.decode(SDAGameListResponseDTO.self, from: json)
        let game = try XCTUnwrap(SDADomainMapper.games(from: response).first)

        XCTAssertTrue(game.status.isLive)
        XCTAssertEqual(game.matchupText, "Yankees at Mariners")
        XCTAssertEqual(game.presentation?.headline, "Yankees rally in Seattle")
        XCTAssertEqual(game.presentation?.visualPriority, 92)
        XCTAssertEqual(game.presentation?.eventCount(for: .key), 4)
        XCTAssertEqual(game.presentation?.primaryActionLabel, "Catch up")
        XCTAssertEqual(game.presentation?.scoreboardPlacement, "bottom")
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
        let json = """
        {
          "games": [
            {
              "id": 91,
              "leagueCode": "pga",
              "gameDate": "2026-05-22T23:10:00Z",
              "status": "final",
              "homeTeam": "Field",
              "awayTeam": "Field",
              "scoreboard": {
                "schemaVersion": 1,
                "layout": "leaderboard",
                "statusLabel": "Final",
                "competitors": [
                  { "teamName": "A. Stone", "scoreText": "-12", "isWinner": true },
                  { "teamName": "B. Vale", "scoreText": "-10" }
                ]
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.sda.decode(SDAGameListResponseDTO.self, from: json)
        let game = try XCTUnwrap(SDADomainMapper.games(from: response).first)

        XCTAssertEqual(game.scoreboard?.layout, "leaderboard")
        XCTAssertEqual(game.scoreboard?.competitors.map(\.teamName), ["A. Stone", "B. Vale"])
        XCTAssertEqual(game.scoreboard?.competitors.first?.scoreText, "-12")
    }

    func testEventPresentationImportanceModesAndScoreStatePreferBackend() throws {
        let json = """
        {
          "game": {
            "id": 89,
            "leagueCode": "nhl",
            "gameDate": "2026-05-22T23:30:00Z",
            "status": "in_progress",
            "homeTeam": "North Harbor",
            "awayTeam": "East Vale",
            "homeTeamAbbr": "NH",
            "awayTeamAbbr": "EV",
            "score": { "home": 0, "away": 0 }
          },
          "teamStats": [],
          "playerStats": [],
          "plays": [
            {
              "eventId": "goal-1",
              "playIndex": 9,
              "quarter": 3,
              "gameClock": "02:14",
              "playType": "shot",
              "teamAbbreviation": "EV",
              "description": "Legacy raw shot text",
              "rawFeedText": "Provider raw goal text",
              "rawFeedSource": "NHL feed",
              "rawFeedUpdatedAt": "2026-05-22T23:41:00Z",
              "presentation": {
                "schemaVersion": 1,
                "headline": "Vale ties it late",
                "body": "Mara Vale scores from the slot to make it 3-3.",
                "primaryLabel": "Goal",
                "timeLabel": "3rd 02:14",
                "scoreLabel": "East Vale 3, North Harbor 3"
              },
              "importance": {
                "schemaVersion": 1,
                "level": "critical",
                "rank": 95,
                "bucket": "scoring",
                "reasons": ["score_change", "tying_play"],
                "isKeyMoment": true,
                "isScoringPlay": true,
                "isLeadChange": false,
                "isTyingPlay": true
              },
              "modeEligibility": { "key": true, "flow": false, "full": false },
              "scoreBefore": { "away": 2, "home": 3, "scoreText": "North Harbor 3, East Vale 2" },
              "scoreboard": {
                "scoreAfter": { "away": 3, "home": 3, "scoreText": "East Vale 3, North Harbor 3", "isTied": true },
                "scoreDelta": { "side": "away", "before": 2, "after": 3, "change": 1 }
              },
              "metadata": { "strength": "even" }
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.sda.decode(SDAGameDetailResponseDTO.self, from: json)
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
        XCTAssertTrue(DetailStreamMode.full.visibleEvents(in: [event]).isEmpty)
        XCTAssertEqual(event.sportMetadata["strength"], .string("even"))
    }

    func testLegacyFallbacksRemainForMissingPresentationAndNoScoreCases() throws {
        let gamesJSON = """
        {
          "games": [
            {
              "id": 90,
              "leagueCode": "nba",
              "gameDate": "2026-05-22T23:30:00Z",
              "status": "scheduled",
              "homeTeam": "Boston Celtics",
              "awayTeam": "New York Knicks"
            },
            {
              "id": 91,
              "leagueCode": "nba",
              "gameDate": "2026-05-22T23:30:00Z",
              "status": "in_progress",
              "homeTeam": "Boston Celtics",
              "awayTeam": "New York Knicks",
              "isLive": true
            },
            {
              "id": 92,
              "leagueCode": "nba",
              "gameDate": "2026-05-22T23:30:00Z",
              "status": "final",
              "homeTeam": "Boston Celtics",
              "awayTeam": "New York Knicks",
              "isFinal": true
            }
          ]
        }
        """.data(using: .utf8)!

        let games = SDADomainMapper.games(from: try JSONDecoder.sda.decode(SDAGameListResponseDTO.self, from: gamesJSON))

        XCTAssertTrue(games[0].status.isPregame)
        XCTAssertFalse(games[0].availableFeatures.hasScoreboard)
        XCTAssertTrue(games[1].status.isLive)
        XCTAssertTrue(games[2].status.isFinal)
        XCTAssertEqual(games[0].matchupText, "New York Knicks at Boston Celtics")

        let detailJSON = """
        {
          "game": {
            "id": 93,
            "leagueCode": "nba",
            "gameDate": "2026-05-22T23:30:00Z",
            "status": "final",
            "homeTeam": "Boston Celtics",
            "awayTeam": "New York Knicks",
            "score": { "home": 104, "away": 99 }
          },
          "teamStats": [],
          "playerStats": [],
          "plays": [
            { "playIndex": 1, "description": "Made three", "scoreChanged": true, "homeScore": 3, "awayScore": 0 },
            { "playIndex": 2, "description": "Defensive rebound", "tier": 3, "scoreChanged": false, "homeScore": 3, "awayScore": 0 }
          ]
        }
        """.data(using: .utf8)!

        let events = SDADomainMapper.detail(from: try JSONDecoder.sda.decode(SDAGameDetailResponseDTO.self, from: detailJSON)).events

        XCTAssertEqual(events[0].headline, "Made three")
        XCTAssertEqual(events[0].importance, .primary)
        XCTAssertNotNil(events[0].scoreDelta)
        XCTAssertEqual(events[1].headline, "Defensive rebound")
        XCTAssertEqual(events[1].importance, .contextual)
        XCTAssertNil(events[1].scoreDelta)
    }
}
