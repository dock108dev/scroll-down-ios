import SwiftUI

/// Unified timeline row that renders pbp, tweet, and odds events
/// iPad: Wider layout for improved readability
struct UnifiedTimelineRowView: View {
    let event: UnifiedTimelineEvent
    var homeTeam: String = "Home"
    var awayTeam: String = "Away"

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var layout: LayoutConfig {
        horizontalSizeClass == .regular ? .iPad : .standard
    }
    
    var body: some View {
        switch event.eventType {
        case .pbp:
            pbpRow
        case .tweet:
            tweetRow
        case .odds:
            oddsRow
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
                    if let label = event.periodLabel {
                        Text(label)
                            .font(layout.periodFont)
                            .foregroundColor(DesignSystem.TextColor.tertiary)
                    }
                }
                .frame(width: layout.timeColumnWidth, alignment: .trailing)
                
                // Divider line — subtle
                Rectangle()
                    .fill(DesignSystem.borderColor)
                    .frame(width: layout.dividerWidth)
                
                // Content — styled with visual hierarchy
                VStack(alignment: .leading, spacing: layout.textSpacing) {
                    if let description = event.description {
                        StyledPlayDescription(
                            description: description,
                            playType: event.playType,
                            font: layout.descriptionFont
                        )
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

            // Away team with color
            HStack(spacing: 4) {
                Text(TeamAbbreviations.abbreviation(for: awayTeam))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(DesignSystem.TeamColors.matchupColor(for: awayTeam, against: homeTeam, isHome: false))
                Text("\(away)")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundColor(DesignSystem.TextColor.primary)
                Text("–")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                Text("\(home)")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundColor(DesignSystem.TextColor.primary)
                Text(TeamAbbreviations.abbreviation(for: homeTeam))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(DesignSystem.TeamColors.matchupColor(for: homeTeam, against: awayTeam, isHome: true))
            }
            .fixedSize()

            Rectangle()
                .fill(DesignSystem.borderColor.opacity(0.5))
                .frame(height: 0.5)
        }
        .padding(.horizontal, layout.rowPadding)
        .padding(.bottom, 6)
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
            
            // Media preview
            if event.imageUrl != nil || event.videoUrl != nil {
                SocialMediaPreview(
                    imageUrl: event.imageUrl,
                    videoUrl: event.videoUrl,
                    postUrl: event.tweetUrl
                )
            }
        }
        .padding(layout.rowPadding)
        .background(DesignSystem.Colors.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tweet")
        .accessibilityValue(event.tweetText ?? "")
    }
    
    // MARK: - Odds Row

    private var oddsRow: some View {
        HStack(spacing: layout.contentSpacing) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(layout.metaFont)
                .foregroundColor(DesignSystem.Accent.primary)

            VStack(alignment: .leading, spacing: layout.textSpacing) {
                if let oddsType = event.oddsType {
                    Text(oddsType)
                        .font(layout.handleFont)
                        .foregroundColor(DesignSystem.TextColor.secondary)
                }
                if let description = event.description {
                    Text(description)
                        .font(layout.descriptionFont)
                        .foregroundColor(DesignSystem.TextColor.primary)
                }
            }

            Spacer(minLength: 0)

            if let label = event.periodLabel {
                Text(label)
                    .font(layout.periodFont)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
            }
        }
        .padding(layout.rowPadding)
        .background(DesignSystem.Colors.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Odds update")
        .accessibilityValue(event.description ?? "")
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

    // iPad layout — wider columns, better spacing for larger screens
    static let iPad = LayoutConfig(
        contentSpacing: 12,
        textSpacing: DesignSystem.Spacing.text,
        rowPadding: DesignSystem.Spacing.elementPadding,
        cornerRadius: DesignSystem.Radius.element,
        timeColumnWidth: 50, // Wider time column for better readability
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

// MARK: - Styled Play Description

/// Provides visual hierarchy for play descriptions
/// - Emphasizes: Action words (MISS, makes, REBOUND, GOAL, etc.)
/// - De-emphasizes: Metadata in parentheses, distances, zones
/// - Maintains: Player names at primary contrast
private struct StyledPlayDescription: View {
    let description: String
    let playType: String?
    let font: Font

    var body: some View {
        Text(styledDescription)
            .font(font)
    }

    private var styledDescription: AttributedString {
        var result = AttributedString(description)

        // Set base style - primary text color
        result.foregroundColor = DesignSystem.TextColor.primary

        // 1. Emphasize action keywords (bold + slightly brighter)
        let actionKeywords = [
            // Basketball
            "MISS", "makes", "REBOUND", "STEAL", "BLOCK", "TURNOVER",
            "FOUL", "FREE THROW", "DUNK", "LAYUP", "Jump Shot", "3PT",
            // Hockey
            "GOAL", "SHOT", "SAVE", "HIT", "PENALTY", "FACEOFF",
            "GIVEAWAY", "TAKEAWAY", "Blocked Shot",
            // Football
            "TOUCHDOWN", "INTERCEPTION", "FUMBLE", "SACK", "RUSH",
            "PASS", "PUNT", "FIELD GOAL", "SAFETY",
            // General
            "Timeout", "Substitution"
        ]

        for keyword in actionKeywords {
            emphasizeKeyword(keyword, in: &result, caseInsensitive: true)
        }

        // 2. De-emphasize parenthetical content (stats, counts)
        // Pattern: anything in parentheses like "(3 PTS)" or "(Off:1 Def:0)"
        deemphasizeParentheses(in: &result)

        // 3. De-emphasize distance/location info
        // Pattern: "from 25 ft", "in the paint", "at the rim"
        let locationPatterns = [
            "from \\d+('| ft)",  // "from 25 ft" or "from 25'"
            "in the paint",
            "at the rim",
            "from the top of the key",
            "from the corner",
            "from downtown"
        ]
        for pattern in locationPatterns {
            deemphasizePattern(pattern, in: &result)
        }

        // 4. De-emphasize zone info for hockey
        // Pattern: "Offensive Zone", "Defensive Zone", "Neutral Zone"
        let zonePatterns = ["Offensive Zone", "Defensive Zone", "Neutral Zone"]
        for zone in zonePatterns {
            deemphasizeExact(zone, in: &result)
        }

        return result
    }

    /// Makes a keyword bold/semibold for emphasis
    private func emphasizeKeyword(_ keyword: String, in attributed: inout AttributedString, caseInsensitive: Bool) {
        let searchString = caseInsensitive ? description.lowercased() : description
        let keywordLower = caseInsensitive ? keyword.lowercased() : keyword
        let attrLength = attributed.characters.count

        var searchStart = searchString.startIndex
        while let range = searchString.range(of: keywordLower, range: searchStart..<searchString.endIndex) {
            // Convert String range to AttributedString range
            let startOffset = searchString.distance(from: searchString.startIndex, to: range.lowerBound)
            let endOffset = searchString.distance(from: searchString.startIndex, to: range.upperBound)

            guard startOffset < attrLength, endOffset <= attrLength else {
                searchStart = range.upperBound
                continue
            }

            let attrStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset)
            attributed[attrStart..<attrEnd].font = font.weight(.semibold)

            searchStart = range.upperBound
        }
    }

    /// De-emphasizes content within parentheses
    private func deemphasizeParentheses(in attributed: inout AttributedString) {
        let attrLength = attributed.characters.count
        var searchStart = description.startIndex

        while let openParen = description.range(of: "(", range: searchStart..<description.endIndex),
              let closeParen = description.range(of: ")", range: openParen.upperBound..<description.endIndex) {
            let fullRange = openParen.lowerBound..<closeParen.upperBound

            let startOffset = description.distance(from: description.startIndex, to: fullRange.lowerBound)
            let endOffset = description.distance(from: description.startIndex, to: fullRange.upperBound)

            guard startOffset < attrLength, endOffset <= attrLength else {
                searchStart = closeParen.upperBound
                continue
            }

            let attrStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset)
            attributed[attrStart..<attrEnd].foregroundColor = DesignSystem.TextColor.tertiary
            attributed[attrStart..<attrEnd].font = font

            searchStart = closeParen.upperBound
        }
    }

    /// De-emphasizes text matching a regex pattern
    private func deemphasizePattern(_ pattern: String, in attributed: inout AttributedString) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return }

        let nsString = description as NSString
        let matches = regex.matches(in: description, range: NSRange(location: 0, length: nsString.length))
        let attrLength = attributed.characters.count

        for match in matches {
            let startOffset = match.range.location
            let endOffset = match.range.location + match.range.length

            guard startOffset < attrLength, endOffset <= attrLength else { continue }

            let attrStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset)
            attributed[attrStart..<attrEnd].foregroundColor = DesignSystem.TextColor.tertiary
        }
    }

    /// De-emphasizes exact string matches
    private func deemphasizeExact(_ text: String, in attributed: inout AttributedString) {
        let attrLength = attributed.characters.count
        var searchStart = description.startIndex

        while let range = description.range(of: text, options: .caseInsensitive, range: searchStart..<description.endIndex) {
            let startOffset = description.distance(from: description.startIndex, to: range.lowerBound)
            let endOffset = description.distance(from: description.startIndex, to: range.upperBound)

            guard startOffset < attrLength, endOffset <= attrLength else {
                searchStart = range.upperBound
                continue
            }

            let attrStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset)
            attributed[attrStart..<attrEnd].foregroundColor = DesignSystem.TextColor.tertiary

            searchStart = range.upperBound
        }
    }
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

#Preview("Visual Hierarchy - Basketball") {
    VStack(spacing: 12) {
        // Made shot with stats
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "11:42",
                    "description": "Tatum makes 3PT Jump Shot from 25 ft (3 PTS)",
                    "home_score": 3,
                    "away_score": 0
                ],
                index: 0
            ),
            homeTeam: "Celtics",
            awayTeam: "Heat"
        )

        // Missed shot
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "11:30",
                    "description": "MISS Brown 16' Pullup Jump Shot from the corner"
                ],
                index: 1
            ),
            homeTeam: "Celtics",
            awayTeam: "Heat"
        )

        // Rebound with stats
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "11:28",
                    "description": "Porzingis REBOUND (Off:1 Def:0)"
                ],
                index: 2
            ),
            homeTeam: "Celtics",
            awayTeam: "Heat"
        )

        // Steal
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 2,
                    "game_clock": "5:15",
                    "description": "White STEAL (2 STL)"
                ],
                index: 3
            ),
            homeTeam: "Celtics",
            awayTeam: "Heat"
        )
    }
    .padding()
}

#Preview("Visual Hierarchy - Hockey") {
    VStack(spacing: 12) {
        // Goal
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "14:32",
                    "description": "GOAL MacKinnon Wrist Shot Offensive Zone (1-0)",
                    "home_score": 1,
                    "away_score": 0
                ],
                index: 0
            ),
            homeTeam: "Avalanche",
            awayTeam: "Senators"
        )

        // Shot/Save
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "12:45",
                    "description": "SHOT Tkachuk Slap Shot Offensive Zone - SAVE Georgiev"
                ],
                index: 1
            ),
            homeTeam: "Avalanche",
            awayTeam: "Senators"
        )

        // Hit
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 2,
                    "game_clock": "8:20",
                    "description": "HIT Makar on Batherson Defensive Zone"
                ],
                index: 2
            ),
            homeTeam: "Avalanche",
            awayTeam: "Senators"
        )

        // Penalty
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 2,
                    "game_clock": "3:45",
                    "description": "PENALTY Rantanen Tripping (2 min) Neutral Zone"
                ],
                index: 3
            ),
            homeTeam: "Avalanche",
            awayTeam: "Senators"
        )
    }
    .padding()
}
