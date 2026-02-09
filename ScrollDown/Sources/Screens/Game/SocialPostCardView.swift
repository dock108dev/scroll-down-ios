import SafariServices
import SwiftUI

/// Social post card displaying team reactions and highlights
/// Phase E: Optional social context that respects reveal state
struct SocialPostCardView: View {
    let post: SocialPostResponse
    let isOutcomeRevealed: Bool
    @State private var showingSafari = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            // Header: team + timestamp
            HStack(spacing: Layout.headerSpacing) {
                // Team badge
                Text(post.teamId)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Layout.badgePadding)
                    .padding(.vertical, Layout.badgePaddingVertical)
                    .background(GameTheme.accentColor)
                    .clipShape(Capsule())
                
                Spacer()
                
                // Timestamp
                if let formattedTime = formattedTimestamp {
                    Text(formattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Reveal indicator (subtle)
                if let revealLevel = post.revealLevel, revealLevel == .post {
                    Image(systemName: "eye")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Post content
            if let text = post.tweetText {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Media preview
            if post.imageUrl != nil || post.videoUrl != nil {
                SocialMediaPreview(
                    imageUrl: post.imageUrl,
                    videoUrl: post.videoUrl,
                    postUrl: post.postUrl
                )
            } else if post.hasVideo {
                WatchOnXButton(postUrl: post.postUrl)
            }
            
            // Source attribution
            if let handle = post.sourceHandle {
                HStack(spacing: Layout.smallSpacing) {
                    Image(systemName: "link")
                        .font(.caption2)
                    Text("@\(handle)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(Layout.cardPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(borderColor, lineWidth: Layout.borderWidth)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Social post from \(post.teamId)")
        .sheet(isPresented: $showingSafari) {
            if let url = URL(string: post.postUrl) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
    
    /// Border color: subtle differentiation for post-reveal content
    private var borderColor: Color {
        if let revealLevel = post.revealLevel, revealLevel == .post {
            // Post-reveal content: slightly more prominent border
            return Color(.systemGray4)
        } else {
            // Pre-reveal content: standard border
            return Color(.systemGray5)
        }
    }
    
    /// Formatted timestamp
    private var formattedTimestamp: String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: post.postedAt) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: post.postedAt) else {
                return nil
            }
            return formatRelativeTime(date)
        }
        return formatRelativeTime(date)
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private enum Layout {
    static let contentSpacing: CGFloat = 10
    static let headerSpacing: CGFloat = 8
    static let smallSpacing: CGFloat = 4
    static let cardPadding: CGFloat = 14
    static let badgePadding: CGFloat = 8
    static let badgePaddingVertical: CGFloat = 4
    static let mediaPreviewPadding: CGFloat = 10
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let borderWidth: CGFloat = 1
}

// MARK: - In-App Safari View

/// Wraps SFSafariViewController for in-app browsing (videos, full posts)
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = .label
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Shared Social Media Preview

/// Reusable media preview that loads images via AsyncImage and shows video thumbnails
struct SocialMediaPreview: View {
    let imageUrl: String?
    let videoUrl: String?
    var postUrl: String? = nil
    var height: CGFloat = 200
    var tappable: Bool = true

    @State private var showingSafari = false

    var body: some View {
        Group {
            if let imageUrlString = imageUrl, let url = URL(string: imageUrlString) {
                let mediaContent = ZStack {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .overlay { ProgressView() }
                            .frame(height: height)
                    }
                    .frame(maxWidth: .infinity, minHeight: height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))

                    if videoUrl != nil {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 52, height: 52)
                            .overlay {
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                    }
                }

                if tappable {
                    Button {
                        showingSafari = true
                    } label: {
                        mediaContent
                    }
                    .buttonStyle(.plain)
                } else {
                    mediaContent
                }
            } else if videoUrl != nil {
                let videoContent = HStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.title3)
                    Text("Watch video")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))

                if tappable {
                    Button {
                        showingSafari = true
                    } label: {
                        videoContent
                    }
                    .buttonStyle(.plain)
                } else {
                    videoContent
                }
            }
        }
        .sheet(isPresented: $showingSafari) {
            if let postUrl, let url = URL(string: postUrl) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}

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

    private var mediaHeight: CGFloat {
        displayMode == .standard ? 200 : 140
    }

    var body: some View {
        Button {
            showingSafari = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Attribution header
                attributionHeader

                // Tweet text
                if let text = post.tweetText {
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.TextColor.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                // Media preview
                if post.imageUrl != nil || post.videoUrl != nil {
                    SocialMediaPreview(
                        imageUrl: post.imageUrl,
                        videoUrl: post.videoUrl,
                        postUrl: post.postUrl,
                        height: mediaHeight,
                        tappable: false
                    )
                } else if post.hasVideo {
                    WatchOnXButton(postUrl: post.postUrl)
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

    // MARK: - Attribution Header

    private var attributionHeader: some View {
        HStack(spacing: 6) {
            // X platform badge
            ZStack {
                Circle()
                    .fill(Color(.label))
                    .frame(width: 18, height: 18)
                Text("\u{1D54F}")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(.systemBackground))
            }

            if let handle = post.sourceHandle {
                Text("@\(handle)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DesignSystem.TextColor.secondary)
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

// MARK: - Watch on X Button

/// Standalone button for video posts that lack a direct media URL
struct WatchOnXButton: View {
    let postUrl: String

    @State private var showingSafari = false

    var body: some View {
        Button { showingSafari = true } label: {
            HStack(spacing: 10) {
                // X platform badge
                ZStack {
                    Circle()
                        .fill(Color(.label))
                        .frame(width: 24, height: 24)
                    Text("\u{1D54F}")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(.systemBackground))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Watch on X")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    Text("Opens in browser")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Play icon in circular background
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 32, height: 32)
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        }
        .buttonStyle(SubtleInteractiveButtonStyle())
        .sheet(isPresented: $showingSafari) {
            if let url = URL(string: postUrl) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    let post = SocialPostResponse(
        id: 1,
        gameId: 123,
        teamId: "BOS",
        postUrl: "https://twitter.com/celtics/status/123",
        postedAt: "2024-01-15T19:30:00Z",
        hasVideo: false,
        videoUrl: nil,
        imageUrl: nil,
        tweetText: "Great energy from the home crowd tonight! 🍀",
        sourceHandle: "celtics",
        mediaType: nil,
        revealLevel: .pre
    )
    
    VStack(spacing: 16) {
        SocialPostCardView(post: post, isOutcomeRevealed: false)
        
        let postReveal = SocialPostResponse(
            id: 2,
            gameId: 123,
            teamId: "LAL",
            postUrl: "https://twitter.com/lakers/status/124",
            postedAt: "2024-01-15T21:45:00Z",
            hasVideo: true,
            videoUrl: "https://example.com/video.mp4",
            imageUrl: nil,
            tweetText: "What a finish! Final highlights coming soon.",
            sourceHandle: "lakers",
            mediaType: .video,
            revealLevel: .post
        )
        
        SocialPostCardView(post: postReveal, isOutcomeRevealed: true)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
