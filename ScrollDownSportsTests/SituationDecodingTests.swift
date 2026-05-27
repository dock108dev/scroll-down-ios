import XCTest
@testable import ScrollDownSports

final class SituationDecodingTests: XCTestCase {
    func testDecodesBaseballSituationInputsForRenderer() throws {
        let event = try mappedEvent(
            responseOverrides: [
                "detailContractVersion": 3,
                "situationContract": situationContract
            ],
            playOverrides: [
                "presentation": [
                    "schemaVersion": 1,
                    "headline": "Mara Stone singles home the go-ahead run.",
                    "body": "Grounder through the left side",
                    "eventTypeLabel": "Single",
                    "scoreLabel": "BAY 4, RIV 3"
                ],
                "scoreBefore": ["away": 3, "home": 3, "scoreText": "3-3", "isTied": true],
                "scoreAfter": ["away": 3, "home": 4, "scoreText": "BAY 4-3", "isTied": false, "leaderSide": "home"],
                "scoreDelta": [
                    "side": "home",
                    "participantRole": "home",
                    "participantID": "home",
                    "before": 3,
                    "after": 4,
                    "change": 1,
                    "scoreText": "BAY +1"
                ],
                "situationBefore": [
                    "schemaVersion": 1,
                    "sport": "mlb",
                    "display": [
                        "headline": "Runners on 2nd and 3rd",
                        "subheadline": "Bottom 8",
                        "tokens": ["B8", "1 out", "2-1 count"],
                        "accessibilityLabel": "Before the play, runners on second and third with one out."
                    ],
                    "score": ["away": 3, "home": 3],
                    "period": ["ordinal": 8, "label": "B8", "phase": "bottom"],
                    "clock": ["label": "1 out", "secondsRemaining": 0],
                    "sportState": [
                        "baseball": [
                            "inning": 8,
                            "half": "bottom",
                            "outs": 1,
                            "balls": 2,
                            "strikes": 1,
                            "bases": ["first": false, "second": true, "third": true],
                            "battingTeamAbbreviation": "BAY"
                        ]
                    ],
                    "pressure": ["level": "critical", "rank": 94, "winProbability": 0.63],
                    "confidence": ["level": "verified", "source": "stats_feed", "reasons": []]
                ],
                "sportMetadata": [
                    "prePitch": [
                        "baseState": "runners_on_second_and_third",
                        "outs": 1,
                        "count": ["balls": 2, "strikes": 1]
                    ],
                    "battingTeamAbbreviation": "BAY"
                ],
                "metadata": ["providerEventType": "single"]
            ],
            playIndex: 31
        )
        let situation = try XCTUnwrap(event.situationBefore)
        let state = BaseballRenderer().baseballPrePitchState(for: event)

        XCTAssertEqual(situation.normalizedSport, "mlb")
        XCTAssertEqual(situation.display?.tokens, ["B8", "1 out", "2-1 count"])
        XCTAssertEqual(situation.score?.away, 3)
        XCTAssertEqual(situation.score?.home, 3)
        XCTAssertEqual(event.scoreBefore?.home, 3)
        XCTAssertEqual(event.scoreAfter.home, 4)
        XCTAssertEqual(event.scoreDelta?.participantRole, .home)
        XCTAssertEqual(event.scoreDelta?.before, 3)
        XCTAssertEqual(event.scoreDelta?.after, 4)
        XCTAssertEqual(event.scoreDelta?.change, 1)
        XCTAssertEqual(event.presentation?.eventTypeLabel, "Single")
        XCTAssertEqual(event.presentation?.scoreLabel, "BAY 4, RIV 3")
        XCTAssertEqual(event.sportMetadata["providerEventType"], .string("single"))
        XCTAssertEqual(state.baseState?.occupiedBases, [.second, .third])
        XCTAssertEqual(state.outs, 1)
        XCTAssertEqual(state.count?.label, "2-1")
    }

    func testSportMetadataPreservesTypesAndMergesPerKey() throws {
        let event = try mappedEvent(
            playOverrides: [
                "sportMetadata": [
                    "baseStateBefore": "runner_on_first",
                    "outsBefore": 1,
                    "isHighLeverage": true,
                    "occupiedBases": ["1B", 2, "third"],
                    "count": ["balls": 3, "strikes": 2],
                    "source": "sport"
                ],
                "metadata": [
                    "providerEventType": "walk",
                    "source": "metadata"
                ]
            ],
            playIndex: 32
        )
        let metadata = event.sportMetadata

        XCTAssertEqual(metadata["baseStateBefore"], .string("runner_on_first"))
        XCTAssertEqual(metadata["outsBefore"], .number(1))
        XCTAssertEqual(metadata["isHighLeverage"], .bool(true))
        XCTAssertEqual(metadata["occupiedBases"], .array([.string("1B"), .number(2), .string("third")]))
        XCTAssertEqual(metadata["count"], .object(["balls": .number(3), "strikes": .number(2)]))
        XCTAssertEqual(metadata["providerEventType"], .string("walk"))
        XCTAssertEqual(metadata["source"], .string("metadata"))
        XCTAssertEqual(metadata["playIndex"], .number(32))
    }

    func testFutureSportSituationPayloadsDecodeThroughSharedFixtureShape() throws {
        for fixture in FutureSportSituationFixture.allCases {
            let event = try mappedEvent(
                responseOverrides: [
                    "detailContractVersion": 3,
                    "situationContract": situationContract
                ],
                playOverrides: fixture.playOverrides(playIndex: 40 + fixture.ordinal),
                playIndex: 40 + fixture.ordinal
            )
            let sportState = try XCTUnwrap(event.situationBefore?.sportState, fixture.rawValue)

            XCTAssertEqual(event.situationBefore?.normalizedSport, fixture.rawValue)
            XCTAssertEqual(event.situationBefore?.display?.headline, fixture.headline)
            XCTAssertEqual(event.sportMetadata["diagramCandidate"], .string(fixture.rawValue))
            XCTAssertEqual(fixture.stateValue(in: sportState), fixture.expectedState)
            XCTAssertNil(sportState.baseball, fixture.rawValue)
        }
    }

    private var situationContract: [String: Any] {
        [
            "schemaVersion": 1,
            "supportsSituationBefore": true,
            "supportsSituationAfter": true,
            "supportedSports": ["mlb", "nfl", "nhl", "nba", "soccer", "golf", "tennis"],
            "minimumDetailContractVersion": 3
        ]
    }

    private func mappedEvent(
        responseOverrides: [String: Any] = [:],
        playOverrides: [String: Any] = [:],
        playIndex: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> GameEvent {
        var play: [String: Any] = [
            "eventId": "decode-\(playIndex)",
            "playIndex": playIndex,
            "displayType": "Single",
            "teamAbbreviation": "BAY",
            "periodLabel": "B8",
            "clockLabel": "1 out",
            "description": "Mapped event",
            "score": ["home": 4, "away": 3],
            "importance": [
                "schemaVersion": 1,
                "level": "primary",
                "rank": 90,
                "bucket": "key",
                "reasons": [],
                "isKeyMoment": true,
                "isScoringPlay": false,
                "isLeadChange": false,
                "isTyingPlay": false,
                "isLateGame": true,
                "isFinalPlay": false,
                "isRunEnding": false
            ],
            "modeEligibility": ["important": true, "standard": true, "all": true]
        ]
        play.merge(playOverrides) { _, new in new }

        var payload: [String: Any] = [
            "detailContractVersion": 2,
            "game": [
                "id": 1904,
                "leagueCode": "mlb",
                "gameDate": "2026-05-22T23:10:00Z",
                "status": "in_progress",
                "homeTeam": "Bay Harbor",
                "awayTeam": "River City",
                "homeTeamAbbr": "BAY",
                "awayTeamAbbr": "RIV",
                "score": ["home": 4, "away": 3]
            ],
            "teamStats": [],
            "playerStats": [],
            "plays": [play]
        ]
        payload.merge(responseOverrides) { _, new in new }

        let data = try JSONSerialization.data(withJSONObject: payload)
        let response = try JSONDecoder.sda.decode(SDAGameDetailResponseDTO.self, from: data)
        return try XCTUnwrap(SDADomainMapper.detail(from: response).events.first, file: file, line: line)
    }
}

private enum FutureSportSituationFixture: String, CaseIterable {
    case football = "nfl"
    case hockey = "nhl"
    case basketball = "nba"
    case soccer
    case golf
    case tennis

    var ordinal: Int {
        switch self {
        case .football: return 1
        case .hockey: return 2
        case .basketball: return 3
        case .soccer: return 4
        case .golf: return 5
        case .tennis: return 6
        }
    }

    var headline: String {
        switch self {
        case .football: return "3rd and 7"
        case .hockey: return "Power play chance"
        case .basketball: return "Late possession"
        case .soccer: return "Corner setup"
        case .golf: return "Approach pressure"
        case .tennis: return "Break point"
        }
    }

    var expectedState: [String: JSONValue] {
        switch self {
        case .football: return ["down": .number(3), "distance": .number(7), "yardLine": .string("SEA 42")]
        case .hockey: return ["strength": .string("power_play"), "zone": .string("offensive")]
        case .basketball: return ["possession": .string("home"), "shotClock": .number(12)]
        case .soccer: return ["setPiece": .string("corner"), "attackingThird": .bool(true)]
        case .golf: return ["hole": .number(17), "lie": .string("fairway")]
        case .tennis: return ["server": .string("home"), "point": .string("break")]
        }
    }

    func playOverrides(playIndex: Int) -> [String: Any] {
        [
            "eventId": "future-\(playIndex)",
            "displayType": headline,
            "situationBefore": [
                "schemaVersion": 1,
                "sport": rawValue,
                "display": ["headline": headline, "tokens": [rawValue.uppercased()]],
                "sportState": [stateKey: expectedState.jsonObject],
                "confidence": ["level": "partial", "source": "provider", "reasons": []]
            ],
            "sportMetadata": [
                "diagramCandidate": rawValue,
                "fieldState": expectedState.jsonObject
            ]
        ]
    }

    func stateValue(in sportState: GameEventSituationSportState) -> [String: JSONValue]? {
        switch self {
        case .football: return sportState.football
        case .hockey: return sportState.hockey
        case .basketball: return sportState.basketball
        case .soccer: return sportState.soccer
        case .golf: return sportState.golf
        case .tennis: return sportState.tennis
        }
    }

    private var stateKey: String {
        switch self {
        case .football: return "football"
        case .hockey: return "hockey"
        case .basketball: return "basketball"
        case .soccer: return "soccer"
        case .golf: return "golf"
        case .tennis: return "tennis"
        }
    }
}

private extension Dictionary where Key == String, Value == JSONValue {
    var jsonObject: [String: Any] {
        mapValues(\.jsonObject)
    }
}

private extension JSONValue {
    var jsonObject: Any {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value
        case .bool(let value):
            return value
        case .object(let value):
            return value.jsonObject
        case .array(let value):
            return value.map(\.jsonObject)
        case .null:
            return NSNull()
        }
    }
}
