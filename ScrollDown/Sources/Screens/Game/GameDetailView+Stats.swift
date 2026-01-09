import SwiftUI

extension GameDetailView {
    func playerStatsSection(_ stats: [PlayerStat]) -> some View {
        CollapsibleSectionCard(
            title: "Player Stats",
            subtitle: "Individual performance",
            isExpanded: $isPlayerStatsExpanded
        ) {
            playerStatsContent(stats)
        }
    }

    @ViewBuilder
    func playerStatsContent(_ stats: [PlayerStat]) -> some View {
        if stats.isEmpty {
            EmptySectionView(text: "Player stats are not yet available.")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    playerStatsHeader
                    ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                        playerStatsRow(stat, isAlternate: index.isMultiple(of: 2))
                    }
                }
                .frame(minWidth: GameDetailLayout.statsTableWidth)
            }
        }
    }

    var playerStatsHeader: some View {
        HStack(spacing: GameDetailLayout.statsColumnSpacing) {
            Text("Player")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("PTS")
                .frame(width: GameDetailLayout.statColumnWidth)
            Text("REB")
                .frame(width: GameDetailLayout.statColumnWidth)
            Text("AST")
                .frame(width: GameDetailLayout.statColumnWidth)
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(.secondary)
        .padding(.vertical, GameDetailLayout.listSpacing)
        .padding(.horizontal, GameDetailLayout.statsHorizontalPadding)
        .background(Color(.systemGray6))
    }

    func playerStatsRow(_ stat: PlayerStat, isAlternate: Bool) -> some View {
        HStack(spacing: GameDetailLayout.statsColumnSpacing) {
            VStack(alignment: .leading, spacing: GameDetailLayout.smallSpacing) {
                Text(stat.playerName)
                    .font(.subheadline.weight(.medium))
                Text(stat.team)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(stat.points.map(String.init) ?? GameDetailConstants.statFallback)
                .frame(width: GameDetailLayout.statColumnWidth)
            Text(stat.rebounds.map(String.init) ?? GameDetailConstants.statFallback)
                .frame(width: GameDetailLayout.statColumnWidth)
            Text(stat.assists.map(String.init) ?? GameDetailConstants.statFallback)
                .frame(width: GameDetailLayout.statColumnWidth)
        }
        .font(.subheadline)
        .padding(.vertical, GameDetailLayout.listSpacing)
        .padding(.horizontal, GameDetailLayout.statsHorizontalPadding)
        .background(isAlternate ? Color(.systemGray6) : Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stat.playerName), \(stat.team)")
        .accessibilityValue("Points \(stat.points ?? 0), rebounds \(stat.rebounds ?? 0), assists \(stat.assists ?? 0)")
    }

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
            VStack(spacing: GameDetailLayout.listSpacing) {
                ForEach(viewModel.teamComparisonStats) { stat in
                    TeamComparisonRowView(
                        stat: stat,
                        homeTeam: stats.first(where: { $0.isHome })?.team ?? "Home",
                        awayTeam: stats.first(where: { !$0.isHome })?.team ?? "Away"
                    )
                }
            }
        }
    }

    var finalScoreSection: some View {
        CollapsibleSectionCard(
            title: "Final Score",
            subtitle: "Wrap-up",
            isExpanded: $isFinalScoreExpanded
        ) {
            finalScoreContent
        }
    }

    var finalScoreContent: some View {
        VStack(spacing: GameDetailLayout.textSpacing) {
            Text(viewModel.game?.scoreDisplay ?? GameDetailConstants.scoreFallback)
                .font(.system(size: GameDetailLayout.finalScoreSize, weight: .bold))
            Text("Final")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GameDetailLayout.listSpacing)
    }
}
