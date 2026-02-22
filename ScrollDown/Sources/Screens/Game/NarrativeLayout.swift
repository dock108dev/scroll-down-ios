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

// MARK: - Flow Block Card View

/// A single flow block with narrative and mini box score
struct FlowBlockCardView: View {
    let block: BlockDisplayModel
    let homeTeam: String
    let awayTeam: String
    let sport: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Period indicator (structural anchor)
            Text(block.periodDisplay)
                .textStyle(.structure)

            // Narrative text
            Text(block.narrative)
                .textStyle(.narrative)
                .fixedSize(horizontal: false, vertical: true)

            // Mini box score at bottom with end score
            if let miniBox = block.miniBox {
                MiniBoxScoreView(
                    miniBox: miniBox,
                    endScore: block.endScore,
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    sport: sport,
                    isFirstBlock: block.blockIndex == 0
                )
            }

            // Embedded social post (if present)
            if let post = block.embeddedSocialPost {
                EmbeddedSocialPostView(post: post)
            }
        }
        .padding(.vertical, 16)
    }

}

// MARK: - Mini Box Score View

/// Compact box score showing score and top performers for a block
struct MiniBoxScoreView: View {
    let miniBox: BlockMiniBox
    let endScore: ScoreSnapshot
    let homeTeam: String
    let awayTeam: String
    let sport: String
    var isFirstBlock: Bool = false

    private var isHockey: Bool { sport == "NHL" }
    private var awayAbbrev: String { teamAbbreviation(awayTeam) }
    private var homeAbbrev: String { teamAbbreviation(homeTeam) }

    var body: some View {
        VStack(spacing: 0) {
            // Away team row
            teamRow(
                abbrev: awayAbbrev,
                score: endScore.away,
                players: miniBox.away.topPlayers,
                color: DesignSystem.TeamColors.matchupColor(for: awayTeam, against: homeTeam, isHome: false)
            )

            Divider()
                .padding(.vertical, 6)

            // Home team row
            teamRow(
                abbrev: homeAbbrev,
                score: endScore.home,
                players: miniBox.home.topPlayers,
                color: DesignSystem.TeamColors.matchupColor(for: homeTeam, against: awayTeam, isHome: true)
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DesignSystem.Colors.cardBackground.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func teamRow(abbrev: String, score: Int, players: [BlockPlayerStat], color: Color) -> some View {
        HStack(spacing: 0) {
            // Team & Score
            HStack(spacing: 6) {
                Text(abbrev)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)

                Text("\(score)")
                    .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(DesignSystem.TextColor.primary)
            }
            .frame(width: 70, alignment: .leading)

            // Players
            HStack(spacing: 12) {
                ForEach(players.prefix(2), id: \.name) { player in
                    playerCell(player: player)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func playerCell(player: BlockPlayerStat) -> some View {
        let isBlockStar = miniBox.isBlockStar(player.name)
        let statLine = isHockey ? player.compactHockeyStats : player.compactBasketballStats
        let deltaLine: String? = isFirstBlock ? nil : (isHockey ? player.hockeyDeltaLine : player.basketballDeltaLine)

        return VStack(alignment: .leading, spacing: 1) {
            Text(player.name)
                .font(.system(size: 12, weight: isBlockStar ? .semibold : .regular))
                .foregroundColor(isBlockStar ? DesignSystem.TextColor.primary : DesignSystem.TextColor.secondary)
                .lineLimit(1)

            Text(statLine)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(DesignSystem.TextColor.tertiary)
                .lineLimit(1)

            if let deltaLine {
                Text(deltaLine)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(DesignSystem.Accent.primary)
                    .lineLimit(1)
            }
        }
        .frame(alignment: .leading)
    }

    private func teamAbbreviation(_ fullName: String) -> String {
        TeamAbbreviations.abbreviation(for: fullName)
    }
}

// MARK: - Embedded Social Post View

/// Displays an embedded social post within a flow block
struct EmbeddedSocialPostView: View {
    let post: SocialPostEntry

    var body: some View {
        SocialPostRow(post: post, displayMode: .embedded)
    }
}

// MARK: - Flow Container View

/// Container for flow blocks
struct FlowContainerView: View {
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
                    FlowBlockCardView(
                        block: block,
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        sport: sport
                    )
                    .id("block-\(block.blockIndex)")
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: PlayRowFramePreferenceKey.self,
                                value: [-(block.blockIndex + 1): geo.frame(in: .named(GameDetailLayout.scrollCoordinateSpace))]
                            )
                        }
                    )

                    if block.blockIndex < blocks.count - 1 {
                        Divider()
                            .background(DesignSystem.borderColor.opacity(0.2))
                    }
                }
            }
            .padding(.leading, NarrativeLayoutConfig.contentLeadingPadding)
            .padding(.trailing, NarrativeLayoutConfig.contentLeadingPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }
}
