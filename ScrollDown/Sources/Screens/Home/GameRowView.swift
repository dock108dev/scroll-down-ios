import SwiftUI

/// Row view for displaying a game summary in a list
struct GameRowView: View {
    let game: GameSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: Layout.stackSpacing) {
            HStack {
                Text(game.leagueCode)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.leagueBadgeHorizontalPadding)
                    .padding(.vertical, Layout.leagueBadgeVerticalPadding)
                    .background(leagueColor.opacity(Layout.leagueBadgeBackgroundOpacity))
                    .foregroundColor(leagueColor)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.leagueBadgeCornerRadius))
                
                Spacer()
                
                Text(game.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: Layout.teamSpacing) {
                Text(game.awayTeam)
                    .font(.subheadline.weight(.semibold))
                Text(game.homeTeam)
                    .font(.subheadline.weight(.semibold))
            }
            
            Text(game.statusLine)
                .font(.footnote)
                .foregroundColor(.secondary)
            
            if game.inferredStatus == .completed {
                spoilerSafeBadge
            }
            
            VStack(alignment: .leading, spacing: Layout.valueSpacing) {
                Text(Strings.valueHeader)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(valueSummaryText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Layout.cardPadding)
        .background(HomeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HomeTheme.cardCornerRadius))
        .shadow(
            color: HomeTheme.cardShadow,
            radius: HomeTheme.cardShadowRadius,
            x: 0,
            y: HomeTheme.cardShadowYOffset
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Helpers
    
    private var leagueColor: Color {
        switch game.leagueCode {
        case "NBA": return .orange
        case "NFL": return .blue
        case "MLB": return .red
        case "NHL": return .purple
        case "NCAAB": return .green
        case "NCAAF": return .teal
        default: return .gray
        }
    }
    
    private var valueSummaryText: String {
        switch game.inferredStatus {
        case .scheduled:
            return Strings.valueSummaryScheduled
        case .inProgress:
            return Strings.valueSummaryInProgress
        case .completed:
            return Strings.valueSummaryCompleted
        case .postponed, .canceled:
            return Strings.valueSummaryScheduled
        }
    }
    
    private var spoilerSafeBadge: some View {
        Text(Strings.spoilerSafeLabel)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, Layout.spoilerBadgeHorizontalPadding)
            .padding(.vertical, Layout.spoilerBadgeVerticalPadding)
            .background(Color(.systemGray5))
            .clipShape(Capsule())
    }
    
    private var accessibilityLabel: String {
        "\(game.awayTeam) at \(game.homeTeam). \(game.statusLine)."
    }
}

private enum Layout {
    static let stackSpacing: CGFloat = 12
    static let teamSpacing: CGFloat = 6
    static let valueSpacing: CGFloat = 4
    static let cardPadding: CGFloat = 16
    static let leagueBadgeHorizontalPadding: CGFloat = 8
    static let leagueBadgeVerticalPadding: CGFloat = 4
    static let leagueBadgeCornerRadius: CGFloat = 6
    static let leagueBadgeBackgroundOpacity: Double = 0.15
    static let spoilerBadgeHorizontalPadding: CGFloat = 10
    static let spoilerBadgeVerticalPadding: CGFloat = 4
}

private enum Strings {
    static let valueHeader = "What you get if you tap"
    static let valueSummaryScheduled = "Preview • Storylines • Lineups"
    static let valueSummaryInProgress = "Live updates • Highlights • Spoiler-safe recap"
    static let valueSummaryCompleted = "Game recap • Highlights • Stats"
    static let spoilerSafeLabel = "🔒 Spoiler-safe"
}

#Preview {
    List {
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
    }
    .listStyle(.plain)
    .background(HomeTheme.background)
}
