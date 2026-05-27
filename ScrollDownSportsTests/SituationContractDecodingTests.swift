import XCTest
@testable import ScrollDownSports

final class SituationContractDecodingTests: XCTestCase {
    func testOldDetailPayloadsDecodeWithoutSituationContract() throws {
        let response = try JSONDecoder.sda.decode(
            SDAGameDetailResponseDTO.self,
            from: try SDAFixtures.gameDetail("mlb_live_new_events")
        )
        let detail = SDADomainMapper.detail(from: response)

        XCTAssertEqual(response.detailContractVersion, 2)
        XCTAssertNil(response.situationContract)
        XCTAssertTrue(response.plays.allSatisfy { $0.situationBefore == nil && $0.situationAfter == nil })
        XCTAssertTrue(detail.events.allSatisfy { $0.situationBefore == nil && $0.situationAfter == nil })
    }

    func testMapsFirstClassBaseballSituationSeparatelyFromMetadata() throws {
        let event = try mappedEvent(
            responseOverrides: [
                "detailContractVersion": 3,
                "situationContract": [
                    "schemaVersion": 1,
                    "supportsSituationBefore": true,
                    "supportsSituationAfter": false,
                    "supportedSports": ["mlb", "nfl", "nhl", "nba", "soccer", "golf", "tennis"],
                    "minimumDetailContractVersion": 3
                ]
            ],
            playOverrides: [
                "situationBefore": [
                    "schemaVersion": 1,
                    "sport": "mlb",
                    "display": [
                        "headline": "Runners on 1st and 2nd",
                        "subheadline": "Top 4th",
                        "tokens": ["T4", "2 outs"],
                        "accessibilityLabel": "Before the play, runners on first and second with two outs."
                    ],
                    "score": ["away": 1, "home": 1],
                    "period": ["ordinal": 4, "label": "T4", "phase": "top"],
                    "sportState": [
                        "baseball": [
                            "inning": 4,
                            "half": "top",
                            "outs": 2,
                            "balls": 3,
                            "strikes": 1,
                            "bases": ["first": true, "second": true, "third": false],
                            "battingTeamAbbreviation": "AWY"
                        ],
                        "football": NSNull(),
                        "hockey": NSNull(),
                        "basketball": NSNull(),
                        "soccer": NSNull(),
                        "golf": NSNull(),
                        "tennis": NSNull()
                    ],
                    "confidence": ["level": "verified", "source": "stats_feed", "reasons": []]
                ],
                "metadata": ["providerEventType": "single"],
                "sportMetadata": ["baseState": "post_play_result"]
            ],
            playIndex: 20
        )
        let situation = try XCTUnwrap(event.situationBefore)
        let baseball = try XCTUnwrap(situation.sportState?.baseball)
        let state = BaseballRenderer().baseballPrePitchState(for: event)

        XCTAssertEqual(situation.normalizedSport, "mlb")
        XCTAssertEqual(situation.display?.headline, "Runners on 1st and 2nd")
        XCTAssertEqual(situation.score?.away, 1)
        XCTAssertEqual(situation.score?.home, 1)
        XCTAssertEqual(baseball.outs, 2)
        XCTAssertEqual(baseball.bases?.first, true)
        XCTAssertEqual(baseball.bases?.second, true)
        XCTAssertEqual(state.baseState?.occupiedBases, [.first, .second])
        XCTAssertEqual(state.outs, 2)
        XCTAssertEqual(state.count?.label, "3-1")
        XCTAssertEqual(event.sportMetadata["baseState"], .string("post_play_result"))
        XCTAssertNil(event.sportMetadata["situationBefore"])
    }

    func testNullSituationBeforeDoesNotCreateDomainSituation() throws {
        let event = try mappedEvent(
            responseOverrides: [
                "detailContractVersion": 3,
                "situationContract": [
                    "schemaVersion": 1,
                    "supportsSituationBefore": true
                ]
            ],
            playOverrides: ["situationBefore": NSNull()],
            playIndex: 21
        )

        XCTAssertNil(event.situationBefore)
    }

    func testUnsupportedSituationStateFailsClosedForBaseball() throws {
        let event = try mappedEvent(
            responseOverrides: [
                "detailContractVersion": 3,
                "situationContract": [
                    "schemaVersion": 1,
                    "supportsSituationBefore": true
                ]
            ],
            playOverrides: [
                "situationBefore": [
                    "schemaVersion": 1,
                    "sport": "football",
                    "sportState": [
                        "football": ["down": 3, "distance": 7],
                        "baseball": NSNull()
                    ],
                    "confidence": ["level": "verified"]
                ],
                "sportMetadata": [
                    "situationBefore": [
                        "baseState": "bases_loaded",
                        "outs": 1
                    ]
                ]
            ],
            playIndex: 22
        )
        let state = BaseballRenderer().baseballPrePitchState(for: event)

        XCTAssertEqual(event.situationBefore?.normalizedSport, "football")
        XCTAssertNil(state.baseState)
        XCTAssertNil(state.outs)
        XCTAssertNil(state.count)
    }

    func testUnknownExtraSituationFieldsDecodeSafely() throws {
        let event = try mappedEvent(
            responseOverrides: [
                "detailContractVersion": 3,
                "situationContract": [
                    "schemaVersion": 1,
                    "supportsSituationBefore": true,
                    "unknownCapability": ["ignored": true]
                ]
            ],
            playOverrides: [
                "situationBefore": [
                    "schemaVersion": 1,
                    "sport": "mlb",
                    "unexpectedTopLevel": ["ignored": true],
                    "sportState": [
                        "baseball": [
                            "outs": 0,
                            "baseState": "bases_empty",
                            "unexpectedBaseballField": "ignored"
                        ],
                        "cricket": ["wickets": 2]
                    ],
                    "confidence": ["level": "derived", "unexpectedConfidenceField": true]
                ],
                "situationAfter": [
                    "schemaVersion": 1,
                    "sport": "mlb",
                    "sportState": ["baseball": ["outs": 1]],
                    "confidence": ["level": "derived"]
                ]
            ],
            playIndex: 23
        )

        XCTAssertEqual(event.situationBefore?.sportState?.baseball?.baseState, "bases_empty")
        XCTAssertEqual(event.situationAfter?.sportState?.baseball?.outs, 1)
    }

    func testMissingSituationContractDoesNotFailValidDetailFetch() async throws {
        let client = TestFixtures.makeAPIClient(
            responses: [.ok(try detailPayload(playIndex: 24))],
            protocolClass: MockValidV2MissingSituationContractURLProtocol.self
        )

        let detail = try await client.fetchGame(id: 900)

        XCTAssertEqual(detail.events.count, 1)
        XCTAssertNil(detail.events.first?.situationBefore)
    }

    private func mappedEvent(
        responseOverrides: [String: Any] = [:],
        playOverrides: [String: Any] = [:],
        playIndex: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> GameEvent {
        let data = try detailPayload(
            responseOverrides: responseOverrides,
            playOverrides: playOverrides,
            playIndex: playIndex
        )
        let response = try JSONDecoder.sda.decode(SDAGameDetailResponseDTO.self, from: data)
        return try XCTUnwrap(SDADomainMapper.detail(from: response).events.first, file: file, line: line)
    }

    private func detailPayload(
        responseOverrides: [String: Any] = [:],
        playOverrides: [String: Any] = [:],
        playIndex: Int
    ) throws -> Data {
        var play: [String: Any] = [
            "eventId": "situation-\(playIndex)",
            "playIndex": playIndex,
            "displayType": "Single",
            "periodLabel": "T4",
            "clockLabel": "2 outs",
            "description": "Mapped event",
            "score": ["home": 1, "away": 1],
            "importance": [
                "schemaVersion": 1,
                "level": "primary",
                "rank": 95,
                "bucket": "key",
                "reasons": [],
                "isKeyMoment": true,
                "isScoringPlay": false,
                "isLeadChange": false,
                "isTyingPlay": false,
                "isLateGame": false,
                "isFinalPlay": false,
                "isRunEnding": false
            ],
            "modeEligibility": ["important": true, "standard": true, "all": true]
        ]
        play.merge(playOverrides) { _, new in new }

        var payload: [String: Any] = [
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
                "score": ["home": 1, "away": 1]
            ],
            "teamStats": [],
            "playerStats": [],
            "plays": [play]
        ]
        payload.merge(responseOverrides) { _, new in new }

        return try JSONSerialization.data(withJSONObject: payload)
    }
}

private final class MockValidV2MissingSituationContractURLProtocol: MockHTTPURLProtocol {}
