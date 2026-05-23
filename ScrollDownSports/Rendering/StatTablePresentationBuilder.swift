import SwiftUI

extension StatPresentationBuilder {
    static func genericPlayerTable(from scoredPlayers: [ScoredPlayerStat]) -> StatTablePresentation {
        let sortedPlayers = scoredPlayers.sorted(by: sortScoredPlayers).prefix(80)
        let statColumns = Array(genericStatColumns.filter { column in
            sortedPlayers.contains { genericValue(column.id, for: $0.player) != nil }
        }.prefix(8))
        let columns = [
            tableColumn("player", "Player", width: 132, alignment: .leading),
            tableColumn("team", "Team", width: 54, alignment: .leading)
        ] + statColumns
        let rows = sortedPlayers.enumerated().map { index, scored in
            var values = ["player": scored.player.playerName, "team": scored.player.team]
            statColumns.forEach { column in
                values[column.id] = genericValue(column.id, for: scored.player) ?? "-"
            }
            return StatTableRowPresentation(id: "\(scored.player.id)-\(index)", values: values)
        }
        return StatTablePresentation(id: "generic-full-stats", title: "Full Stats", columns: columns, rows: rows)
    }

    static func baseballBatterTable(from batters: [ScoredBatter]) -> StatTablePresentation {
        let columns = [
            tableColumn("player", "Player", width: 132, alignment: .leading),
            tableColumn("team", "Team", width: 54, alignment: .leading),
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
                    "player": player.playerName, "team": player.team, "pos": player.position ?? "-",
                    "ab": statString(player.atBats), "h": statString(player.hits), "r": statString(player.runs),
                    "rbi": statString(player.rbi), "hr": statString(player.homeRuns),
                    "bb": statString(player.baseOnBalls), "k": statString(player.strikeOuts)
                ]
            )
        }
        return StatTablePresentation(id: "baseball-batters", title: "Batters", columns: columns, rows: rows)
    }

    static func baseballPitcherTable(from pitchers: [ScoredPitcher]) -> StatTablePresentation {
        let columns = [
            tableColumn("player", "Player", width: 132, alignment: .leading),
            tableColumn("team", "Team", width: 54, alignment: .leading),
            tableColumn("ip", "IP", width: 46), tableColumn("h", "H"), tableColumn("r", "R"),
            tableColumn("er", "ER"), tableColumn("bb", "BB"), tableColumn("k", "K"),
            tableColumn("hr", "HR")
        ]
        let rows = pitchers.sorted(by: sortScoredPitchers).enumerated().map { index, scored in
            let player = scored.player
            return StatTableRowPresentation(
                id: "\(player.id)-\(index)",
                values: [
                    "player": player.playerName, "team": player.team, "ip": player.inningsPitched ?? "-",
                    "h": statString(player.hits), "r": statString(player.runs), "er": statString(player.earnedRuns),
                    "bb": statString(player.baseOnBalls), "k": statString(player.strikeOuts),
                    "hr": statString(player.homeRuns)
                ]
            )
        }
        return StatTablePresentation(id: "baseball-pitchers", title: "Pitchers", columns: columns, rows: rows)
    }

    static func hockeySkaterTable(from players: [ScoredNHLPlayer]) -> StatTablePresentation {
        let columns = [
            tableColumn("player", "Player", width: 132, alignment: .leading),
            tableColumn("team", "Team", width: 54, alignment: .leading),
            tableColumn("g", "G"), tableColumn("a", "A"), tableColumn("pts", "PTS", width: 46),
            tableColumn("sog", "SOG", width: 48)
        ]
        let rows = players.sorted(by: sortScoredNHLPlayers).enumerated().map { index, scored in
            let player = scored.player
            return StatTableRowPresentation(
                id: "\(player.id)-skater-\(index)",
                values: [
                    "player": player.playerName, "team": player.team, "g": statString(player.goals),
                    "a": statString(player.assists), "pts": statString(player.points),
                    "sog": statString(player.shotsOnGoal)
                ]
            )
        }
        return StatTablePresentation(id: "hockey-skaters", title: "Skaters", columns: columns, rows: rows)
    }

    static func hockeyGoalieTable(from players: [ScoredNHLPlayer]) -> StatTablePresentation {
        let hasSavePercentage = players.contains { $0.player.saves != nil && $0.player.goalsAgainst != nil }
        var columns = [
            tableColumn("player", "Player", width: 132, alignment: .leading),
            tableColumn("team", "Team", width: 54, alignment: .leading),
            tableColumn("sv", "SV"), tableColumn("ga", "GA")
        ]
        if hasSavePercentage {
            columns.append(tableColumn("svp", "SV%", width: 50))
        }
        let rows = players.sorted(by: sortScoredNHLPlayers).enumerated().map { index, scored in
            let player = scored.player
            var values = [
                "player": player.playerName, "team": player.team,
                "sv": statString(player.saves), "ga": statString(player.goalsAgainst)
            ]
            if hasSavePercentage {
                values["svp"] = savePercentage(for: player)
            }
            return StatTableRowPresentation(id: "\(player.id)-goalie-\(index)", values: values)
        }
        return StatTablePresentation(id: "hockey-goalies", title: "Goalies", columns: columns, rows: rows)
    }

    static func teamStatTable(for teams: [TeamStat]) -> StatTablePresentation {
        let teamItems = teams.map { ($0, compactTeamItems($0)) }
        let statKeys = teamItems.flatMap(\.1).reduce(into: [String]()) { keys, item in
            guard !keys.contains(item.key) else { return }
            keys.append(item.key)
        }.prefix(8)
        let columns = [
            tableColumn("team", "Team", width: 132, alignment: .leading),
            tableColumn("side", "Side", width: 54, alignment: .leading)
        ] + statKeys.map { key in
            let label = teamItems.flatMap(\.1).first(where: { $0.key == key })?.label ?? key.camelTitle
            return tableColumn(key, label, width: max(46, CGFloat(min(72, max(2, label.count) * 8))))
        }
        let rows = teamItems.enumerated().map { index, pair in
            let (team, items) = pair
            var values = ["team": team.team, "side": team.isHome ? "Home" : "Away"]
            statKeys.forEach { key in
                values[key] = items.first(where: { $0.key == key })?.value ?? "-"
            }
            return StatTableRowPresentation(id: "\(team.id)-\(index)", values: values)
        }
        return StatTablePresentation(id: "team-stats-table", title: "Full Team Stats", columns: columns, rows: rows)
    }

    static func teamHighlight(for team: TeamStat) -> StatHighlightPresentation {
        let items = compactTeamItems(team).prefix(3).map {
            StatPillPresentation(label: $0.label, value: $0.value)
        }
        let headline = items.prefix(2).map { "\($0.label) \($0.value)" }.joined(separator: ", ")
        return StatHighlightPresentation(
            id: team.id,
            rank: nil,
            title: team.team,
            subtitle: team.isHome ? "Home" : "Away",
            headline: headline.isEmpty ? "Team totals available" : headline,
            stats: items,
            accentTone: .neutral
        )
    }
}

extension StatPresentationBuilder {
    static var genericStatColumns: [StatTableColumnPresentation] {
        [
            tableColumn("min", "MIN"), tableColumn("pts", "PTS"), tableColumn("reb", "REB"),
            tableColumn("ast", "AST"), tableColumn("yds", "YDS"), tableColumn("td", "TD"),
            tableColumn("g", "G"), tableColumn("a", "A"), tableColumn("sog", "SOG", width: 48),
            tableColumn("sv", "SV"), tableColumn("k", "K"), tableColumn("rbi", "RBI", width: 46)
        ]
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
        case "k": return rawString(["strikeOuts", "strikeouts", "so", "k"], in: player.rawStats)
        case "rbi": return rawString(["rbi", "runsBattedIn"], in: player.rawStats)
        default: return nil
        }
    }

    static func genericStatCells(for player: PlayerStat) -> [StatPillPresentation] {
        genericStatColumns.compactMap { column in
            guard let value = genericValue(column.id, for: player), value != "-" else { return nil }
            return StatPillPresentation(label: column.label, value: value)
        }
    }
}
