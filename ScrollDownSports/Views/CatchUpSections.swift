import SwiftUI

struct PlayByPlaySection: View {
    let plays: [PlayEntry]

    var body: some View {
        CatchUpSection(title: "Play by Play", systemImage: "arrow.down.doc") {
            if plays.isEmpty {
                UnavailableText("No play-by-play data yet.")
            } else {
                ForEach(groupedPeriods, id: \.period) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.period)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)

                        ForEach(group.plays) { play in
                            PlayRow(play: play)
                        }
                    }
                }
            }
        }
    }

    private var groupedPeriods: [(period: String, plays: [PlayEntry])] {
        let unique = Dictionary(grouping: plays) { play in
            "\(play.periodLabel ?? "")|\(play.gameClock ?? "")|\(play.description ?? "")"
        }
        .compactMap { $0.value.first }

        let grouped = Dictionary(grouping: unique) { play in
            play.periodLabel ?? "Game"
        }

        return grouped
            .map { period, plays in
                (
                    period: period,
                    plays: plays.sorted {
                        if $0.playIndex != $1.playIndex {
                            return $0.playIndex < $1.playIndex
                        }
                        return $0.clockText < $1.clockText
                    }
                )
            }
            .sorted { left, right in
                (left.plays.first?.playIndex ?? 0) < (right.plays.first?.playIndex ?? 0)
            }
    }
}

private struct PlayRow: View {
    let play: PlayEntry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 4) {
                Circle()
                    .fill(play.scoreChanged == true ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 1)
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 4) {
                if !play.clockText.isEmpty {
                    Text(play.clockText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text(play.description ?? play.playType ?? "Play update")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                if let team = play.teamAbbreviation {
                    Text(team)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
            }
            .padding(.bottom, 12)
        }
    }
}

struct PlayerStatsSection: View {
    let detail: GameDetailResponse

    var body: some View {
        CatchUpSection(title: "Player Stats", systemImage: "person.3") {
            if detail.leagueCode == "mlb", hasMLBStats {
                MLBPlayerStats(detail: detail)
            } else if let nhlSkaters = detail.nhlSkaters, !nhlSkaters.isEmpty {
                NHLStats(title: "Skaters", players: nhlSkaters)
                if let goalies = detail.nhlGoalies, !goalies.isEmpty {
                    NHLStats(title: "Goalies", players: goalies)
                }
            } else if detail.playerStats.isEmpty {
                UnavailableText("No player stats available yet.")
            } else {
                GenericPlayerStats(players: detail.playerStats)
            }
        }
    }

    private var hasMLBStats: Bool {
        !(detail.mlbBatters ?? []).isEmpty || !(detail.mlbPitchers ?? []).isEmpty
    }
}

private struct GenericPlayerStats: View {
    let players: [PlayerStat]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(players.prefix(80)) { player in
                StatCard(title: player.playerName, subtitle: player.team) {
                    StatPills(items: genericItems(for: player))
                }
            }
        }
    }

    private func genericItems(for player: PlayerStat) -> [(String, String)] {
        var items: [(String, String)] = []
        append("MIN", player.minutes, to: &items)
        append("PTS", player.points, to: &items)
        append("REB", player.rebounds, to: &items)
        append("AST", player.assists, to: &items)
        append("YDS", player.yards, to: &items)
        append("TD", player.touchdowns, to: &items)

        if items.isEmpty {
            for key in ["goals", "assists", "points", "shots", "hits", "saves", "strikeOuts", "rbi"] {
                if let value = player.rawStats[key]?.displayString, !value.isEmpty {
                    items.append((key.camelTitle, value))
                }
            }
        }
        return items
    }

    private func append(_ label: String, _ value: Double?, to items: inout [(String, String)]) {
        guard let value else { return }
        if value.rounded() == value {
            items.append((label, String(Int(value))))
        } else {
            items.append((label, String(format: "%.1f", value)))
        }
    }
}

private struct MLBPlayerStats: View {
    let detail: GameDetailResponse

    var body: some View {
        VStack(spacing: 10) {
            ForEach(detail.mlbBatters ?? []) { player in
                StatCard(title: player.playerName, subtitle: "\(player.team) Batter") {
                    StatPills(items: [
                        ("AB", player.atBats?.description),
                        ("H", player.hits?.description),
                        ("R", player.runs?.description),
                        ("RBI", player.rbi?.description),
                        ("HR", player.homeRuns?.description),
                        ("BB", player.baseOnBalls?.description),
                        ("K", player.strikeOuts?.description)
                    ].compactMap { label, value in value.map { (label, $0) } })
                }
            }

            ForEach(detail.mlbPitchers ?? []) { player in
                StatCard(title: player.playerName, subtitle: "\(player.team) Pitcher") {
                    StatPills(items: [
                        ("IP", player.inningsPitched),
                        ("H", player.hits?.description),
                        ("R", player.runs?.description),
                        ("ER", player.earnedRuns?.description),
                        ("BB", player.baseOnBalls?.description),
                        ("K", player.strikeOuts?.description),
                        ("HR", player.homeRuns?.description)
                    ].compactMap { label, value in value.map { (label, $0) } })
                }
            }
        }
    }
}

private struct NHLStats: View {
    let title: String
    let players: [NHLPlayerStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            ForEach(players) { player in
                StatCard(title: player.playerName, subtitle: player.team) {
                    StatPills(items: [
                        ("G", player.goals?.description),
                        ("A", player.assists?.description),
                        ("PTS", player.points?.description),
                        ("SOG", player.shotsOnGoal?.description),
                        ("SV", player.saves?.description),
                        ("GA", player.goalsAgainst?.description)
                    ].compactMap { label, value in value.map { (label, $0) } })
                }
            }
        }
    }
}

struct TeamStatsSection: View {
    let detail: GameDetailResponse

    var body: some View {
        CatchUpSection(title: "Team Stats", systemImage: "chart.bar.xaxis") {
            if detail.teamStats.count < 2 {
                UnavailableText("No team stats available yet.")
            } else {
                ForEach(detail.teamStats) { team in
                    StatCard(title: team.team, subtitle: team.isHome ? "Home" : "Away") {
                        StatPills(items: teamItems(team).prefix(16).map { $0 })
                    }
                }
            }
        }
    }

    private func teamItems(_ team: TeamStat) -> [(String, String)] {
        if let normalized = team.normalizedStats, !normalized.isEmpty {
            return normalized.compactMap { stat in
                guard let value = stat.value?.displayString, !value.isEmpty else { return nil }
                return (stat.displayLabel, value)
            }
        }

        return team.stats
            .sorted { $0.key < $1.key }
            .compactMap { key, value in
                let display = value.displayString
                guard !display.isEmpty, display != "-" else { return nil }
                return (key.camelTitle, display)
            }
    }
}

struct BoxScoreSection: View {
    let game: Game

    var body: some View {
        CatchUpSection(title: "Box Score", systemImage: "number.square") {
            VStack(spacing: 12) {
                ScoreRow(
                    team: game.awayTeam,
                    abbreviation: game.awayTeamAbbr,
                    score: game.resolvedAwayScore
                )
                Divider()
                ScoreRow(
                    team: game.homeTeam,
                    abbreviation: game.homeTeamAbbr,
                    score: game.resolvedHomeScore
                )

                if game.isLiveGame {
                    Text([game.currentPeriodLabel, game.gameClock].compactMap { $0 }.joined(separator: " "))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else if game.isFinalGame {
                    Text("Final")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct ScoreRow: View {
    let team: String
    let abbreviation: String?
    let score: Int?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(abbreviation ?? team)
                    .font(.headline)
                Text(team)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(score.map(String.init) ?? "-")
                .font(.largeTitle.weight(.bold))
                .monospacedDigit()
        }
    }
}

private struct CatchUpSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.bold))
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StatCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            content
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct StatPills: View {
    let items: [(String, String)]

    var body: some View {
        if items.isEmpty {
            UnavailableText("Stats unavailable.")
        } else {
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.0) { label, value in
                    VStack(spacing: 2) {
                        Text(value)
                            .font(.subheadline.weight(.bold))
                        Text(label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

private struct UnavailableText: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private extension GameDetailResponse {
    var leagueCode: String {
        game.leagueCode.lowercased()
    }
}

private extension String {
    var camelTitle: String {
        replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

