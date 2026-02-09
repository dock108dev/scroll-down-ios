import SwiftUI

// MARK: - Team Stats Container
/// Simplified team stats view that shows how the game tilted.
/// Design: Team identity at top, stats grouped logically, numbers primary.
/// iPad: Multi-column layout for better use of space and improved readability.

struct TeamStatsContainer: View {
    let stats: [TeamComparisonStat]
    let homeTeam: String
    let awayTeam: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: Team Identity Header
            // Show abbreviations once at top — not repeated per row
            teamIdentityHeader

            // MARK: Stat Groups
            // iPad: Multi-column layout for better space utilization
            // iPhone: Single column for vertical scrolling efficiency
            if horizontalSizeClass == .regular {
                // iPad: Two-column layout
                multiColumnStatGroups
            } else {
                // iPhone: Single column layout
                singleColumnStatGroups
            }
        }
    }

    // MARK: - iPad Multi-Column Layout
    private var multiColumnStatGroups: some View {
        VStack(spacing: 16) {
            // First row: Shooting and Volume side-by-side
            HStack(alignment: .top, spacing: 16) {
                if !shootingStats.isEmpty {
                    StatGroupView(
                        title: "Shooting",
                        stats: shootingStats,
                        homeAbbrev: homeAbbrev,
                        awayAbbrev: awayAbbrev,
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        allStats: stats
                    )
                    .frame(maxWidth: .infinity)
                }

                if !volumeStats.isEmpty {
                    StatGroupView(
                        title: "Volume",
                        stats: volumeStats,
                        homeAbbrev: homeAbbrev,
                        awayAbbrev: awayAbbrev,
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        allStats: stats
                    )
                    .frame(maxWidth: .infinity)
                }
            }

            // Second row: Discipline (full width when alone, or could pair with future categories)
            if !disciplineStats.isEmpty {
                StatGroupView(
                    title: "Discipline",
                    stats: disciplineStats,
                    homeAbbrev: homeAbbrev,
                    awayAbbrev: awayAbbrev,
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    allStats: stats
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - iPhone Single Column Layout
    private var singleColumnStatGroups: some View {
        VStack(spacing: 16) {
            if !shootingStats.isEmpty {
                StatGroupView(
                    title: "Shooting",
                    stats: shootingStats,
                    homeAbbrev: homeAbbrev,
                    awayAbbrev: awayAbbrev,
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    allStats: stats
                )
            }

            if !volumeStats.isEmpty {
                StatGroupView(
                    title: "Volume",
                    stats: volumeStats,
                    homeAbbrev: homeAbbrev,
                    awayAbbrev: awayAbbrev,
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    allStats: stats
                )
            }

            if !disciplineStats.isEmpty {
                StatGroupView(
                    title: "Discipline",
                    stats: disciplineStats,
                    homeAbbrev: homeAbbrev,
                    awayAbbrev: awayAbbrev,
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    allStats: stats
                )
            }
        }
    }
    
    // MARK: - Team Identity Header
    /// Uses actual team colors for visual identity
    private var teamIdentityHeader: some View {
        let awayColor = DesignSystem.TeamColors.color(for: awayTeam)
        let homeColor = DesignSystem.TeamColors.color(for: homeTeam)

        return HStack {
            // Away team (left)
            Text(awayAbbrev)
                .font(.caption.weight(.bold))
                .foregroundColor(awayColor)
                .frame(width: 44, height: 26)
                .background(awayColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))

            Spacer()

            // Home team (right)
            Text(homeAbbrev)
                .font(.caption.weight(.bold))
                .foregroundColor(homeColor)
                .frame(width: 44, height: 26)
                .background(homeColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Stat Groupings
    /// Logical groupings make the stats easier to scan
    
    private var shootingStats: [TeamComparisonStat] {
        stats.filter { stat in
            ["Field Goal %", "3-Point %", "Free Throw %"].contains(stat.name)
        }
    }
    
    private var volumeStats: [TeamComparisonStat] {
        stats.filter { stat in
            ["Field Goals Made", "3-Pointers Made", "Free Throws Made",
             "Total Rebounds", "Offensive Rebounds", "Defensive Rebounds", "Assists"].contains(stat.name)
        }
    }
    
    private var disciplineStats: [TeamComparisonStat] {
        stats.filter { stat in
            ["Steals", "Blocks", "Turnovers", "Personal Fouls"].contains(stat.name)
        }
    }
    
    // MARK: - Abbreviation Helpers
    
    private var homeAbbrev: String {
        teamAbbreviation(homeTeam)
    }
    
    private var awayAbbrev: String {
        teamAbbreviation(awayTeam)
    }
    
    private func teamAbbreviation(_ fullName: String) -> String {
        let abbreviations: [String: String] = [
            "Atlanta Hawks": "ATL", "Boston Celtics": "BOS", "Brooklyn Nets": "BKN",
            "Charlotte Hornets": "CHA", "Chicago Bulls": "CHI", "Cleveland Cavaliers": "CLE",
            "Dallas Mavericks": "DAL", "Denver Nuggets": "DEN", "Detroit Pistons": "DET",
            "Golden State Warriors": "GSW", "Houston Rockets": "HOU", "Indiana Pacers": "IND",
            "Los Angeles Clippers": "LAC", "Los Angeles Lakers": "LAL", "Memphis Grizzlies": "MEM",
            "Miami Heat": "MIA", "Milwaukee Bucks": "MIL", "Minnesota Timberwolves": "MIN",
            "New Orleans Pelicans": "NOP", "New York Knicks": "NYK", "Oklahoma City Thunder": "OKC",
            "Orlando Magic": "ORL", "Philadelphia 76ers": "PHI", "Phoenix Suns": "PHX",
            "Portland Trail Blazers": "POR", "Sacramento Kings": "SAC", "San Antonio Spurs": "SAS",
            "Toronto Raptors": "TOR", "Utah Jazz": "UTA", "Washington Wizards": "WAS"
        ]
        return abbreviations[fullName] ?? String(fullName.split(separator: " ").last?.prefix(3) ?? "").uppercased()
    }
}

// MARK: - Stat Group View
/// A single container for a logical group of stats (Shooting, Volume, Discipline)

private struct StatGroupView: View {
    let title: String
    let stats: [TeamComparisonStat]
    let allStats: [TeamComparisonStat]  // All stats for cross-referencing annotations
    let homeAbbrev: String
    let awayAbbrev: String
    let homeTeam: String
    let awayTeam: String

    init(title: String, stats: [TeamComparisonStat], homeAbbrev: String, awayAbbrev: String, homeTeam: String = "", awayTeam: String = "", allStats: [TeamComparisonStat]? = nil) {
        self.title = title
        self.stats = stats
        self.homeAbbrev = homeAbbrev
        self.awayAbbrev = awayAbbrev
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.allStats = allStats ?? stats
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header — TERTIARY contrast, tighter spacing
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(DesignSystem.TextColor.tertiary)
                .tracking(0.5)
                .padding(.horizontal, 10)
                .padding(.bottom, 6) // Tightened from 8

            // Stats container
            VStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                    SimplifiedStatRow(
                        stat: stat,
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        annotation: StatAnnotationGenerator.annotation(
                            for: stat,
                            allStats: allStats,
                            homeAbbrev: homeAbbrev,
                            awayAbbrev: awayAbbrev
                        )
                    )

                    // Divider between rows — subtle
                    if index < stats.count - 1 {
                        Rectangle()
                            .fill(DesignSystem.borderColor.opacity(0.4))
                            .frame(height: 0.5)
                            .padding(.horizontal, 10)
                    }
                }
            }
            .background(DesignSystem.Colors.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        }
    }
}

// MARK: - Simplified Stat Row
/// Uses actual team colors for visual comparison

private struct SimplifiedStatRow: View {
    let stat: TeamComparisonStat
    let homeTeam: String
    let awayTeam: String
    let annotation: String?

    init(stat: TeamComparisonStat, homeTeam: String = "", awayTeam: String = "", annotation: String? = nil) {
        self.stat = stat
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.annotation = annotation
    }

    private var homeColor: Color {
        DesignSystem.TeamColors.color(for: homeTeam)
    }

    private var awayColor: Color {
        DesignSystem.TeamColors.color(for: awayTeam)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Values and bars row
            HStack(spacing: 10) {
                // Away value (left)
                Text(stat.awayDisplay)
                    .font(.subheadline.weight(awayIsHigher ? .semibold : .regular))
                    .foregroundColor(awayValueColor)
                    .frame(width: 50, alignment: .trailing)

                // Visual comparison bar — both teams get their own color
                comparisonBar

                // Home value (right)
                Text(stat.homeDisplay)
                    .font(.subheadline.weight(homeIsHigher ? .semibold : .regular))
                    .foregroundColor(homeValueColor)
                    .frame(width: 50, alignment: .leading)
            }

            // Stat label — below bars, centered, readable
            Text(shortLabel)
                .font(.caption)
                .foregroundColor(DesignSystem.TextColor.secondary)

            // Contextual annotation (if available)
            if let annotation {
                Text(annotation)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, annotation != nil ? 10 : 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stat.name)
        .accessibilityValue("Away \(stat.awayDisplay), Home \(stat.homeDisplay)\(annotation.map { ". \($0)" } ?? "")")
    }

    // MARK: - Value Colors
    // Each team gets its actual color, winner is bolder

    private var awayValueColor: Color {
        awayIsHigher ? awayColor : awayColor.opacity(0.5)
    }

    private var homeValueColor: Color {
        homeIsHigher ? homeColor : homeColor.opacity(0.5)
    }

    // MARK: - Comparison Bar
    /// Both bars use actual team colors
    private var comparisonBar: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let awayWidth = barWidth(for: stat.awayValue, total: totalWidth)
            let homeWidth = barWidth(for: stat.homeValue, total: totalWidth)

            HStack(spacing: 1) {
                // Away bar (left)
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(awayColor.opacity(0.8))
                        .frame(width: awayWidth)
                }
                // Grey track behind
                .background(Color(.systemGray5).opacity(0.5))

                // Center divider — subtle neutral
                Rectangle()
                    .fill(Color(.separator).opacity(0.4))
                    .frame(width: 1)

                // Home bar (right)
                HStack {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(homeColor.opacity(0.8))
                        .frame(width: homeWidth)
                    Spacer()
                }
                // Grey track behind
                .background(Color(.systemGray5).opacity(0.5))
            }
        }
        .frame(height: 4) // Slightly thicker for color visibility
    }
    
    private func barWidth(for value: Double?, total: CGFloat) -> CGFloat {
        guard let value, maxValue > 0 else { return 0 }
        let halfWidth = (total - 3) / 2
        return halfWidth * min(value / maxValue, 1)
    }
    
    private var maxValue: Double {
        max(stat.homeValue ?? 0, stat.awayValue ?? 0)
    }
    
    private var homeIsHigher: Bool {
        (stat.homeValue ?? 0) > (stat.awayValue ?? 0)
    }
    
    private var awayIsHigher: Bool {
        (stat.awayValue ?? 0) > (stat.homeValue ?? 0)
    }
    
    /// Shortened stat labels for cleaner display
    private var shortLabel: String {
        let shorts: [String: String] = [
            "Field Goal %": "FG%",
            "3-Point %": "3P%",
            "Free Throw %": "FT%",
            "Field Goals Made": "FGM",
            "3-Pointers Made": "3PM",
            "Free Throws Made": "FTM",
            "Total Rebounds": "REB",
            "Offensive Rebounds": "OREB",
            "Defensive Rebounds": "DREB",
            "Assists": "AST",
            "Steals": "STL",
            "Blocks": "BLK",
            "Turnovers": "TO",
            "Personal Fouls": "PF"
        ]
        return shorts[stat.name] ?? stat.name
    }
}

// MARK: - Single Row View

struct TeamComparisonRowView: View {
    let stat: TeamComparisonStat
    let homeTeam: String
    let awayTeam: String

    var body: some View {
        SimplifiedStatRow(stat: stat, homeTeam: homeTeam, awayTeam: awayTeam)
            .background(DesignSystem.Colors.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
    }
}

// MARK: - Previews

#Preview("Team Stats Container") {
    TeamStatsContainer(
        stats: [
            TeamComparisonStat(name: "Field Goal %", homeValue: 0.52, awayValue: 0.44, homeDisplay: "52.0%", awayDisplay: "44.0%"),
            TeamComparisonStat(name: "3-Point %", homeValue: 0.38, awayValue: 0.35, homeDisplay: "38.0%", awayDisplay: "35.0%"),
            TeamComparisonStat(name: "Free Throw %", homeValue: 0.85, awayValue: 0.78, homeDisplay: "85.0%", awayDisplay: "78.0%"),
            TeamComparisonStat(name: "Total Rebounds", homeValue: 48, awayValue: 42, homeDisplay: "48", awayDisplay: "42"),
            TeamComparisonStat(name: "Assists", homeValue: 28, awayValue: 22, homeDisplay: "28", awayDisplay: "22"),
            TeamComparisonStat(name: "Turnovers", homeValue: 12, awayValue: 18, homeDisplay: "12", awayDisplay: "18"),
            TeamComparisonStat(name: "Steals", homeValue: 8, awayValue: 6, homeDisplay: "8", awayDisplay: "6")
        ],
        homeTeam: "Cleveland Cavaliers",
        awayTeam: "Minnesota Timberwolves"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Single Row") {
    TeamComparisonRowView(
        stat: TeamComparisonStat(
            name: "Field Goal %",
            homeValue: 0.52,
            awayValue: 0.44,
            homeDisplay: "52.0%",
            awayDisplay: "44.0%"
        ),
        homeTeam: "Home",
        awayTeam: "Away"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
