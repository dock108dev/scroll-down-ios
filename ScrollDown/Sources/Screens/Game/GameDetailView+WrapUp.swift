import SwiftUI

// MARK: - Wrap-up Section Extension

extension GameDetailView {
    // MARK: - Wrap-up Section (Tier 4: Reference)

    var wrapUpSection: some View {
        Tier4Container(
            title: "Wrap-up",
            isExpanded: $isWrapUpExpanded
        ) {
            wrapUpContent
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

        // Use actual team colors
        let awayColor = DesignSystem.TeamColors.color(for: game.awayTeam)
        let homeColor = DesignSystem.TeamColors.color(for: game.homeTeam)

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
                    Text(abbreviatedPlayerName(scorer.playerName))
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

    private func abbreviatedPlayerName(_ fullName: String) -> String {
        let parts = fullName.split(separator: " ")
        guard parts.count >= 2 else { return fullName }
        let firstInitial = parts[0].prefix(1)
        let lastName = parts.dropFirst().joined(separator: " ")
        return "\(firstInitial). \(lastName)"
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
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.text) {
            HStack {
                if let handle = post.sourceHandle {
                    Text("@\(handle)")
                        .font(DesignSystem.Typography.rowMeta.weight(.medium))
                        .foregroundColor(GameTheme.accentColor)
                }
                Spacer()
                Text(formatTweetDate(post.postedAt))
                    .font(DesignSystem.Typography.rowMeta)
                    .foregroundColor(.secondary)
            }
            if let text = post.tweetText {
                Text(text)
                    .font(DesignSystem.Typography.rowTitle)
                    .foregroundColor(.primary)
            }
        }
        .padding(DesignSystem.Spacing.elementPadding)
        .background(DesignSystem.Colors.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
    }

    private func formatTweetDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let parsedDate = formatter.date(from: dateString)
            ?? ISO8601DateFormatter().date(from: dateString)
        if let parsedDate {
            return parsedDate.formatted(date: .abbreviated, time: .shortened)
        }
        return dateString
    }
}
