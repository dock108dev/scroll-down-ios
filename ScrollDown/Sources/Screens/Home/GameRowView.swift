import SwiftUI

/// Display state for game cards on home screen
enum GameCardState {
    case active    // Has some data (odds, PBP, social, etc.) — tappable, full styling
    case noData    // Truly zero data — greyed, non-tappable (should rarely happen)

    var isTappable: Bool { self == .active }
}


/// Row view for displaying a game summary in a list
/// Two visual states: active (tappable, full styling) and noData (greyed, non-tappable)
struct GameRowView: View {
    @EnvironmentObject var readStateStore: ReadStateStore
    @Environment(\.colorScheme) private var colorScheme
    let game: GameSummary

    /// Bumped to force SwiftUI to re-evaluate computed properties after store updates
    @State private var scoreRefreshToken = false

    /// Whether the user has read this game's wrap-up (only for final games)
    private var isRead: Bool {
        guard game.status?.isFinal == true else { return false }
        return readStateStore.isRead(gameId: game.id)
    }

    /// Resolved scores: reading-position scores first, then full scores if game is read or "always show" is on
    private var resolvedScores: (away: Int, home: Int)? {
        _ = scoreRefreshToken // dependency so SwiftUI re-evaluates after updates
        // Check for saved reading-position scores (from scrolling PBP)
        if let saved = ReadingPositionStore.shared.savedScores(for: game.id) {
            return saved
        }
        // Show scores if game is read OR user has "always show" enabled
        let shouldShow = isRead || readStateStore.scoreRevealMode == .always
        if shouldShow, let away = game.awayScore, let home = game.homeScore {
            return (away: away, home: home)
        }
        return nil
    }

    /// Context string for saved scores (e.g., "@ Q2 · 2m ago")
    private var scoreContextText: String? {
        _ = scoreRefreshToken
        return ReadingPositionStore.shared.scoreContext(for: game.id)
    }

    /// Updates saved scores to the current live score from the game summary
    func updateToLiveScore() {
        guard let away = game.awayScore, let home = game.homeScore else { return }
        ReadingPositionStore.shared.updateScores(for: game.id, awayScore: away, homeScore: home)
        scoreRefreshToken.toggle()
    }

    /// Computed card state based on data availability — active unless truly empty
    var cardState: GameCardState {
        let hasAnyData = game.hasOdds == true
            || game.hasPbp == true
            || game.hasSocial == true
            || game.hasRequiredData == true
        return hasAnyData ? .active : .noData
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // League pill - classifies without stealing attention
            Text(game.league)
                .font(.caption2.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(leagueColor.opacity(cardState == .active ? 1.0 : 0.4))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Matchup title - the headline
            Text(matchupTitle)
                .font(.subheadline.weight(.medium))
                .foregroundColor(matchupTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            // Score display — reading-position scores or final scores for read games
            if let scores = resolvedScores {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(TeamAbbreviations.abbreviation(for: game.awayTeamName)) \(scores.away)")
                            .foregroundColor(awayTeamColor)
                        Text("-")
                            .foregroundColor(.secondary)
                        Text("\(scores.home) \(TeamAbbreviations.abbreviation(for: game.homeTeamName))")
                            .foregroundColor(homeTeamColor)
                    }
                    .font(.caption.weight(.semibold).monospacedDigit())

                    if let context = scoreContextText {
                        Text(context)
                            .font(.caption2)
                            .foregroundColor(DesignSystem.TextColor.tertiary)
                    }
                }
            } else if game.status?.isLive == true {
                // Live game with no saved score — hint to hold-to-check
                Text("Hold to check score")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary.opacity(0.6))
            }

            // Resume context (if user has a saved reading position but no scores yet)
            if resolvedScores == nil, let resumeText = ReadingPositionStore.shared.resumeDisplayText(for: game.id) {
                Text(resumeText)
                    .font(.caption2)
                    .foregroundColor(.orange)
            }

            // Date display
            Text(dateDisplay)
                .font(.caption2)
                .foregroundColor(Color(.secondaryLabel))

            Spacer(minLength: 4)

            // CTA aligned to bottom-right
            HStack {
                Spacer()
                rightElement
            }
        }
        .padding(12)
        .frame(minHeight: 110)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HomeTheme.cardCornerRadius))
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: 0,
            y: HomeTheme.cardShadowYOffset
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    // MARK: - State-Based Appearance

    private var matchupTextColor: Color {
        switch cardState {
        case .active: return .primary
        case .noData: return Color(.secondaryLabel)
        }
    }

    private var cardBackground: some View {
        Group {
            switch cardState {
            case .active:
                HomeTheme.cardBackground
            case .noData:
                Color(.systemGray5)
            }
        }
    }

    private var shadowColor: Color {
        switch cardState {
        case .active: return HomeTheme.cardShadow
        case .noData: return .clear
        }
    }

    private var shadowRadius: CGFloat {
        switch cardState {
        case .active: return HomeTheme.cardShadowRadius
        case .noData: return 0
        }
    }

    @ViewBuilder
    private var rightElement: some View {
        if cardState == .active && isRead {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
        } else {
            EmptyView()
        }
    }

    // MARK: - Helpers

    private var matchupTitle: String {
        "\(game.awayTeamName) at \(game.homeTeamName)"
    }

    private var dateDisplay: String {
        game.shortFormattedDate
    }

    private var leagueColor: Color {
        // Muted, distinct, non-brand colors for UI taxonomy
        switch game.league {
        case "NBA": return Color(red: 0.23, green: 0.36, blue: 0.63)  // Muted indigo
        case "NFL": return Color(red: 0.22, green: 0.45, blue: 0.32)  // Muted forest
        case "MLB": return Color(red: 0.65, green: 0.22, blue: 0.22)  // Muted burgundy
        case "NHL": return Color(red: 0.18, green: 0.44, blue: 0.42)  // Teal slate
        case "NCAAB": return Color(red: 0.70, green: 0.42, blue: 0.15) // Muted amber
        case "NCAAF": return Color(red: 0.45, green: 0.25, blue: 0.50) // Muted plum
        default: return Color(.systemGray)
        }
    }

    /// Resolves team color using game summary's inline color fields first, then cache fallback
    private func teamColor(light: String?, dark: String?, teamName: String, opponentName: String, isHome: Bool) -> Color {
        if let hex = (colorScheme == .dark ? dark : light), !hex.isEmpty {
            return Color(uiColor: UIColor(hex: hex))
        }
        return DesignSystem.TeamColors.matchupColor(for: teamName, against: opponentName, isHome: isHome)
    }

    private var awayTeamColor: Color {
        teamColor(light: game.awayTeamColorLight, dark: game.awayTeamColorDark,
                  teamName: game.awayTeamName, opponentName: game.homeTeamName, isHome: false)
    }

    private var homeTeamColor: Color {
        teamColor(light: game.homeTeamColorLight, dark: game.homeTeamColorDark,
                  teamName: game.homeTeamName, opponentName: game.awayTeamName, isHome: true)
    }

    private var accessibilityLabel: String {
        let stateDescription: String
        switch cardState {
        case .active:
            stateDescription = "Tap to view game"
        case .noData:
            stateDescription = "Game data not yet available"
        }
        return "\(game.awayTeamName) at \(game.homeTeamName). \(stateDescription)."
    }

    private var accessibilityHint: String {
        cardState.isTappable ? "Double tap to view game" : ""
    }
}

#Preview("Card States") {
    VStack(spacing: 16) {
        // Active - Completed game with full data
        GameRowView(game: GameSummary(
            id: 12345,
            leagueCode: "NBA",
            gameDate: "2026-01-23T19:30:00-05:00",
            status: .completed,
            homeTeam: "Boston Celtics",
            awayTeam: "Los Angeles Lakers",
            homeScore: 112,
            awayScore: 108,
            hasBoxscore: true,
            hasPlayerStats: true,
            hasOdds: true,
            hasSocial: true,
            hasPbp: true,
            playCount: 12,
            socialPostCount: 24,
            hasRequiredData: true,
            scrapeVersion: 2,
            lastScrapedAt: "2026-01-24T03:15:00Z"
        ))

        // Active - Scheduled game with odds only
        GameRowView(game: GameSummary(
            id: 12346,
            leagueCode: "NFL",
            gameDate: "2026-01-25T21:00:00-05:00",
            status: .scheduled,
            homeTeam: "Miami Heat",
            awayTeam: "New York Knicks",
            homeScore: nil,
            awayScore: nil,
            hasBoxscore: false,
            hasPlayerStats: false,
            hasOdds: true,
            hasSocial: false,
            hasPbp: false,
            playCount: 0,
            socialPostCount: 0,
            hasRequiredData: false,
            scrapeVersion: 1,
            lastScrapedAt: nil
        ))

        // noData - Truly empty game (rare)
        GameRowView(game: GameSummary(
            id: 12347,
            leagueCode: "MLB",
            gameDate: "2026-01-25T20:00:00-05:00",
            status: .scheduled,
            homeTeam: "Phoenix Suns",
            awayTeam: "Golden State Warriors",
            homeScore: nil,
            awayScore: nil,
            hasBoxscore: false,
            hasPlayerStats: false,
            hasOdds: false,
            hasSocial: false,
            hasPbp: false,
            playCount: 0,
            socialPostCount: 0,
            hasRequiredData: false,
            scrapeVersion: 1,
            lastScrapedAt: nil
        ))
    }
    .padding()
    .background(HomeTheme.background)
    .environmentObject(ReadStateStore.shared)
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        // Active - Completed
        GameRowView(game: GameSummary(
            id: 12345,
            leagueCode: "NBA",
            gameDate: "2026-01-23T19:30:00-05:00",
            status: .completed,
            homeTeam: "Boston Celtics",
            awayTeam: "Los Angeles Lakers",
            homeScore: 112,
            awayScore: 108,
            hasBoxscore: true,
            hasPlayerStats: true,
            hasOdds: true,
            hasSocial: true,
            hasPbp: true,
            playCount: 12,
            socialPostCount: 24,
            hasRequiredData: true,
            scrapeVersion: 2,
            lastScrapedAt: "2026-01-24T03:15:00Z"
        ))

        // Active - Scheduled with odds
        GameRowView(game: GameSummary(
            id: 12347,
            leagueCode: "MLB",
            gameDate: "2026-01-25T20:00:00-05:00",
            status: .scheduled,
            homeTeam: "Phoenix Suns",
            awayTeam: "Golden State Warriors",
            homeScore: nil,
            awayScore: nil,
            hasBoxscore: false,
            hasPlayerStats: false,
            hasOdds: true,
            hasSocial: false,
            hasPbp: false,
            playCount: 0,
            socialPostCount: 0,
            hasRequiredData: false,
            scrapeVersion: 1,
            lastScrapedAt: nil
        ))
    }
    .padding()
    .background(HomeTheme.background)
    .preferredColorScheme(.dark)
    .environmentObject(ReadStateStore.shared)
}
