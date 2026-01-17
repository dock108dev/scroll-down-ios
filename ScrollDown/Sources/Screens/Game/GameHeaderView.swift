import SwiftUI

// MARK: - Matchup Header Card
/// Premium, sports-native header card using typography and shape instead of logos.
/// Design philosophy: Confident and finished even with zero images.

struct GameHeaderView: View {
    let game: Game
    var scoreRevealed: Bool = false
    
    // Entrance animation state
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            // MARK: Primary Row - Team Matchup
            // Abbreviations are the hero element; largest and most prominent
            HStack(spacing: 0) {
                // Away team (left side)
                TeamBadgeView(
                    teamName: game.awayTeam,
                    isHome: false
                )
                
                Spacer()
                
                // Center divider - reduced visual weight, not competing with teams
                VStack(spacing: 2) {
                    Text("@")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .frame(width: 24)
                
                Spacer()
                
                // Home team (right side) - slightly heavier to indicate home
                TeamBadgeView(
                    teamName: game.homeTeam,
                    isHome: true
                )
            }
            
            // MARK: Secondary Row - Status + Metadata
            // Visually subordinate to the matchup
            HStack(spacing: 8) {
                // Status pill - secondary prominence
                statusPill
                
                // Date/time metadata - tertiary prominence
                if let date = game.parsedGameDate {
                    Text(date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                        .font(.caption2)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .shadow(
            color: DesignSystem.Shadow.color,
            radius: DesignSystem.Shadow.radius,
            x: 0,
            y: DesignSystem.Shadow.y
        )
        .padding(.horizontal, Layout.cardInset)
        // Subtle entrance animation - fade + slight rise
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
    
    // MARK: - Status Pill
    /// Small, secondary status indicator. Subtle tint, not loud.
    private var statusPill: some View {
        Text(statusText)
            .font(.caption2.weight(.semibold))
            .foregroundColor(statusForeground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusBackground)
            .clipShape(Capsule())
    }
    
    private var statusText: String {
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
    
    // Status colors - muted, not attention-grabbing
    private var statusForeground: Color {
        switch game.status {
        case .inProgress:
            return Color(.systemGreen)
        default:
            return Color(.secondaryLabel)
        }
    }
    
    private var statusBackground: Color {
        switch game.status {
        case .inProgress:
            return Color(.systemGreen).opacity(0.12)
        default:
            return Color(.systemGray5)
        }
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
    
    // Card background with subtle material effect
    private var cardBackground: some View {
        DesignSystem.Colors.cardBackground
    }
}

// MARK: - Team Badge View
/// Displays team as abbreviation badge + city name
/// DUAL-TEAM COLORS: Away = Team A (indigo), Home = Team B (teal)

private struct TeamBadgeView: View {
    let teamName: String
    let isHome: Bool
    
    var body: some View {
        VStack(alignment: isHome ? .trailing : .leading, spacing: 5) {
            // Abbreviation badge — each team gets its own color
            Text(abbreviation)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(teamColor)
                .frame(width: 52, height: 34)
                .background(badgeBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
            
            // City/team name - neutral secondary text
            Text(teamName)
                .font(.caption2)
                .foregroundColor(DesignSystem.TextColor.secondary)
                .lineLimit(1)
        }
    }
    
    // Team color — Away (A) = indigo, Home (B) = teal
    private var teamColor: Color {
        isHome ? DesignSystem.TeamColors.teamB : DesignSystem.TeamColors.teamA
    }
    
    // Badge background — each team gets its own tinted background
    private var badgeBackground: Color {
        isHome ? DesignSystem.Colors.homeBadge : DesignSystem.Colors.awayBadge
    }
    
    /// Generate 2-3 letter abbreviation from team name
    /// Uses common sports abbreviation patterns
    private var abbreviation: String {
        // Common NBA/NFL team abbreviations
        let abbreviations: [String: String] = [
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
            "Washington Wizards": "WAS"
        ]
        
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

// MARK: - Layout Constants
/// Intentional spacing values for tight, premium feel

private enum Layout {
    // Vertical rhythm - tighter than before
    static let verticalSpacing: CGFloat = 12
    static let verticalPadding: CGFloat = 16
    
    // Horizontal balance
    static let horizontalPadding: CGFloat = 16
    static let cardInset: CGFloat = 20
}

// MARK: - Previews

#Preview("Final Game") {
    GameHeaderView(game: PreviewFixtures.highlightsHeavyGame.game, scoreRevealed: false)
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
}

#Preview("Dark Mode") {
    GameHeaderView(game: PreviewFixtures.highlightsHeavyGame.game, scoreRevealed: false)
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
}
