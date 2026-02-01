import SwiftUI

/// Main story view container for completed games - TIER 1 (PRIMARY)
/// Feels like the page itself - no cards, largest typography, generous spacing
/// This is what users should read first and understand the game from
struct GameStoryView: View {
    @ObservedObject var viewModel: GameDetailViewModel
    @Binding var isCompactStoryExpanded: Bool
    @State private var showingFullPlayByPlay = false
    @State private var collapsedQuarters: Set<Int> = []
    @State private var hasInitializedCollapsed = false

    var body: some View {
        // TIER 1: No card container - this IS the page content
        // Visual rhythm: generous spacing between moments creates natural reading pauses
        VStack(alignment: .leading, spacing: 0) {
            // Story moments as flowing narrative with rhythm
            let moments = viewModel.momentDisplayModels
            ForEach(moments.indices, id: \.self) { index in
                Tier1MomentView(
                    moment: moments[index],
                    homeTeam: viewModel.game?.homeTeam ?? "Home",
                    awayTeam: viewModel.game?.awayTeam ?? "Away"
                )

                // Visual pause between moments (not after last one)
                if index < moments.count - 1 {
                    MomentDivider()
                }
            }

            // Transition to secondary content
            if viewModel.hasUnifiedTimeline {
                ContentBreak()

                viewAllPlaysButton
            }
        }
        .sheet(isPresented: $showingFullPlayByPlay) {
            FullPlayByPlayView(viewModel: viewModel)
        }
    }

    // MARK: - Quarter Grouping (kept for potential future use)

    private var groupedMomentsByQuarter: [QuarterMomentGroup] {
        let moments = viewModel.momentDisplayModels
        var groups: [Int: [MomentDisplayModel]] = [:]

        for moment in moments {
            let period = moment.period
            groups[period, default: []].append(moment)
        }

        return groups.keys.sorted().map { quarter in
            QuarterMomentGroup(quarter: quarter, moments: groups[quarter] ?? [])
        }
    }

    private func quarterTitle(_ quarter: Int) -> String {
        if quarter <= 4 {
            return "Quarter \(quarter)"
        } else {
            return "OT\(quarter - 4)"
        }
    }

    // MARK: - Combined Narrative

    private var combinedNarrative: String? {
        let moments = Array(viewModel.momentDisplayModels.prefix(2))
        let narratives = moments.map { $0.narrative }
        return narratives.isEmpty ? nil : narratives.joined(separator: " ")
    }

    // MARK: - Compact Story Section

    private func compactStorySection(_ story: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.caption)
                Text("Game Story")
                    .font(.caption.weight(.semibold))
                Spacer()
            }
            .foregroundColor(DesignSystem.TextColor.secondary)

            Text(story)
                .font(.subheadline)
                .foregroundColor(DesignSystem.TextColor.primary)
                .lineLimit(isCompactStoryExpanded ? nil : 3)

            if story.count > 200 {
                Button(isCompactStoryExpanded ? "Show Less" : "Read More") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCompactStoryExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.accent)
                .buttonStyle(SubtleInteractiveButtonStyle())
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.cardBackground.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor.opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - View All Plays Button

    private var viewAllPlaysButton: some View {
        Button {
            showingFullPlayByPlay = true
        } label: {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.caption)
                Text("View All Plays")
                    .font(.caption.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .foregroundColor(DesignSystem.Colors.accent)
            .padding(DesignSystem.Spacing.elementPadding)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
            .contentShape(Rectangle())
        }
        .buttonStyle(InteractiveRowButtonStyle())
    }
}

// MARK: - Quarter Moment Group

private struct QuarterMomentGroup {
    let quarter: Int
    let moments: [MomentDisplayModel]
}

// MARK: - Tier 1 Moment View (No Card)

/// Primary narrative moment - no card container, largest typography
/// This is the main content users read to understand the game
struct Tier1MomentView: View {
    let moment: MomentDisplayModel
    let homeTeam: String
    let awayTeam: String

    var body: some View {
        VStack(alignment: .leading, spacing: TierLayout.Primary.lineSpacing) {
            // Time context (subtle, not prominent)
            if let timeRange = momentTimeRange {
                Text(timeRange)
                    .font(.caption)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
            }

            // Narrative text - LARGEST typography on screen
            Text(moment.narrative)
                .font(TierLayout.Primary.narrativeFont.weight(moment.isHighlight ? .medium : .regular))
                .foregroundColor(DesignSystem.TextColor.primary)
                .lineSpacing(TierLayout.Primary.lineSpacing)
                .fixedSize(horizontal: false, vertical: true)

            // Score context (inline, not boxed)
            HStack(spacing: 12) {
                // Away score
                HStack(spacing: 4) {
                    Text(awayTeam)
                        .font(.caption.weight(.medium))
                        .foregroundColor(DesignSystem.TeamColors.teamA)
                    Text("\(moment.endScore.away)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundColor(DesignSystem.TeamColors.teamA)
                }

                Text("–")
                    .font(.caption)
                    .foregroundColor(DesignSystem.TextColor.tertiary)

                // Home score
                HStack(spacing: 4) {
                    Text("\(moment.endScore.home)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundColor(DesignSystem.TeamColors.teamB)
                    Text(homeTeam)
                        .font(.caption.weight(.medium))
                        .foregroundColor(DesignSystem.TeamColors.teamB)
                }
            }

            // Mini box score (if available) - subtle treatment
            if let boxScore = moment.cumulativeBoxScore {
                Tier1BoxScoreView(boxScore: boxScore, homeTeam: homeTeam, awayTeam: awayTeam)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private var momentTimeRange: String? {
        guard let start = moment.startClock else { return nil }
        let periodLabel = "Q\(moment.period)"
        if let end = moment.endClock {
            return "\(periodLabel) \(start) – \(end)"
        }
        return "\(periodLabel) \(start)"
    }
}

// MARK: - Tier 1 Box Score View (Subtle)

/// Minimal box score for Tier 1 - doesn't compete with narrative
private struct Tier1BoxScoreView: View {
    let boxScore: MomentBoxScore
    let homeTeam: String
    let awayTeam: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let topAway = boxScore.away.topPlayer {
                playerLine(player: topAway, team: awayTeam, color: DesignSystem.TeamColors.teamA)
            }
            if let topHome = boxScore.home.topPlayer {
                playerLine(player: topHome, team: homeTeam, color: DesignSystem.TeamColors.teamB)
            }
        }
    }

    private func playerLine(player: MomentPlayerStat, team: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(player.name)
                .font(.caption2.weight(.medium))
                .foregroundColor(DesignSystem.TextColor.secondary)
            Text(player.pts != nil ? player.basketballStatLine : player.hockeyStatLine)
                .font(.caption2)
                .foregroundColor(DesignSystem.TextColor.tertiary)
        }
    }
}

// MARK: - Moment Divider

/// Visual pause between story moments
/// Creates natural reading rhythm without heavy separation
private struct MomentDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(DesignSystem.borderColor.opacity(0.2))
                .frame(height: 1)
                .frame(maxWidth: 40)

            Circle()
                .fill(DesignSystem.borderColor.opacity(0.3))
                .frame(width: 4, height: 4)

            Rectangle()
                .fill(DesignSystem.borderColor.opacity(0.2))
                .frame(height: 1)
                .frame(maxWidth: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VisualRhythm.primarySpacing)
    }
}

// MARK: - Previews

#Preview("Game Story View") {
    let viewModel = GameDetailViewModel()
    return ScrollView {
        GameStoryView(
            viewModel: viewModel,
            isCompactStoryExpanded: .constant(false)
        )
        .padding()
    }
}
