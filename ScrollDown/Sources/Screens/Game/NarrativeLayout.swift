import SwiftUI

// MARK: - Layout Constants

enum NarrativeLayoutConfig {
    static let spineWidth: CGFloat = 2
    static let spineOpacity: Double = 0.15
    static let spineLeadingPadding: CGFloat = 0
    static let contentLeadingPadding: CGFloat = 16
}

// MARK: - Narrative Spine

/// Subtle left-side vertical element implying chronological flow
struct NarrativeSpine: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        DesignSystem.borderColor.opacity(0.05),
                        DesignSystem.borderColor.opacity(NarrativeLayoutConfig.spineOpacity),
                        DesignSystem.borderColor.opacity(NarrativeLayoutConfig.spineOpacity),
                        DesignSystem.borderColor.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: NarrativeLayoutConfig.spineWidth)
    }
}

// MARK: - Story Block Card View

/// A single story block with narrative and mini box score
struct StoryBlockCardView: View {
    let block: BlockDisplayModel
    let homeTeam: String
    let awayTeam: String
    let sport: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Period indicator
            Text(block.periodDisplay)
                .textStyle(.metadataSmall)

            // Narrative text
            Text(block.narrative)
                .textStyle(.narrative)
                .fixedSize(horizontal: false, vertical: true)

            // Mini box score at bottom
            if let miniBox = block.miniBox {
                MiniBoxScoreView(
                    miniBox: miniBox,
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    sport: sport
                )
            }

            // Embedded tweet (if present)
            if let tweet = block.embeddedTweet {
                EmbeddedTweetView(tweet: tweet)
            }
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Mini Box Score View

/// Compact box score showing top performers for a block
struct MiniBoxScoreView: View {
    let miniBox: BlockMiniBox
    let homeTeam: String
    let awayTeam: String
    let sport: String

    private var isHockey: Bool { sport == "NHL" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            teamStatLine(
                team: awayTeam,
                teamBox: miniBox.away,
                color: DesignSystem.TeamColors.teamA
            )

            teamStatLine(
                team: homeTeam,
                teamBox: miniBox.home,
                color: DesignSystem.TeamColors.teamB
            )
        }
        .padding(12)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func teamStatLine(team: String, teamBox: BlockTeamMiniBox, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(team)
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
                .frame(width: 44, alignment: .leading)

            ForEach(teamBox.topPlayers.prefix(2), id: \.name) { player in
                playerStatView(player: player, isBlockStar: miniBox.isBlockStar(player.name))
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func playerStatView(player: BlockPlayerStat, isBlockStar: Bool) -> some View {
        let statLine = isHockey ? player.hockeyStatLine : player.basketballStatLine

        HStack(spacing: 2) {
            Text(player.name)
                .font(.caption.weight(isBlockStar ? .semibold : .regular))
                .foregroundColor(isBlockStar ? DesignSystem.TextColor.primary : DesignSystem.TextColor.secondary)

            Text(statLine)
                .font(.caption2.monospacedDigit())
                .foregroundColor(DesignSystem.TextColor.tertiary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            isBlockStar
                ? DesignSystem.Colors.accent.opacity(0.1)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Embedded Tweet View

/// Displays an embedded tweet within a story block
struct EmbeddedTweetView: View {
    let tweet: EmbeddedTweet

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "bubble.left.fill")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                Text(tweet.authorHandle)
                    .font(.caption.weight(.medium))
                    .foregroundColor(DesignSystem.TextColor.secondary)
            }

            Text(tweet.text)
                .font(.subheadline)
                .foregroundColor(DesignSystem.TextColor.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(DesignSystem.Colors.cardBackground.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignSystem.borderColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Story Container View

/// Container for story blocks
struct StoryContainerView: View {
    @ObservedObject var viewModel: GameDetailViewModel

    var body: some View {
        let blocks = viewModel.blockDisplayModels
        let homeTeam = viewModel.game?.homeTeam ?? "Home"
        let awayTeam = viewModel.game?.awayTeam ?? "Away"
        let sport = viewModel.game?.leagueCode ?? "NBA"

        HStack(alignment: .top, spacing: 0) {
            NarrativeSpine()
                .padding(.leading, NarrativeLayoutConfig.spineLeadingPadding)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(blocks) { block in
                    StoryBlockCardView(
                        block: block,
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        sport: sport
                    )

                    if block.blockIndex < blocks.count - 1 {
                        Divider()
                            .background(DesignSystem.borderColor.opacity(0.2))
                    }
                }
            }
            .padding(.leading, NarrativeLayoutConfig.contentLeadingPadding)
        }
    }
}
