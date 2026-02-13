import SwiftUI

/// Social post card displaying team reactions and highlights
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
                Text(SocialPostRow.sanitizeTweetText(text))
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
        tweetText: "Great energy from the home crowd tonight! \u{1F340}",
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
