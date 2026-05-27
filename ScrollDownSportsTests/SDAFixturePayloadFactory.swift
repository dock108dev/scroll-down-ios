import Foundation

enum SDAFixturePayloadFactory {
    static func gameList(ids: [Int]) throws -> Data {
        let template = try gameSummaryDictionary()
        let games = ids.map { id in
            var game = template
            game["id"] = id
            game["playCount"] = 2
            game["hasPbp"] = true
            return game
        }
        return try serialize([
            "games": games,
            "total": ids.count,
            "lastUpdatedAt": NSNull()
        ])
    }

    static func gameSummary(id: Int, playCount: Int) throws -> String {
        var summary = try gameSummaryDictionary()
        summary["id"] = id
        summary["playCount"] = playCount
        let data = try serialize(summary)
        guard let string = String(data: data, encoding: .utf8) else {
            throw JSONFixtureError.invalidPayload("game summary \(id)")
        }
        return string
    }

    static func gameDetail(gameId: Int, playIDs: [String]) throws -> Data {
        var detail = try jsonObject(from: SDAFixtures.gameDetail("mlb_live_new_events"))
        var game = try requireDictionary(detail["game"], context: "game")
        game["id"] = gameId
        detail["game"] = game
        detail["plays"] = try makePlays(playIDs: playIDs)
        detail["teamStats"] = []
        detail["playerStats"] = []
        detail["mlbBatters"] = NSNull()
        detail["mlbPitchers"] = NSNull()
        detail["nhlSkaters"] = NSNull()
        detail["nhlGoalies"] = NSNull()
        return try serialize(detail)
    }

    private static func makePlays(playIDs: [String]) throws -> [[String: Any]] {
        let detail = try jsonObject(from: SDAFixtures.gameDetail("mlb_live_new_events"))
        let plays = try requireArray(detail["plays"], context: "plays")
        guard let template = plays.first as? [String: Any] else {
            throw JSONFixtureError.invalidPayload("missing play template")
        }

        return playIDs.enumerated().map { index, id in
            var play = template
            play["eventId"] = id
            play["playIndex"] = index + 1
            play["gameClock"] = "10:0\(index)"
            play["clockLabel"] = "10:0\(index)"
            play["timeLabel"] = "10:0\(index)"
            play["description"] = "Game update \(index + 1)"
            play["score"] = ["home": index, "away": 0]
            play["scoreBefore"] = NSNull()
            play["scoreAfter"] = NSNull()
            play["scoreDelta"] = NSNull()
            play["scoreboard"] = NSNull()
            play["sportMetadata"] = [:]
            play["metadata"] = [:]
            return play
        }
    }

    private static func gameSummaryDictionary() throws -> [String: Any] {
        let list = try jsonObject(from: SDAFixtures.gameList("live_mlb_two_games"))
        let games = try requireArray(list["games"], context: "games")
        guard let first = games.first as? [String: Any] else {
            throw JSONFixtureError.invalidPayload("missing game summary template")
        }
        return first
    }

    private static func jsonObject(from data: Data) throws -> [String: Any] {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw JSONFixtureError.invalidPayload("root object")
        }
        return object
    }

    private static func requireDictionary(_ value: Any?, context: String) throws -> [String: Any] {
        guard let dictionary = value as? [String: Any] else {
            throw JSONFixtureError.invalidPayload(context)
        }
        return dictionary
    }

    private static func requireArray(_ value: Any?, context: String) throws -> [Any] {
        guard let array = value as? [Any] else {
            throw JSONFixtureError.invalidPayload(context)
        }
        return array
    }

    private static func serialize(_ object: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
}
