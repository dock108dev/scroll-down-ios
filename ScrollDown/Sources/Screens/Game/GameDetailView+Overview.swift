import SwiftUI

extension GameDetailView {
    // MARK: - Pregame Buzz Section (Tier 4: Reference)

    var pregameSection: some View {
        Tier4Container(
            title: "Pregame Buzz",
            isExpanded: $isOverviewExpanded
        ) {
            pregameBuzzContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pregame buzz")
    }

    @ViewBuilder
    private var pregameBuzzContent: some View {
        let posts = viewModel.pregameSocialPosts
        if posts.isEmpty {
            EmptySectionView(text: "No pregame posts available.")
        } else {
            VStack(spacing: GameDetailLayout.listSpacing) {
                ForEach(posts) { post in
                    pregamePostRow(post)
                }
            }
        }
    }

    /// Individual pre-game social post row
    private func pregamePostRow(_ post: SocialPostEntry) -> some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.smallSpacing) {
            HStack {
                if let handle = post.sourceHandle {
                    Text("@\(handle)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(GameTheme.accentColor)
                }
                Spacer()
                Text(formatPregameDate(post.postedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let text = post.tweetText {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            if post.hasVideo, post.videoUrl != nil {
                pregameMediaIndicator(type: "Video")
            } else if post.imageUrl != nil {
                pregameMediaIndicator(type: "Image")
            }
        }
        .padding(GameDetailLayout.listSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func pregameMediaIndicator(type: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: type == "Video" ? "play.rectangle" : "photo")
                .font(.caption)
            Text("\(type) available")
                .font(.caption)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.caption2)
        }
        .foregroundColor(.secondary)
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formatPregameDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let parsedDate = formatter.date(from: dateString)
            ?? ISO8601DateFormatter().date(from: dateString)
        if let parsedDate {
            return parsedDate.formatted(date: .omitted, time: .shortened)
        }
        return dateString
    }
}
