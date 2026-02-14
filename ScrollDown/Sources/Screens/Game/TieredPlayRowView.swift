import SwiftUI

/// Row view for Tier 1 (Primary) events
/// Strongest visual weight - bold typography, accent bar, larger spacing
struct Tier1PlayRowView: View {
    let event: UnifiedTimelineEvent
    let homeTeam: String
    let awayTeam: String

    /// Resolve which full team name this play belongs to (home or away)
    private var resolvedTeamName: String? {
        guard let team = event.team else { return nil }
        let teamLower = team.lowercased()
        let homeAbbrev = TeamAbbreviations.abbreviation(for: homeTeam).lowercased()
        let awayAbbrev = TeamAbbreviations.abbreviation(for: awayTeam).lowercased()

        if teamLower == homeAbbrev || homeTeam.lowercased().contains(teamLower) {
            return homeTeam
        } else if teamLower == awayAbbrev || awayTeam.lowercased().contains(teamLower) {
            return awayTeam
        }
        return nil
    }

    /// Accent bar color from resolved team
    private var accentColor: Color {
        if let teamName = resolvedTeamName {
            let isHome = teamName == homeTeam
            return DesignSystem.TeamColors.matchupColor(
                for: teamName,
                against: isHome ? awayTeam : homeTeam,
                isHome: isHome
            )
        }
        return DesignSystem.Colors.accent
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                // Accent bar colored by scoring team
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: 3)

                // Time column
                VStack(alignment: .trailing, spacing: 2) {
                    if let clock = event.gameClock {
                        Text(clock)
                            .font(.caption.weight(.medium).monospacedDigit())
                            .foregroundColor(DesignSystem.TextColor.secondary)
                    }
                    if let label = event.periodLabel {
                        Text(label)
                            .font(.caption2)
                            .foregroundColor(DesignSystem.TextColor.tertiary)
                    }
                }
                .frame(width: 44, alignment: .trailing)

                // Content - bold treatment
                VStack(alignment: .leading, spacing: 4) {
                    if let description = event.description {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            if let teamName = resolvedTeamName {
                                Text(TeamAbbreviations.abbreviation(for: teamName))
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(accentColor)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(accentColor.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            Text(description)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(DesignSystem.TextColor.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Score change emphasis with team colors
                    if let home = event.homeScore, let away = event.awayScore {
                        HStack(spacing: 4) {
                            Text(TeamAbbreviations.abbreviation(for: awayTeam))
                                .font(.caption.weight(.bold))
                                .foregroundColor(DesignSystem.TeamColors.matchupColor(for: awayTeam, against: homeTeam, isHome: false))
                            Text("\(away)")
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundColor(DesignSystem.TextColor.primary)
                            Text("–")
                                .font(.caption)
                                .foregroundColor(DesignSystem.TextColor.tertiary)
                            Text("\(home)")
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundColor(DesignSystem.TextColor.primary)
                            Text(TeamAbbreviations.abbreviation(for: homeTeam))
                                .font(.caption.weight(.bold))
                                .foregroundColor(DesignSystem.TeamColors.matchupColor(for: homeTeam, against: awayTeam, isHome: true))
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scoring play")
        .accessibilityValue(event.description ?? "")
    }
}

/// Row view for Tier 2 (Secondary) events
/// Visible but de-emphasized — medium-weight font, left accent line, subtle background
struct Tier2PlayRowView: View {
    let event: UnifiedTimelineEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Time column - muted
            VStack(alignment: .trailing, spacing: 2) {
                if let clock = event.gameClock {
                    Text(clock)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                }
            }
            .frame(width: 44, alignment: .trailing)

            // Left accent line — distinguishes T2 from T3's dot
            Rectangle()
                .fill(DesignSystem.TextColor.tertiary.opacity(0.35))
                .frame(width: 2)

            // Content — medium weight, clearly above T3's caption2/tertiary
            if let description = event.description {
                Text(description)
                    .font(.caption.weight(.medium))
                    .foregroundColor(DesignSystem.TextColor.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Play")
        .accessibilityValue(event.description ?? "")
    }
}

/// Row view for Tier 3 (Tertiary) events - individual event within expanded group
/// Minimal visual weight - smallest font, lightest color
struct Tier3PlayRowView: View {
    let event: UnifiedTimelineEvent

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Minimal time
            if let clock = event.gameClock {
                Text(clock)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(DesignSystem.TextColor.tertiary.opacity(0.7))
                    .frame(width: 40, alignment: .trailing)
            }

            // Dot indicator
            Circle()
                .fill(DesignSystem.TextColor.tertiary.opacity(0.4))
                .frame(width: 4, height: 4)

            // Minimal description
            if let description = event.description {
                Text(description)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Play")
        .accessibilityValue(event.description ?? "")
    }
}

/// Container view that renders a TieredPlayGroup appropriately based on tier
struct TieredPlayGroupView: View {
    let group: TieredPlayGroup
    let homeTeam: String
    let awayTeam: String

    var body: some View {
        switch group.tier {
        case .primary:
            // T1: flush left — most prominent
            ForEach(group.events) { event in
                Tier1PlayRowView(
                    event: event,
                    homeTeam: homeTeam,
                    awayTeam: awayTeam
                )
            }

        case .secondary:
            // T2: indented once
            ForEach(group.events) { event in
                Tier2PlayRowView(event: event)
                    .padding(.leading, 16)
            }

        case .tertiary:
            // T3: indented twice — least prominent
            ForEach(group.events) { event in
                Tier3PlayRowView(event: event)
                    .padding(.leading, 32)
            }
        }
    }
}

// MARK: - Previews

#Preview("Tier 1 - Scoring Play") {
    Tier1PlayRowView(
        event: UnifiedTimelineEvent(
            from: [
                "event_type": "pbp",
                "period": 4,
                "game_clock": "1:45",
                "description": "S. Curry makes 3-pt shot from 28 ft",
                "home_score": 108,
                "away_score": 105
            ],
            index: 0,
            sport: "NBA"
        ),
        homeTeam: "Warriors",
        awayTeam: "Lakers"
    )
    .padding()
}

#Preview("Tier 2 - Foul") {
    Tier2PlayRowView(
        event: UnifiedTimelineEvent(
            from: [
                "event_type": "pbp",
                "period": 2,
                "game_clock": "5:30",
                "description": "L. James personal foul (P2.T3)"
            ],
            index: 0,
            sport: "NBA"
        )
    )
    .padding()
}

#Preview("Tier 3 - Inline") {
    VStack(spacing: 2) {
        Tier3PlayRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "8:45",
                    "description": "MISS A. Davis 16' Jump Shot"
                ],
                index: 0,
                sport: "NBA"
            )
        )
        Tier3PlayRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "8:42",
                    "description": "D. Green defensive rebound"
                ],
                index: 1,
                sport: "NBA"
            )
        )
    }
    .padding()
}

#Preview("All Tiers") {
    ScrollView {
        VStack(spacing: 8) {
            Tier1PlayRowView(
                event: UnifiedTimelineEvent(
                    from: [
                        "event_type": "pbp",
                        "period": 4,
                        "game_clock": "0:45",
                        "description": "S. Curry makes go-ahead 3-pt shot",
                        "home_score": 110,
                        "away_score": 108
                    ],
                    index: 0,
                    sport: "NBA"
                ),
                homeTeam: "Warriors",
                awayTeam: "Lakers"
            )

            Tier2PlayRowView(
                event: UnifiedTimelineEvent(
                    from: [
                        "event_type": "pbp",
                        "period": 4,
                        "game_clock": "0:30",
                        "description": "L. James turnover (bad pass)"
                    ],
                    index: 1,
                    sport: "NBA"
                )
            )

            Tier3PlayRowView(
                event: UnifiedTimelineEvent(
                    from: [
                        "event_type": "pbp",
                        "period": 1,
                        "game_clock": "8:45",
                        "description": "MISS A. Davis 16' Jump Shot"
                    ],
                    index: 0,
                    sport: "NBA"
                )
            )
        }
        .padding()
    }
}
