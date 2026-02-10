import SwiftUI

/// Display state for game cards on home screen
enum GameCardState {
    case available   // Has PBP data - tappable, prominent
    case pregame     // Scheduled but has odds/pregame data - tappable
    case comingSoon  // Completed but hasPbp == false - greyed, non-tappable
    case upcoming    // Upcoming/scheduled game - non-tappable, muted appearance

    var isTappable: Bool {
        self == .available || self == .pregame
    }
}


/// Row view for displaying a game summary in a list
/// Supports three visual states: flow available, flow pending, and upcoming
struct GameRowView: View {
    let game: GameSummary

    /// Whether the user has read this game's wrap-up
    private var isRead: Bool {
        guard game.status?.isCompleted == true else { return false }
        return UserDefaults.standard.bool(forKey: "game.read.\(game.id)")
    }

    /// Computed card state based on game status and data availability
    var cardState: GameCardState {
        guard let status = game.status else { return .upcoming }

        switch status {
        case .completed, .final:
            // Use hasPbp from API to determine if content is available
            if game.hasPbp != true {
                return .comingSoon
            }
            return .available
        case .scheduled:
            return .pregame
        case .inProgress, .postponed, .canceled:
            return .upcoming
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // League pill - classifies without stealing attention
            Text(game.league)
                .font(.caption2.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(leagueColor.opacity(cardState == .available || cardState == .pregame ? 1.0 : 0.4))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Matchup title - the headline
            Text(matchupTitle)
                .font(.subheadline.weight(.medium))
                .foregroundColor(matchupTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            // Final score for read games — team-colored
            if isRead, let home = game.homeScore, let away = game.awayScore {
                HStack(spacing: 4) {
                    Text("\(TeamAbbreviations.abbreviation(for: game.awayTeamName)) \(away)")
                        .foregroundColor(DesignSystem.TeamColors.color(for: game.awayTeamName))
                    Text("-")
                        .foregroundColor(.secondary)
                    Text("\(home) \(TeamAbbreviations.abbreviation(for: game.homeTeamName))")
                        .foregroundColor(DesignSystem.TeamColors.color(for: game.homeTeamName))
                }
                .font(.caption.weight(.semibold).monospacedDigit())
            }

            // Date + optional play/moment counts (debug)
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
        case .available, .pregame: return .primary
        case .comingSoon, .upcoming: return Color(.secondaryLabel)
        }
    }

    private var cardBackground: some View {
        Group {
            switch cardState {
            case .available, .pregame:
                HomeTheme.cardBackground
            case .comingSoon, .upcoming:
                // Muted background - lighter in dark mode to avoid blending
                Color(.systemGray5)
            }
        }
    }

    private var shadowColor: Color {
        switch cardState {
        case .available, .pregame: return HomeTheme.cardShadow
        case .comingSoon, .upcoming: return .clear
        }
    }

    private var shadowRadius: CGFloat {
        switch cardState {
        case .available, .pregame: return HomeTheme.cardShadowRadius
        case .comingSoon, .upcoming: return 0
        }
    }

    @ViewBuilder
    private var rightElement: some View {
        if cardState == .available && isRead {
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
        // For upcoming games, emphasize the scheduled time
        if cardState == .upcoming, let date = game.parsedGameDate {
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

    /// Whether this game has full flow content (not just PBP)
    private var hasFullFlow: Bool {
        (game.hasRequiredData == true) || (game.hasPbp == true && game.hasSocial == true)
    }

    private var accessibilityLabel: String {
        let stateDescription: String
        switch cardState {
        case .available:
            stateDescription = "Tap to view game flow"
        case .pregame:
            stateDescription = "Tap to view pregame buzz"
        case .comingSoon:
            stateDescription = "Coming soon, play-by-play data is being processed"
        case .upcoming:
            stateDescription = "Upcoming game, not yet available"
        }
        return "\(game.awayTeamName) at \(game.homeTeamName). \(stateDescription)."
    }

    private var accessibilityHint: String {
        cardState.isTappable ? "Double tap to view game" : ""
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
