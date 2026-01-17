import SwiftUI

/// Expandable card view for a game moment
/// Shows moment header with type badge, note, clock range, and score delta
/// When expanded, shows player contributions and all plays within the moment
struct MomentCardView: View {
    let moment: Moment
    let plays: [UnifiedTimelineEvent]
    let homeTeam: String
    let awayTeam: String
    @Binding var isExpanded: Bool
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible, tappable)
            Button(action: toggleExpansion) {
                headerContent
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(borderColor, lineWidth: DesignSystem.borderWidth)
        )
        .shadow(
            color: DesignSystem.Shadow.color,
            radius: DesignSystem.Shadow.subtleRadius,
            x: 0,
            y: DesignSystem.Shadow.subtleY
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }
    
    // MARK: - Header Content
    
    private var headerContent: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.elementPadding) {
            // Left: Type badge and main content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.text) {
                // Type badge and note
                HStack(spacing: 6) {
                    momentTypeBadge
                    
                    Text(moment.displayLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(DesignSystem.TextColor.primary)
                }
                
                // Clock and score range
                HStack(spacing: 8) {
                    if let timeRange = moment.timeRange {
                        Label(timeRange, systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.TextColor.tertiary)
                    }
                    
                    scoreRangeChip
                }
                
                // Player preview (collapsed: top 2 players)
                if !moment.players.isEmpty && !isExpanded {
                    playerPreview
                }
            }
            
            Spacer()
            
            // Right: Expansion indicator and play count
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                
                Text("\(moment.playCount) plays")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
            }
        }
        .padding(DesignSystem.Spacing.elementPadding)
        .contentShape(Rectangle())
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.list) {
            Divider()
                .padding(.horizontal, DesignSystem.Spacing.elementPadding)
            
            // Player contributions (expanded: all players)
            if !moment.players.isEmpty {
                playerContributionsSection
                    .padding(.horizontal, DesignSystem.Spacing.elementPadding)
            }
            
            // Plays list
            if !plays.isEmpty {
                VStack(spacing: DesignSystem.Spacing.list) {
                    ForEach(plays) { event in
                        UnifiedTimelineRowView(
                            event: event,
                            homeTeam: homeTeam,
                            awayTeam: awayTeam
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.elementPadding)
                .padding(.bottom, DesignSystem.Spacing.elementPadding)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var momentTypeBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: moment.type.iconName)
                .font(.caption2)
            if moment.isNotable {
                Text(moment.type.displayName.uppercased())
                    .font(.caption2.weight(.bold))
            }
        }
        .foregroundColor(badgeTextColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(badgeBackgroundColor)
        .clipShape(Capsule())
    }
    
    private var scoreRangeChip: some View {
        HStack(spacing: 4) {
            Text(moment.scoreStart)
                .font(.caption2.monospacedDigit())
                .foregroundColor(DesignSystem.TextColor.secondary)
            
            Image(systemName: "arrow.right")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(DesignSystem.TextColor.tertiary)
            
            Text(moment.scoreEnd)
                .font(.caption2.weight(.medium).monospacedDigit())
                .foregroundColor(DesignSystem.TextColor.primary)
        }
    }
    
    private var playerPreview: some View {
        let topPlayers = Array(moment.players.prefix(2))
        return HStack(spacing: 8) {
            ForEach(topPlayers, id: \.name) { player in
                HStack(spacing: 4) {
                    Text(player.name)
                        .font(.caption2)
                        .foregroundColor(DesignSystem.TextColor.secondary)
                    if let summary = player.summary {
                        Text("(\(summary))")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.TextColor.tertiary)
                    }
                }
            }
            
            if moment.players.count > 2 {
                Text("+\(moment.players.count - 2)")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
            }
        }
    }
    
    private var playerContributionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.text) {
            Text("Key contributors")
                .font(.caption.weight(.semibold))
                .foregroundColor(DesignSystem.TextColor.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(moment.players, id: \.name) { player in
                    HStack {
                        Text(player.name)
                            .font(.caption)
                            .foregroundColor(DesignSystem.TextColor.primary)
                        
                        Spacer()
                        
                        Text(player.displayStats)
                            .font(.caption.monospacedDigit())
                            .foregroundColor(DesignSystem.TextColor.secondary)
                    }
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.text)
    }
    
    // MARK: - Styling
    
    private var badgeBackgroundColor: Color {
        switch moment.type {
        case .run:
            return Color.orange.opacity(0.15)
        case .battle:
            return Color.purple.opacity(0.15)
        case .closing:
            return Color.red.opacity(0.15)
        case .neutral:
            return DesignSystem.Colors.neutralBadge
        }
    }
    
    private var badgeTextColor: Color {
        switch moment.type {
        case .run:
            return Color.orange
        case .battle:
            return Color.purple
        case .closing:
            return Color.red
        case .neutral:
            return DesignSystem.TextColor.tertiary
        }
    }
    
    private var borderColor: Color {
        if moment.isNotable {
            return badgeTextColor.opacity(0.3)
        }
        return DesignSystem.borderColor.opacity(0.6)
    }
    
    // MARK: - Actions
    
    private func toggleExpansion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded.toggle()
        }
    }
}

// MARK: - Preview

#Preview("Run Moment - Collapsed") {
    let moment = Moment(
        id: "m_001",
        type: .run,
        startPlay: 21,
        endPlay: 34,
        playCount: 14,
        teams: ["BOS", "LAL"],
        players: [
            PlayerContribution(name: "J. Tatum", stats: ["pts": 8, "ast": 2], summary: "8 pts, 2 ast"),
            PlayerContribution(name: "J. Brown", stats: ["pts": 4], summary: "4 pts"),
            PlayerContribution(name: "D. White", stats: ["stl": 2], summary: "2 stl")
        ],
        scoreStart: "9-12",
        scoreEnd: "9-18",
        clock: "Q1 9:12-7:48",
        isNotable: true,
        note: "8-0 run"
    )
    
    MomentCardView(
        moment: moment,
        plays: [],
        homeTeam: "Celtics",
        awayTeam: "Lakers",
        isExpanded: .constant(false)
    )
    .padding()
}

#Preview("Battle Moment - Expanded") {
    let moment = Moment(
        id: "m_002",
        type: .battle,
        startPlay: 35,
        endPlay: 52,
        playCount: 18,
        teams: ["BOS", "LAL"],
        players: [
            PlayerContribution(name: "L. James", stats: ["pts": 6, "ast": 3], summary: "6 pts, 3 ast"),
            PlayerContribution(name: "J. Tatum", stats: ["pts": 5], summary: "5 pts")
        ],
        scoreStart: "18-22",
        scoreEnd: "26-28",
        clock: "Q1 7:48-4:30",
        isNotable: true,
        note: "Lead changes"
    )
    
    let events = [
        UnifiedTimelineEvent(from: [
            "event_type": "pbp",
            "period": 1,
            "game_clock": "7:30",
            "description": "L. James makes 2-pt shot",
            "home_score": 20,
            "away_score": 22
        ], index: 0),
        UnifiedTimelineEvent(from: [
            "event_type": "pbp",
            "period": 1,
            "game_clock": "7:12",
            "description": "J. Tatum makes 3-pt shot",
            "home_score": 23,
            "away_score": 22
        ], index: 1)
    ]
    
    MomentCardView(
        moment: moment,
        plays: events,
        homeTeam: "Celtics",
        awayTeam: "Lakers",
        isExpanded: .constant(true)
    )
    .padding()
}

#Preview("Neutral Moment") {
    let moment = Moment(
        id: "m_003",
        type: .neutral,
        startPlay: 1,
        endPlay: 20,
        playCount: 20,
        teams: ["BOS", "LAL"],
        players: [],
        scoreStart: "0-0",
        scoreEnd: "9-12",
        clock: "Q1 12:00-9:12",
        isNotable: false,
        note: nil
    )
    
    MomentCardView(
        moment: moment,
        plays: [],
        homeTeam: "Celtics",
        awayTeam: "Lakers",
        isExpanded: .constant(false)
    )
    .padding()
}
