import SwiftUI

extension GameDetailView {
    // MARK: - Pregame Section
    
    var pregameSection: some View {
        CollapsibleSectionCard(
            title: "Pregame",
            subtitle: "Context and preview",
            isExpanded: $isOverviewExpanded
        ) {
            pregameContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pregame information")
    }

    private var pregameContent: some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.sectionSpacing) {
            // Game context - when/where/who
            if let context = viewModel.gameContext {
                contextSection(context)
            }
            
            // Pre-game social posts (lineup announcements, injury updates, etc.)
            if !viewModel.pregameTweets.isEmpty {
                pregameSocialSection
            }
        }
    }
    
    /// Context section explaining the game matchup
    private func contextSection(_ context: String) -> some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.smallSpacing) {
            Label("Context", systemImage: "info.circle")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            
            Text(context)
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(GameDetailLayout.contextPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: GameDetailLayout.contextCornerRadius))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Game context")
        .accessibilityValue(context)
    }
    
    /// Pre-game social posts (limited to 3)
    private var pregameSocialSection: some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.smallSpacing) {
            Label("Pre-game", systemImage: "bubble.left.and.bubble.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            
            VStack(spacing: GameDetailLayout.listSpacing) {
                ForEach(viewModel.pregameTweets.prefix(3)) { tweet in
                    pregameTweetRow(tweet)
                }
            }
        }
    }
    
    /// Individual pre-game tweet row
    private func pregameTweetRow(_ tweet: UnifiedTimelineEvent) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let handle = tweet.sourceHandle {
                Text("@\(handle)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.blue)
            }
            
            if let text = tweet.tweetText {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }
        }
        .padding(GameDetailLayout.contextPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: GameDetailLayout.contextCornerRadius))
    }
    
}
