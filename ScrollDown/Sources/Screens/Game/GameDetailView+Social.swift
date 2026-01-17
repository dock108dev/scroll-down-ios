import SwiftUI

// MARK: - Related Posts

extension GameDetailView {
    
    /// Related posts section - currently unused but may be re-enabled
    /// Shows external articles/posts related to the game
    var relatedPostsContent: some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.cardSpacing) {
            switch viewModel.relatedPostsState {
            case .idle, .loading:
                HStack(spacing: GameDetailLayout.listSpacing) {
                    ProgressView()
                    Text("Loading related posts...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            case .failed(let message):
                VStack(alignment: .leading, spacing: GameDetailLayout.listSpacing) {
                    Text("Related posts unavailable.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await viewModel.loadRelatedPosts(gameId: gameId, service: appConfig.gameService) }
                    }
                    .buttonStyle(.bordered)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            case .loaded:
                if viewModel.relatedPosts.isEmpty {
                    EmptySectionView(text: "Related posts will appear here.")
                } else {
                    LazyVStack(spacing: GameDetailLayout.cardSpacing) {
                        ForEach(viewModel.relatedPosts) { post in
                            RelatedPostCardView(
                                post: post,
                                isRevealed: viewModel.isRelatedPostRevealed(post),
                                onReveal: {
                                    withAnimation(.easeInOut) {
                                        viewModel.revealRelatedPost(id: post.id)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadRelatedPosts(gameId: gameId, service: appConfig.gameService)
        }
    }
}
