import SwiftUI

/// Unified timeline row that renders both pbp and tweet events
/// Branches on event_type — no client-side type detection
struct UnifiedTimelineRowView: View {
    let event: UnifiedTimelineEvent
    var homeTeam: String = "Home"
    var awayTeam: String = "Away"
    
    private var layout: LayoutConfig { .standard }
    
    var body: some View {
        switch event.eventType {
        case .pbp:
            pbpRow
        case .tweet:
            tweetRow
        case .unknown:
            unknownRow
        }
    }
    
    // MARK: - Play-by-Play Row
    
    private var pbpRow: some View {
        VStack(spacing: 0) {
            // Main play row
            HStack(alignment: .top, spacing: layout.contentSpacing) {
                // Time column — TERTIARY contrast (metadata)
                VStack(alignment: .trailing, spacing: layout.timeStackSpacing) {
                    if let clock = event.gameClock {
                        Text(clock)
                            .font(layout.timeFont)
                            .foregroundColor(DesignSystem.TextColor.tertiary)
                            .monospacedDigit()
                    }
                    if let period = event.period {
                        Text("Q\(period)")
                            .font(layout.periodFont)
                            .foregroundColor(DesignSystem.TextColor.tertiary)
                    }
                }
                .frame(width: layout.timeColumnWidth, alignment: .trailing)
                
                // Divider line — subtle
                Rectangle()
                    .fill(DesignSystem.borderColor)
                    .frame(width: layout.dividerWidth)
                
                // Content — PRIMARY contrast
                VStack(alignment: .leading, spacing: layout.textSpacing) {
                    if let description = event.description {
                        Text(description)
                            .font(layout.descriptionFont)
                            .foregroundColor(DesignSystem.TextColor.primary)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(layout.rowPadding)
            
            // Score bar for scoring plays
            if isScoringPlay, let home = event.homeScore, let away = event.awayScore {
                scoreBar(home: home, away: away)
            }
        }
        .background(DesignSystem.Colors.rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor.opacity(0.6), lineWidth: DesignSystem.borderWidth)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Play")
        .accessibilityValue(event.description ?? "")
    }
    
    private func scoreBar(home: Int, away: Int) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(DesignSystem.borderColor.opacity(0.5))
                .frame(height: 0.5)
            
            Text("\(awayTeam) \(away) – \(home) \(homeTeam)")
                .font(.caption2.weight(.medium))
                .foregroundColor(DesignSystem.TextColor.secondary)
                .fixedSize()
            
            Rectangle()
                .fill(DesignSystem.borderColor.opacity(0.5))
                .frame(height: 0.5)
        }
        .padding(.horizontal, layout.rowPadding)
        .padding(.bottom, 6) // Tightened
    }
    
    // MARK: - Tweet Row
    
    private var tweetRow: some View {
        VStack(alignment: .leading, spacing: layout.textSpacing) {
            // Header with source — Interaction accent for links (not team color)
            HStack {
                Image(systemName: "bubble.left.fill")
                    .font(layout.metaFont)
                    .foregroundColor(DesignSystem.Accent.primary)
                
                if let handle = event.sourceHandle {
                    Text("@\(handle)")
                        .font(layout.handleFont)
                        .foregroundColor(DesignSystem.Accent.primary)
                }
                
                Spacer()
                
                // Timestamp — NEUTRAL tertiary
                if let postedAt = event.postedAt {
                    Text(formattedDate(postedAt))
                        .font(layout.timestampFont)
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                }
            }
            
            // Tweet text — NEUTRAL primary
            if let text = event.tweetText {
                Text(text)
                    .font(layout.tweetTextFont)
                    .foregroundColor(DesignSystem.TextColor.primary)
            }
            
            // Media preview — NEUTRAL secondary
            if event.imageUrl != nil || event.videoUrl != nil {
                HStack {
                    Image(systemName: event.videoUrl != nil ? "play.rectangle.fill" : "photo.fill")
                        .font(layout.metaFont)
                        .foregroundColor(DesignSystem.TextColor.secondary)
                    Text(event.videoUrl != nil ? "Video" : "Image")
                        .font(layout.metaFont)
                        .foregroundColor(DesignSystem.TextColor.secondary)
                }
            }
        }
        .padding(layout.rowPadding)
        .background(DesignSystem.Colors.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tweet")
        .accessibilityValue(event.tweetText ?? "")
    }
    
    // MARK: - Unknown Event Row
    
    private var unknownRow: some View {
        HStack {
            Image(systemName: "questionmark.circle")
                .foregroundColor(.secondary)
            Text(event.displayTitle)
                .font(layout.descriptionFont)
                .foregroundColor(.secondary)
        }
        .padding(layout.rowPadding)
        .background(DesignSystem.Colors.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
    }
    
    // MARK: - Helpers
    
    /// Detects if this play resulted in points scored
    /// Based on description patterns in real PBP data
    private var isScoringPlay: Bool {
        guard let desc = event.description?.lowercased() else { return false }
        
        // Basketball scoring patterns
        if desc.contains("makes") { return true }
        if desc.contains("free throw") && !desc.contains("miss") { return true }
        
        // Football scoring patterns
        if desc.contains("touchdown") { return true }
        if desc.contains("field goal") && desc.contains("good") { return true }
        if desc.contains("extra point") && desc.contains("good") { return true }
        if desc.contains("safety") { return true }
        if desc.contains("2-point conversion") && !desc.contains("fail") { return true }
        
        return false
    }
    
    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .none
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Layout Configuration

/// Layout configuration for compact vs standard modes
/// Compact mode: reduced spacing, tighter typography, collapsed media
/// Standard mode: full spacing, standard typography, visible media
private struct LayoutConfig {
    // Spacing
    let contentSpacing: CGFloat
    let textSpacing: CGFloat
    let rowPadding: CGFloat
    let cornerRadius: CGFloat
    let timeColumnWidth: CGFloat
    let dividerWidth: CGFloat
    let timeStackSpacing: CGFloat
    
    // Typography
    let timeFont: Font
    let periodFont: Font
    let descriptionFont: Font
    let metaFont: Font
    let handleFont: Font
    let timestampFont: Font
    let tweetTextFont: Font
    
    // Standard layout — tightened spacing, proper contrast
    static let standard = LayoutConfig(
        contentSpacing: 8,
        textSpacing: DesignSystem.Spacing.text,
        rowPadding: DesignSystem.Spacing.elementPadding,
        cornerRadius: DesignSystem.Radius.element,
        timeColumnWidth: 42,
        dividerWidth: 1,
        timeStackSpacing: DesignSystem.Spacing.tight,
        timeFont: DesignSystem.Typography.rowMeta.monospacedDigit(),
        periodFont: DesignSystem.Typography.rowMeta,
        descriptionFont: DesignSystem.Typography.rowTitle,
        metaFont: DesignSystem.Typography.rowMeta,
        handleFont: DesignSystem.Typography.rowMeta.weight(.medium),
        timestampFont: DesignSystem.Typography.rowMeta,
        tweetTextFont: DesignSystem.Typography.rowTitle
    )
}

#Preview("PBP Scoring Play") {
    UnifiedTimelineRowView(
        event: UnifiedTimelineEvent(
            from: [
                "event_type": "pbp",
                "period": 1,
                "game_clock": "11:42",
                "description": "S. Curry makes 3-pt shot from 25 ft",
                "team": "GSW",
                "player_name": "S. Curry",
                "home_score": 3,
                "away_score": 0
            ],
            index: 0
        ),
        homeTeam: "Warriors",
        awayTeam: "Lakers"
    )
    .padding()
}

#Preview("PBP Non-Scoring Play") {
    UnifiedTimelineRowView(
        event: UnifiedTimelineEvent(
            from: [
                "event_type": "pbp",
                "period": 1,
                "game_clock": "11:30",
                "description": "L. James misses 3-pt jump shot from 26 ft",
                "team": "LAL"
            ],
            index: 1
        ),
        homeTeam: "Warriors",
        awayTeam: "Lakers"
    )
    .padding()
}

#Preview("Tweet Event") {
    UnifiedTimelineRowView(
        event: UnifiedTimelineEvent(
            from: [
                "event_type": "tweet",
                "tweet_text": "What a shot by Curry! The crowd goes wild!",
                "source_handle": "warriors",
                "posted_at": "2026-01-13T19:30:00Z",
                "image_url": "https://example.com/image.jpg"
            ],
            index: 2
        ),
        homeTeam: "Warriors",
        awayTeam: "Lakers"
    )
    .padding()
}
