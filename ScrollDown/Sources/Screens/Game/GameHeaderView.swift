import SwiftUI

// MARK: - Game Header View
/// Editorial, story-first header anchoring context, not score.
/// Design philosophy: Calm, intentional, identical across all leagues.

struct GameHeaderView: View {
    let game: Game
    var scoreRevealed: Bool = false

    @State private var hasAppeared = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Primary Row - Team Matchup
            HStack(spacing: 0) {
                // Away team block (left side) - tappable with color bar
                TappableTeamBlock(
                    teamName: game.awayTeam,
                    leagueCode: game.leagueCode,
                    isHome: false
                )

                Spacer()

                // Center separator - low contrast "@"
                Text("@")
                    .font(.subheadline.weight(.regular))
                    .foregroundColor(Color(.tertiaryLabel))

                Spacer()

                // Home team block (right side) - tappable with color bar
                TappableTeamBlock(
                    teamName: game.homeTeam,
                    leagueCode: game.leagueCode,
                    isHome: true
                )
            }
            .padding(.vertical, 16)

            // Subtle divider
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(height: 0.5)

            // MARK: Metadata Row - Game State + Date
            HStack(spacing: 0) {
                Text(metadataText)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .foregroundColor(Color(.secondaryLabel))

                Spacer()
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

    // MARK: - Metadata Text
    /// Format: "FINAL · JAN 22" or "UPCOMING · JAN 22"
    private var metadataText: String {
        let statusText = gameStatusText
        let dateText = formattedGameDate
        return "\(statusText) · \(dateText)"
    }

    private var gameStatusText: String {
        switch game.status {
        case .completed, .final:
            return "Final"
        case .scheduled:
            return "Upcoming"
        case .inProgress:
            return "Live"
        case .postponed:
            return "Postponed"
        case .canceled:
            return "Canceled"
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
        case .completed, .final:
            return "Game complete"
        case .scheduled:
            return "Upcoming game"
        case .inProgress:
            return "Game in progress"
        case .postponed:
            return "Game postponed"
        case .canceled:
            return "Game canceled"
        }
    }
}

// MARK: - Tappable Team Block
/// Wraps team info with navigation and press feedback

private struct TappableTeamBlock: View {
    let teamName: String
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
                        .fill(DesignSystem.TeamColors.color(for: teamName).opacity(0.8))
                        .frame(width: 3)

                    TeamBlockView(
                        teamName: teamName,
                        isHome: false,
                        alignment: .leading
                    )
                    .padding(.leading, 12)
                } else {
                    // Home team: color bar on right
                    TeamBlockView(
                        teamName: teamName,
                        isHome: true,
                        alignment: .trailing
                    )
                    .padding(.trailing, 12)

                    Rectangle()
                        .fill(DesignSystem.TeamColors.color(for: teamName).opacity(0.8))
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

// MARK: - Team Abbreviations
/// Shared utility for generating team abbreviations

enum TeamAbbreviations {
    private static let abbreviations: [String: String] = [
        // NBA
        "Atlanta Hawks": "ATL",
        "Boston Celtics": "BOS",
        "Brooklyn Nets": "BKN",
        "Charlotte Hornets": "CHA",
        "Chicago Bulls": "CHI",
        "Cleveland Cavaliers": "CLE",
        "Dallas Mavericks": "DAL",
        "Denver Nuggets": "DEN",
        "Detroit Pistons": "DET",
        "Golden State Warriors": "GSW",
        "Houston Rockets": "HOU",
        "Indiana Pacers": "IND",
        "Los Angeles Clippers": "LAC",
        "Los Angeles Lakers": "LAL",
        "Memphis Grizzlies": "MEM",
        "Miami Heat": "MIA",
        "Milwaukee Bucks": "MIL",
        "Minnesota Timberwolves": "MIN",
        "New Orleans Pelicans": "NOP",
        "New York Knicks": "NYK",
        "Oklahoma City Thunder": "OKC",
        "Orlando Magic": "ORL",
        "Philadelphia 76ers": "PHI",
        "Phoenix Suns": "PHX",
        "Portland Trail Blazers": "POR",
        "Sacramento Kings": "SAC",
        "San Antonio Spurs": "SAS",
        "Toronto Raptors": "TOR",
        "Utah Jazz": "UTA",
        "Washington Wizards": "WAS",
        // NFL (common)
        "Arizona Cardinals": "ARI",
        "Atlanta Falcons": "ATL",
        "Baltimore Ravens": "BAL",
        "Buffalo Bills": "BUF",
        "Carolina Panthers": "CAR",
        "Chicago Bears": "CHI",
        "Cincinnati Bengals": "CIN",
        "Cleveland Browns": "CLE",
        "Dallas Cowboys": "DAL",
        "Denver Broncos": "DEN",
        "Detroit Lions": "DET",
        "Green Bay Packers": "GB",
        "Houston Texans": "HOU",
        "Indianapolis Colts": "IND",
        "Jacksonville Jaguars": "JAX",
        "Kansas City Chiefs": "KC",
        "Las Vegas Raiders": "LV",
        "Los Angeles Chargers": "LAC",
        "Los Angeles Rams": "LAR",
        "Miami Dolphins": "MIA",
        "Minnesota Vikings": "MIN",
        "New England Patriots": "NE",
        "New Orleans Saints": "NO",
        "New York Giants": "NYG",
        "New York Jets": "NYJ",
        "Philadelphia Eagles": "PHI",
        "Pittsburgh Steelers": "PIT",
        "San Francisco 49ers": "SF",
        "Seattle Seahawks": "SEA",
        "Tampa Bay Buccaneers": "TB",
        "Tennessee Titans": "TEN",
        "Washington Commanders": "WAS",
        // NHL (common)
        "Anaheim Ducks": "ANA",
        "Boston Bruins": "BOS",
        "Buffalo Sabres": "BUF",
        "Calgary Flames": "CGY",
        "Carolina Hurricanes": "CAR",
        "Chicago Blackhawks": "CHI",
        "Colorado Avalanche": "COL",
        "Columbus Blue Jackets": "CBJ",
        "Dallas Stars": "DAL",
        "Detroit Red Wings": "DET",
        "Edmonton Oilers": "EDM",
        "Florida Panthers": "FLA",
        "Los Angeles Kings": "LA",
        "Minnesota Wild": "MIN",
        "Montreal Canadiens": "MTL",
        "Nashville Predators": "NSH",
        "New Jersey Devils": "NJ",
        "New York Islanders": "NYI",
        "New York Rangers": "NYR",
        "Ottawa Senators": "OTT",
        "Philadelphia Flyers": "PHI",
        "Pittsburgh Penguins": "PIT",
        "San Jose Sharks": "SJ",
        "Seattle Kraken": "SEA",
        "St. Louis Blues": "STL",
        "Tampa Bay Lightning": "TB",
        "Toronto Maple Leafs": "TOR",
        "Vancouver Canucks": "VAN",
        "Vegas Golden Knights": "VGK",
        "Washington Capitals": "WSH",
        "Winnipeg Jets": "WPG"
    ]

    static func abbreviation(for teamName: String) -> String {
        if let known = abbreviations[teamName] {
            return known
        }
        // Default: use first 3 letters of last word (team nickname)
        let words = teamName.split(separator: " ")
        if let lastWord = words.last {
            return String(lastWord.prefix(3)).uppercased()
        }
        return String(teamName.prefix(3)).uppercased()
    }
}

// MARK: - Team Block View
/// Displays team as abbreviation (bold) + full name (secondary)

private struct TeamBlockView: View {
    let teamName: String
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
        DesignSystem.TeamColors.color(for: teamName)
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
