import SwiftUI

extension GameDetailView {
    // MARK: - Pregame Buzz Section
    
    var pregameSection: some View {
        CollapsibleSectionCard(
            title: "Pregame Buzz",
            subtitle: "Posts from gameday",
            isExpanded: $isOverviewExpanded
        ) {
            pregameBuzzContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pregame buzz")
    }

    @ViewBuilder
    private var pregameBuzzContent: some View {
        let tweets = viewModel.pregameTweets
        if tweets.isEmpty {
            EmptySectionView(text: "No pregame posts available.")
        } else {
            VStack(spacing: GameDetailLayout.listSpacing) {
                ForEach(tweets) { tweet in
                    pregameTweetRow(tweet)
                }
            }
        }
    }
    
    /// Individual pre-game tweet row
    private func pregameTweetRow(_ tweet: UnifiedTimelineEvent) -> some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.smallSpacing) {
            HStack {
                if let handle = tweet.sourceHandle {
                    Text("@\(handle)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(GameTheme.accentColor)
                }
                Spacer()
                if let postedAt = tweet.postedAt {
                    Text(formatPregameDate(postedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let text = tweet.tweetText {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding(GameDetailLayout.listSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
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
