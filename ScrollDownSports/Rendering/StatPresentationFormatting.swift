import SwiftUI

extension StatPresentationBuilder {
    static func genericHeadline(for player: PlayerStat) -> String {
        let points = statString(player.points)
        let rebounds = statString(player.rebounds)
        let assists = statString(player.assists)
        if points != nil || rebounds != nil || assists != nil {
            return [
                points.map { "\($0) pts" },
                rebounds.map { "\($0) reb" },
                assists.map { "\($0) ast" }
            ].compactMap(\.self).joined(separator: ", ")
        }
        if player.yards != nil || player.touchdowns != nil {
            return [
                statString(player.yards).map { "\($0) yds" },
                statString(player.touchdowns).map { "\($0) TD" }
            ].compactMap(\.self).joined(separator: ", ")
        }
        let rawParts = [
            rawString(["goals", "goal"], in: player.rawStats).map { "\($0) goals" },
            rawString(["assists", "ast"], in: player.rawStats).map { "\($0) assists" },
            rawString(["shots", "shotsOnGoal", "sog"], in: player.rawStats).map { "\($0) shots" },
            rawString(["saves", "sv"], in: player.rawStats).map { "\($0) saves" },
            rawString(["strikeOuts", "strikeouts", "so", "k"], in: player.rawStats).map { "\($0) K" },
            rawString(["rbi", "runsBattedIn"], in: player.rawStats).map { "\($0) RBI" }
        ].compactMap(\.self)
        return rawParts.prefix(3).joined(separator: ", ")
    }

    static func genericHeadline(
        for player: PlayerStat,
        columns: [StatTableColumnPresentation]
    ) -> String {
        let cells = genericStatCells(for: player, columns: columns)
        guard !cells.isEmpty else { return genericHeadline(for: player) }
        return cells.prefix(3).map { "\($0.value) \($0.label)" }.joined(separator: ", ")
    }

    static func batterHeadline(for player: MLBBatterStat) -> String {
        var parts: [String] = []
        if let hits = player.hits, let atBats = player.atBats {
            parts.append("\(hits)-for-\(atBats)")
        } else if let hits = player.hits {
            parts.append("\(hits) H")
        }
        if player.homeRuns.orZero > 0 {
            parts.append("\(player.homeRuns.orZero) HR")
        }
        if player.rbi.orZero > 0 {
            parts.append("\(player.rbi.orZero) RBI")
        }
        if parts.count < 3, player.runs.orZero > 0 {
            parts.append("\(player.runs.orZero) R")
        }
        return parts.prefix(3).joined(separator: ", ")
    }

    static func pitcherHeadline(for player: MLBPitcherStat) -> String {
        [
            player.inningsPitched.map { "\($0) IP" },
            player.strikeOuts.map { "\($0) K" },
            player.earnedRuns.map { "\($0) ER" } ?? player.hits.map { "\($0) H" }
        ].compactMap(\.self).prefix(3).joined(separator: ", ")
    }

    static func skaterHeadline(for player: NHLPlayerStat) -> String {
        if player.goals.orZero > 0, player.assists.orZero > 0 {
            return "\(player.goals.orZero) G, \(player.assists.orZero) A, \(player.shotsOnGoal.orZero) SOG"
        }
        if player.goals.orZero > 0 {
            return "\(player.goals.orZero) goals, \(player.shotsOnGoal.orZero) shots"
        }
        if player.assists.orZero > 0 {
            return "\(player.assists.orZero) assists, \(player.points.orZero) pts"
        }
        return "\(player.shotsOnGoal.orZero) shots"
    }

    static func goalieHeadline(for player: NHLPlayerStat) -> String {
        if let saves = player.saves, let goalsAgainst = player.goalsAgainst {
            return "\(saves) saves, \(goalsAgainst) GA"
        }
        return "\(player.saves.orZero) saves"
    }
}

extension StatPresentationBuilder {
    static func batterCells(for player: MLBBatterStat) -> [StatPillPresentation] {
        [
            ("HR", player.homeRuns), ("RBI", player.rbi), ("H", player.hits), ("R", player.runs)
        ].compactMap { label, value in
            guard let value, value > 0 else { return nil }
            return StatPillPresentation(label: label, value: "\(value)")
        }
    }

    static func pitcherCells(for player: MLBPitcherStat) -> [StatPillPresentation] {
        [
            ("IP", player.inningsPitched),
            ("K", player.strikeOuts.map(String.init)),
            ("ER", player.earnedRuns.map(String.init))
        ].compactMap { label, value in
            guard let value, !value.isEmpty else { return nil }
            return StatPillPresentation(label: label, value: value)
        }
    }

    static func skaterCells(for player: NHLPlayerStat) -> [StatPillPresentation] {
        [
            ("G", player.goals), ("A", player.assists), ("PTS", player.points), ("SOG", player.shotsOnGoal)
        ].compactMap { label, value in
            guard let value, value > 0 else { return nil }
            return StatPillPresentation(label: label, value: "\(value)")
        }
    }

    static func goalieCells(for player: NHLPlayerStat) -> [StatPillPresentation] {
        [
            ("SV", player.saves), ("GA", player.goalsAgainst)
        ].compactMap { label, value in
            guard let value else { return nil }
            return StatPillPresentation(label: label, value: "\(value)")
        }
    }
}

extension StatPresentationBuilder {
    static func mergeHighlights(
        _ first: [(StatHighlightPresentation, Double)],
        _ second: [(StatHighlightPresentation, Double)]
    ) -> [(StatHighlightPresentation, Double)] {
        (first + second)
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.title < rhs.0.title
            }
            .prefix(3)
            .map { $0 }
    }

    static func includeDiverseHighlight(
        _ selected: inout [(StatHighlightPresentation, Double)],
        candidate: StatHighlightPresentation?,
        score: Double
    ) {
        guard let candidate, score >= 6, !selected.contains(where: { $0.0.id == candidate.id }) else { return }
        replaceLast(&selected, with: (candidate, score))
    }

    static func replaceLast(
        _ selected: inout [(StatHighlightPresentation, Double)],
        with candidate: (StatHighlightPresentation, Double)
    ) {
        if selected.count < 3 {
            selected.append(candidate)
        } else if !selected.isEmpty {
            selected[selected.count - 1] = candidate
        }
        selected.sort { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0.title < rhs.0.title
        }
    }

    static func ranked(_ selected: [(StatHighlightPresentation, Double)]) -> [StatHighlightPresentation] {
        selected.prefix(3).enumerated().map { index, pair in
            StatHighlightPresentation(
                id: pair.0.id,
                rank: index + 1,
                title: pair.0.title,
                subtitle: pair.0.subtitle,
                headline: pair.0.headline,
                stats: pair.0.stats,
                accentTone: pair.0.accentTone
            )
        }
    }
}

extension StatPresentationBuilder {
    static func scoreForBatter(id: String, in batters: [ScoredBatter]) -> Double {
        batters.first(where: { $0.player.id == id })?.score ?? 0
    }

    static func scoreForPitcher(id: String, in pitchers: [ScoredPitcher]) -> Double {
        pitchers.first(where: { $0.player.id == id })?.score ?? 0
    }

    static func scoreForNHL(id: String, in players: [ScoredNHLPlayer], suffix: String) -> Double {
        let playerID = String(id.dropLast(suffix.count))
        return players.first(where: { $0.player.id == playerID })?.score ?? 0
    }

    static func tableColumn(
        _ id: String,
        _ label: String,
        width: CGFloat = 40,
        alignment: StatTableColumnAlignment = .trailing
    ) -> StatTableColumnPresentation {
        StatTableColumnPresentation(id: id, label: label, width: width, alignment: alignment)
    }

    static func compactTeamItems(_ team: TeamStat) -> [(key: String, label: String, value: String)] {
        if let normalized = team.normalizedStats, !normalized.isEmpty {
            return normalized.compactMap { stat in
                guard let value = stat.value?.displayString, !value.isEmpty, value != "-" else { return nil }
                return (stat.key, stat.displayLabel, value)
            }
        }

        return team.stats
            .sorted { $0.key < $1.key }
            .compactMap { key, value in
                let display = value.displayString
                guard !display.isEmpty, display != "-" else { return nil }
                return (key, key.camelTitle, display)
            }
    }
}

extension StatPresentationBuilder {
    static func rawString(_ keys: [String], in rawStats: [String: JSONValue]) -> String? {
        for key in keys {
            guard let value = rawStats[key]?.displayString, !value.isEmpty, value != "-" else { continue }
            return value
        }
        return nil
    }

    static func rawDouble(_ keys: [String], in rawStats: [String: JSONValue]) -> Double {
        for key in keys {
            guard let value = rawStats[key] else { continue }
            if let number = value.numberValue {
                return number
            }
            if case .string(let string) = value, let number = Double(string) {
                return number
            }
        }
        return 0
    }

    static func statString(_ value: Int?) -> String {
        value.map(String.init) ?? "-"
    }

    static func statString(_ value: Double?) -> String? {
        guard let value else { return nil }
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    static func savePercentage(for player: NHLPlayerStat) -> String {
        guard let saves = player.saves, let goalsAgainst = player.goalsAgainst else { return "-" }
        let shotsAgainst = saves + goalsAgainst
        guard shotsAgainst > 0 else { return "-" }
        return String(format: "%.3f", Double(saves) / Double(shotsAgainst)).replacingOccurrences(of: "0.", with: ".")
    }
}

extension StatPresentationBuilder {
    static func sortScoredPlayers(_ lhs: ScoredPlayerStat, _ rhs: ScoredPlayerStat) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        return lhs.player.playerName < rhs.player.playerName
    }

    static func sortScoredBatters(_ lhs: ScoredBatter, _ rhs: ScoredBatter) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        return lhs.player.playerName < rhs.player.playerName
    }

    static func sortScoredPitchers(_ lhs: ScoredPitcher, _ rhs: ScoredPitcher) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        return lhs.player.playerName < rhs.player.playerName
    }

    static func sortScoredNHLPlayers(_ lhs: ScoredNHLPlayer, _ rhs: ScoredNHLPlayer) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        return lhs.player.playerName < rhs.player.playerName
    }
}

extension Optional where Wrapped == Double {
    var orZero: Double { self ?? 0 }
}

extension Optional where Wrapped == Int {
    var orZero: Int { self ?? 0 }
}

extension String {
    var camelTitle: String {
        replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}
