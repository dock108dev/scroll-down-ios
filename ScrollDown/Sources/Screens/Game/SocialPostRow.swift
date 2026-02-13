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

    @State private var showingSafari = false

    private var hasMedia: Bool {
        post.imageUrl != nil || post.videoUrl != nil || post.hasVideo
    }

    private var thumbnailSize: CGFloat { 240 }

    var body: some View {
        Button {
            showingSafari = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Attribution header
                attributionHeader

                // Two-column layout: text left, media thumbnail right
                if hasMedia {
                    HStack(alignment: .top, spacing: 10) {
                        // Text column
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

                        // Thumbnail column
                        mediaThumbnail
                    }
                } else if let text = post.tweetText {
                    Text(Self.sanitizeTweetText(text))
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.TextColor.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
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

    // MARK: - Media Thumbnail

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
        } else if post.videoUrl != nil || post.hasVideo {
            // Video without thumbnail image — styled as a tappable video card
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: thumbnailSize, height: thumbnailSize)
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
            }
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

    /// Normalize Unicode line/paragraph separators and other invisible whitespace
    /// that cause unexpected line breaks in tweet text.
    static func sanitizeTweetText(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{2028}", with: " ")  // Line Separator
            .replacingOccurrences(of: "\u{2029}", with: "\n") // Paragraph Separator
            .replacingOccurrences(of: "\u{0085}", with: "\n") // Next Line
            .replacingOccurrences(of: "\u{000B}", with: " ")  // Vertical Tab
            .replacingOccurrences(of: "\u{000C}", with: " ")  // Form Feed
            .replacingOccurrences(of: "\u{200B}", with: "")   // Zero Width Space
            .replacingOccurrences(of: "\u{FEFF}", with: "")   // BOM / Zero Width No-Break Space
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
