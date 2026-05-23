import SwiftUI

enum StatPresentationBuilder {
    static func genericPlayerSections(for detail: GameDetail) -> [StatSectionPresentation] {
        guard !detail.playerStats.isEmpty else {
            return [
                StatSectionPresentation(
                    id: "player-stats-empty",
                    title: nil,
                    cards: [],
                    emptyMessage: "No player stats available yet."
                )
            ]
        }

        let scoredPlayers = detail.playerStats.map { ScoredPlayerStat(player: $0, score: genericImpactScore($0)) }
        return [
            StatSectionPresentation(
                id: "player-stats",
                title: nil,
                highlights: genericImpactPlayers(from: scoredPlayers),
                cards: [],
                tables: [genericPlayerTable(from: scoredPlayers)],
                emptyMessage: nil
            )
        ]
    }

    static func baseballPlayerSections(for detail: GameDetail) -> [StatSectionPresentation] {
        let batters = detail.mlbBatters ?? []
        let pitchers = detail.mlbPitchers ?? []
        guard !batters.isEmpty || !pitchers.isEmpty else {
            return genericPlayerSections(for: detail)
        }

        let scoredBatters = batters.map { ScoredBatter(player: $0, score: batterImpactScore($0)) }
        let scoredPitchers = pitchers.map { ScoredPitcher(player: $0, score: pitcherImpactScore($0)) }
        var tables: [StatTablePresentation] = []
        if !scoredBatters.isEmpty {
            tables.append(baseballBatterTable(from: scoredBatters))
        }
        if !scoredPitchers.isEmpty {
            tables.append(baseballPitcherTable(from: scoredPitchers))
        }

        return [
            StatSectionPresentation(
                id: "baseball-player-stats",
                title: nil,
                highlights: baseballImpactPlayers(batters: scoredBatters, pitchers: scoredPitchers),
                cards: [],
                tables: tables,
                emptyMessage: nil
            )
        ]
    }

    static func hockeyPlayerSections(for detail: GameDetail) -> [StatSectionPresentation] {
        let skaters = detail.nhlSkaters ?? []
        let goalies = detail.nhlGoalies ?? []
        guard !skaters.isEmpty || !goalies.isEmpty else {
            return genericPlayerSections(for: detail)
        }

        let scoredSkaters = skaters.map { ScoredNHLPlayer(player: $0, role: "Skater", score: skaterImpactScore($0)) }
        let scoredGoalies = goalies.map { ScoredNHLPlayer(player: $0, role: "Goalie", score: goalieImpactScore($0)) }
        var tables: [StatTablePresentation] = []
        if !scoredSkaters.isEmpty {
            tables.append(hockeySkaterTable(from: scoredSkaters))
        }
        if !scoredGoalies.isEmpty {
            tables.append(hockeyGoalieTable(from: scoredGoalies))
        }

        return [
            StatSectionPresentation(
                id: "hockey-player-stats",
                title: nil,
                highlights: hockeyImpactPlayers(skaters: scoredSkaters, goalies: scoredGoalies),
                cards: [],
                tables: tables,
                emptyMessage: nil
            )
        ]
    }

    static func teamStatSection(for detail: GameDetail) -> StatSectionPresentation {
        guard detail.teamStats.count >= 2 else {
            return StatSectionPresentation(
                id: "team-stats-empty",
                title: nil,
                cards: [],
                emptyMessage: "No team stats available yet."
            )
        }

        return StatSectionPresentation(
            id: "team-stats",
            title: nil,
            highlights: detail.teamStats.map(teamHighlight),
            cards: [],
            tables: [teamStatTable(for: detail.teamStats)],
            emptyMessage: nil
        )
    }

    static func outs(from inningsPitched: String?) -> Int {
        guard let inningsPitched = inningsPitched?.trimmingCharacters(in: .whitespacesAndNewlines),
              !inningsPitched.isEmpty else {
            return 0
        }
        let parts = inningsPitched.split(separator: ".", omittingEmptySubsequences: false)
        guard let wholeInnings = Int(parts.first ?? "") else { return 0 }
        let partialOuts: Int
        if parts.count > 1, let fraction = parts.last, let outs = Int(fraction) {
            partialOuts = (0...2).contains(outs) ? outs : 0
        } else {
            partialOuts = 0
        }
        return wholeInnings * 3 + partialOuts
    }
}

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
    static func genericImpactScore(_ player: PlayerStat) -> Double {
        player.points.orZero
            + player.rebounds.orZero * 0.7
            + player.assists.orZero * 0.8
            + player.yards.orZero * 0.04
            + player.touchdowns.orZero * 6
            + rawDouble(["goals", "goal"], in: player.rawStats) * 3
            + rawDouble(["assists", "ast"], in: player.rawStats) * 1.5
            + rawDouble(["shots", "shotsOnGoal", "sog"], in: player.rawStats) * 0.25
            + rawDouble(["saves", "sv"], in: player.rawStats) * 0.2
            + rawDouble(["strikeOuts", "strikeouts", "so", "k"], in: player.rawStats) * 0.7
            + rawDouble(["rbi", "runsBattedIn"], in: player.rawStats) * 1.2
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
    static func genericImpactPlayers(from players: [ScoredPlayerStat]) -> [StatHighlightPresentation] {
        let eligible = players.filter { $0.score > 0 }.sorted(by: sortScoredPlayers)
        guard let top = eligible.first, top.score >= 8 || eligible.count >= 2 else { return [] }
        return eligible.prefix(4).enumerated().map { index, scored in
            StatHighlightPresentation(
                id: scored.player.id,
                rank: index + 1,
                title: scored.player.playerName,
                subtitle: scored.player.team,
                headline: genericHeadline(for: scored.player),
                stats: genericStatCells(for: scored.player).prefix(3).map { $0 },
                accentTone: .scoring
            )
        }
    }

    static func baseballImpactPlayers(
        batters: [ScoredBatter],
        pitchers: [ScoredPitcher]
    ) -> [StatHighlightPresentation] {
        let sortedBatters = batters.filter { $0.score > 0 }.sorted(by: sortScoredBatters)
        let sortedPitchers = pitchers.filter { $0.score > 0 }.sorted(by: sortScoredPitchers)
        let batterHighlights = sortedBatters.map { scored in
            StatHighlightPresentation(
                id: scored.player.id,
                rank: nil,
                title: scored.player.playerName,
                subtitle: [scored.player.team, scored.player.position].compactMap(\.self).joined(separator: " "),
                headline: batterHeadline(for: scored.player),
                stats: batterCells(for: scored.player).prefix(3).map { $0 },
                accentTone: .scoring
            )
        }
        let pitcherHighlights = sortedPitchers.map { scored in
            StatHighlightPresentation(
                id: scored.player.id,
                rank: nil,
                title: scored.player.playerName,
                subtitle: "\(scored.player.team) Pitcher",
                headline: pitcherHeadline(for: scored.player),
                stats: pitcherCells(for: scored.player).prefix(3).map { $0 },
                accentTone: .defensivePitching
            )
        }

        var selected = mergeHighlights(
            batterHighlights.map { ($0, scoreForBatter(id: $0.id, in: sortedBatters)) },
            pitcherHighlights.map { ($0, scoreForPitcher(id: $0.id, in: sortedPitchers)) }
        )
        includeDiverseHighlight(&selected, candidate: pitcherHighlights.first, score: sortedPitchers.first?.score ?? 0)
        includeDiverseHighlight(&selected, candidate: batterHighlights.first, score: sortedBatters.first?.score ?? 0)
        return ranked(selected)
    }

    static func hockeyImpactPlayers(
        skaters: [ScoredNHLPlayer],
        goalies: [ScoredNHLPlayer]
    ) -> [StatHighlightPresentation] {
        let skaterHighlights = skaters.filter { $0.score > 0 }.sorted(by: sortScoredNHLPlayers).map { scored in
            StatHighlightPresentation(
                id: "\(scored.player.id)-skater",
                rank: nil,
                title: scored.player.playerName,
                subtitle: "\(scored.player.team) Skater",
                headline: skaterHeadline(for: scored.player),
                stats: skaterCells(for: scored.player).prefix(3).map { $0 },
                accentTone: .scoring
            )
        }
        let goalieHighlights = goalies.filter { $0.score > 0 }.sorted(by: sortScoredNHLPlayers).map { scored in
            StatHighlightPresentation(
                id: "\(scored.player.id)-goalie",
                rank: nil,
                title: scored.player.playerName,
                subtitle: "\(scored.player.team) Goalie",
                headline: goalieHeadline(for: scored.player),
                stats: goalieCells(for: scored.player).prefix(3).map { $0 },
                accentTone: .defensivePitching
            )
        }

        var selected = mergeHighlights(
            skaterHighlights.map { ($0, scoreForNHL(id: $0.id, in: skaters, suffix: "-skater")) },
            goalieHighlights.map { ($0, scoreForNHL(id: $0.id, in: goalies, suffix: "-goalie")) }
        )
        if selected.allSatisfy({ !$0.0.id.hasSuffix("-goalie") }),
           let goalie = goalieHighlights.first,
           let bestGoalie = goalies.sorted(by: sortScoredNHLPlayers).first,
           bestGoalie.score >= 6 {
            replaceLast(&selected, with: (goalie, bestGoalie.score))
        }
        return ranked(selected)
    }
}
