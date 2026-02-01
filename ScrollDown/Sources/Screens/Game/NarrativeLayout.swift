import SwiftUI

// MARK: - Narrative Layout System
/// Creates a story-first experience where the game reads as continuous narrative
/// with expandable footnotes for play details

// MARK: - Layout Constants

enum NarrativeLayoutConfig {
    /// Spine styling
    static let spineWidth: CGFloat = 2
    static let spineOpacity: Double = 0.15
    static let spineLeadingPadding: CGFloat = 0

    /// Paragraph styling
    static let paragraphSpacing: CGFloat = 28
    static let paragraphLineSpacing: CGFloat = 6
    static let contentLeadingPadding: CGFloat = 16

    /// Footnote styling
    static let footnoteIndent: CGFloat = 12
    static let footnoteSpacing: CGFloat = 6
    static let expanderTopPadding: CGFloat = 12
}

// MARK: - Narrative Spine

/// Subtle left-side vertical element implying chronological flow
/// Runs full height of narrative section, never visually dominant
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

// MARK: - Narrative Block

/// A single narrative paragraph with inline play expansion
/// Represents a state change in the game
struct NarrativeBlockView: View {
    let moment: MomentDisplayModel
    let plays: [StoryPlay]
    let homeTeam: String
    let awayTeam: String
    let isHighlighted: (Int) -> Bool
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Time context (subtle, metadata)
            if let timeRange = momentTimeRange {
                Text(timeRange)
                    .textStyle(.metadataSmall)
                    .padding(.bottom, 4)
            }

            // Narrative text - primary content, largest presence
            Text(moment.narrative)
                .textStyle(moment.isHighlight ? .narrativeEmphasis : .narrative)
                .fixedSize(horizontal: false, vertical: true)

            // Inline score context
            scoreContextView
                .padding(.top, 8)

            // Footnote expander (only if plays exist)
            if !plays.isEmpty {
                footnoteExpanderView
                    .padding(.top, NarrativeLayoutConfig.expanderTopPadding)
            }

            // Expanded plays (inline footnotes)
            if isExpanded && !plays.isEmpty {
                InlineFootnotePlays(
                    plays: plays,
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    isHighlighted: isHighlighted
                )
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }

    // MARK: - Time Range

    private var momentTimeRange: String? {
        guard let start = moment.startClock else { return nil }
        let periodLabel = "Q\(moment.period)"
        if let end = moment.endClock {
            return "\(periodLabel) \(start) – \(end)"
        }
        return "\(periodLabel) \(start)"
    }

    // MARK: - Score Context

    private var scoreContextView: some View {
        HStack(spacing: 12) {
            // Away score
            HStack(spacing: 4) {
                Text(awayTeam)
                    .textStyle(.labelSmall, color: DesignSystem.TeamColors.teamA)
                Text("\(moment.endScore.away)")
                    .textStyle(.scoreDisplay, color: DesignSystem.TeamColors.teamA)
            }

            Text("–")
                .textStyle(.metadata)

            // Home score
            HStack(spacing: 4) {
                Text("\(moment.endScore.home)")
                    .textStyle(.scoreDisplay, color: DesignSystem.TeamColors.teamB)
                Text(homeTeam)
                    .textStyle(.labelSmall, color: DesignSystem.TeamColors.teamB)
            }
        }
    }

    // MARK: - Footnote Expander

    private var footnoteExpanderView: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                    .frame(width: 10)

                Text(isExpanded ? "Hide plays" : "View \(plays.count) play\(plays.count == 1 ? "" : "s")")
                    .textStyle(.labelSmall)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "Hide plays for this paragraph" : "View \(plays.count) plays for this paragraph")
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
    }
}

// MARK: - Inline Footnote Plays

/// Expanded plays shown inline under a narrative paragraph
/// Visually indented, smaller typography, reduced contrast
struct InlineFootnotePlays: View {
    let plays: [StoryPlay]
    let homeTeam: String
    let awayTeam: String
    let isHighlighted: (Int) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: NarrativeLayoutConfig.footnoteSpacing) {
            ForEach(plays, id: \.playId) { play in
                FootnotePlayRowView(
                    play: play,
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    isHighlighted: isHighlighted(play.playId)
                )
            }
        }
        .padding(.leading, NarrativeLayoutConfig.footnoteIndent)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Expanded plays for this paragraph")
    }
}

// MARK: - Footnote Play Row

/// Individual play within footnote expansion
/// Smaller, indented, clearly subordinate to narrative
struct FootnotePlayRowView: View {
    let play: StoryPlay
    let homeTeam: String
    let awayTeam: String
    let isHighlighted: Bool

    private var tier: PlayTier {
        guard let desc = play.description?.lowercased() else { return .tertiary }

        // Simple tier classification for story plays
        if isScoringPlay(desc) {
            return .primary
        } else if isTier2Play(desc) {
            return .secondary
        }
        return .tertiary
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Visual indicator based on tier
            tierIndicator
                .frame(width: 3)

            // Time
            if let clock = play.clock {
                Text(clock)
                    .textStyle(.metadataSmall)
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }

            // Description
            VStack(alignment: .leading, spacing: 2) {
                if let description = play.description {
                    Text(description)
                        .textStyle(tier == .primary ? .labelSmall : .metadataSmall,
                                   color: tier == .primary
                                       ? DesignSystem.TextColor.primary
                                       : DesignSystem.TextColor.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Score for scoring plays
                if tier == .primary, let home = play.homeScore, let away = play.awayScore {
                    Text("\(awayTeam) \(away) – \(home) \(homeTeam)")
                        .font(.caption2.weight(.medium).monospacedDigit())
                        .foregroundColor(DesignSystem.TextColor.scoreHighlight)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, tier == .primary ? 6 : 4)
        .padding(.horizontal, 8)
        .background(
            tier == .primary
                ? DesignSystem.Colors.cardBackground.opacity(0.5)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    private var tierIndicator: some View {
        switch tier {
        case .primary:
            RoundedRectangle(cornerRadius: 1)
                .fill(DesignSystem.Colors.accent)
        case .secondary:
            RoundedRectangle(cornerRadius: 1)
                .fill(DesignSystem.borderColor.opacity(0.5))
        case .tertiary:
            Circle()
                .fill(DesignSystem.borderColor.opacity(0.3))
                .frame(width: 3, height: 3)
        }
    }

    private func isScoringPlay(_ desc: String) -> Bool {
        desc.contains("makes") ||
        (desc.contains("free throw") && !desc.contains("miss")) ||
        (desc.contains("dunk") && !desc.contains("miss")) ||
        (desc.contains("layup") && !desc.contains("miss")) ||
        (desc.contains("goal") && !desc.contains("no goal"))
    }

    private func isTier2Play(_ desc: String) -> Bool {
        desc.contains("foul") ||
        desc.contains("turnover") ||
        desc.contains("steal") ||
        desc.contains("violation") ||
        desc.contains("penalty")
    }
}

// MARK: - Narrative Container

/// Full narrative story container with spine and paragraph flow
/// No card background - this IS the page
struct NarrativeContainerView: View {
    @ObservedObject var viewModel: GameDetailViewModel
    @Binding var expandedMoments: Set<Int>

    var body: some View {
        let moments = viewModel.momentDisplayModels
        let homeTeam = viewModel.game?.homeTeam ?? "Home"
        let awayTeam = viewModel.game?.awayTeam ?? "Away"

        HStack(alignment: .top, spacing: 0) {
            // Visual spine - subtle chronological indicator
            NarrativeSpine()
                .padding(.leading, NarrativeLayoutConfig.spineLeadingPadding)

            // Narrative content
            VStack(alignment: .leading, spacing: NarrativeLayoutConfig.paragraphSpacing) {
                ForEach(moments.indices, id: \.self) { index in
                    let moment = moments[index]
                    let plays = viewModel.playsForMoment(moment)

                    NarrativeBlockView(
                        moment: moment,
                        plays: plays,
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        isHighlighted: { playId in
                            viewModel.isPlayHighlighted(playId, in: moment)
                        },
                        isExpanded: Binding(
                            get: { expandedMoments.contains(moment.momentIndex) },
                            set: { newValue in
                                if newValue {
                                    expandedMoments.insert(moment.momentIndex)
                                } else {
                                    expandedMoments.remove(moment.momentIndex)
                                }
                            }
                        )
                    )
                }
            }
            .padding(.leading, NarrativeLayoutConfig.contentLeadingPadding)
        }
    }
}

// MARK: - Previews

#Preview("Narrative Block") {
    NarrativeBlockView(
        moment: MomentDisplayModel(
            momentIndex: 0,
            narrative: "The Warriors surged ahead with a devastating 12-2 run sparked by Curry's back-to-back threes. The Lakers called timeout trailing by double digits for the first time.",
            period: 2,
            startClock: "8:45",
            endClock: "5:30",
            startScore: ScoreSnapshot(home: 45, away: 42),
            endScore: ScoreSnapshot(home: 57, away: 44),
            playIds: [1, 2, 3],
            highlightedPlayIds: [1, 2],
            derivedBeatType: .run,
            cumulativeBoxScore: nil
        ),
        plays: [
            StoryPlay(playId: 1, playIndex: 1, period: 2, clock: "8:45", description: "S. Curry makes 3-pt shot from 28 ft", homeScore: 48, awayScore: 42),
            StoryPlay(playId: 2, playIndex: 2, period: 2, clock: "8:20", description: "L. James turnover (bad pass)", homeScore: 48, awayScore: 42),
            StoryPlay(playId: 3, playIndex: 3, period: 2, clock: "8:05", description: "S. Curry makes 3-pt shot from 26 ft", homeScore: 51, awayScore: 42)
        ],
        homeTeam: "Warriors",
        awayTeam: "Lakers",
        isHighlighted: { [1, 2].contains($0) },
        isExpanded: .constant(true)
    )
    .padding()
}

#Preview("Footnote Play Row - Tier 1") {
    FootnotePlayRowView(
        play: StoryPlay(
            playId: 1,
            playIndex: 1,
            period: 4,
            clock: "1:45",
            description: "S. Curry makes 3-pt shot from 28 ft",
            homeScore: 108,
            awayScore: 105
        ),
        homeTeam: "Warriors",
        awayTeam: "Lakers",
        isHighlighted: true
    )
    .padding()
}

#Preview("Footnote Play Row - Tier 2") {
    FootnotePlayRowView(
        play: StoryPlay(
            playId: 2,
            playIndex: 2,
            period: 2,
            clock: "5:30",
            description: "L. James personal foul (P2.T3)"
        ),
        homeTeam: "Warriors",
        awayTeam: "Lakers",
        isHighlighted: false
    )
    .padding()
}
