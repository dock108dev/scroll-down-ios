import SwiftUI

struct HighlightCardView: View {
    @Environment(\.openURL) private var openURL
    let post: SocialPostEntry

    var body: some View {
        Button {
            if let url = URL(string: post.postUrl) {
                openURL(url)
            }
        } label: {
            VStack(alignment: .leading, spacing: Layout.spacing) {
                HStack {
                    Text(postTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: Layout.metaSpacing) {
                        if let handle = post.sourceHandle {
                            Text("@\(handle)")
                                .font(.caption.weight(.medium))
                                .foregroundColor(GameTheme.accentColor)
                        }
                        Text(formattedTimestamp)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                mediaView

                if let text = post.tweetText {
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(Layout.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GameTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(GameTheme.cardBorder, lineWidth: Layout.borderWidth)
            )
            .shadow(
                color: GameTheme.cardShadow,
                radius: Layout.shadowRadius,
                x: 0,
                y: Layout.shadowYOffset
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Highlight from \(post.sourceHandle ?? "social")")
        .accessibilityHint("Opens the original post")
    }

    private var mediaView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.mediaCornerRadius)
                .fill(Color(.systemGray6))
                .frame(height: Layout.mediaHeight)

            if let imageURL = post.imageUrl, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    mediaPlaceholder
                }
                .frame(height: Layout.mediaHeight)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Layout.mediaCornerRadius))
            } else {
                mediaPlaceholder
            }
        }
    }

    private var postTitle: String {
        post.hasVideo ? "Highlight" : "Post"
    }

    private var formattedTimestamp: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let parsedDate = formatter.date(from: post.postedAt)
            ?? ISO8601DateFormatter().date(from: post.postedAt)
        if let parsedDate {
            return parsedDate.formatted(date: .abbreviated, time: .shortened)
        }
        return post.postedAt
    }

    private var mediaPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.mediaCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray6), Color(.systemGray5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: Layout.mediaHeight)
            VStack(spacing: Layout.placeholderSpacing) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: Layout.videoIconSize))
                    .foregroundColor(.secondary)
                Text("Media unavailable in mock mode")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Layout.placeholderPadding)
        }
    }
}

private enum Layout {
    static let spacing: CGFloat = 12
    static let padding: CGFloat = 14
    static let cornerRadius: CGFloat = 16
    static let borderWidth: CGFloat = 1
    static let mediaHeight: CGFloat = 160
    static let mediaCornerRadius: CGFloat = 12
    static let videoIconSize: CGFloat = 32
    static let placeholderSpacing: CGFloat = 6
    static let placeholderPadding: CGFloat = 12
    static let metaSpacing: CGFloat = 2
    static let shadowRadius: CGFloat = 10
    static let shadowYOffset: CGFloat = 4
}

#Preview {
    HighlightCardView(post: PreviewFixtures.highlightsHeavyGame.socialPosts.first ?? PreviewFixtures.highlightsHeavyGame.socialPosts[0])
        .padding()
        .background(Color(.systemGroupedBackground))
}
