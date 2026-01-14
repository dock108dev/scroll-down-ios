import SwiftUI

/// Unified timeline row that renders both pbp and tweet events
/// Branches on event_type — no client-side type detection
/// Supports compact mode for density changes (layout only, not content)
struct UnifiedTimelineRowView: View {
    let event: UnifiedTimelineEvent
    var isCompact: Bool = false
    
    private var layout: LayoutConfig {
        isCompact ? .compact : .standard
    }
    
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
        HStack(alignment: .top, spacing: layout.contentSpacing) {
            // Time column
            VStack(alignment: .trailing, spacing: layout.timeStackSpacing) {
                if let clock = event.gameClock {
                    Text(clock)
                        .font(layout.timeFont)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                if let period = event.period {
                    Text("Q\(period)")
                        .font(layout.periodFont)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: layout.timeColumnWidth, alignment: .trailing)
            
            // Divider line
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(width: layout.dividerWidth)
            
            // Content
            VStack(alignment: .leading, spacing: layout.textSpacing) {
                if let description = event.description {
                    Text(description)
                        .font(layout.descriptionFont)
                        .foregroundColor(.primary)
                        .lineLimit(isCompact ? 2 : nil)
                }
                
                // Meta info (team/player) - hidden in compact mode
                if !isCompact {
                    HStack(spacing: layout.metaSpacing) {
                        if let team = event.team {
                            Text(team)
                                .font(layout.metaFont)
                                .foregroundColor(.secondary)
                        }
                        if let player = event.playerName {
                            Text(player)
                                .font(layout.metaFont)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Score chip if available
                if let home = event.homeScore, let away = event.awayScore {
                    Text("\(away) - \(home)")
                        .font(layout.scoreChipFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, layout.scoreChipHPadding)
                        .padding(.vertical, layout.scoreChipVPadding)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(layout.rowPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: layout.cornerRadius)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Play")
        .accessibilityValue(event.description ?? "")
    }
    
    // MARK: - Tweet Row
    
    private var tweetRow: some View {
        VStack(alignment: .leading, spacing: layout.textSpacing) {
            // Header with source
            HStack {
                Image(systemName: "bubble.left.fill")
                    .font(layout.metaFont)
                    .foregroundColor(.blue)
                
                if let handle = event.sourceHandle {
                    Text("@\(handle)")
                        .font(layout.handleFont)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if let postedAt = event.postedAt {
                    Text(formattedDate(postedAt))
                        .font(layout.timestampFont)
                        .foregroundColor(.secondary)
                }
            }
            
            // Tweet text
            if let text = event.tweetText {
                Text(text)
                    .font(layout.tweetTextFont)
                    .foregroundColor(.primary)
                    .lineLimit(isCompact ? 2 : 4)
            }
            
            // Media preview - collapsed in compact mode
            if !isCompact, event.imageUrl != nil || event.videoUrl != nil {
                HStack {
                    Image(systemName: event.videoUrl != nil ? "play.rectangle.fill" : "photo.fill")
                        .font(layout.metaFont)
                        .foregroundColor(.secondary)
                    Text(event.videoUrl != nil ? "Video" : "Image")
                        .font(layout.metaFont)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(layout.rowPadding)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius))
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
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius))
    }
    
    // MARK: - Helpers
    
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
    let metaSpacing: CGFloat
    let rowPadding: CGFloat
    let cornerRadius: CGFloat
    let timeColumnWidth: CGFloat
    let dividerWidth: CGFloat
    let timeStackSpacing: CGFloat
    let scoreChipHPadding: CGFloat
    let scoreChipVPadding: CGFloat
    
    // Typography
    let timeFont: Font
    let periodFont: Font
    let descriptionFont: Font
    let metaFont: Font
    let handleFont: Font
    let timestampFont: Font
    let tweetTextFont: Font
    let scoreChipFont: Font
    
    // Standard layout (default)
    static let standard = LayoutConfig(
        contentSpacing: 12,
        textSpacing: 4,
        metaSpacing: 8,
        rowPadding: 12,
        cornerRadius: 12,
        timeColumnWidth: 48,
        dividerWidth: 2,
        timeStackSpacing: 2,
        scoreChipHPadding: 8,
        scoreChipVPadding: 4,
        timeFont: .caption.weight(.semibold),
        periodFont: .caption2,
        descriptionFont: .subheadline,
        metaFont: .caption,
        handleFont: .caption.weight(.semibold),
        timestampFont: .caption2,
        tweetTextFont: .subheadline,
        scoreChipFont: .caption.weight(.medium)
    )
    
    // Compact layout (reduced density)
    static let compact = LayoutConfig(
        contentSpacing: 8,
        textSpacing: 2,
        metaSpacing: 4,
        rowPadding: 8,
        cornerRadius: 8,
        timeColumnWidth: 40,
        dividerWidth: 1,
        timeStackSpacing: 1,
        scoreChipHPadding: 6,
        scoreChipVPadding: 2,
        timeFont: .caption2.weight(.semibold),
        periodFont: .caption2,
        descriptionFont: .footnote,
        metaFont: .caption2,
        handleFont: .caption2.weight(.semibold),
        timestampFont: .caption2,
        tweetTextFont: .footnote,
        scoreChipFont: .caption2.weight(.medium)
    )
}

#Preview("PBP Event - Standard") {
    UnifiedTimelineRowView(event: UnifiedTimelineEvent(
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
    ), isCompact: false)
    .padding()
}

#Preview("PBP Event - Compact") {
    UnifiedTimelineRowView(event: UnifiedTimelineEvent(
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
    ), isCompact: true)
    .padding()
}

#Preview("Tweet Event - Standard") {
    UnifiedTimelineRowView(event: UnifiedTimelineEvent(
        from: [
            "event_type": "tweet",
            "tweet_text": "What a shot by Curry! 🔥 The crowd goes wild as he drains another three pointer!",
            "source_handle": "warriors",
            "posted_at": "2026-01-13T19:30:00Z",
            "image_url": "https://example.com/image.jpg"
        ],
        index: 1
    ), isCompact: false)
    .padding()
}

#Preview("Tweet Event - Compact") {
    UnifiedTimelineRowView(event: UnifiedTimelineEvent(
        from: [
            "event_type": "tweet",
            "tweet_text": "What a shot by Curry! 🔥 The crowd goes wild as he drains another three pointer!",
            "source_handle": "warriors",
            "posted_at": "2026-01-13T19:30:00Z",
            "image_url": "https://example.com/image.jpg"
        ],
        index: 1
    ), isCompact: true)
    .padding()
}
