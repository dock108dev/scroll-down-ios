import SwiftUI

struct PlayByPlaySection: View {
    let plays: [PlayEntry]
    @State private var showP2 = false
    @State private var showP3 = false
    @State private var configuredSignature = ""

    var body: some View {
        CatchUpSection(title: "Key Moments", systemImage: "sparkles") {
            if plays.isEmpty {
                UnavailableText("No play-by-play data yet.")
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    priorityControls

                    if visiblePlays.isEmpty {
                        UnavailableText("No plays in the selected priority bands.")
                    } else {
                        ForEach(visiblePlays) { play in
                            PlayRow(play: play, band: play.priorityBand)
                        }
                    }
                }
                .onAppear(perform: configureDefaultExpansion)
                .onChange(of: playSignature) { _, _ in
                    configureDefaultExpansion()
                }
            }
        }
    }

    private var priorityControls: some View {
        HStack(spacing: 8) {
            PriorityFilterButton(
                band: .p1,
                count: count(.p1),
                isExpanded: true,
                isLocked: true
            ) {}

            PriorityFilterButton(
                band: .p2,
                count: count(.p2),
                isExpanded: showP2,
                isLocked: false
            ) {
                showP2.toggle()
            }

            PriorityFilterButton(
                band: .p3,
                count: count(.p3),
                isExpanded: showP3,
                isLocked: false
            ) {
                showP3.toggle()
            }
        }
    }

    private var visiblePlays: [PlayEntry] {
        dedupedPlays.filter { play in
            switch play.priorityBand {
            case .p1:
                return true
            case .p2:
                return showP2
            case .p3:
                return showP3
            }
        }
    }

    private var dedupedPlays: [PlayEntry] {
        let unique = Dictionary(grouping: plays) { play in
            "\(play.periodLabel ?? "")|\(play.gameClock ?? "")|\(play.description ?? "")"
        }
        .compactMap { $0.value.first }

        return unique.sorted {
            if $0.playIndex != $1.playIndex {
                return $0.playIndex < $1.playIndex
            }
            return $0.clockText < $1.clockText
        }
    }

    private var playSignature: String {
        "\(dedupedPlays.count)-\(dedupedPlays.last?.playIndex ?? 0)-\(count(.p1))-\(count(.p2))-\(count(.p3))"
    }

    private func count(_ band: PlayPriorityBand) -> Int {
        dedupedPlays.filter { $0.priorityBand == band }.count
    }

    private func configureDefaultExpansion() {
        guard configuredSignature != playSignature else { return }
        configuredSignature = playSignature
        let hasP1 = count(.p1) > 0
        let hasP2 = count(.p2) > 0
        showP2 = !hasP1 && hasP2
        showP3 = !hasP1 && !hasP2
    }
}

private struct PriorityFilterButton: View {
    let band: PlayPriorityBand
    let count: Int
    let isExpanded: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                PriorityBadge(band: band)
                Text("\(count)")
                    .font(.caption.weight(.bold))
                if !isLocked {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
                }
            }
            .foregroundStyle(isExpanded ? .primary : .secondary)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                (isExpanded ? band.color.opacity(0.14) : Color(.tertiarySystemGroupedBackground)),
                in: RoundedRectangle(cornerRadius: 7)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

private struct PlayRow: View {
    let play: PlayEntry
    let band: PlayPriorityBand

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 4) {
                Circle()
                    .fill(band.color)
                    .frame(width: band == .p1 ? 10 : 7, height: band == .p1 ? 10 : 7)
                Rectangle()
                    .fill(band.color.opacity(0.25))
                    .frame(width: 1)
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    PriorityBadge(band: band)
                    if !play.clockText.isEmpty {
                        Text(play.clockText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(play.description ?? play.playType ?? "Play update")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    if let team = play.teamAbbreviation {
                        Text(team)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(band.color)
                    }
                    if play.scoreChanged == true {
                        Text("Scoring")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }
}

private struct PriorityBadge: View {
    let band: PlayPriorityBand

    var body: some View {
        Text(band.rawValue)
            .font(.caption2.weight(.black))
            .foregroundStyle(.white)
            .padding(.vertical, 3)
            .padding(.horizontal, 7)
            .background(band.color, in: RoundedRectangle(cornerRadius: 5))
    }
}

private enum PlayPriorityBand: String, CaseIterable {
    case p1 = "P1"
    case p2 = "P2"
    case p3 = "P3"

    var title: String {
        switch self {
        case .p1: return "Game changers"
        case .p2: return "Momentum"
        case .p3: return "Routine stream"
        }
    }

    var color: Color {
        switch self {
        case .p1: return Color(.systemOrange)
        case .p2: return Color(.systemTeal)
        case .p3: return Color(.systemGray)
        }
    }
}

private extension PlayEntry {
    var priorityBand: PlayPriorityBand {
        if scoreChanged == true || tier == 1 {
            return .p1
        }
        if tier == 2 {
            return .p2
        }
        return .p3
    }
}

struct PlayerStatsSection: View {
    let detail: GameDetailResponse
    @State private var isExpanded = false

    var body: some View {
        CollapsibleCatchUpSection(title: "Player Stats", systemImage: "person.3", isExpanded: $isExpanded) {
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
    @State private var isExpanded = false

    var body: some View {
        CollapsibleCatchUpSection(title: "Team Stats", systemImage: "chart.bar.xaxis", isExpanded: $isExpanded) {
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
    @State private var scoreRevealed = false
    @State private var showRevealConfirm = false

    var body: some View {
        CatchUpSection(title: "Box Score", systemImage: "number.square") {
            if scoreRevealed {
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

                    HStack {
                        if let gameStateText {
                            Text(gameStateText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(game.isLiveGame ? .green : .secondary)
                        }
                        Spacer()
                        Button("Hide score") {
                            scoreRevealed = false
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "eye.slash")
                            .foregroundStyle(Color(.systemTeal))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Score hidden")
                                .font(.subheadline.weight(.semibold))
                            Text("Reveal only when you are ready to see the current or final boxscore.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        showRevealConfirm = true
                    } label: {
                        Label("Reveal box score", systemImage: "eye")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                .confirmationDialog(
                    "Reveal score?",
                    isPresented: $showRevealConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Reveal box score", role: .destructive) {
                        scoreRevealed = true
                    }
                    Button("Keep hidden", role: .cancel) {}
                } message: {
                    Text("This may reveal the current or final score.")
                }
            }
        }
    }

    private var gameStateText: String? {
        if game.isLiveGame {
            let liveText = [game.currentPeriodLabel, game.gameClock]
                .compactMap { $0 }
                .joined(separator: " ")
            return liveText.isEmpty ? "Live" : liveText
        }
        if game.isFinalGame {
            return "Final"
        }
        if game.isPregame {
            return "Scheduled"
        }
        return nil
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

private struct CollapsibleCatchUpSection<Content: View>: View {
    let title: String
    let systemImage: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: Content

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content
                .padding(.top, 10)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.bold))
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
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
