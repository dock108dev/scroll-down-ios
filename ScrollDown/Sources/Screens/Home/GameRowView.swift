import SwiftUI

/// Row view for displaying a game summary in a list
struct GameRowView: View {
    let game: GameSummary
    @State private var isNuggetSheetPresented = false
    
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
                    Text(statusText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    previewWidget
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
        .sheet(isPresented: $isNuggetSheetPresented) {
            NuggetDetailSheet(
                nuggetText: nuggetText,
                tags: Strings.nuggetTags
            )
        }
    }
    
    // MARK: - Helpers

    private var previewWidget: some View {
        VStack(alignment: .leading, spacing: Layout.previewSpacing) {
            if shouldShowPlaceholder {
                placeholderBadgeRow
            } else {
                HStack(spacing: Layout.previewSpacing) {
                    previewBadge(title: Strings.excitementLabel, value: excitementScore)
                    previewBadge(title: Strings.qualityLabel, value: qualityScore)
                    
                    Spacer()
                    
                    infoButton
                }
            }
        }
    }

    private func previewBadge(title: String, value: Int) -> some View {
        HStack(spacing: Layout.badgeSpacing) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.caption2.weight(.bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, Layout.badgeHorizontalPadding)
        .padding(.vertical, Layout.badgeVerticalPadding)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }

    private var infoButton: some View {
        Button {
            isNuggetSheetPresented = true
        } label: {
            Image(systemName: Strings.infoIconFilled)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(Layout.infoPadding)
                .background(Color(.systemGray6))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Strings.expandNuggetLabel)
    }

    private var placeholderBadgeRow: some View {
        HStack(spacing: Layout.previewSpacing) {
            skeletonBadge(width: Layout.skeletonBadgeWidthLarge)
            skeletonBadge(width: Layout.skeletonBadgeWidthSmall)
            
            Spacer()
            
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: Layout.skeletonInfoSize, height: Layout.skeletonInfoSize)
        }
        .accessibilityHidden(true)
    }

    private func skeletonBadge(width: CGFloat) -> some View {
        Capsule()
            .fill(Color(.systemGray5))
            .frame(width: width, height: Layout.skeletonBadgeHeight)
    }
    
    private var matchupTitle: String {
        "\(game.awayTeam) at \(game.homeTeam)"
    }

    private var statusText: String {
        shouldShowPlaceholder ? Strings.evaluatingMatchup : game.statusLine
    }

    private var shouldShowPlaceholder: Bool {
        !(game.hasRequiredData ?? false)
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

    private var excitementScore: Int {
        previewScore(from: game.playCount, fallbackSeed: game.id * 7 + 13, baseScore: 58)
    }

    private var qualityScore: Int {
        previewScore(from: game.socialPostCount, fallbackSeed: game.id * 11 + 29, baseScore: 52)
    }

    private var nuggetText: String {
        let nuggets = Strings.nuggets
        let index = abs(game.id) % nuggets.count
        return nuggets[index]
    }

    private func previewScore(from metric: Int?, fallbackSeed: Int, baseScore: Int) -> Int {
        if let metric, metric > 0 {
            return min(99, baseScore + (metric % 40))
        }
        let normalized = abs(fallbackSeed) % 30
        return min(95, baseScore + normalized)
    }
}

private enum Layout {
    static let accentStripHeight: CGFloat = 4
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 16
    static let contentSpacing: CGFloat = 12
    static let textSpacing: CGFloat = 6
    static let metaSpacing: CGFloat = 6
    static let previewSpacing: CGFloat = 8
    static let badgeSpacing: CGFloat = 4
    static let badgeHorizontalPadding: CGFloat = 8
    static let badgeVerticalPadding: CGFloat = 4
    static let infoPadding: CGFloat = 6
    static let skeletonBadgeHeight: CGFloat = 20
    static let skeletonBadgeWidthLarge: CGFloat = 92
    static let skeletonBadgeWidthSmall: CGFloat = 76
    static let skeletonInfoSize: CGFloat = 24
    static let nuggetSheetTagSpacing: CGFloat = 8
    static let nuggetSheetTagPadding: CGFloat = 6
    static let nuggetSheetHorizontalPadding: CGFloat = 16
    static let nuggetSheetVerticalPadding: CGFloat = 20
}

private enum Strings {
    static let excitementLabel = "Excitement"
    static let qualityLabel = "Quality"
    static let infoIconFilled = "info.circle.fill"
    static let expandNuggetLabel = "Open game nugget"
    static let nuggetSheetTitle = "Why this game matters"
    static let nuggetTags = ["Rivalry", "Postseason Stakes", "Bubble Watch"]
    static let evaluatingMatchup = "Evaluating matchup..."
    static let nuggets = [
        "Momentum swings make the late stages worth a peek.",
        "A matchup of styles could set up a tight finish.",
        "Expect a steady pace with a few key turning points.",
        "Late-game execution may decide this one.",
        "Plenty of back-and-forth keeps the tension high."
    ]
}

private struct NuggetDetailSheet: View {
    let nuggetText: String
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.nuggetSheetVerticalPadding) {
            Text(Strings.nuggetSheetTitle)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)

            Text(nuggetText)
                .font(.body)
                .foregroundColor(.secondary)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120), alignment: .leading)],
                alignment: .leading,
                spacing: Layout.nuggetSheetTagSpacing
            ) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, Layout.nuggetSheetHorizontalPadding)
                        .padding(.vertical, Layout.nuggetSheetTagPadding)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                        .accessibilityLabel(tag)
                }
            }
        }
        .padding(.horizontal, Layout.nuggetSheetHorizontalPadding)
        .padding(.vertical, Layout.nuggetSheetVerticalPadding)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
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
