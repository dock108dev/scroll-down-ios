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

            // Mini box score at bottom with end score
            if let miniBox = block.miniBox {
                MiniBoxScoreView(
                    miniBox: miniBox,
                    endScore: block.endScore,
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

/// Compact box score showing score and top performers for a block
struct MiniBoxScoreView: View {
    let miniBox: BlockMiniBox
    let endScore: ScoreSnapshot
    let homeTeam: String
    let awayTeam: String
    let sport: String

    private var isHockey: Bool { sport == "NHL" }

    private var awayAbbrev: String { teamAbbreviation(awayTeam) }
    private var homeAbbrev: String { teamAbbreviation(homeTeam) }

    var body: some View {
        HStack(spacing: 16) {
            // Score column
            VStack(spacing: 4) {
                scoreRow(abbrev: awayAbbrev, score: endScore.away, color: DesignSystem.TeamColors.teamA)
                scoreRow(abbrev: homeAbbrev, score: endScore.home, color: DesignSystem.TeamColors.teamB)
            }

            Divider()
                .frame(height: 36)

            // Players column
            VStack(alignment: .leading, spacing: 4) {
                playersRow(teamBox: miniBox.away)
                playersRow(teamBox: miniBox.home)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func scoreRow(abbrev: String, score: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(abbrev)
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
                .frame(width: 36, alignment: .leading)

            Text("\(score)")
                .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundColor(DesignSystem.TextColor.primary)
                .frame(width: 44, alignment: .trailing)
        }
    }

    private func playersRow(teamBox: BlockTeamMiniBox) -> some View {
        HStack(spacing: 16) {
            ForEach(teamBox.topPlayers.prefix(2), id: \.name) { player in
                playerView(player: player)
            }
        }
    }

    private func playerView(player: BlockPlayerStat) -> some View {
        let isBlockStar = miniBox.isBlockStar(player.name)
        let statLine = isHockey ? player.hockeyStatLine : player.basketballStatLine

        return HStack(spacing: 4) {
            Text(player.name)
                .font(.caption.weight(isBlockStar ? .semibold : .regular))
                .foregroundColor(isBlockStar ? DesignSystem.TextColor.primary : DesignSystem.TextColor.secondary)

            Text(statLine)
                .font(.caption2.monospacedDigit())
                .foregroundColor(DesignSystem.TextColor.tertiary)
        }
    }

    private func teamAbbreviation(_ fullName: String) -> String {
        // Common NBA/NHL team abbreviations
        let abbreviations: [String: String] = [
            "Atlanta Hawks": "ATL", "Boston Celtics": "BOS", "Brooklyn Nets": "BKN",
            "Charlotte Hornets": "CHA", "Chicago Bulls": "CHI", "Cleveland Cavaliers": "CLE",
            "Dallas Mavericks": "DAL", "Denver Nuggets": "DEN", "Detroit Pistons": "DET",
            "Golden State Warriors": "GSW", "Houston Rockets": "HOU", "Indiana Pacers": "IND",
            "LA Clippers": "LAC", "LA Lakers": "LAL", "Los Angeles Clippers": "LAC",
            "Los Angeles Lakers": "LAL", "Memphis Grizzlies": "MEM", "Miami Heat": "MIA",
            "Milwaukee Bucks": "MIL", "Minnesota Timberwolves": "MIN", "New Orleans Pelicans": "NOP",
            "New York Knicks": "NYK", "Oklahoma City Thunder": "OKC", "Orlando Magic": "ORL",
            "Philadelphia 76ers": "PHI", "Phoenix Suns": "PHX", "Portland Trail Blazers": "POR",
            "Sacramento Kings": "SAC", "San Antonio Spurs": "SAS", "Toronto Raptors": "TOR",
            "Utah Jazz": "UTA", "Washington Wizards": "WAS"
        ]

        if let abbrev = abbreviations[fullName] {
            return abbrev
        }

        // Fallback: first 3 letters
        return String(fullName.prefix(3)).uppercased()
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
