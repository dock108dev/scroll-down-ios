import SwiftUI

// MARK: - Wrap-up Section Extension

extension GameDetailView {
    // MARK: - Wrap-up Section (Tier 4: Reference)

    var wrapUpSection: some View {
        Section(header:
            PinnedSectionHeader(title: "Wrap-up", isExpanded: $isWrapUpExpanded)
                .id(GameSection.final.anchorId)
                .background(GameTheme.background)
        ) {
            if isWrapUpExpanded {
                wrapUpContent
                    .sectionCardBody()
            }
        }
    }

    var wrapUpContent: some View {
        VStack(spacing: GameDetailLayout.sectionSpacing) {
            // Mini boxscore
            if let game = viewModel.game {
                miniBoxscore(game: game)
            } else {
                Text(GameDetailConstants.scorePlaceholder)
                    .font(.system(size: GameDetailLayout.finalScoreSize, weight: .bold))
            }

            // Odds results
            if !viewModel.wrapUpOddsLines.isEmpty {
                wrapUpOddsCard(viewModel.wrapUpOddsLines)
            }

            // Post-game social posts
            postGameSocialContent
        }
    }

    // MARK: - Mini Boxscore

    private func miniBoxscore(game: Game) -> some View {
        let awayWon = (game.awayScore ?? 0) > (game.homeScore ?? 0)
        let homeWon = (game.homeScore ?? 0) > (game.awayScore ?? 0)
        let stats = viewModel.playerStats

        let awayHighScorer = stats
            .filter { $0.team == game.awayTeam }
            .max(by: { ($0.points ?? 0) < ($1.points ?? 0) })

        let homeHighScorer = stats
            .filter { $0.team == game.homeTeam }
            .max(by: { ($0.points ?? 0) < ($1.points ?? 0) })

        // Use matchup-aware team colors (handles same-color teams)
        let awayColor = DesignSystem.TeamColors.matchupColor(for: game.awayTeam, against: game.homeTeam, isHome: false)
        let homeColor = DesignSystem.TeamColors.matchupColor(for: game.homeTeam, against: game.awayTeam, isHome: true)

        return VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 56, alignment: .leading)
                Text("FINAL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                    .frame(width: 56)
                Spacer()
                Text("TOP SCORER")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                    .frame(width: 120, alignment: .trailing)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(DesignSystem.Colors.elevatedBackground)

            // Away team row
            boxscoreTeamRow(
                teamAbbrev: TeamAbbreviations.abbreviation(for: game.awayTeam),
                score: game.awayScore ?? 0,
                isWinner: awayWon,
                highScorer: awayHighScorer,
                teamColor: awayColor,
                isAlternate: false
            )

            // Home team row
            boxscoreTeamRow(
                teamAbbrev: TeamAbbreviations.abbreviation(for: game.homeTeam),
                score: game.homeScore ?? 0,
                isWinner: homeWon,
                highScorer: homeHighScorer,
                teamColor: homeColor,
                isAlternate: true
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor, lineWidth: DesignSystem.borderWidth)
        )
    }

    private func boxscoreTeamRow(
        teamAbbrev: String,
        score: Int,
        isWinner: Bool,
        highScorer: PlayerStat?,
        teamColor: Color,
        isAlternate: Bool
    ) -> some View {
        HStack(spacing: 0) {
            // Team abbreviation with winner indicator
            HStack(spacing: 4) {
                if isWinner {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 8))
                        .foregroundColor(teamColor)
                }
                Text(teamAbbrev)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(teamColor)
            }
            .frame(width: 56, alignment: .leading)

            // Final score
            Text("\(score)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(isWinner ? teamColor : DesignSystem.TextColor.secondary)
                .frame(width: 56)

            Spacer()

            // High scorer with stats
            if let scorer = highScorer {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(scorer.playerName.abbreviatedPlayerName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.TextColor.primary)
                    HStack(spacing: 6) {
                        Text("\(scorer.points ?? 0) pts")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(teamColor)
                        if let reb = scorer.rebounds, reb > 0 {
                            Text("\(reb) reb")
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.TextColor.secondary)
                        }
                        if let ast = scorer.assists, ast > 0 {
                            Text("\(ast) ast")
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.TextColor.secondary)
                        }
                    }
                }
                .frame(width: 120, alignment: .trailing)
            } else {
                Text("--")
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                    .frame(width: 120, alignment: .trailing)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(isAlternate ? DesignSystem.Colors.alternateRowBackground : DesignSystem.Colors.rowBackground)
    }

    // MARK: - Post-Game Social Content

    @ViewBuilder
    var postGameSocialContent: some View {
        let posts = viewModel.postgameSocialPosts
        if posts.isEmpty {
            EmptySectionView(text: "No post-game reactions yet.")
        } else {
            VStack(alignment: .leading, spacing: GameDetailLayout.listSpacing) {
                Text("Reactions")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                ForEach(posts) { post in
                    postGamePostRow(post)
                }
            }
        }
    }

    private func postGamePostRow(_ post: SocialPostEntry) -> some View {
        SocialPostRow(post: post, displayMode: .standard)
    }

    // MARK: - Wrap-up Odds Card

    /// Strip verbose suffixes from server-generated outcome labels.
    /// "GW covered by 15.0" → "GW covered", "Under by 24.5" → "Under", "GW won (-180)" → "GW won"
    private func simplifiedOutcome(_ text: String) -> String {
        var result = text
        if let range = result.range(of: #" by [\d.]+"#, options: .regularExpression) {
            result = String(result[result.startIndex..<range.lowerBound])
        }
        if let range = result.range(of: #" \([^)]+\)$"#, options: .regularExpression) {
            result = String(result[result.startIndex..<range.lowerBound])
        }
        return result
    }

    private func wrapUpOddsCard(_ lines: [GameDetailViewModel.WrapUpOddsLine]) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("ODDS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                Spacer()
                Text("RESULT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignSystem.TextColor.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(DesignSystem.Colors.elevatedBackground)

            ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                HStack(spacing: 0) {
                    Text(line.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.TextColor.primary)
                        .frame(width: 48, alignment: .leading)

                    Text(line.lineType)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                        .frame(width: 36, alignment: .leading)

                    Text(line.line)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.TextColor.secondary)
                        .lineLimit(1)

                    Spacer()

                    if let outcome = line.outcome {
                        Text(simplifiedOutcome(outcome))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.TextColor.primary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(index % 2 != 0 ? DesignSystem.Colors.alternateRowBackground : DesignSystem.Colors.rowBackground)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor, lineWidth: DesignSystem.borderWidth)
        )
    }
}
