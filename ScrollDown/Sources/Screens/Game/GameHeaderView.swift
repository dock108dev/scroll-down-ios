import SwiftUI

// MARK: - Game Header View
/// Editorial, flow-first header anchoring context, not score.
/// Design philosophy: Calm, intentional, identical across all leagues.

struct GameHeaderView: View {
    let game: Game
    var scoreRevealed: Bool = false
    var onRevealScore: (() -> Void)? = nil
    var scoreRevealMode: ScoreRevealMode = .onMarkRead
    var hasReadingPosition: Bool = false
    var resumeText: String? = nil
    var displayAwayScore: Int? = nil
    var displayHomeScore: Int? = nil

    @State private var hasAppeared = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Whether the score should be shown based on preference + game state
    private var shouldShowScore: Bool {
        // Display scores provided by scroll tracking or hold-to-reveal
        if displayAwayScore != nil && displayHomeScore != nil { return true }
        // Already explicitly revealed (e.g. wrap-up opened)
        if scoreRevealed { return true }
        // Check preference
        switch scoreRevealMode {
        case .always:
            return game.awayScore != nil && game.homeScore != nil
        case .resumed:
            return hasReadingPosition && game.awayScore != nil && game.homeScore != nil
        case .onMarkRead:
            return false
        }
    }

    /// Resolved away score: display score (from scroll position) takes priority over game score
    private var resolvedAwayScore: Int? {
        displayAwayScore ?? game.awayScore
    }

    /// Resolved home score: display score (from scroll position) takes priority over game score
    private var resolvedHomeScore: Int? {
        displayHomeScore ?? game.homeScore
    }

    private var awayColor: Color {
        DesignSystem.TeamColors.matchupColor(for: game.awayTeam, against: game.homeTeam, isHome: false)
    }

    private var homeColor: Color {
        DesignSystem.TeamColors.matchupColor(for: game.homeTeam, against: game.awayTeam, isHome: true)
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Primary Row - Team Matchup (NO SCORE - spoiler free!)
            HStack(spacing: 0) {
                // Away team block (left side)
                TappableTeamBlock(
                    teamName: game.awayTeam,
                    opponentName: game.homeTeam,
                    leagueCode: game.leagueCode,
                    isHome: false
                )

                Spacer()

                // Center: score if revealed (or earned via scrolling), otherwise "vs"
                if shouldShowScore, let away = resolvedAwayScore, let home = resolvedHomeScore {
                    VStack(spacing: 2) {
                        HStack(spacing: 8) {
                            Text("\(away)")
                                .font(.title2.weight(.bold).monospacedDigit())
                                .foregroundColor(awayColor)
                            Text("–")
                                .font(.title3.weight(.medium))
                                .foregroundColor(DesignSystem.TextColor.tertiary)
                            Text("\(home)")
                                .font(.title2.weight(.bold).monospacedDigit())
                                .foregroundColor(homeColor)
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        Text("vs")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.TextColor.tertiary)
                        if game.awayScore != nil || game.status.isLive {
                            Text(game.status.isLive ? "Hold to update" : "Hold to reveal score")
                                .font(.caption2)
                                .foregroundColor(DesignSystem.TextColor.tertiary.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 0.5) {
                        guard game.awayScore != nil || game.status.isLive else { return }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onRevealScore?()
                    }
                }

                Spacer()

                // Home team block (right side)
                TappableTeamBlock(
                    teamName: game.homeTeam,
                    opponentName: game.awayTeam,
                    leagueCode: game.leagueCode,
                    isHome: true
                )
            }
            .padding(.vertical, 20)

            // Subtle divider
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(height: 0.5)

            // MARK: Metadata Row - Game State + Date + League
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    // Status badge with optional pulsing live dot
                    HStack(spacing: 4) {
                        if game.status.isLive {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                                .modifier(PulsingDotModifier())
                        }
                        Text(gameStatusText)
                            .font(.caption2.weight(.bold))
                            .textCase(.uppercase)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusBadgeColor.opacity(0.15))
                    .foregroundColor(statusBadgeColor)
                    .clipShape(Capsule())

                    Text("·")
                        .foregroundColor(DesignSystem.TextColor.tertiary)

                    Text(formattedGameDate)
                        .font(.caption.weight(.medium))
                        .foregroundColor(DesignSystem.TextColor.secondary)

                    Spacer()

                    // League badge
                    Text(game.leagueCode)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.elevatedBackground)
                        .clipShape(Capsule())
                }

                // Resume text (when user has a saved reading position)
                if let resumeText {
                    HStack {
                        Text(resumeText)
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .shadow(
            color: DesignSystem.Shadow.color,
            radius: DesignSystem.Shadow.radius,
            x: 0,
            y: DesignSystem.Shadow.y
        )
        // Subtle entrance animation
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 4)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                hasAppeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Matchup: \(game.awayTeam) at \(game.homeTeam)")
        .accessibilityValue(statusAccessibilityLabel)
    }

    private var statusBadgeColor: Color {
        switch game.status {
        case .completed, .final, .archived:
            return .green
        case .inProgress, .live:
            return .red
        case .scheduled, .pregame:
            return .blue
        case .postponed, .canceled:
            return .orange
        case .unknown:
            return .gray
        }
    }

    // MARK: - Metadata Text
    /// Format: "FINAL · JAN 22" or "UPCOMING · JAN 22"
    private var metadataText: String {
        let statusText = gameStatusText
        let dateText = formattedGameDate
        return "\(statusText) · \(dateText)"
    }

    private var gameStatusText: String {
        switch game.status {
        case .completed, .final, .archived:
            return "Final"
        case .scheduled, .pregame:
            return "Upcoming"
        case .inProgress, .live:
            return "Live"
        case .postponed:
            return "Postponed"
        case .canceled:
            return "Canceled"
        case .unknown:
            return "Unknown"
        }
    }

    private var formattedGameDate: String {
        guard let date = game.parsedGameDate else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date).uppercased()
    }

    private var statusAccessibilityLabel: String {
        switch game.status {
        case .completed, .final, .archived:
            return "Game complete"
        case .scheduled, .pregame:
            return "Upcoming game"
        case .inProgress, .live:
            return "Game in progress"
        case .postponed:
            return "Game postponed"
        case .canceled:
            return "Game canceled"
        case .unknown:
            return "Game status unknown"
        }
    }
}

// MARK: - Tappable Team Block
/// Wraps team info with navigation and press feedback

private struct TappableTeamBlock: View {
    let teamName: String
    let opponentName: String
    let leagueCode: String
    let isHome: Bool

    private var abbreviation: String {
        TeamAbbreviations.abbreviation(for: teamName)
    }

    var body: some View {
        NavigationLink(value: AppRoute.team(name: teamName, abbreviation: abbreviation, league: leagueCode)) {
            HStack(spacing: 0) {
                if !isHome {
                    // Away team: color bar on left
                    Rectangle()
                        .fill(DesignSystem.TeamColors.matchupColor(for: teamName, against: opponentName, isHome: isHome).opacity(0.8))
                        .frame(width: 3)

                    TeamBlockView(
                        teamName: teamName,
                        opponentName: opponentName,
                        isHome: false,
                        alignment: .leading
                    )
                    .padding(.leading, 12)
                } else {
                    // Home team: color bar on right
                    TeamBlockView(
                        teamName: teamName,
                        opponentName: opponentName,
                        isHome: true,
                        alignment: .trailing
                    )
                    .padding(.trailing, 12)

                    Rectangle()
                        .fill(DesignSystem.TeamColors.matchupColor(for: teamName, against: opponentName, isHome: isHome).opacity(0.8))
                        .frame(width: 3)
                }
            }
            .contentShape(Rectangle()) // Large hit target
        }
        .buttonStyle(InteractiveRowButtonStyle())
        .accessibilityLabel("View \(teamName) team page")
        .accessibilityHint("Double tap to see team details")
    }
}

// Note: Uses InteractiveRowButtonStyle from CollapsibleCards.swift for consistent tap feedback

// MARK: - Pulsing Live Dot Animation

private struct PulsingDotModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// MARK: - Team Block View
/// Displays team as abbreviation (bold) + full name (secondary)

private struct TeamBlockView: View {
    let teamName: String
    let opponentName: String
    let isHome: Bool
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            // Team abbreviation - hero element
            Text(TeamAbbreviations.abbreviation(for: teamName))
                .font(.title2.weight(.bold))
                .foregroundColor(teamColor)

            // Team name - secondary
            Text(teamName)
                .font(.caption)
                .foregroundColor(DesignSystem.TextColor.secondary)
                .lineLimit(1)
        }
    }

    private var teamColor: Color {
        DesignSystem.TeamColors.matchupColor(for: teamName, against: opponentName, isHome: isHome)
    }
}

// MARK: - Previews

#Preview("Final Game") {
    GameHeaderView(game: PreviewFixtures.highlightsHeavyGame.game, scoreRevealed: false)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Dark Mode") {
    GameHeaderView(game: PreviewFixtures.highlightsHeavyGame.game, scoreRevealed: false)
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
}

#Preview("Pregame") {
    GameHeaderView(game: PreviewFixtures.preGameOnlyGame.game, scoreRevealed: false)
        .padding()
        .background(Color(.systemGroupedBackground))
}
