import SwiftUI

/// Row view for displaying a game summary in a list
struct GameRowView: View {
    let game: GameSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent strip at top
            Rectangle()
                .fill(leagueColor)
                .frame(height: Layout.accentStripHeight)
            
            HStack(alignment: .center, spacing: Layout.contentSpacing) {
                VStack(alignment: .leading, spacing: Layout.textSpacing) {
                    // League + Date row
                    HStack(spacing: Layout.metaSpacing) {
                        Text(game.leagueCode)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(leagueColor)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(game.shortFormattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Matchup title
                    Text(matchupTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    // Status line
                    Text(game.statusLine)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(Layout.cardPadding)
        }
        .background(HomeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius))
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
        "\(game.awayTeam) at \(game.homeTeam)"
    }
    
    private var leagueColor: Color {
        switch game.leagueCode {
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
        "\(game.awayTeam) at \(game.homeTeam). \(game.statusLine)."
    }
}

private enum Layout {
    static let accentStripHeight: CGFloat = 4
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 16
    static let contentSpacing: CGFloat = 12
    static let textSpacing: CGFloat = 6
    static let metaSpacing: CGFloat = 6
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
