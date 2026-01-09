import SwiftUI

extension GameDetailView {
    var preGameSection: some View {
        CollapsibleSectionCard(
            title: "Pre-Game",
            subtitle: "Before tipoff",
            isExpanded: $isPreGameExpanded
        ) {
            preGameContent
        }
        .accessibilityHint("Expands to show pre-game posts")
    }

    var preGameContent: some View {
        VStack(spacing: GameDetailLayout.cardSpacing) {
            ForEach(viewModel.preGamePosts) { post in
                HighlightCardView(post: post)
            }

            if viewModel.preGamePosts.isEmpty {
                EmptySectionView(text: "Pre-game posts will appear here.")
            }
        }
    }

    var postGameSection: some View {
        CollapsibleSectionCard(
            title: "Post-Game",
            subtitle: "Reactions",
            isExpanded: $isPostGameExpanded
        ) {
            postGameContent
        }
        .accessibilityHint("Expands to show post-game posts")
    }

    var postGameContent: some View {
        VStack(spacing: GameDetailLayout.cardSpacing) {
            ForEach(viewModel.postGamePosts) { post in
                HighlightCardView(post: post)
            }

            if viewModel.postGamePosts.isEmpty {
                EmptySectionView(text: "Post-game posts will appear here.")
            }
        }
    }

    var compactPostsContent: some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.cardSpacing) {
            if viewModel.preGamePosts.isEmpty && viewModel.postGamePosts.isEmpty {
                EmptySectionView(text: "Posts will appear here.")
            } else {
                compactPostsSection(
                    title: "Pre-Game",
                    posts: viewModel.preGamePosts,
                    emptyText: "Pre-game posts will appear here."
                )
                compactPostsSection(
                    title: "Post-Game",
                    posts: viewModel.postGamePosts,
                    emptyText: "Post-game posts will appear here."
                )
            }

            relatedPostsCompactSection
        }
    }

    func compactPostsSection(
        title: String,
        posts: [SocialPostEntry],
        emptyText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.listSpacing) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            if posts.isEmpty {
                EmptySectionView(text: emptyText)
            } else {
                ForEach(posts) { post in
                    HighlightCardView(post: post)
                }
            }
        }
    }

    /// Social section (Phase E) - Optional, opt-in social context
    var socialSection: some View {
        CollapsibleSectionCard(
            title: "Social",
            subtitle: "Team reactions",
            isExpanded: $isSocialExpanded
        ) {
            socialContent
        }
        .accessibilityHint("Expands to show social posts")
    }
    
    @ViewBuilder
    private var socialContent: some View {
        if !viewModel.isSocialTabEnabled {
            // Social tab not yet enabled - show opt-in prompt
            socialOptInView
        } else {
            // Social tab enabled - show posts
            socialFeedView
        }
    }
    
    /// Opt-in prompt for social tab
    private var socialOptInView: some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.listSpacing) {
            Text("See team reactions and highlights from social media")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                Task {
                    await viewModel.enableSocialTab(gameId: gameId, service: appConfig.gameService)
                }
            } label: {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Enable Social Tab")
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(GameTheme.accentColor)
            
            Text("Optional: Adds extra color without affecting the core timeline")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, GameDetailLayout.smallSpacing)
    }
    
    /// Social feed view with reveal-aware filtering
    @ViewBuilder
    private var socialFeedView: some View {
        switch viewModel.socialPostsState {
        case .idle, .loading:
            // Phase F: Loading skeleton instead of spinner
            VStack(spacing: GameDetailLayout.cardSpacing) {
                ForEach(0..<3, id: \.self) { _ in
                    LoadingSkeletonView(style: .socialPost)
                }
            }
        case .failed:
            // Phase F: Improved error state
            EmptySectionView(
                text: "Social posts unavailable. Tap to retry.",
                icon: "exclamationmark.triangle"
            )
            .onTapGesture {
                Task { await viewModel.loadSocialPosts(gameId: gameId, service: appConfig.gameService) }
            }
        case .loaded:
            let filteredPosts = viewModel.filteredSocialPosts
            if filteredPosts.isEmpty {
                // Phase F: Contextual empty state
                EmptySectionView(
                    text: viewModel.isOutcomeRevealed 
                        ? "No social posts available for this game."
                        : "No pre-reveal social posts yet. More may appear after revealing the outcome.",
                    icon: "bubble.left.and.bubble.right"
                )
            } else {
                LazyVStack(spacing: GameDetailLayout.cardSpacing) {
                    ForEach(filteredPosts) { post in
                        SocialPostCardView(
                            post: post,
                            isOutcomeRevealed: viewModel.isOutcomeRevealed
                        )
                    }
                }
            }
        }
    }

    var relatedPostsSection: some View {
        CollapsibleSectionCard(
            title: "Related Posts",
            subtitle: "More coverage",
            isExpanded: $isRelatedPostsExpanded
        ) {
            relatedPostsContent
        }
        .accessibilityHint("Expands to show related posts")
    }

    var relatedPostsCompactSection: some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.listSpacing) {
            Text("Related")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            relatedPostsContent
        }
    }

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
