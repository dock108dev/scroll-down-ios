import SwiftUI

extension StatPresentationBuilder {
    static func genericPlayerTable(
        from scoredPlayers: [ScoredPlayerStat],
        statColumns availableColumns: [StatTableColumnPresentation] = genericStatColumns,
        tableID: String = "generic-full-stats",
        title: String = "Full Stats"
    ) -> StatTablePresentation {
        let sortedPlayers = scoredPlayers.sorted(by: sortScoredPlayers).prefix(80)
        let statColumns = Array(availableColumns.filter { column in
            sortedPlayers.contains { genericValue(column.id, for: $0.player) != nil }
        }.prefix(8))
        let columns = [
            tableColumn("player", "Player", width: 154, alignment: .leading),
            tableColumn("team", "Team", width: 42, alignment: .leading)
        ] + statColumns
        let rows = sortedPlayers.enumerated().map { index, scored in
            var values = ["player": scored.player.playerName, "team": shortTeamCode(scored.player.team)]
            statColumns.forEach { column in
                values[column.id] = genericValue(column.id, for: scored.player) ?? "-"
            }
            return StatTableRowPresentation(id: "\(scored.player.id)-\(index)", values: values)
        }
        return StatTablePresentation(id: tableID, title: title, columns: columns, rows: rows)
    }

    static func baseballBatterTable(from batters: [ScoredBatter], teamAbbreviations: [String: String]) -> StatTablePresentation {
        let columns = [
            tableColumn("player", "Player", width: 154, alignment: .leading),
            tableColumn("team", "Team", width: 42, alignment: .leading),
            tableColumn("pos", "Pos", width: 44, alignment: .leading),
            tableColumn("ab", "AB"), tableColumn("h", "H"), tableColumn("r", "R"),
            tableColumn("rbi", "RBI", width: 46), tableColumn("hr", "HR"), tableColumn("bb", "BB"),
            tableColumn("k", "K")
        ]
        let rows = batters.sorted(by: sortScoredBatters).enumerated().map { index, scored in
            let player = scored.player
            return StatTableRowPresentation(
                id: "\(player.id)-\(index)",
                values: [
                    "player": player.playerName,
                    "team": teamAbbreviations[player.team] ?? shortTeamCode(player.team),
                    "pos": player.position ?? "-",
                    "ab": statString(player.atBats), "h": statString(player.hits), "r": statString(player.runs),
                    "rbi": statString(player.rbi), "hr": statString(player.homeRuns),
                    "bb": statString(player.baseOnBalls), "k": statString(player.strikeOuts)
                ]
            )
        }
        return StatTablePresentation(id: "baseball-batters", title: "Batters", columns: columns, rows: rows)
    }

    static func baseballPitcherTable(from pitchers: [ScoredPitcher], teamAbbreviations: [String: String]) -> StatTablePresentation {
        let columns = [
            tableColumn("player", "Player", width: 154, alignment: .leading),
            tableColumn("team", "Team", width: 42, alignment: .leading),
            tableColumn("ip", "IP", width: 46), tableColumn("h", "H"), tableColumn("r", "R"),
            tableColumn("er", "ER"), tableColumn("bb", "BB"), tableColumn("k", "K"),
            tableColumn("hr", "HR")
        ]
        let rows = pitchers.sorted(by: sortScoredPitchers).enumerated().map { index, scored in
            let player = scored.player
            return StatTableRowPresentation(
                id: "\(player.id)-\(index)",
                values: [
                    "player": player.playerName, "team": teamAbbreviations[player.team] ?? shortTeamCode(player.team), "ip": player.inningsPitched ?? "-",
                    "h": statString(player.hits), "r": statString(player.runs), "er": statString(player.earnedRuns),
                    "bb": statString(player.baseOnBalls), "k": statString(player.strikeOuts),
                    "hr": statString(player.homeRuns)
                ]
            )
        }
        return StatTablePresentation(id: "baseball-pitchers", title: "Pitchers", columns: columns, rows: rows)
    }

    static func hockeySkaterTable(from players: [ScoredNHLPlayer], teamAbbreviations: [String: String]) -> StatTablePresentation {
        let columns = [
            tableColumn("player", "Player", width: 154, alignment: .leading),
            tableColumn("team", "Team", width: 42, alignment: .leading),
            tableColumn("g", "G"), tableColumn("a", "A"), tableColumn("pts", "PTS", width: 46),
            tableColumn("sog", "SOG", width: 48)
        ]
        let rows = players.sorted(by: sortScoredNHLPlayers).enumerated().map { index, scored in
            let player = scored.player
            return StatTableRowPresentation(
                id: "\(player.id)-skater-\(index)",
                values: [
                    "player": player.playerName, "team": teamAbbreviations[player.team] ?? shortTeamCode(player.team), "g": statString(player.goals),
                    "a": statString(player.assists), "pts": statString(player.points),
                    "sog": statString(player.shotsOnGoal)
                ]
            )
        }
        return StatTablePresentation(id: "hockey-skaters", title: "Skaters", columns: columns, rows: rows)
    }

    static func hockeyGoalieTable(from players: [ScoredNHLPlayer], teamAbbreviations: [String: String]) -> StatTablePresentation {
        let hasSavePercentage = players.contains { $0.player.saves != nil && $0.player.goalsAgainst != nil }
        var columns = [
            tableColumn("player", "Player", width: 154, alignment: .leading),
            tableColumn("team", "Team", width: 42, alignment: .leading),
            tableColumn("sv", "SV"), tableColumn("ga", "GA")
        ]
        if hasSavePercentage {
            columns.append(tableColumn("svp", "SV%", width: 50))
        }
        let rows = players.sorted(by: sortScoredNHLPlayers).enumerated().map { index, scored in
            let player = scored.player
            var values = [
                "player": player.playerName, "team": teamAbbreviations[player.team] ?? shortTeamCode(player.team),
                "sv": statString(player.saves), "ga": statString(player.goalsAgainst)
            ]
            if hasSavePercentage {
                values["svp"] = savePercentage(for: player)
            }
            return StatTableRowPresentation(id: "\(player.id)-goalie-\(index)", values: values)
        }
        return StatTablePresentation(id: "hockey-goalies", title: "Goalies", columns: columns, rows: rows)
    }

    static func shortTeamCode(_ name: String) -> String {
        String(name.split(separator: " ").last?.prefix(3) ?? "TM").uppercased()
    }
}

extension StatPresentationBuilder {
    static var genericStatColumns: [StatTableColumnPresentation] {
        [
            tableColumn("min", "MIN"), tableColumn("pts", "PTS"), tableColumn("reb", "REB"),
            tableColumn("ast", "AST"), tableColumn("yds", "YDS"), tableColumn("td", "TD"),
            tableColumn("g", "G"), tableColumn("a", "A"), tableColumn("sog", "SOG", width: 48),
            tableColumn("sv", "SV"), tableColumn("h", "H"), tableColumn("r", "R"),
            tableColumn("rbi", "RBI", width: 46), tableColumn("hr", "HR"), tableColumn("bb", "BB"),
            tableColumn("k", "K"), tableColumn("ip", "IP", width: 46), tableColumn("er", "ER"), tableColumn("ga", "GA"),
            tableColumn("rank", "Rank", width: 52), tableColumn("score", "Score", width: 58),
            tableColumn("thru", "Thru", width: 52)
        ]
    }

    static func genericStatColumns(for sport: Sport) -> [StatTableColumnPresentation] {
        let ids: [String]
        switch sport {
        case .mlb:
            ids = ["h", "r", "rbi", "hr", "bb", "k"]
        case .nfl:
            ids = ["yds", "td"]
        case .nba:
            ids = ["min", "pts", "reb", "ast"]
        case .nhl:
            ids = ["g", "a", "pts", "sog", "sv", "ga"]
        case .soccer:
            ids = ["g", "a", "sog"]
        case .golf:
            ids = ["rank", "score", "thru"]
        case .tennis, .other:
            return genericStatColumns
        }
        return ids.compactMap { id in
            genericStatColumns.first { $0.id == id }
        }
    }

    static func genericValue(_ columnID: String, for player: PlayerStat) -> String? {
        switch columnID {
        case "min": return statString(player.minutes)
        case "pts": return statString(player.points) ?? rawString(["points", "pts"], in: player.rawStats)
        case "reb": return statString(player.rebounds)
        case "ast": return statString(player.assists) ?? rawString(["assists", "ast"], in: player.rawStats)
        case "yds": return statString(player.yards)
        case "td": return statString(player.touchdowns)
        case "g": return rawString(["goals", "goal"], in: player.rawStats)
        case "a": return rawString(["assists", "ast"], in: player.rawStats)
        case "sog": return rawString(["shots", "shotsOnGoal", "sog"], in: player.rawStats)
        case "sv": return rawString(["saves", "sv"], in: player.rawStats)
        case "ga": return rawString(["goalsAgainst", "goals_against", "ga"], in: player.rawStats)
        case "h": return rawString(["hits", "h"], in: player.rawStats)
        case "r": return rawString(["runs", "r"], in: player.rawStats)
        case "rbi": return rawString(["rbi", "runsBattedIn"], in: player.rawStats)
        case "hr": return rawString(["homeRuns", "hr"], in: player.rawStats)
        case "bb": return rawString(["walks", "baseOnBalls", "bb"], in: player.rawStats)
        case "k": return rawString(["strikeOuts", "strikeouts", "so", "k"], in: player.rawStats)
        case "ip": return rawString(["inningsPitched", "ip"], in: player.rawStats)
        case "er": return rawString(["earnedRuns", "er"], in: player.rawStats)
        case "rank": return rawString(["rank", "position"], in: player.rawStats)
        case "score": return rawString(["score", "total", "strokes"], in: player.rawStats)
        case "thru": return rawString(["thru", "holesThru", "through"], in: player.rawStats)
        default: return nil
        }
    }

    static func genericStatCells(
        for player: PlayerStat,
        columns: [StatTableColumnPresentation] = genericStatColumns
    ) -> [StatPillPresentation] {
        columns.compactMap { column in
            guard let value = genericValue(column.id, for: player), value != "-" else { return nil }
            return StatPillPresentation(label: column.label, value: value)
        }
    }
}
