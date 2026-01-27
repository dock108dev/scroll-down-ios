import SwiftUI

/// Display state for game cards on home screen
enum GameCardState {
    case available   // Completed game - tappable, prominent
    case locked      // Upcoming/scheduled game - non-tappable, locked appearance

    var isTappable: Bool {
        self == .available
    }
}

/// What content type is available for this game
enum GameContentType {
    case story       // Full story with moments
    case playByPlay  // PBP only (no story)
    case pending     // Not yet determined/loading
}

/// Row view for displaying a game summary in a list
/// Supports three visual states: story available, story pending, and locked
struct GameRowView: View {
    let game: GameSummary

    /// Computed card state based on game status
    var cardState: GameCardState {
        guard let status = game.status else { return .locked }

        switch status {
        case .completed, .final:
            return .available
        case .scheduled, .inProgress, .postponed, .canceled:
            return .locked
        }
    }

    /// What content type is available for this game
    /// Note: We can't reliably know if a story exists from GameSummary alone.
    /// Stories are only available for NBA/NCAAB games with moments.
    /// For now, show PBP indicator when hasPbp is true.
    var contentType: GameContentType {
        guard cardState == .available else { return .pending }

        // Only NBA and NCAAB currently have story support
        let storyLeagues = ["NBA", "NCAAB"]
        let supportsStory = storyLeagues.contains(game.league)

        // If league supports stories and has required data, indicate story
        // But this is still a heuristic - actual story availability requires fetching
        if supportsStory && game.hasRequiredData == true {
            return .story
        }

        // For other leagues or when hasPbp is explicitly true, show PBP
        if game.hasPbp == true {
            return .playByPlay
        }

        return .pending
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // League pill - classifies without stealing attention
            Text(game.league)
                .font(.caption2.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(leagueColor.opacity(cardState == .available ? 1.0 : 0.4))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Matchup title - the headline
            Text(matchupTitle)
                .font(.subheadline.weight(.medium))
                .foregroundColor(matchupTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            // Date + optional moment count
            VStack(alignment: .leading, spacing: 2) {
                Text(dateDisplay)
                    .font(.caption2)
                    .foregroundColor(Color(.secondaryLabel))

                // Moment count - readable at a glance
                if cardState == .available, let momentCount = game.playCount, momentCount > 0 {
                    Text("\(momentCount) moments")
                        .font(.caption2)
                        .foregroundColor(Color(.secondaryLabel).opacity(0.8))
                }

                // Content type indicator
                if cardState == .available {
                    contentTypeIndicator
                }
            }

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
        case .available: return .primary
        case .locked: return Color(.secondaryLabel)
        }
    }

    private var cardBackground: some View {
        Group {
            switch cardState {
            case .available:
                HomeTheme.cardBackground
            case .locked:
                // Muted background - lighter in dark mode to avoid blending
                Color(.systemGray5)
            }
        }
    }

    private var shadowColor: Color {
        switch cardState {
        case .available: return HomeTheme.cardShadow
        case .locked: return .clear
        }
    }

    private var shadowRadius: CGFloat {
        switch cardState {
        case .available: return HomeTheme.cardShadowRadius
        case .locked: return 0
        }
    }

    @ViewBuilder
    private var rightElement: some View {
        switch cardState {
        case .available:
            // Subtle chevron affordance - card itself invites the tap
            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundColor(Color(.tertiaryLabel))
        case .locked:
            // Clear lock state without chevron
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                Text("After game")
                    .font(.caption2)
            }
            .foregroundColor(Color(.quaternaryLabel))
        }
    }

    @ViewBuilder
    private var contentTypeIndicator: some View {
        HStack(spacing: 4) {
            switch contentType {
            case .story:
                Image(systemName: "book.fill")
                    .font(.caption2)
                Text("Story")
                    .font(.caption2)
            case .playByPlay:
                Image(systemName: "list.bullet")
                    .font(.caption2)
                Text("Play-by-Play")
                    .font(.caption2)
            case .pending:
                EmptyView()
            }
        }
        .foregroundColor(Color(.tertiaryLabel))
    }

    // MARK: - Helpers

    private var matchupTitle: String {
        "\(game.awayTeamName) at \(game.homeTeamName)"
    }

    private var dateDisplay: String {
        // For locked games, emphasize the scheduled time
        if cardState == .locked, let date = game.parsedGameDate {
            let formatter = DateFormatter()
            if Calendar.current.isDateInTomorrow(date) {
                formatter.timeStyle = .short
                return "Tomorrow · \(formatter.string(from: date))"
            }
        }
        return game.shortFormattedDate
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

    /// Whether this game has full story content (not just PBP)
    private var hasFullStory: Bool {
        (game.hasRequiredData == true) || (game.hasPbp == true && game.hasSocial == true)
    }

    private var accessibilityLabel: String {
        let stateDescription: String
        switch cardState {
        case .available:
            stateDescription = "Tap to read story"
        case .locked:
            stateDescription = "Available after game completes"
        }
        return "\(game.awayTeamName) at \(game.homeTeamName). \(stateDescription)."
    }

    private var accessibilityHint: String {
        cardState.isTappable ? "Double tap to read story" : ""
    }
}

private enum Layout {
    static let cardPadding: CGFloat = 14
    static let contentSpacing: CGFloat = 10
    static let textSpacing: CGFloat = 4
}

#Preview("Card States") {
    VStack(spacing: 16) {
        // Available - Completed game (with moments)
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

        // Available - Completed game (no moments yet)
        GameRowView(game: GameSummary(
            id: 12346,
            leagueCode: "NFL",
            gameDate: "2026-01-23T21:00:00-05:00",
            status: .completed,
            homeTeam: "Miami Heat",
            awayTeam: "New York Knicks",
            homeScore: 98,
            awayScore: 102,
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

        // Locked - Scheduled/Upcoming
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
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        // Available - Completed
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

        // Locked - Scheduled
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
}
