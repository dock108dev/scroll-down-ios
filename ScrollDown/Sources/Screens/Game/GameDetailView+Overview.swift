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
        SocialPostRow(post: post, displayMode: .standard)
    }
}
