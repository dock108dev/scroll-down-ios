import SwiftUI

/// Row view for displaying a game summary in a list
struct GameRowView: View {
    let game: GameSummary
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Subtle league accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(leagueColor.opacity(0.8))
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                // Matchup title - primary
                Text(matchupTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                // League + Date row - secondary, calmer
                HStack(spacing: 4) {
                    Text(game.league)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(leagueColor)
                    
                    Text("·")
                        .font(.caption2)
                        .foregroundColor(Color(.secondaryLabel))
                    
                    Text(game.shortFormattedDate)
                        .font(.caption2)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(HomeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HomeTheme.cardCornerRadius))
        .shadow(
            color: HomeTheme.cardShadow,
            radius: HomeTheme.cardShadowRadius,
            x: 0,
            y: HomeTheme.cardShadowYOffset
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Helpers
    
    private var matchupTitle: String {
        "\(game.awayTeamName) at \(game.homeTeamName)"
    }
    
    private var leagueColor: Color {
        switch game.league {
        case "NBA": return Color(red: 0.0, green: 0.47, blue: 0.84)   // Blue
        case "NFL": return Color(red: 0.0, green: 0.53, blue: 0.32)   // Green
        case "MLB": return Color(red: 0.76, green: 0.15, blue: 0.15)  // Red
        case "NHL": return Color(red: 0.0, green: 0.0, blue: 0.0)     // Black
        case "NCAAB": return Color(red: 0.85, green: 0.45, blue: 0.0) // Orange
        case "NCAAF": return Color(red: 0.55, green: 0.0, blue: 0.55) // Purple
        default: return .gray
        }
    }
    
    private var accessibilityLabel: String {
        "\(game.awayTeamName) at \(game.homeTeamName). \(game.statusLine)."
    }
}

private enum Layout {
    static let cardPadding: CGFloat = 14
    static let contentSpacing: CGFloat = 10
    static let textSpacing: CGFloat = 4
}

#Preview {
    VStack(spacing: 12) {
        GameRowView(game: GameSummary(
            id: 12345,
            leagueCode: "NBA",
            gameDate: "2026-01-01T19:30:00-05:00",
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
            playCount: 482,
            socialPostCount: 24,
            hasRequiredData: true,
            scrapeVersion: 2,
            lastScrapedAt: "2026-01-02T03:15:00Z"
        ))
        
        GameRowView(game: GameSummary(
            id: 12346,
            leagueCode: "NFL",
            gameDate: "2026-01-01T20:00:00-05:00",
            status: .scheduled,
            homeTeam: "New York Giants",
            awayTeam: "Dallas Cowboys",
            homeScore: nil,
            awayScore: nil,
            hasBoxscore: false,
            hasPlayerStats: false,
            hasOdds: true,
            hasSocial: true,
            hasPbp: false,
            playCount: 0,
            socialPostCount: 5,
            hasRequiredData: false,
            scrapeVersion: 1,
            lastScrapedAt: nil
        ))
    }
    .padding()
    .background(HomeTheme.background)
}

#Preview("Dark") {
    VStack(spacing: 12) {
        GameRowView(game: GameSummary(
            id: 12345,
            leagueCode: "NBA",
            gameDate: "2026-01-01T19:30:00-05:00",
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
            playCount: 482,
            socialPostCount: 24,
            hasRequiredData: true,
            scrapeVersion: 2,
            lastScrapedAt: "2026-01-02T03:15:00Z"
        ))
        
        GameRowView(game: GameSummary(
            id: 12346,
            leagueCode: "NFL",
            gameDate: "2026-01-01T20:00:00-05:00",
            status: .scheduled,
            homeTeam: "New York Giants",
            awayTeam: "Dallas Cowboys",
            homeScore: nil,
            awayScore: nil,
            hasBoxscore: false,
            hasPlayerStats: false,
            hasOdds: true,
            hasSocial: true,
            hasPbp: false,
            playCount: 0,
            socialPostCount: 5,
            hasRequiredData: false,
            scrapeVersion: 1,
            lastScrapedAt: nil
        ))
    }
    .padding()
    .background(HomeTheme.background)
    .preferredColorScheme(.dark)
}
