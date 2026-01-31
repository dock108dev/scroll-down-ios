import SwiftUI

// MARK: - Player Stats Extension

extension GameDetailView {
    // MARK: - Player Stats Section

    func playerStatsSection(_ stats: [PlayerStat]) -> some View {
        CollapsibleSectionCard(
            title: "Player Stats",
            subtitle: viewModel.isNHL ? "Skaters & Goalies" : "Individual performance",
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

            VStack(spacing: GameDetailLayout.listSpacing) {
                // Team filter
                if teams.count > 1 {
                    teamFilterPicker(teams: teams)
                }

                // Stats table with frozen columns + horizontal scroll
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

                    // SCROLLABLE COLUMNS - all rows scroll together
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(spacing: 0) {
                            scrollableHeaderCell
                            ForEach(Array(processedStats.enumerated()), id: \.element.id) { index, stat in
                                scrollableDataCell(stat, isAlternate: index.isMultiple(of: 2))
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
            }
        }
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
                    teamFilterButton(title: shortTeamName(team), team: team)
                }
            }
        }
    }

    private func teamFilterButton(title: String, team: String?) -> some View {
        let isSelected = playerStatsTeamFilter == team
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                playerStatsTeamFilter = team
            }
        } label: {
            Text(title)
                .font(DesignSystem.Typography.rowMeta.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? GameTheme.accentColor : DesignSystem.Colors.elevatedBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func shortTeamName(_ fullName: String) -> String {
        // Extract last word as team name (e.g., "Boston Celtics" -> "Celtics")
        fullName.split(separator: " ").last.map(String.init) ?? fullName
    }

    // MARK: - Frozen Column Cells (Player + Team)

    private var frozenHeaderCell: some View {
        HStack(spacing: 4) {
            Text("Player")
                .frame(width: 100, alignment: .leading)
            Text("")
                .frame(width: 36)
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
        let isHomeTeam = stat.team == viewModel.game?.homeTeam
        let bgColor = isAlternate ? DesignSystem.Colors.alternateRowBackground : DesignSystem.Colors.rowBackground

        return HStack(spacing: 4) {
            PlayerNameCell(fullName: stat.playerName)
                .frame(width: 100, alignment: .leading)

            Text(teamAbbreviation(stat.team))
                .font(.caption2.weight(.medium))
                .foregroundColor(isHomeTeam ? DesignSystem.TeamColors.teamB : DesignSystem.TeamColors.teamA)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(isHomeTeam ? DesignSystem.Colors.homeBadge : DesignSystem.Colors.awayBadge)
                .clipShape(Capsule())
                .frame(width: 36)
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

    private var scrollableHeaderCell: some View {
        HStack(spacing: 6) {
            Text("MIN").frame(width: 38)
            Text("PTS").frame(width: 34)
            Text("REB").frame(width: 34)
            Text("AST").frame(width: 34)
            Text("FG").frame(width: 48)
            Text("3PT").frame(width: 48)
            Text("FT").frame(width: 48)
            Text("STL").frame(width: 30)
            Text("BLK").frame(width: 30)
            Text("TO").frame(width: 30)
            Text("+/-").frame(width: 38)
        }
        .font(DesignSystem.Typography.statLabel)
        .foregroundColor(DesignSystem.TextColor.secondary)
        .textCase(.uppercase)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(DesignSystem.Colors.elevatedBackground)
    }

    private func scrollableDataCell(_ stat: PlayerStat, isAlternate: Bool) -> some View {
        let bgColor = isAlternate ? DesignSystem.Colors.alternateRowBackground : DesignSystem.Colors.rowBackground
        return HStack(spacing: 6) {
            Text(formatMinutes(stat.minutes))
                .foregroundColor(DesignSystem.TextColor.secondary)
                .frame(width: 38)

            Text(stat.points.map(String.init) ?? "--")
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.TextColor.primary)
                .frame(width: 34)

            Text(stat.rebounds.map(String.init) ?? "--")
                .frame(width: 34)

            Text(stat.assists.map(String.init) ?? "--")
                .frame(width: 34)

            Text(formatShotStat(made: rawStatInt(stat, "fg"), attempted: rawStatInt(stat, "fga")))
                .frame(width: 48)

            Text(formatShotStat(made: rawStatInt(stat, "fg3"), attempted: rawStatInt(stat, "fg3a")))
                .frame(width: 48)

            Text(formatShotStat(made: rawStatInt(stat, "ft"), attempted: rawStatInt(stat, "fta")))
                .frame(width: 48)

            Text(rawStatInt(stat, "stl").map(String.init) ?? "--")
                .frame(width: 30)

            Text(rawStatInt(stat, "blk").map(String.init) ?? "--")
                .frame(width: 30)

            Text(rawStatInt(stat, "tov").map(String.init) ?? "--")
                .frame(width: 30)

            Text(rawStatString(stat, "plus_minus") ?? "--")
                .foregroundColor(plusMinusColor(rawStatString(stat, "plus_minus")))
                .frame(width: 38)
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

    func teamAbbreviation(_ fullName: String) -> String {
        // Common NBA team abbreviations
        let abbreviations: [String: String] = [
            "Atlanta Hawks": "ATL",
            "Boston Celtics": "BOS",
            "Brooklyn Nets": "BKN",
            "Charlotte Hornets": "CHA",
            "Chicago Bulls": "CHI",
            "Cleveland Cavaliers": "CLE",
            "Dallas Mavericks": "DAL",
            "Denver Nuggets": "DEN",
            "Detroit Pistons": "DET",
            "Golden State Warriors": "GSW",
            "Houston Rockets": "HOU",
            "Indiana Pacers": "IND",
            "Los Angeles Clippers": "LAC",
            "Los Angeles Lakers": "LAL",
            "Memphis Grizzlies": "MEM",
            "Miami Heat": "MIA",
            "Milwaukee Bucks": "MIL",
            "Minnesota Timberwolves": "MIN",
            "New Orleans Pelicans": "NOP",
            "New York Knicks": "NYK",
            "Oklahoma City Thunder": "OKC",
            "Orlando Magic": "ORL",
            "Philadelphia 76ers": "PHI",
            "Phoenix Suns": "PHX",
            "Portland Trail Blazers": "POR",
            "Sacramento Kings": "SAC",
            "San Antonio Spurs": "SAS",
            "Toronto Raptors": "TOR",
            "Utah Jazz": "UTA",
            "Washington Wizards": "WAS"
        ]

        if let abbrev = abbreviations[fullName] {
            return abbrev
        }

        // Default: take first 3 letters of last word
        let words = fullName.split(separator: " ")
        if let lastWord = words.last {
            return String(lastWord.prefix(3)).uppercased()
        }
        return String(fullName.prefix(3)).uppercased()
    }

    func abbreviatedName(_ fullName: String) -> String {
        let parts = fullName.split(separator: " ")
        guard parts.count >= 2 else { return fullName }
        let firstInitial = parts[0].prefix(1)
        let lastName = parts.dropFirst().joined(separator: " ")
        return "\(firstInitial). \(lastName)"
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

    private func rawStatInt(_ stat: PlayerStat, _ key: String) -> Int? {
        guard let value = stat.rawStats[key] else { return nil }
        if let intVal = value.value as? Int { return intVal }
        if let doubleVal = value.value as? Double { return Int(doubleVal) }
        if let strVal = value.value as? String, let parsed = Int(strVal) { return parsed }
        return nil
    }

    private func rawStatString(_ stat: PlayerStat, _ key: String) -> String? {
        guard let value = stat.rawStats[key] else { return nil }
        if let strVal = value.value as? String { return strVal }
        if let intVal = value.value as? Int { return String(intVal) }
        if let doubleVal = value.value as? Double { return String(Int(doubleVal)) }
        return nil
    }

    // MARK: - Team Stats Section

    func teamStatsSection(_ stats: [TeamStat]) -> some View {
        CollapsibleSectionCard(
            title: "Team Stats",
            subtitle: "How the game unfolded",
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

// MARK: - Player Name Cell with Tap to Expand

struct PlayerNameCell: View {
    let fullName: String

    @State private var showingFullName = false

    var body: some View {
        Text(abbreviatedName)
            .font(.subheadline.weight(.medium))
            .foregroundColor(.primary)
            .lineLimit(1)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.15)) {
                    showingFullName = true
                }
                // Auto-dismiss after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeIn(duration: 0.15)) {
                        showingFullName = false
                    }
                }
            }
            .overlay(alignment: .top) {
                if showingFullName {
                    fullNameTooltip
                        .offset(y: -36)
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
                }
            }
    }

    private var fullNameTooltip: some View {
        Text(fullName)
            .font(DesignSystem.Typography.rowMeta.weight(.medium))
            .foregroundColor(.white)
            .fixedSize()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.darkGray))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))
            .shadow(color: .black.opacity(0.2), radius: DesignSystem.Shadow.subtleRadius, y: DesignSystem.Shadow.subtleY)
            .zIndex(100)
    }

    /// Convert "Jayson Tatum" to "J. Tatum"
    private var abbreviatedName: String {
        let parts = fullName.split(separator: " ")
        guard parts.count >= 2 else { return fullName }

        let firstInitial = parts[0].prefix(1)
        let lastName = parts.dropFirst().joined(separator: " ")
        return "\(firstInitial). \(lastName)"
    }
}
