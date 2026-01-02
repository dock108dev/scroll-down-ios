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
                    if let handle = post.sourceHandle {
                        Text("@\(handle)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.blue)
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
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(Color(.systemGray5), lineWidth: Layout.borderWidth)
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
                    ProgressView()
                }
                .frame(height: Layout.mediaHeight)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Layout.mediaCornerRadius))
            } else if post.hasVideo {
                VStack(spacing: Layout.videoSpacing) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: Layout.videoIconSize))
                        .foregroundColor(.blue)
                    Text("Watch highlight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: Layout.videoIconSize))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var postTitle: String {
        post.hasVideo ? "Highlight" : "Post"
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
    static let videoSpacing: CGFloat = 6
}

#Preview {
    HighlightCardView(post: PreviewFixtures.highlightsHeavyGame.socialPosts.first ?? PreviewFixtures.highlightsHeavyGame.socialPosts[0])
        .padding()
        .background(Color(.systemGroupedBackground))
}
