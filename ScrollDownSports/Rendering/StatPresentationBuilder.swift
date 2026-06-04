import SwiftUI

enum StatPresentationBuilder {
    static func genericPlayerSections(for detail: GameDetail, sport: Sport = .other("generic")) -> [StatSectionPresentation] {
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

        if sport == .mlb, let sections = genericBaseballPlayerSections(for: detail.playerStats) {
            return sections
        }
        if sport == .nhl, let sections = genericHockeyPlayerSections(for: detail.playerStats) {
            return sections
        }

        let statColumns = genericStatColumns(for: sport)
        let scoredPlayers = detail.playerStats.map { ScoredPlayerStat(player: $0, score: genericImpactScore($0, columns: statColumns)) }
        let impactHighlights = genericImpactPlayers(from: scoredPlayers, columns: statColumns)
        let teamAbbreviations = teamAbbreviations(for: detail)
        var sections: [StatSectionPresentation] = []
        if !impactHighlights.isEmpty {
            sections.append(
                StatSectionPresentation(
                    id: "player-impact",
                    title: nil,
                    highlights: impactHighlights,
                    cards: [],
                    tables: [],
                    emptyMessage: nil
                )
            )
        }
        sections.append(
            StatSectionPresentation(
                id: "player-stats-by-team",
                title: "By Team",
                highlights: [],
                cards: [],
                tables: genericPlayerTablesByTeam(from: scoredPlayers, statColumns: statColumns, teamAbbreviations: teamAbbreviations),
                emptyMessage: nil
            )
        )
        return sections
    }

    static func baseballPlayerSections(for detail: GameDetail) -> [StatSectionPresentation] {
        let batters = detail.mlbBatters ?? []
        let pitchers = detail.mlbPitchers ?? []
        guard !batters.isEmpty || !pitchers.isEmpty else {
            return genericPlayerSections(for: detail, sport: .mlb)
        }

        let scoredBatters = batters.map { ScoredBatter(player: $0, score: batterImpactScore($0)) }
        let scoredPitchers = pitchers.map { ScoredPitcher(player: $0, score: pitcherImpactScore($0)) }
        let teamAbbreviations = teamAbbreviations(for: detail)
        var sections: [StatSectionPresentation] = []
        let impactHighlights = baseballImpactHighlights(from: scoredBatters, pitchers: scoredPitchers)
        if !impactHighlights.isEmpty {
            sections.append(
                StatSectionPresentation(
                    id: "baseball-impact",
                    title: nil,
                    highlights: impactHighlights,
                    cards: [],
                    tables: [],
                    emptyMessage: nil
                )
            )
        }
        if !scoredBatters.isEmpty {
            sections.append(
                StatSectionPresentation(
                    id: "baseball-batter-stats",
                    title: "Batters",
                    highlights: [],
                    cards: [],
                    tables: baseballBatterTablesByTeam(from: scoredBatters, teamAbbreviations: teamAbbreviations),
                    emptyMessage: nil
                )
            )
        }
        if !scoredPitchers.isEmpty {
            sections.append(
                StatSectionPresentation(
                    id: "baseball-pitcher-stats",
                    title: "Pitchers",
                    highlights: [],
                    cards: [],
                    tables: baseballPitcherTablesByTeam(from: scoredPitchers, teamAbbreviations: teamAbbreviations),
                    emptyMessage: nil
                )
            )
        }

        return sections
    }

    private static func genericBaseballPlayerSections(for players: [PlayerStat]) -> [StatSectionPresentation]? {
        let pitcherColumns = columns(["ip", "h", "r", "er", "bb", "k", "hr"])
        let hitterColumns = columns(["h", "r", "rbi", "hr", "bb", "k"])
        let pitchers = players.filter { genericPlayer($0, hasAnyValueIn: columns(["ip", "er"])) }
        let pitcherIDs = Set(pitchers.map(\.id))
        let hitters = players.filter { !pitcherIDs.contains($0.id) && genericPlayer($0, hasAnyValueIn: hitterColumns) }

        guard !pitchers.isEmpty || !hitters.isEmpty else { return nil }

        let scoredHitters = hitters.map { ScoredPlayerStat(player: $0, score: genericImpactScore($0, columns: hitterColumns)) }
        let scoredPitchers = pitchers.map { ScoredPlayerStat(player: $0, score: genericImpactScore($0, columns: pitcherColumns)) }
        var sections: [StatSectionPresentation] = []
        let impactHighlights = genericImpactPlayers(
            from: scoredHitters + scoredPitchers,
            columns: uniqueColumns(hitterColumns + pitcherColumns)
        )
        if !impactHighlights.isEmpty {
            sections.append(
                StatSectionPresentation(
                    id: "baseball-generic-impact",
                    title: nil,
                    highlights: impactHighlights,
                    cards: [],
                    tables: [],
                    emptyMessage: nil
                )
            )
        }
        if !hitters.isEmpty {
            sections.append(
                genericSplitSection(
                    id: "baseball-hitter-stats",
                    title: "Hitters",
                    tableID: "baseball-generic-hitters",
                    tableTitle: "Hitters",
                    players: scoredHitters,
                    columns: hitterColumns,
                    accentTone: .scoring
                )
            )
        }
        if !pitchers.isEmpty {
            sections.append(
                genericSplitSection(
                    id: "baseball-pitcher-stats",
                    title: "Pitchers",
                    tableID: "baseball-generic-pitchers",
                    tableTitle: "Pitchers",
                    players: scoredPitchers,
                    columns: pitcherColumns,
                    accentTone: .defensivePitching
                )
            )
        }
        return sections
    }

    private static func genericHockeyPlayerSections(for players: [PlayerStat]) -> [StatSectionPresentation]? {
        let goalieColumns = columns(["sv", "ga"])
        let skaterColumns = columns(["g", "a", "pts", "sog"])
        let goalies = players.filter { genericPlayer($0, hasAnyValueIn: goalieColumns) }
        let goalieIDs = Set(goalies.map(\.id))
        let skaters = players.filter { !goalieIDs.contains($0.id) && genericPlayer($0, hasAnyValueIn: skaterColumns) }

        guard !goalies.isEmpty || !skaters.isEmpty else { return nil }

        let scoredSkaters = skaters.map { ScoredPlayerStat(player: $0, score: genericImpactScore($0, columns: skaterColumns)) }
        let scoredGoalies = goalies.map { ScoredPlayerStat(player: $0, score: genericImpactScore($0, columns: goalieColumns)) }
        var sections: [StatSectionPresentation] = []
        let impactHighlights = genericImpactPlayers(
            from: scoredSkaters + scoredGoalies,
            columns: uniqueColumns(skaterColumns + goalieColumns)
        )
        if !impactHighlights.isEmpty {
            sections.append(
                StatSectionPresentation(
                    id: "hockey-generic-impact",
                    title: nil,
                    highlights: impactHighlights,
                    cards: [],
                    tables: [],
                    emptyMessage: nil
                )
            )
        }
        if !skaters.isEmpty {
            sections.append(
                genericSplitSection(
                    id: "hockey-skater-stats",
                    title: "Skaters",
                    tableID: "hockey-generic-skaters",
                    tableTitle: "Skaters",
                    players: scoredSkaters,
                    columns: skaterColumns,
                    accentTone: .scoring
                )
            )
        }
        if !goalies.isEmpty {
            sections.append(
                genericSplitSection(
                    id: "hockey-goalie-stats",
                    title: "Goalies",
                    tableID: "hockey-generic-goalies",
                    tableTitle: "Goalies",
                    players: scoredGoalies,
                    columns: goalieColumns,
                    accentTone: .defensivePitching
                )
            )
        }
        return sections
    }

    private static func genericSplitSection(
        id: String,
        title: String,
        tableID: String,
        tableTitle: String,
        players: [ScoredPlayerStat],
        columns: [StatTableColumnPresentation],
        accentTone: SportsTheme.Tone
    ) -> StatSectionPresentation {
        StatSectionPresentation(
            id: id,
            title: title,
            highlights: [],
            cards: [],
            tables: genericPlayerTablesByTeam(
                from: players,
                statColumns: columns,
                tableIDPrefix: tableID,
                titleSuffix: tableTitle
            ),
            emptyMessage: nil
        )
    }

    private static func genericPlayer(
        _ player: PlayerStat,
        hasAnyValueIn columns: [StatTableColumnPresentation]
    ) -> Bool {
        columns.contains { genericValue($0.id, for: player) != nil }
    }

    private static func columns(_ ids: [String]) -> [StatTableColumnPresentation] {
        ids.compactMap { id in
            genericStatColumns.first { $0.id == id }
        }
    }

    private static func uniqueColumns(_ columns: [StatTableColumnPresentation]) -> [StatTableColumnPresentation] {
        var seen: Set<String> = []
        return columns.filter { column in
            guard !seen.contains(column.id) else { return false }
            seen.insert(column.id)
            return true
        }
    }

    static func hockeyPlayerSections(for detail: GameDetail) -> [StatSectionPresentation] {
        let skaters = detail.nhlSkaters ?? []
        let goalies = detail.nhlGoalies ?? []
        guard !skaters.isEmpty || !goalies.isEmpty else {
            return genericPlayerSections(for: detail, sport: .nhl)
        }

        let scoredSkaters = skaters.map { ScoredNHLPlayer(player: $0, role: "Skater", score: skaterImpactScore($0)) }
        let scoredGoalies = goalies.map { ScoredNHLPlayer(player: $0, role: "Goalie", score: goalieImpactScore($0)) }
        let teamAbbreviations = teamAbbreviations(for: detail)
        var sections: [StatSectionPresentation] = []
        let impactHighlights = hockeyImpactHighlights(from: scoredSkaters, goalies: scoredGoalies)
        if !impactHighlights.isEmpty {
            sections.append(
                StatSectionPresentation(
                    id: "hockey-impact",
                    title: nil,
                    highlights: impactHighlights,
                    cards: [],
                    tables: [],
                    emptyMessage: nil
                )
            )
        }
        if !scoredSkaters.isEmpty {
            sections.append(
                StatSectionPresentation(
                    id: "hockey-skater-stats",
                    title: "Skaters",
                    highlights: [],
                    cards: [],
                    tables: hockeySkaterTablesByTeam(from: scoredSkaters, teamAbbreviations: teamAbbreviations),
                    emptyMessage: nil
                )
            )
        }
        if !scoredGoalies.isEmpty {
            sections.append(
                StatSectionPresentation(
                    id: "hockey-goalie-stats",
                    title: "Goalies",
                    highlights: [],
                    cards: [],
                    tables: hockeyGoalieTablesByTeam(from: scoredGoalies, teamAbbreviations: teamAbbreviations),
                    emptyMessage: nil
                )
            )
        }

        return sections
    }

    static func teamStatSection(for detail: GameDetail) -> StatSectionPresentation {
        teamStatSectionWithComparison(for: detail)
    }

    static func teamComparison(for detail: GameDetail) -> StatComparisonPresentation? {
        teamComparison(for: detail.teamStats)
    }

    static func teamComparison(for teams: [TeamStat]) -> StatComparisonPresentation? {
        let teamItems = teams.map { ($0, compactTeamItems($0)) }
        guard teamItems.count >= 2 else { return nil }

        let statKeys = Array(teamItems.flatMap(\.1).reduce(into: [String]()) { keys, item in
            guard !keys.contains(item.key) else { return }
            keys.append(item.key)
        }.prefix(8))
        guard !statKeys.isEmpty else { return nil }

        let columns = teamItems.enumerated().map { index, pair in
            let team = pair.0
            return StatComparisonColumnPresentation(
                id: "\(team.id)-\(index)",
                title: teamCode(for: team.team, explicit: team.teamAbbreviation),
                subtitle: team.isHome ? "Home" : "Away"
            )
        }
        let rows = statKeys.map { key in
            let label = teamItems.flatMap(\.1).first(where: { $0.key == key })?.label ?? key.camelTitle
            let values = Dictionary(uniqueKeysWithValues: teamItems.enumerated().map { index, pair in
                let columnID = "\(pair.0.id)-\(index)"
                let value = pair.1.first(where: { $0.key == key })?.value ?? "-"
                return (columnID, value)
            })
            return StatComparisonRowPresentation(id: key, label: label, values: values)
        }

        return StatComparisonPresentation(
            id: "team-comparison",
            title: "Team Comparison",
            columns: columns,
            rows: rows
        )
    }

    static func teamStatSectionWithComparison(for detail: GameDetail) -> StatSectionPresentation {
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
            highlights: [],
            comparison: teamComparison(for: detail),
            cards: [],
            tables: [],
            emptyMessage: nil
        )
    }

    static func teamAbbreviations(for detail: GameDetail) -> [String: String] {
        Dictionary(uniqueKeysWithValues: detail.game.participants.map { participant in
            let abbreviation = participant.abbreviation ?? String(participant.name.prefix(3)).uppercased()
            return (participant.name, abbreviation)
        })
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
