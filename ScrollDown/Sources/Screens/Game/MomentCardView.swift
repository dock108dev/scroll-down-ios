import SwiftUI

/// Expandable card view for a V2 story moment - shows narrative, beat type, and plays
struct MomentCardView: View {
    let moment: MomentDisplayModel
    let plays: [UnifiedTimelineEvent]
    let homeTeam: String
    let awayTeam: String
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible, tappable)
            Button(action: toggleExpansion) {
                headerContent
            }
            .buttonStyle(InteractiveRowButtonStyle())

            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor.opacity(0.3), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    // MARK: - Header Content

    private var headerContent: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left edge accent (only for highlight beat types)
            if moment.isHighlight {
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.Colors.accent)
                    .frame(width: 3)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Primary: Narrative text
                Text(moment.narrative)
                    .font(.subheadline.weight(moment.isHighlight ? .semibold : .regular))
                    .foregroundColor(DesignSystem.TextColor.primary)
                    .lineLimit(2)

                // Secondary: Beat type badge + time range + score
                HStack(spacing: 6) {
                    beatTypeBadge

                    if let timeRange = moment.timeRangeDisplay {
                        Text("·")
                            .font(.caption)
                            .foregroundColor(DesignSystem.TextColor.tertiary)

                        Text(timeRange)
                            .font(.caption)
                            .foregroundColor(DesignSystem.TextColor.tertiary)
                    }

                    Text("·")
                        .font(.caption)
                        .foregroundColor(DesignSystem.TextColor.tertiary)

                    scoreLabel
                }

                // Tertiary: Highlight count (collapsed only)
                if moment.highlightedPlayCount > 0 && !isExpanded {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundColor(DesignSystem.Colors.accent)
                        Text("\(moment.highlightedPlayCount) key play\(moment.highlightedPlayCount == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.TextColor.secondary)
                    }
                }
            }

            Spacer()

            // Right: Expansion indicator
            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundColor(DesignSystem.TextColor.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, moment.isHighlight ? 8 : 12)
        .contentShape(Rectangle())
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.horizontal, 12)

            // Plays list with highlight indicators
            if !plays.isEmpty {
                VStack(spacing: 8) {
                    ForEach(plays) { event in
                        HStack(spacing: 8) {
                            // Star indicator for highlighted plays
                            if moment.isPlayHighlighted(event.playIndex) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.Colors.accent)
                            } else {
                                // Placeholder to maintain alignment
                                Color.clear
                                    .frame(width: 10, height: 10)
                            }

                            UnifiedTimelineRowView(
                                event: event,
                                homeTeam: homeTeam,
                                awayTeam: awayTeam
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
            }

            // Score summary at end of moment
            scoreBoxView
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Score Box View

    private var scoreBoxView: some View {
        HStack(spacing: 0) {
            // Away team score
            VStack(spacing: 2) {
                Text(awayTeam)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                    .lineLimit(1)
                Text("\(moment.endScore.away)")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundColor(DesignSystem.TextColor.primary)
            }
            .frame(maxWidth: .infinity)

            // Score change indicator
            VStack(spacing: 2) {
                Text("Score")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                let awayDiff = moment.endScore.away - moment.startScore.away
                let homeDiff = moment.endScore.home - moment.startScore.home
                Text("+\(awayDiff) / +\(homeDiff)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(DesignSystem.TextColor.secondary)
            }
            .frame(maxWidth: .infinity)

            // Home team score
            VStack(spacing: 2) {
                Text(homeTeam)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                    .lineLimit(1)
                Text("\(moment.endScore.home)")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundColor(DesignSystem.TextColor.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignSystem.borderColor.opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - Helper Views

    private var beatTypeBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: moment.derivedBeatType.iconName)
                .font(.system(size: 9))
            Text(moment.derivedBeatType.displayName)
                .font(.caption)
        }
        .foregroundColor(moment.isHighlight ? DesignSystem.Colors.accent : DesignSystem.TextColor.tertiary)
    }

    private var scoreLabel: some View {
        HStack(spacing: 4) {
            Text("\(moment.startScore.away)-\(moment.startScore.home)")
                .font(.caption.monospacedDigit())
                .foregroundColor(DesignSystem.TextColor.tertiary)

            Image(systemName: "arrow.right")
                .font(.system(size: 8))
                .foregroundColor(DesignSystem.TextColor.tertiary)

            Text("\(moment.endScore.away)-\(moment.endScore.home)")
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundColor(DesignSystem.TextColor.secondary)
        }
    }

    // MARK: - Actions

    private func toggleExpansion() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isExpanded.toggle()
        }
    }
}

// MARK: - Play Index Extension

private extension UnifiedTimelineEvent {
    var playIndex: Int {
        // Extract play index from id or use hash
        if let idStr = id.split(separator: "-").last,
           let idx = Int(idStr) {
            return idx
        }
        return id.hashValue
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
            derivedBeatType: .run
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
            derivedBeatType: .backAndForth
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
            derivedBeatType: .closingSequence
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
