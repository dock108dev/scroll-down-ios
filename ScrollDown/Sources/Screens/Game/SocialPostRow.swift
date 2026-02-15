import SwiftUI

// MARK: - Social Post Display Mode

enum SocialPostDisplayMode {
    case standard
    case embedded
}

// MARK: - Unified Social Post Row

/// Unified view for displaying social posts across Pregame, Postgame, and Flow tabs
struct SocialPostRow: View {
    let post: SocialPostEntry
    var displayMode: SocialPostDisplayMode = .standard

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingSafari = false

    private var hasImageMedia: Bool {
        post.imageUrl != nil
    }

    private var hasVideoOnly: Bool {
        !hasImageMedia && (post.videoUrl != nil || post.hasVideo)
    }

    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var thumbnailSize: CGFloat { isCompact ? 120 : 240 }

    var body: some View {
        Button {
            showingSafari = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Attribution header
                attributionHeader

                // Image posts: side-by-side on iPad, stacked on iPhone
                if hasImageMedia {
                    if isCompact {
                        // iPhone: text above, image below (full width)
                        if let text = post.tweetText {
                            Text(Self.sanitizeTweetText(text))
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.TextColor.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        mediaFullWidth
                    } else {
                        // iPad: two-column layout, text left, image right
                        HStack(alignment: .top, spacing: 10) {
                            if let text = post.tweetText {
                                Text(Self.sanitizeTweetText(text))
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.TextColor.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Spacer()
                            }

                            mediaThumbnail
                        }
                    }
                } else if let text = post.tweetText {
                    Text(Self.sanitizeTweetText(text))
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.TextColor.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                // Video below text (full width) when no image thumbnail
                if hasVideoOnly {
                    videoContent
                }

                // Engagement metrics (standard mode only)
                if displayMode == .standard {
                    engagementMetrics
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cardRadius)
                    .stroke(DesignSystem.borderColor.opacity(displayMode == .embedded ? 0.3 : 1), lineWidth: DesignSystem.borderWidth)
            )
            .shadow(color: displayMode == .standard ? Color.black.opacity(0.06) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(SubtleInteractiveButtonStyle())
        .sheet(isPresented: $showingSafari) {
            if let url = URL(string: post.postUrl) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Media Thumbnail (image posts only)

    @ViewBuilder
    private var mediaThumbnail: some View {
        if let imageUrlString = post.imageUrl, let url = URL(string: imageUrlString) {
            ZStack {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .overlay { ProgressView().scaleEffect(0.7) }
                }
                .frame(width: thumbnailSize, height: thumbnailSize)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if post.videoUrl != nil {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 11))
                        }
                }
            }
        }
    }

    // MARK: - Full-Width Media (iPhone image posts)

    @ViewBuilder
    private var mediaFullWidth: some View {
        if let imageUrlString = post.imageUrl, let url = URL(string: imageUrlString) {
            ZStack {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .overlay { ProgressView().scaleEffect(0.7) }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if post.videoUrl != nil {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 11))
                        }
                }
            }
        }
    }

    // MARK: - Video Content (video-only posts, full width)

    @ViewBuilder
    private var videoContent: some View {
        if let videoUrlString = post.videoUrl, let url = URL(string: videoUrlString) {
            InlineVideoPlayer(url: url)
        } else {
            WatchOnXButton(postUrl: post.postUrl)
        }
    }

    // MARK: - Attribution Header

    private var attributionHeader: some View {
        HStack(spacing: 5) {
            // X platform badge (citation-sized, not dominant)
            ZStack {
                Circle()
                    .fill(Color(.label).opacity(0.5))
                    .frame(width: 14, height: 14)
                Text("\u{1D54F}")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Color(.systemBackground))
            }

            if let handle = post.sourceHandle {
                Text("@\(handle)")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(DesignSystem.TextColor.tertiary)
            }

            Spacer()

            Text(formattedTimestamp)
                .font(.caption2)
                .foregroundColor(DesignSystem.TextColor.tertiary)

            Image(systemName: "arrow.up.right")
                .font(.caption2)
                .foregroundColor(DesignSystem.TextColor.tertiary)
        }
    }

    // MARK: - Engagement Metrics

    @ViewBuilder
    private var engagementMetrics: some View {
        let replies = post.repliesCount ?? 0
        let retweets = post.retweetsCount ?? 0
        let likes = post.likesCount ?? 0

        if replies > 0 || retweets > 0 || likes > 0 {
            HStack(spacing: 16) {
                if replies > 0 {
                    metricLabel(icon: "bubble.right", count: replies)
                }
                if retweets > 0 {
                    metricLabel(icon: "arrow.2.squarepath", count: retweets)
                }
                if likes > 0 {
                    metricLabel(icon: "heart", count: likes)
                }
                Spacer()
            }
        }
    }

    private func metricLabel(icon: String, count: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(compactNumber(count))
                .font(.caption2)
        }
        .foregroundColor(DesignSystem.TextColor.tertiary)
    }

    // MARK: - Helpers

    private var cardBackground: Color {
        switch displayMode {
        case .standard:
            return DesignSystem.Colors.cardBackground
        case .embedded:
            return DesignSystem.Colors.cardBackground.opacity(0.3)
        }
    }

    private var cardRadius: CGFloat {
        switch displayMode {
        case .standard:
            return DesignSystem.Radius.card
        case .embedded:
            return DesignSystem.Radius.element
        }
    }

    private var formattedTimestamp: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: post.postedAt) {
            return relativeTime(date)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: post.postedAt) {
            return relativeTime(date)
        }
        return post.postedAt
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Strip URLs, decode HTML entities, normalize Unicode separators,
    /// and collapse whitespace so the post reads cleanly in a non-tappable Text view.
    static func sanitizeTweetText(_ text: String) -> String {
        var result = text

        // 0. Decode HTML entities (emojis may arrive as &#x1F525; or &#128293; or &amp;)
        result = decodeHTMLEntities(result)

        // 1. Strip URLs FIRST — before unicode normalization can break them
        //    Match http(s) URLs even if unicode separators split them
        result = result.replacingOccurrences(
            of: #"https?://[\S\u{2028}\u{2029}\u{0085}]+"#,
            with: "",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"www\.[\S\u{2028}\u{2029}\u{0085}]+"#,
            with: "",
            options: .regularExpression
        )
        // Strip bare shortened URLs (bit.ly/xxx, t.co/xxx, etc.)
        result = result.replacingOccurrences(
            of: #"(?:bit\.ly|t\.co|tinyurl\.com|goo\.gl|ow\.ly|buff\.ly|dlvr\.it|is\.gd)/[\S\u{2028}\u{2029}\u{0085}]+"#,
            with: "",
            options: .regularExpression
        )

        // 2. Normalize unicode separators (preserve emoji variation selectors like \u{FE0F})
        result = result
            .replacingOccurrences(of: "\u{2028}", with: " ")  // Line Separator
            .replacingOccurrences(of: "\u{2029}", with: "\n") // Paragraph Separator
            .replacingOccurrences(of: "\u{0085}", with: "\n") // Next Line
            .replacingOccurrences(of: "\u{000B}", with: " ")  // Vertical Tab
            .replacingOccurrences(of: "\u{000C}", with: " ")  // Form Feed
            .replacingOccurrences(of: "\u{200B}", with: "")   // Zero Width Space
            .replacingOccurrences(of: "\u{FEFF}", with: "")   // BOM / Zero Width No-Break Space

        // 3. Clean up leftover punctuation and collapse whitespace
        result = result.replacingOccurrences(
            of: #"[:\-–—]\s*\n"#,
            with: "\n",
            options: .regularExpression
        )
        // Collapse runs of whitespace-only lines
        result = result.replacingOccurrences(
            of: #"\n[ \t]*\n"#,
            with: "\n\n",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"\n{3,}"#,
            with: "\n\n",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Decode HTML entities: &#x1F525; &#128293; &amp; &lt; etc.
    private static func decodeHTMLEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }

        var result = text

        // Hex entities: &#x1F525;
        let hexPattern = #"&#x([0-9A-Fa-f]+);"#
        if let regex = try? NSRegularExpression(pattern: hexPattern) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, range: range).reversed()
            for match in matches {
                if let hexRange = Range(match.range(at: 1), in: result),
                   let codePoint = UInt32(result[hexRange], radix: 16),
                   let scalar = Unicode.Scalar(codePoint) {
                    let fullRange = Range(match.range, in: result)!
                    result.replaceSubrange(fullRange, with: String(scalar))
                }
            }
        }

        // Decimal entities: &#128293;
        let decPattern = #"&#([0-9]+);"#
        if let regex = try? NSRegularExpression(pattern: decPattern) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, range: range).reversed()
            for match in matches {
                if let decRange = Range(match.range(at: 1), in: result),
                   let codePoint = UInt32(result[decRange]),
                   let scalar = Unicode.Scalar(codePoint) {
                    let fullRange = Range(match.range, in: result)!
                    result.replaceSubrange(fullRange, with: String(scalar))
                }
            }
        }

        // Named entities
        result = result
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")

        return result
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
}
