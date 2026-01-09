import SwiftUI

extension GameDetailView {
    var displayOptionsSection: some View {
        SectionCardView(title: "Recap Style", subtitle: "Choose your flow") {
            Toggle("Compact Mode", isOn: $isCompactMode)
                .tint(GameTheme.accentColor)
        }
        .accessibilityHint("Switch to a chapter-based recap flow")
    }

    var overviewSection: some View {
        CollapsibleSectionCard(
            title: "Overview",
            subtitle: "Recap",
            isExpanded: $isOverviewExpanded
        ) {
            overviewContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game overview")
    }

    var overviewContent: some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.sectionSpacing) {
            // Context section (D1) - why this game matters
            if let context = viewModel.gameContext {
                contextSection(context)
            }
            
            // Recap content
            VStack(alignment: .leading, spacing: GameDetailLayout.textSpacing) {
                aiSummaryView

                VStack(alignment: .leading, spacing: GameDetailLayout.listSpacing) {
                    ForEach(viewModel.recapBullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: GameDetailLayout.listSpacing) {
                            Circle()
                                .frame(width: GameDetailLayout.bulletSize, height: GameDetailLayout.bulletSize)
                                .foregroundColor(.secondary)
                                .padding(.top, GameDetailLayout.bulletOffset)
                            Text(bullet)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            
            // Outcome reveal gate (D3)
            revealGateView
        }
    }
    
    /// Context section explaining why the game matters
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
    
    /// Outcome reveal gate - explicit user control
    private var revealGateView: some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.smallSpacing) {
            Divider()
                .padding(.vertical, GameDetailLayout.smallSpacing)
            
            HStack(spacing: GameDetailLayout.listSpacing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.isOutcomeRevealed ? "Outcome visible" : "Outcome hidden")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text(viewModel.isOutcomeRevealed ? "Final result is shown" : "Final result is hidden")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    Task {
                        await viewModel.toggleOutcomeReveal(gameId: gameId, service: appConfig.gameService)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isOutcomeRevealed ? "eye.slash" : "eye")
                        Text(viewModel.isOutcomeRevealed ? "Hide" : "Reveal")
                    }
                    .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(viewModel.isOutcomeRevealed ? .secondary : GameTheme.accentColor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.isOutcomeRevealed ? "Outcome visible" : "Outcome hidden")
        .accessibilityHint("Tap to \(viewModel.isOutcomeRevealed ? "hide" : "reveal") final result")
    }

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

    func timelineSection(using proxy: ScrollViewProxy) -> some View {
        CollapsibleSectionCard(
            title: "Timeline",
            subtitle: "Play-by-play",
            isExpanded: $isTimelineExpanded
        ) {
            timelineContent(using: proxy)
        }
        .onChange(of: viewModel.timelineQuarters) { quarters in
            guard !hasInitializedQuarters else { return }
            // Q1 expanded, Q2+ collapsed per spec
            collapsedQuarters = Set(quarters.filter { $0.quarter > 1 }.map(\.quarter))
            hasInitializedQuarters = true
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: TimelineFramePreferenceKey.self,
                    value: proxy.frame(in: .named(GameDetailLayout.scrollCoordinateSpace))
                )
            }
        )
        .accessibilityElement(children: .contain)
    }

    func timelineContent(using proxy: ScrollViewProxy) -> some View {
        VStack(spacing: GameDetailLayout.cardSpacing) {
            if let liveMarker = viewModel.liveScoreMarker {
                TimelineScoreChipView(marker: liveMarker)
            }

            ForEach(viewModel.timelineQuarters) { quarter in
                quarterSection(quarter, using: proxy)
            }

            if viewModel.timelineQuarters.isEmpty {
                EmptySectionView(text: "No play-by-play data available.")
            }
        }
    }

    func quarterSection(
        _ quarter: GameDetailViewModel.QuarterTimeline,
        using proxy: ScrollViewProxy
    ) -> some View {
        CollapsibleQuarterCard(
            title: "\(quarterTitle(quarter.quarter)) (\(quarter.plays.count) plays)",
            isExpanded: Binding(
                get: { !collapsedQuarters.contains(quarter.quarter) },
                set: { isExpanded in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        if isExpanded {
                            collapsedQuarters.remove(quarter.quarter)
                        } else {
                            collapsedQuarters.insert(quarter.quarter)
                        }
                    }
                    if isExpanded {
                        scrollToQuarterHeader(quarter.quarter, using: proxy)
                    }
                }
            )
        ) {
            VStack(spacing: GameDetailLayout.cardSpacing) {
                ForEach(quarter.plays) { play in
                    if let highlights = viewModel.highlightByPlayIndex[play.playIndex] {
                        ForEach(highlights) { highlight in
                            HighlightCardView(post: highlight)
                        }
                    }

                    TimelineRowView(play: play)
                        .id("play-\(play.playIndex)")
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: PlayRowFramePreferenceKey.self,
                                    value: [play.playIndex: proxy.frame(in: .named(GameDetailLayout.scrollCoordinateSpace))]
                                )
                            }
                        )

                    if let marker = viewModel.scoreMarker(for: play) {
                        TimelineScoreChipView(marker: marker)
                    }
                }
            }
            .padding(.top, GameDetailLayout.listSpacing)
        }
        .id(quarterAnchorId(quarter.quarter))
    }

    func playerStatsSection(_ stats: [PlayerStat]) -> some View {
        CollapsibleSectionCard(
            title: "Player Stats",
            subtitle: "Individual performance",
            isExpanded: $isPlayerStatsExpanded
        ) {
            playerStatsContent(stats)
        }
    }

    @ViewBuilder
    func playerStatsContent(_ stats: [PlayerStat]) -> some View {
        if stats.isEmpty {
            EmptySectionView(text: "Player stats are not yet available.")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    playerStatsHeader
                    ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                        playerStatsRow(stat, isAlternate: index.isMultiple(of: 2))
                    }
                }
                .frame(minWidth: GameDetailLayout.statsTableWidth)
            }
        }
    }

    var playerStatsHeader: some View {
        HStack(spacing: GameDetailLayout.statsColumnSpacing) {
            Text("Player")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("PTS")
                .frame(width: GameDetailLayout.statColumnWidth)
            Text("REB")
                .frame(width: GameDetailLayout.statColumnWidth)
            Text("AST")
                .frame(width: GameDetailLayout.statColumnWidth)
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(.secondary)
        .padding(.vertical, GameDetailLayout.listSpacing)
        .padding(.horizontal, GameDetailLayout.statsHorizontalPadding)
        .background(Color(.systemGray6))
    }

    func playerStatsRow(_ stat: PlayerStat, isAlternate: Bool) -> some View {
        HStack(spacing: GameDetailLayout.statsColumnSpacing) {
            VStack(alignment: .leading, spacing: GameDetailLayout.smallSpacing) {
                Text(stat.playerName)
                    .font(.subheadline.weight(.medium))
                Text(stat.team)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(stat.points.map(String.init) ?? GameDetailConstants.statFallback)
                .frame(width: GameDetailLayout.statColumnWidth)
            Text(stat.rebounds.map(String.init) ?? GameDetailConstants.statFallback)
                .frame(width: GameDetailLayout.statColumnWidth)
            Text(stat.assists.map(String.init) ?? GameDetailConstants.statFallback)
                .frame(width: GameDetailLayout.statColumnWidth)
        }
        .font(.subheadline)
        .padding(.vertical, GameDetailLayout.listSpacing)
        .padding(.horizontal, GameDetailLayout.statsHorizontalPadding)
        .background(isAlternate ? Color(.systemGray6) : Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stat.playerName), \(stat.team)")
        .accessibilityValue("Points \(stat.points ?? 0), rebounds \(stat.rebounds ?? 0), assists \(stat.assists ?? 0)")
    }

    func teamStatsSection(_ stats: [TeamStat]) -> some View {
        CollapsibleSectionCard(
            title: "Team Stats",
            subtitle: "How the game unfolded",
            isExpanded: $isTeamStatsExpanded
        ) {
            teamStatsContent(stats)
        }
    }

    @ViewBuilder
    func teamStatsContent(_ stats: [TeamStat]) -> some View {
        if viewModel.teamComparisonStats.isEmpty {
            EmptySectionView(text: "Team stats will appear once available.")
        } else {
            VStack(spacing: GameDetailLayout.listSpacing) {
                ForEach(viewModel.teamComparisonStats) { stat in
                    TeamComparisonRowView(
                        stat: stat,
                        homeTeam: stats.first(where: { $0.isHome })?.team ?? "Home",
                        awayTeam: stats.first(where: { !$0.isHome })?.team ?? "Away"
                    )
                }
            }
        }
    }

    var finalScoreSection: some View {
        CollapsibleSectionCard(
            title: "Final Score",
            subtitle: "Wrap-up",
            isExpanded: $isFinalScoreExpanded
        ) {
            finalScoreContent
        }
    }

    var finalScoreContent: some View {
        VStack(spacing: GameDetailLayout.textSpacing) {
            Text(viewModel.game?.scoreDisplay ?? GameDetailConstants.scoreFallback)
                .font(.system(size: GameDetailLayout.finalScoreSize, weight: .bold))
            Text("Final")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GameDetailLayout.listSpacing)
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

    // MARK: - Helper Views

    func sectionNavigationBar(onSelect: @escaping (GameSection) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GameDetailLayout.navigationSpacing) {
                ForEach(GameSection.navigationSections, id: \.self) { section in
                    Button {
                        onSelect(section)
                    } label: {
                        Text(section.title)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, GameDetailLayout.navigationHorizontalPadding)
                            .padding(.vertical, GameDetailLayout.navigationVerticalPadding)
                            .foregroundColor(selectedSection == section ? .white : .primary)
                            .background(selectedSection == section ? GameTheme.accentColor : Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Jump to \(section.title)")
                }
            }
            .padding(.horizontal, GameDetailLayout.horizontalPadding)
            .padding(.vertical, GameDetailLayout.listSpacing)
        }
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .bottom
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Section navigation")
    }

    func compactChapterSection(
        number: Int,
        title: String,
        subtitle: String?,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.chapterSpacing) {
            Text("Chapter \(number)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, GameDetailLayout.chapterHorizontalPadding)
            CollapsibleSectionCard(
                title: title,
                subtitle: subtitle,
                isExpanded: isExpanded
            ) {
                content()
            }
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
        case .failed(let message):
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
