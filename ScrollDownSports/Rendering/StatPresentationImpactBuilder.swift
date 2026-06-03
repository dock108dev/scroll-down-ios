import SwiftUI

struct ScoredPlayerStat {
    let player: PlayerStat
    let score: Double
}

struct ScoredBatter {
    let player: MLBBatterStat
    let score: Double
}

struct ScoredPitcher {
    let player: MLBPitcherStat
    let score: Double
}

struct ScoredNHLPlayer {
    let player: NHLPlayerStat
    let role: String
    let score: Double
}

extension StatPresentationBuilder {
    static func genericImpactScore(_ player: PlayerStat, columns: [StatTableColumnPresentation]) -> Double {
        columns.reduce(0) { score, column in
            score + genericImpactValue(column.id, for: player)
        }
    }

    static func genericImpactValue(_ columnID: String, for player: PlayerStat) -> Double {
        switch columnID {
        case "min": return player.minutes.orZero * 0.02
        case "pts": return player.points.orZero + rawDouble(["points", "pts"], in: player.rawStats)
        case "reb": return player.rebounds.orZero * 0.7
        case "ast": return player.assists.orZero * 0.8 + rawDouble(["assists", "ast"], in: player.rawStats) * 1.5
        case "yds": return player.yards.orZero * 0.04
        case "td": return player.touchdowns.orZero * 6
        case "g": return rawDouble(["goals", "goal"], in: player.rawStats) * 3
        case "a": return rawDouble(["assists", "ast"], in: player.rawStats) * 1.5
        case "sog": return rawDouble(["shots", "shotsOnGoal", "sog"], in: player.rawStats) * 0.25
        case "sv": return rawDouble(["saves", "sv"], in: player.rawStats) * 0.2
        case "ga": return max(0, 3 - rawDouble(["goalsAgainst", "goals_against", "ga"], in: player.rawStats))
        case "h": return rawDouble(["hits", "h"], in: player.rawStats) * 1.5
        case "r": return rawDouble(["runs", "r"], in: player.rawStats) * 1.25
        case "rbi": return rawDouble(["rbi", "runsBattedIn"], in: player.rawStats) * 1.2
        case "hr": return rawDouble(["homeRuns", "hr"], in: player.rawStats) * 5
        case "bb": return rawDouble(["walks", "baseOnBalls", "bb"], in: player.rawStats) * 0.75
        case "k": return rawDouble(["strikeOuts", "strikeouts", "so", "k"], in: player.rawStats) * 0.7
        case "ip": return rawDouble(["inningsPitched", "ip"], in: player.rawStats) * 0.8
        case "er": return max(0, 3 - rawDouble(["earnedRuns", "er"], in: player.rawStats))
        default: return 0
        }
    }

    static func batterImpactScore(_ player: MLBBatterStat) -> Double {
        max(
            0,
            Double(player.homeRuns.orZero) * 5
                + Double(player.rbi.orZero) * 2
                + Double(player.hits.orZero) * 1.5
                + Double(player.runs.orZero) * 1.25
                + Double(player.baseOnBalls.orZero) * 0.75
                - Double(player.strikeOuts.orZero) * 0.3
        )
    }

    static func pitcherImpactScore(_ player: MLBPitcherStat) -> Double {
        max(
            0,
            Double(outs(from: player.inningsPitched)) * 0.8
                + Double(player.strikeOuts.orZero) * 1.5
                - Double(player.earnedRuns.orZero) * 2.5
                - Double(player.runs.orZero)
                - Double(player.hits.orZero) * 0.6
                - Double(player.baseOnBalls.orZero) * 0.7
                - Double(player.homeRuns.orZero) * 1.5
        )
    }

    static func skaterImpactScore(_ player: NHLPlayerStat) -> Double {
        Double(player.goals.orZero) * 4
            + Double(player.assists.orZero) * 2
            + Double(player.points.orZero)
            + Double(player.shotsOnGoal.orZero) * 0.35
    }

    static func goalieImpactScore(_ player: NHLPlayerStat) -> Double {
        guard player.saves != nil else { return 0 }
        return max(0, Double(player.saves.orZero) * 0.35 - Double(player.goalsAgainst.orZero) * 2)
    }
}

extension StatPresentationBuilder {
    static func genericImpactPlayers(
        from players: [ScoredPlayerStat],
        columns: [StatTableColumnPresentation] = genericStatColumns,
        accentTone: SportsTheme.Tone = .scoring
    ) -> [StatHighlightPresentation] {
        let eligible = players.filter { $0.score > 0 }.sorted(by: sortScoredPlayers)
        guard let top = eligible.first, top.score >= 8 || eligible.count >= 2 else { return [] }
        return eligible.prefix(3).enumerated().map { index, scored in
            let cells = genericStatCells(for: scored.player, columns: columns)
            return StatHighlightPresentation(
                id: scored.player.id,
                rank: index + 1,
                title: scored.player.playerName,
                subtitle: scored.player.team,
                headline: genericHeadline(for: scored.player, columns: columns),
                stats: cells.prefix(3).map { $0 },
                accentTone: accentTone
            )
        }
    }

    static func baseballImpactHighlights(from batters: [ScoredBatter], pitchers: [ScoredPitcher]) -> [StatHighlightPresentation] {
        let batterCandidates = batters
            .filter { $0.score > 0 }
            .sorted(by: sortScoredBatters)
            .map { scored in
                (
                    StatHighlightPresentation(
                        id: scored.player.id,
                        rank: nil,
                        title: scored.player.playerName,
                        subtitle: [scored.player.team, scored.player.position].compactMap(\.self).joined(separator: " "),
                        headline: batterHeadline(for: scored.player),
                        stats: batterCells(for: scored.player).prefix(3).map { $0 },
                        accentTone: .scoring
                    ),
                    scored.score
                )
            }
        let pitcherCandidates = pitchers
            .filter { $0.score > 0 }
            .sorted(by: sortScoredPitchers)
            .map { scored in
                (
                    StatHighlightPresentation(
                        id: scored.player.id,
                        rank: nil,
                        title: scored.player.playerName,
                        subtitle: "\(scored.player.team) Pitcher",
                        headline: pitcherHeadline(for: scored.player),
                        stats: pitcherCells(for: scored.player).prefix(3).map { $0 },
                        accentTone: .defensivePitching
                    ),
                    scored.score
                )
            }
        return ranked(mergeHighlights(batterCandidates, pitcherCandidates))
    }

    static func hockeyImpactHighlights(from skaters: [ScoredNHLPlayer], goalies: [ScoredNHLPlayer]) -> [StatHighlightPresentation] {
        let skaterCandidates = skaters
            .filter { $0.score > 0 }
            .sorted(by: sortScoredNHLPlayers)
            .map { scored in
                (
                    StatHighlightPresentation(
                        id: "\(scored.player.id)-skater",
                        rank: nil,
                        title: scored.player.playerName,
                        subtitle: "\(scored.player.team) Skater",
                        headline: skaterHeadline(for: scored.player),
                        stats: skaterCells(for: scored.player).prefix(3).map { $0 },
                        accentTone: .scoring
                    ),
                    scored.score
                )
            }
        let goalieCandidates = goalies
            .filter { $0.score > 0 }
            .sorted(by: sortScoredNHLPlayers)
            .map { scored in
                (
                    StatHighlightPresentation(
                        id: "\(scored.player.id)-goalie",
                        rank: nil,
                        title: scored.player.playerName,
                        subtitle: "\(scored.player.team) Goalie",
                        headline: goalieHeadline(for: scored.player),
                        stats: goalieCells(for: scored.player).prefix(3).map { $0 },
                        accentTone: .defensivePitching
                    ),
                    scored.score
                )
            }
        return ranked(mergeHighlights(skaterCandidates, goalieCandidates))
    }
}
