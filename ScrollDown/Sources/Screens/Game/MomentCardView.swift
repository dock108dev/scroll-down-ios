import SwiftUI

/// Card view for a story moment (non-expandable)
struct MomentCardView: View {
    let moment: MomentDisplayModel
    let plays: [UnifiedTimelineEvent]
    let homeTeam: String
    let awayTeam: String
    @Binding var isExpanded: Bool  // Kept for API compatibility but unused

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerContent
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor.opacity(0.3), lineWidth: 0.5)
        )
    }

    // MARK: - Header Content

    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                // Left edge accent (only for highlight beat types)
                if moment.isHighlight {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.accent)
                        .frame(width: 3)
                }

                // Narrative text
                Text(moment.narrative)
                    .font(.subheadline.weight(moment.isHighlight ? .semibold : .regular))
                    .foregroundColor(DesignSystem.TextColor.primary)
                    .multilineTextAlignment(.leading)
            }

            // Compact two-column score box (always visible)
            compactScoreBox

            // Mini box score with top performers (if available)
            if let boxScore = moment.cumulativeBoxScore {
                miniBoxScoreView(boxScore)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, moment.isHighlight ? 8 : 12)
    }

    // MARK: - Compact Score Box (Two Column with Time)

    private var compactScoreBox: some View {
        HStack(spacing: 0) {
            // Away team score
            HStack(spacing: 6) {
                Text(awayTeam)
                    .font(.caption)
                    .foregroundColor(DesignSystem.TextColor.secondary)
                    .lineLimit(1)
                Text("\(moment.endScore.away)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundColor(DesignSystem.TextColor.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Time range in center
            if let timeRange = momentTimeRange {
                Text(timeRange)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
            }

            // Home team score
            HStack(spacing: 6) {
                Text("\(moment.endScore.home)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundColor(DesignSystem.TextColor.primary)
                Text(homeTeam)
                    .font(.caption)
                    .foregroundColor(DesignSystem.TextColor.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    /// Time range display (e.g., "Q1 12:00 - 11:03")
    private var momentTimeRange: String? {
        guard let start = moment.startClock else { return nil }
        let periodLabel = "Q\(moment.period)"
        if let end = moment.endClock {
            return "\(periodLabel) \(start) - \(end)"
        }
        return "\(periodLabel) \(start)"
    }

    // MARK: - Mini Box Score

    private func miniBoxScoreView(_ boxScore: MomentBoxScore) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Away team top performer
            if let topAway = boxScore.away.topPlayer {
                playerStatRow(player: topAway, teamName: awayTeam)
            }

            // Home team top performer
            if let topHome = boxScore.home.topPlayer {
                playerStatRow(player: topHome, teamName: homeTeam)
            }
        }
        .padding(.top, 4)
    }

    private func playerStatRow(player: MomentPlayerStat, teamName: String) -> some View {
        HStack(spacing: 6) {
            // Team abbreviation
            Text(teamName)
                .font(.caption2)
                .foregroundColor(DesignSystem.TextColor.tertiary)
                .frame(width: 40, alignment: .leading)

            // Player name
            Text(player.name)
                .font(.caption.weight(.medium))
                .foregroundColor(DesignSystem.TextColor.secondary)
                .lineLimit(1)

            Spacer()

            // Stats (basketball or hockey based on what's available)
            Text(player.pts != nil ? player.basketballStatLine : player.hockeyStatLine)
                .font(.caption2)
                .foregroundColor(DesignSystem.TextColor.tertiary)
        }
    }

}

// MARK: - Previews

#Preview("Moment - Scoring Run") {
    MomentCardView(
        moment: MomentDisplayModel(
            momentIndex: 0,
            narrative: "Thunder go on a 12-0 run to take control of the game.",
            period: 2,
            startClock: "8:45",
            endClock: "5:30",
            startScore: ScoreSnapshot(home: 45, away: 42),
            endScore: ScoreSnapshot(home: 57, away: 42),
            playIds: [100, 101, 102, 103, 104],
            highlightedPlayIds: [101, 103],
            derivedBeatType: .run,
            cumulativeBoxScore: MomentBoxScore(
                home: MomentTeamBoxScore(
                    team: "Thunder",
                    score: 57,
                    players: [MomentPlayerStat(name: "S. Gilgeous-Alexander", pts: 18, reb: 3, ast: 4, threePm: 2, fgm: nil, ftm: nil, goals: nil, assists: nil, sog: nil, plusMinus: nil)],
                    goalie: nil
                ),
                away: MomentTeamBoxScore(
                    team: "Spurs",
                    score: 42,
                    players: [MomentPlayerStat(name: "V. Wembanyama", pts: 12, reb: 8, ast: 2, threePm: 1, fgm: nil, ftm: nil, goals: nil, assists: nil, sog: nil, plusMinus: nil)],
                    goalie: nil
                )
            )
        ),
        plays: [],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(false)
    )
    .padding()
}

#Preview("Moment - Back and Forth") {
    MomentCardView(
        moment: MomentDisplayModel(
            momentIndex: 1,
            narrative: "Teams trade baskets in a competitive stretch of play.",
            period: 3,
            startClock: "12:00",
            endClock: "8:00",
            startScore: ScoreSnapshot(home: 57, away: 50),
            endScore: ScoreSnapshot(home: 65, away: 58),
            playIds: [200, 201, 202],
            highlightedPlayIds: [],
            derivedBeatType: .backAndForth,
            cumulativeBoxScore: nil
        ),
        plays: [],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(false)
    )
    .padding()
}

#Preview("Moment - Expanded with Plays") {
    MomentCardView(
        moment: MomentDisplayModel(
            momentIndex: 2,
            narrative: "Thunder close out the game with a strong finish.",
            period: 4,
            startClock: "2:00",
            endClock: "0:00",
            startScore: ScoreSnapshot(home: 98, away: 92),
            endScore: ScoreSnapshot(home: 112, away: 105),
            playIds: [300, 301, 302],
            highlightedPlayIds: [301],
            derivedBeatType: .closingSequence,
            cumulativeBoxScore: nil
        ),
        plays: [
            UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 4,
                    "game_clock": "0:45",
                    "description": "S. Gilgeous-Alexander makes free throw 1 of 2",
                    "home_score": 110,
                    "away_score": 105
                ],
                index: 301
            )
        ],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(true)
    )
    .padding()
}
