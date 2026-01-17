import SwiftUI

/// Expandable card view for a game moment
/// Clean, professional design - narrative headlines, minimal color, compressed metadata
struct MomentCardView: View {
    let moment: Moment
    let plays: [UnifiedTimelineEvent]
    let homeTeam: String
    let awayTeam: String
    @Binding var isExpanded: Bool
    
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
                    .transition(.opacity)
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor.opacity(0.3), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
    
    // MARK: - Header Content
    
    private var headerContent: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left edge accent (only for major inflections)
            if moment.isMajorInflection {
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.Colors.accent)
                    .frame(width: 3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Primary: Narrative headline
                Text(moment.narrativeHeadline(homeTeam: homeTeam, awayTeam: awayTeam))
                    .font(.subheadline.weight(moment.isMajorInflection ? .semibold : .regular))
                    .foregroundColor(DesignSystem.TextColor.primary)
                    .lineLimit(2)
                
                // Secondary: Compressed metadata + score
                HStack(spacing: 6) {
                    Text(moment.compactMetadata)
                        .font(.caption)
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                    
                    Text("·")
                        .font(.caption)
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                    
                    scoreLabel
                }
                
                // Tertiary: Player preview (collapsed only, if notable)
                if !moment.players.isEmpty && !isExpanded && moment.isNotable {
                    playerPreview
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Right: Expansion indicator
            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundColor(DesignSystem.TextColor.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, moment.isMajorInflection ? 8 : 12)
        .contentShape(Rectangle())
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.horizontal, 12)
            
            // Player contributions
            if !moment.players.isEmpty {
                playerContributionsSection
                    .padding(.horizontal, 12)
            }
            
            // Plays list
            if !plays.isEmpty {
                VStack(spacing: 8) {
                    ForEach(plays) { event in
                        UnifiedTimelineRowView(
                            event: event,
                            homeTeam: homeTeam,
                            awayTeam: awayTeam
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var scoreLabel: some View {
        HStack(spacing: 4) {
            Text(moment.scoreStart)
                .font(.caption.monospacedDigit())
                .foregroundColor(DesignSystem.TextColor.tertiary)
            
            Image(systemName: "arrow.right")
                .font(.system(size: 8))
                .foregroundColor(DesignSystem.TextColor.tertiary)
            
            Text(moment.scoreEnd)
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundColor(DesignSystem.TextColor.secondary)
        }
    }
    
    private var playerPreview: some View {
        let topPlayers = Array(moment.players.prefix(2))
        return HStack(spacing: 6) {
            ForEach(topPlayers, id: \.name) { player in
                Text("\(player.name) \(player.summary ?? "")")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.secondary)
            }
            
            if moment.players.count > 2 {
                Text("+\(moment.players.count - 2)")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
            }
        }
    }
    
    private var playerContributionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
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
    
    // MARK: - Actions
    
    private func toggleExpansion() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isExpanded.toggle()
        }
    }
}

// MARK: - Preview

#Preview("Major Inflection - Lead Change") {
    let moment = Moment(
        id: "m_001",
        type: .flip,
        startPlay: 21,
        endPlay: 34,
        playCount: 14,
        teams: ["SAS", "OKC"],
        primaryTeam: "San Antonio Spurs",
        players: [
            PlayerContribution(name: "V. Wembanyama", stats: ["pts": 8, "blk": 2], summary: "8 pts, 2 blk"),
            PlayerContribution(name: "D. Murray", stats: ["pts": 4], summary: "4 pts")
        ],
        scoreStart: "7–5",
        scoreEnd: "15–10",
        clock: "Q1 9:16–7:15",
        isNotable: true,
        note: nil,
        teamInControl: "away"
    )
    
    MomentCardView(
        moment: moment,
        plays: [],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(false)
    )
    .padding()
}

#Preview("Normal Stretch") {
    let moment = Moment(
        id: "m_002",
        type: .neutral,
        startPlay: 35,
        endPlay: 52,
        playCount: 18,
        teams: ["SAS", "OKC"],
        players: [],
        scoreStart: "15–10",
        scoreEnd: "22–18",
        clock: "Q1 7:15–4:30",
        isNotable: false,
        note: nil,
        teamInControl: "away"
    )
    
    MomentCardView(
        moment: moment,
        plays: [],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(false)
    )
    .padding()
}

#Preview("Expanded with Players") {
    let moment = Moment(
        id: "m_003",
        type: .leadBuild,
        startPlay: 1,
        endPlay: 20,
        playCount: 20,
        teams: ["SAS", "OKC"],
        primaryTeam: "Oklahoma City Thunder",
        players: [
            PlayerContribution(name: "S. Gilgeous-Alexander", stats: ["pts": 12], summary: "12 pts"),
            PlayerContribution(name: "J. Williams", stats: ["pts": 6, "ast": 3], summary: "6 pts, 3 ast")
        ],
        scoreStart: "22–18",
        scoreEnd: "34–20",
        clock: "Q2 12:00–8:00",
        isNotable: true,
        isPeriodStart: true,
        note: nil,
        teamInControl: "home"
    )
    
    MomentCardView(
        moment: moment,
        plays: [],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(true)
    )
    .padding()
}
