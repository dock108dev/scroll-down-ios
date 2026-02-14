import SwiftUI

// MARK: - NHL Stats Extension

extension GameDetailView {
    // MARK: - NHL Stats Content

    @ViewBuilder
    var nhlStatsContent: some View {
        let skaters = viewModel.nhlSkaters
        let goalies = viewModel.nhlGoalies

        if skaters.isEmpty && goalies.isEmpty {
            EmptySectionView(text: "Player stats are not yet available.")
        } else {
            VStack(spacing: GameDetailLayout.listSpacing) {
                // Data health warning
                if let health = viewModel.nhlDataHealth, health.isHealthy == false {
                    nhlDataHealthWarning(health)
                }

                // Skaters section
                if !skaters.isEmpty {
                    nhlSkatersTable(skaters)
                }

                // Goalies section
                if !goalies.isEmpty {
                    nhlGoaliesTable(goalies)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func nhlDataHealthWarning(_ health: NHLDataHealth) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("Some stats may be incomplete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - NHL Skaters Table

    private func nhlSkatersTable(_ skaters: [NHLSkaterStat]) -> some View {
        let filteredSkaters = skaters
            .filter { playerStatsTeamFilter == nil || $0.team == playerStatsTeamFilter }
            .sorted { ($0.toi ?? "") > ($1.toi ?? "") }
        let teams = uniqueNHLTeams(from: skaters)

        return VStack(spacing: 8) {
            // Section header
            HStack {
                Text("Skaters")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            // Team filter
            if teams.count > 1 {
                teamFilterPicker(teams: teams)
            }

            // Table - constrained to parent width
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    nhlSkaterHeaderRow
                    ForEach(Array(filteredSkaters.enumerated()), id: \.element.id) { index, skater in
                        nhlSkaterDataRow(skater, isAlternate: index.isMultiple(of: 2))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var nhlSkaterHeaderRow: some View {
        HStack(spacing: 6) {
            Text("Player").frame(width: 120, alignment: .leading)
            Text("TOI").frame(width: 42)
            Text("G").frame(width: 28)
            Text("A").frame(width: 28)
            Text("PTS").frame(width: 34)
            Text("+/-").frame(width: 34)
            Text("SOG").frame(width: 34)
            Text("HIT").frame(width: 34)
            Text("BLK").frame(width: 34)
            Text("PIM").frame(width: 34)
        }
        .font(DesignSystem.Typography.statLabel)
        .foregroundColor(DesignSystem.TextColor.secondary)
        .textCase(.uppercase)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(DesignSystem.Colors.elevatedBackground)
    }

    private func nhlSkaterDataRow(_ skater: NHLSkaterStat, isAlternate: Bool) -> some View {
        let bgColor = isAlternate ? DesignSystem.Colors.alternateRowBackground : DesignSystem.Colors.rowBackground
        let goals = skater.goals ?? 0
        let assists = skater.assists ?? 0
        let points = skater.points ?? (goals + assists)

        return HStack(spacing: 6) {
            // Player name
            Text(skater.playerName.abbreviatedPlayerName)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            // TOI
            Text(skater.toi ?? "--")
                .foregroundColor(DesignSystem.TextColor.secondary)
                .frame(width: 42)

            // Goals
            Text("\(goals)")
                .fontWeight(goals > 0 ? .semibold : .regular)
                .foregroundColor(goals > 0 ? DesignSystem.TextColor.primary : DesignSystem.TextColor.secondary)
                .frame(width: 28)

            // Assists
            Text("\(assists)")
                .frame(width: 28)

            // Points
            Text("\(points)")
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.TextColor.primary)
                .frame(width: 34)

            // +/-
            Text(formatPlusMinus(skater.plusMinus))
                .foregroundColor(plusMinusColorInt(skater.plusMinus))
                .frame(width: 34)

            // SOG
            Text(skater.shotsOnGoal?.description ?? "--")
                .frame(width: 34)

            // Hits
            Text(skater.hits?.description ?? "--")
                .frame(width: 34)

            // Blocked
            Text(skater.blockedShots?.description ?? "--")
                .frame(width: 34)

            // PIM
            Text(skater.penaltyMinutes?.description ?? "--")
                .frame(width: 34)
        }
        .font(DesignSystem.Typography.statValue)
        .foregroundColor(DesignSystem.TextColor.secondary)
        .frame(height: 36)
        .padding(.horizontal, 8)
        .background(bgColor)
    }

    // MARK: - NHL Goalies Table

    private func nhlGoaliesTable(_ goalies: [NHLGoalieStat]) -> some View {
        VStack(spacing: 8) {
            // Section header
            HStack {
                Text("Goalies")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            // Table - constrained to parent width (matches skaters table structure)
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    nhlGoalieHeaderRow
                    ForEach(Array(goalies.enumerated()), id: \.element.id) { index, goalie in
                        nhlGoalieDataRow(goalie, isAlternate: index.isMultiple(of: 2))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var nhlGoalieHeaderRow: some View {
        HStack(spacing: 6) {
            Text("Player").frame(width: 120, alignment: .leading)
            Text("TOI").frame(width: 50)
            Text("SA").frame(width: 34)
            Text("SV").frame(width: 34)
            Text("GA").frame(width: 34)
            Text("SV%").frame(width: 50)
        }
        .font(DesignSystem.Typography.statLabel)
        .foregroundColor(DesignSystem.TextColor.secondary)
        .textCase(.uppercase)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(DesignSystem.Colors.elevatedBackground)
    }

    private func nhlGoalieDataRow(_ goalie: NHLGoalieStat, isAlternate: Bool) -> some View {
        let bgColor = isAlternate ? DesignSystem.Colors.alternateRowBackground : DesignSystem.Colors.rowBackground

        return HStack(spacing: 6) {
            // Player name
            Text(goalie.playerName.abbreviatedPlayerName)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            // TOI
            Text(goalie.toi ?? "--")
                .foregroundColor(DesignSystem.TextColor.secondary)
                .frame(width: 50)

            // Shots Against
            Text(goalie.shotsAgainst?.description ?? "--")
                .frame(width: 34)

            // Saves
            Text(goalie.saves?.description ?? "--")
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.TextColor.primary)
                .frame(width: 34)

            // Goals Against
            Text(goalie.goalsAgainst?.description ?? "--")
                .frame(width: 34)

            // Save %
            Text(formatSavePercentage(goalie.savePercentage))
                .fontWeight(.semibold)
                .foregroundColor(savePctColor(goalie.savePercentage))
                .frame(width: 50)
        }
        .font(DesignSystem.Typography.statValue)
        .foregroundColor(DesignSystem.TextColor.secondary)
        .frame(height: 36)
        .padding(.horizontal, 8)
        .background(bgColor)
    }

    // MARK: - NHL Formatting Helpers

    private func formatSavePercentage(_ pct: Double?) -> String {
        guard let pct = pct else { return "--" }
        return String(format: ".%03d", Int(pct * 1000))
    }

    private func savePctColor(_ pct: Double?) -> Color {
        guard let pct = pct else { return DesignSystem.TextColor.secondary }
        if pct >= 0.920 { return Color(.systemGreen) }
        if pct >= 0.900 { return DesignSystem.TextColor.primary }
        return Color(.systemRed).opacity(0.8)
    }

    private func formatPlusMinus(_ value: Int?) -> String {
        guard let value = value else { return "--" }
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    private func plusMinusColorInt(_ value: Int?) -> Color {
        guard let value = value else { return DesignSystem.TextColor.secondary }
        if value > 0 { return Color(.systemGreen) }
        if value < 0 { return Color(.systemRed).opacity(0.8) }
        return DesignSystem.TextColor.secondary
    }

    private func uniqueNHLTeams(from skaters: [NHLSkaterStat]) -> [String] {
        var seen = Set<String>()
        return skaters.compactMap { skater in
            if seen.contains(skater.team) { return nil }
            seen.insert(skater.team)
            return skater.team
        }
    }
}
