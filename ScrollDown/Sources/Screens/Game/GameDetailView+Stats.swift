import SwiftUI
import OSLog

// MARK: - Player Stats Extension

extension GameDetailView {
    // MARK: - Player Stats Section (Tier 3: Supporting)

    func playerStatsSection(_ stats: [PlayerStat]) -> some View {
        CollapsibleSectionCard(
            title: "Player Stats",
            isExpanded: $isPlayerStatsExpanded
        ) {
            // NHL uses separate skaters/goalies arrays
            if viewModel.isNHL {
                nhlStatsContent
            } else {
                playerStatsContent(stats)
            }
        }
    }

    // MARK: - NBA Stats Content

    @ViewBuilder
    func playerStatsContent(_ stats: [PlayerStat]) -> some View {
        if stats.isEmpty {
            EmptySectionView(text: "Player stats are not yet available.")
        } else {
            let processedStats = filteredAndSortedStats(stats)
            let teams = uniqueTeams(from: stats)
            let columns = availableStatColumns(stats)

            VStack(spacing: GameDetailLayout.listSpacing) {
                // Team filter
                if teams.count > 1 {
                    teamFilterPicker(teams: teams)
                }

                // Stats table with frozen columns + stat columns
                // Use flexible layout when few columns (NCAAB), scrollable when many (NBA)
                let useFlexible = columns.count <= 6

                HStack(alignment: .top, spacing: 0) {
                    // FROZEN COLUMNS (Player + Team) - stays fixed
                    VStack(spacing: 0) {
                        frozenHeaderCell
                        ForEach(Array(processedStats.enumerated()), id: \.element.id) { index, stat in
                            frozenDataCell(stat, isAlternate: index.isMultiple(of: 2))
                        }
                    }

                    // Divider
                    Rectangle()
                        .fill(DesignSystem.borderColor)
                        .frame(width: 1)

                    // STAT COLUMNS - flexible when few, scrollable when many
                    if useFlexible {
                        VStack(spacing: 0) {
                            scrollableHeaderCell(columns: columns, flexible: true)
                            ForEach(Array(processedStats.enumerated()), id: \.element.id) { index, stat in
                                scrollableDataCell(stat, isAlternate: index.isMultiple(of: 2), columns: columns, flexible: true)
                            }
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            VStack(spacing: 0) {
                                scrollableHeaderCell(columns: columns, flexible: false)
                                ForEach(Array(processedStats.enumerated()), id: \.element.id) { index, stat in
                                    scrollableDataCell(stat, isAlternate: index.isMultiple(of: 2), columns: columns, flexible: false)
                                }
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
            }
        }
    }

    // MARK: - Player Stat Key Aliases
    // Multi-key aliases to handle varying API key names across NBA / NCAAB providers.
    private enum PlayerStatKeys {
        static let fg = ["fg", "fgm", "fg_made", "fgMade", "fieldGoalsMade"]
        static let fga = ["fga", "fg_attempted", "fgAttempted", "fieldGoalsAttempted"]
        static let fg3 = ["fg3", "fg3m", "fg3Made", "three_made", "threePointersMade"]
        static let fg3a = ["fg3a", "fg3Attempted", "three_attempted", "threePointersAttempted"]
        static let ft = ["ft", "ftm", "ft_made", "ftMade", "freeThrowsMade"]
        static let fta = ["fta", "ft_attempted", "ftAttempted", "freeThrowsAttempted"]
        static let stl = ["stl", "steals"]
        static let blk = ["blk", "blocks"]
        static let tov = ["tov", "turnovers", "to"]
        static let pf = ["pf", "personalFouls", "personal_fouls", "fouls"]
        static let plusMinus = ["plus_minus", "plusMinus", "+/-"]
    }

    private func availableStatColumns(_ stats: [PlayerStat]) -> Set<String> {
        var available = Set<String>()

        #if DEBUG
        // Log first player's rawStats keys for diagnosing mismatches
        if let first = stats.first {
            let keys = Array(first.rawStats.keys).sorted()
            Logger(subsystem: "com.scrolldown.app", category: "stats")
                .debug("🏀 PlayerStat sample rawStats keys: \(keys, privacy: .public)")
        }
        #endif

        for stat in stats {
            if stat.minutes != nil { available.insert("min") }
            if stat.points != nil { available.insert("pts") }
            if stat.rebounds != nil { available.insert("reb") }
            if stat.assists != nil { available.insert("ast") }
            if rawStatIntMulti(stat, PlayerStatKeys.fg) != nil { available.insert("fg") }
            if rawStatIntMulti(stat, PlayerStatKeys.fg3) != nil { available.insert("3pt") }
            if rawStatIntMulti(stat, PlayerStatKeys.ft) != nil { available.insert("ft") }
            if rawStatIntMulti(stat, PlayerStatKeys.stl) != nil { available.insert("stl") }
            if rawStatIntMulti(stat, PlayerStatKeys.blk) != nil { available.insert("blk") }
            if rawStatIntMulti(stat, PlayerStatKeys.tov) != nil { available.insert("tov") }
            if rawStatStringMulti(stat, PlayerStatKeys.plusMinus) != nil { available.insert("+/-") }
            if rawStatIntMulti(stat, PlayerStatKeys.pf) != nil { available.insert("pf") }
        }
        return available
    }

    private func uniqueTeams(from stats: [PlayerStat]) -> [String] {
        var seen = Set<String>()
        return stats.compactMap { stat in
            if seen.contains(stat.team) { return nil }
            seen.insert(stat.team)
            return stat.team
        }
    }

    private func filteredAndSortedStats(_ stats: [PlayerStat]) -> [PlayerStat] {
        stats
            // Filter out players who didn't play (no minutes or 0 minutes)
            .filter { ($0.minutes ?? 0) > 0 }
            // Filter by team if selected
            .filter { playerStatsTeamFilter == nil || $0.team == playerStatsTeamFilter }
            // Sort by minutes played descending
            .sorted { ($0.minutes ?? 0) > ($1.minutes ?? 0) }
    }

    // MARK: - Team Filter (Shared)

    func teamFilterPicker(teams: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                teamFilterButton(title: "All", team: nil)
                ForEach(teams, id: \.self) { team in
                    teamFilterButton(title: TeamAbbreviations.abbreviation(for: team), team: team)
                }
            }
        }
    }

    private func teamFilterButton(title: String, team: String?) -> some View {
        let isSelected = playerStatsTeamFilter == team
        let homeTeam = viewModel.game?.homeTeam ?? ""
        let awayTeam = viewModel.game?.awayTeam ?? ""
        let teamColor = team.map { DesignSystem.TeamColors.matchupColor(for: $0, against: $0 == homeTeam ? awayTeam : homeTeam, isHome: $0 == homeTeam) } ?? GameTheme.accentColor
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                playerStatsTeamFilter = team
            }
        } label: {
            Text(title)
                .font(DesignSystem.Typography.rowMeta.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? teamColor : DesignSystem.Colors.elevatedBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Frozen Column Cells (Player + Team)

    private var frozenHeaderCell: some View {
        HStack(spacing: 4) {
            Text("Player")
                .frame(width: 100, alignment: .leading)
            Text("")
                .frame(width: 48)
        }
        .font(DesignSystem.Typography.statLabel)
        .foregroundColor(DesignSystem.TextColor.secondary)
        .textCase(.uppercase)
        .padding(.vertical, 8)
        .padding(.leading, DesignSystem.Spacing.elementPadding)
        .padding(.trailing, 4)
        .background(DesignSystem.Colors.elevatedBackground)
    }

    private func frozenDataCell(_ stat: PlayerStat, isAlternate: Bool) -> some View {
        let homeTeam = viewModel.game?.homeTeam ?? ""
        let awayTeam = viewModel.game?.awayTeam ?? ""
        let teamColor = DesignSystem.TeamColors.matchupColor(for: stat.team, against: stat.team == homeTeam ? awayTeam : homeTeam, isHome: stat.team == homeTeam)
        let bgColor = isAlternate ? DesignSystem.Colors.alternateRowBackground : DesignSystem.Colors.rowBackground

        return HStack(spacing: 4) {
            PlayerNameCell(fullName: stat.playerName)
                .frame(width: 100, alignment: .leading)

            Text(TeamAbbreviations.abbreviation(for: stat.team))
                .font(.caption2.weight(.medium))
                .foregroundColor(teamColor)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(teamColor.opacity(0.15))
                .clipShape(Capsule())
                .frame(width: 48)
        }
        .frame(height: 36)
        .padding(.leading, DesignSystem.Spacing.elementPadding)
        .padding(.trailing, 4)
        .background(bgColor)
        .overlay(alignment: .bottom) {
            if !isAlternate {
                Rectangle()
                    .fill(DesignSystem.borderColor.opacity(0.4))
                    .frame(height: DesignSystem.borderWidth)
            }
        }
    }

    // MARK: - Scrollable Column Cells (Stats)

    @ViewBuilder
    private func statColumnFrame(_ text: String, width: CGFloat, flexible: Bool) -> some View {
        if flexible {
            Text(text).frame(maxWidth: .infinity)
        } else {
            Text(text).frame(width: width)
        }
    }

    private func scrollableHeaderCell(columns: Set<String>, flexible: Bool = false) -> some View {
        HStack(spacing: 6) {
            if columns.contains("min") { statColumnFrame("MIN", width: 38, flexible: flexible) }
            if columns.contains("pts") { statColumnFrame("PTS", width: 34, flexible: flexible) }
            if columns.contains("reb") { statColumnFrame("REB", width: 34, flexible: flexible) }
            if columns.contains("ast") { statColumnFrame("AST", width: 34, flexible: flexible) }
            if columns.contains("fg") { statColumnFrame("FG", width: 48, flexible: flexible) }
            if columns.contains("3pt") { statColumnFrame("3PT", width: 48, flexible: flexible) }
            if columns.contains("ft") { statColumnFrame("FT", width: 48, flexible: flexible) }
            if columns.contains("stl") { statColumnFrame("STL", width: 30, flexible: flexible) }
            if columns.contains("blk") { statColumnFrame("BLK", width: 30, flexible: flexible) }
            if columns.contains("tov") { statColumnFrame("TO", width: 30, flexible: flexible) }
            if columns.contains("+/-") { statColumnFrame("+/-", width: 38, flexible: flexible) }
            if columns.contains("pf") { statColumnFrame("PF", width: 30, flexible: flexible) }
        }
        .font(DesignSystem.Typography.statLabel)
        .foregroundColor(DesignSystem.TextColor.secondary)
        .textCase(.uppercase)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(DesignSystem.Colors.elevatedBackground)
    }

    @ViewBuilder
    private func dataColumnFrame<V: View>(_ content: V, width: CGFloat, flexible: Bool) -> some View {
        if flexible {
            content.frame(maxWidth: .infinity)
        } else {
            content.frame(width: width)
        }
    }

    private func scrollableDataCell(_ stat: PlayerStat, isAlternate: Bool, columns: Set<String>, flexible: Bool = false) -> some View {
        let bgColor = isAlternate ? DesignSystem.Colors.alternateRowBackground : DesignSystem.Colors.rowBackground
        return HStack(spacing: 6) {
            if columns.contains("min") {
                dataColumnFrame(
                    Text(formatMinutes(stat.minutes))
                        .foregroundColor(DesignSystem.TextColor.secondary),
                    width: 38, flexible: flexible
                )
            }

            if columns.contains("pts") {
                dataColumnFrame(
                    Text(stat.points.map(String.init) ?? "--")
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.TextColor.primary),
                    width: 34, flexible: flexible
                )
            }

            if columns.contains("reb") {
                dataColumnFrame(
                    Text(stat.rebounds.map(String.init) ?? "--"),
                    width: 34, flexible: flexible
                )
            }

            if columns.contains("ast") {
                dataColumnFrame(
                    Text(stat.assists.map(String.init) ?? "--"),
                    width: 34, flexible: flexible
                )
            }

            if columns.contains("fg") {
                dataColumnFrame(
                    Text(formatShotStat(made: rawStatIntMulti(stat, PlayerStatKeys.fg), attempted: rawStatIntMulti(stat, PlayerStatKeys.fga))),
                    width: 48, flexible: flexible
                )
            }

            if columns.contains("3pt") {
                dataColumnFrame(
                    Text(formatShotStat(made: rawStatIntMulti(stat, PlayerStatKeys.fg3), attempted: rawStatIntMulti(stat, PlayerStatKeys.fg3a))),
                    width: 48, flexible: flexible
                )
            }

            if columns.contains("ft") {
                dataColumnFrame(
                    Text(formatShotStat(made: rawStatIntMulti(stat, PlayerStatKeys.ft), attempted: rawStatIntMulti(stat, PlayerStatKeys.fta))),
                    width: 48, flexible: flexible
                )
            }

            if columns.contains("stl") {
                dataColumnFrame(
                    Text(rawStatIntMulti(stat, PlayerStatKeys.stl).map(String.init) ?? "--"),
                    width: 30, flexible: flexible
                )
            }

            if columns.contains("blk") {
                dataColumnFrame(
                    Text(rawStatIntMulti(stat, PlayerStatKeys.blk).map(String.init) ?? "--"),
                    width: 30, flexible: flexible
                )
            }

            if columns.contains("tov") {
                dataColumnFrame(
                    Text(rawStatIntMulti(stat, PlayerStatKeys.tov).map(String.init) ?? "--"),
                    width: 30, flexible: flexible
                )
            }

            if columns.contains("+/-") {
                let pmValue = rawStatStringMulti(stat, PlayerStatKeys.plusMinus)
                dataColumnFrame(
                    Text(pmValue ?? "--")
                        .foregroundColor(plusMinusColor(pmValue)),
                    width: 38, flexible: flexible
                )
            }

            if columns.contains("pf") {
                dataColumnFrame(
                    Text(rawStatIntMulti(stat, PlayerStatKeys.pf).map(String.init) ?? "--"),
                    width: 30, flexible: flexible
                )
            }
        }
        .font(DesignSystem.Typography.statValue)
        .foregroundColor(DesignSystem.TextColor.secondary)
        .frame(height: 36)
        .padding(.horizontal, 8)
        .background(bgColor)
        .overlay(alignment: .bottom) {
            if !isAlternate {
                Rectangle()
                    .fill(DesignSystem.borderColor.opacity(0.4))
                    .frame(height: DesignSystem.borderWidth)
            }
        }
    }

    // MARK: - Stat Formatting Helpers

    private func plusMinusColor(_ value: String?) -> Color {
        guard let val = value else { return DesignSystem.TextColor.secondary }
        // Positive: accent-tinted green, Negative: muted red
        if val.hasPrefix("+") { return Color(.systemGreen) }
        if val.hasPrefix("-") { return Color(.systemRed).opacity(0.8) }
        return DesignSystem.TextColor.secondary
    }

    private func formatMinutes(_ minutes: Double?) -> String {
        guard let mins = minutes else { return "--" }
        let whole = Int(mins)
        let seconds = Int((mins - Double(whole)) * 60)
        return String(format: "%d:%02d", whole, seconds)
    }

    private func formatShotStat(made: Int?, attempted: Int?) -> String {
        guard let m = made, let a = attempted else { return "--" }
        return "\(m)-\(a)"
    }

    private func resolveRawStat(_ stat: PlayerStat, _ key: String) -> AnyCodable? {
        stat.rawStats[key]
    }

    private func rawStatInt(_ stat: PlayerStat, _ key: String) -> Int? {
        guard let value = resolveRawStat(stat, key) else { return nil }
        if let intVal = value.value as? Int { return intVal }
        if let doubleVal = value.value as? Double { return Int(doubleVal) }
        if let strVal = value.value as? String, let parsed = Int(strVal) { return parsed }
        return nil
    }

    private func rawStatString(_ stat: PlayerStat, _ key: String) -> String? {
        guard let value = resolveRawStat(stat, key) else { return nil }
        if let strVal = value.value as? String { return strVal }
        if let intVal = value.value as? Int { return String(intVal) }
        if let doubleVal = value.value as? Double { return String(Int(doubleVal)) }
        return nil
    }

    /// Multi-key lookup: tries each key in order, returns first match as Int.
    private func rawStatIntMulti(_ stat: PlayerStat, _ keys: [String]) -> Int? {
        for key in keys {
            if let val = rawStatInt(stat, key) { return val }
        }
        return nil
    }

    /// Multi-key lookup: tries each key in order, returns first match as String.
    private func rawStatStringMulti(_ stat: PlayerStat, _ keys: [String]) -> String? {
        for key in keys {
            if let val = rawStatString(stat, key) { return val }
        }
        return nil
    }

    // MARK: - Team Stats Section (Tier 3: Supporting)

    func teamStatsSection(_ stats: [TeamStat]) -> some View {
        CollapsibleSectionCard(
            title: "Team Stats",
            isExpanded: $isTeamStatsExpanded
        ) {
            teamStatsContent(stats)
        }
    }

    @ViewBuilder
    func teamStatsContent(_ stats: [TeamStat]) -> some View {
        if viewModel.teamComparisonStats.isEmpty {
            EmptySectionView(text: "Team stats will appear once available.")
        } else {
            // Use the new grouped container for cleaner presentation
            TeamStatsContainer(
                stats: viewModel.teamComparisonStats,
                homeTeam: stats.first(where: { $0.isHome })?.team ?? "Home",
                awayTeam: stats.first(where: { !$0.isHome })?.team ?? "Away"
            )
        }
    }
}

