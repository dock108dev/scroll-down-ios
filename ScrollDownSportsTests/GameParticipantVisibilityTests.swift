import XCTest
@testable import ScrollDownSports

final class GameParticipantVisibilityTests: XCTestCase {
    func testParticipantConcretenessCoversBlankMissingAndPlaceholderCases() {
        let concreteAbbreviationOnly = participant(name: "", abbreviation: "BOS")
        let concreteNameOnly = participant(name: "Boston Bruins", abbreviation: nil)
        XCTAssertTrue(GameParticipantVisibility.isConcreteParticipant(concreteAbbreviationOnly))
        XCTAssertTrue(GameParticipantVisibility.isConcreteParticipant(concreteNameOnly))
        XCTAssertFalse(GameParticipantVisibility.isConcreteParticipant(nil))
        XCTAssertFalse(GameParticipantVisibility.isConcreteParticipant(participant(name: "", abbreviation: nil)))
        XCTAssertFalse(GameParticipantVisibility.isConcreteParticipant(participant(name: " \n\t ", abbreviation: "")))

        for value in ["TBD", "TBA", "T.B.D.", "T.B.A.", "To Be Determined", "To Be Announced"] {
            XCTAssertFalse(
                GameParticipantVisibility.isConcreteParticipant(participant(name: value, abbreviation: "BOS")),
                "Expected \(value) name to be non-concrete"
            )
            XCTAssertFalse(
                GameParticipantVisibility.isConcreteParticipant(participant(name: "", abbreviation: value)),
                "Expected \(value) abbreviation to be non-concrete"
            )
        }
    }

    func testParticipantConcretenessCoversCommonUnresolvedLabels() {
        let placeholders = [
            "Unknown Team",
            "N/A",
            "Opponent TBD",
            "Team TBD",
            "Away Team TBD",
            "Winner of Game 1",
            "Loser Game 2",
            "Play-In Winner",
            "Wild Card Winner",
            "No. 1 Seed",
            "#1 Seed",
            "West 8 Seed",
            "Higher Seed",
            "Team 1",
            "Team A",
            "Away Team",
            "Club B",
            "BYE"
        ]

        for value in placeholders {
            XCTAssertTrue(GameParticipantVisibility.isPlaceholderParticipantText(value), "Expected \(value) to be a placeholder")
            XCTAssertFalse(
                GameParticipantVisibility.isConcreteParticipant(participant(name: value, abbreviation: nil)),
                "Expected \(value) to be non-concrete"
            )
        }
    }

    func testDomainMapperPreservesApiParticipantTruthWhileVisibilityFiltersIt() throws {
        let json = """
        {
          "games": [
            {
              "id": 91,
              "leagueCode": "nhl",
              "gameDate": "2026-05-22T23:10:00Z",
              "status": "scheduled",
              "homeTeam": "T.B.D.",
              "awayTeam": "Boston Bruins",
              "homeTeamAbbr": "TBD",
              "awayTeamAbbr": "BOS",
              "hasPbp": true,
              "playCount": 1
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.sda.decode(SDAGameListResponseDTO.self, from: json)
        let game = try XCTUnwrap(SDADomainMapper.games(from: response).first)

        XCTAssertEqual(game.homeParticipant?.name, "T.B.D.")
        XCTAssertEqual(game.homeParticipant?.abbreviation, "TBD")
        XCTAssertFalse(GameParticipantVisibility.hasConcreteParticipants(game))
    }

    private func participant(name: String, abbreviation: String?) -> GameParticipant {
        GameParticipant(id: UUID().uuidString, role: .away, name: name, abbreviation: abbreviation)
    }
}
