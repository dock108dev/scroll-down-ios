import SwiftUI

/// Unified timeline row that renders pbp, tweet, and odds events
/// iPad: Wider layout for improved readability
struct UnifiedTimelineRowView: View {
    let event: UnifiedTimelineEvent
    var homeTeam: String = "Home"
    var awayTeam: String = "Away"
    var isKeyPlay: Bool = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var layout: TimelineRowLayoutConfig {
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
                    HStack(spacing: 4) {
                        if isKeyPlay {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(DesignSystem.Accent.primary)
                        }
                        if let description = event.description {
                            StyledPlayDescription(
                                description: description,
                                playType: event.playType,
                                font: layout.descriptionFont
                            )
                        }
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
                Text("\u{2013}")
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
                Text(SocialPostRow.sanitizeTweetText(text))
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

            // Engagement metrics
            tweetEngagementBar
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

    // MARK: - Tweet Engagement

    @ViewBuilder
    private var tweetEngagementBar: some View {
        let replies = event.repliesCount ?? 0
        let retweets = event.retweetsCount ?? 0
        let likes = event.likesCount ?? 0

        if replies > 0 || retweets > 0 || likes > 0 {
            HStack(spacing: 16) {
                if replies > 0 {
                    engagementMetric(icon: "bubble.right", count: replies)
                }
                if retweets > 0 {
                    engagementMetric(icon: "arrow.2.squarepath", count: retweets)
                }
                if likes > 0 {
                    engagementMetric(icon: "heart", count: likes)
                }
                Spacer()
            }
        }
    }

    private func engagementMetric(icon: String, count: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(compactNumber(count))
                .font(.caption2)
        }
        .foregroundColor(DesignSystem.TextColor.tertiary)
    }

    private func compactNumber(_ value: Int) -> String {
        switch value {
        case 0..<1_000:
            return "\(value)"
        case 1_000..<1_000_000:
            let k = Double(value) / 1_000.0
            return k.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(k))K"
                : String(format: "%.1fK", k)
        default:
            let m = Double(value) / 1_000_000.0
            return m.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(m))M"
                : String(format: "%.1fM", m)
        }
    }

    // MARK: - Helpers

    /// Detects if this play resulted in points scored.
    /// Uses hardcoded string matching because the event model lacks a `isScoring` flag —
    /// the server PBP data only provides free-text descriptions, not structured scoring metadata.
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
