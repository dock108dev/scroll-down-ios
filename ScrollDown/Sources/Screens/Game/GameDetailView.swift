import SwiftUI

/// Game detail view showing full game information
struct GameDetailView: View {
    @EnvironmentObject var appConfig: AppConfig
    let gameId: Int
    
    @StateObject private var viewModel: GameDetailViewModel
    @State private var selectedSection: GameSection = .overview
    @State private var collapsedQuarters: Set<Int> = []
    @State private var hasInitializedQuarters = false
    @State private var viewMode: ViewMode = .full
    @State private var isOverviewExpanded = false
    @State private var isPreGameExpanded = true
    @State private var isTimelineExpanded = false
    @State private var isPlayerStatsExpanded = false
    @State private var isTeamStatsExpanded = false
    @State private var isFinalScoreExpanded = false
    @State private var isPostGameExpanded = false

    init(gameId: Int, detail: GameDetailResponse? = nil) {
        self.gameId = gameId
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(detail: detail))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.detail != nil {
                gameContentView()
            }
        }
        .navigationTitle(viewModel.game?.matchupTitle ?? "Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(gameId: gameId, service: appConfig.gameService)
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading game...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Error")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.load(gameId: gameId, service: appConfig.gameService) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func gameContentView() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: Layout.sectionSpacing) {
                    if let game = viewModel.game {
                        GameHeaderView(game: game, scoreRevealed: isFinalScoreExpanded)
                            .id(GameSection.header)
                    }

                    VStack(spacing: Layout.sectionSpacing) {
                        viewModeToggleCard
                            .id(Layout.viewModeAnchor)
                        overviewSection
                            .id(GameSection.overview)
                            .onAppear {
                                selectedSection = .overview
                            }
                        preGameSection
                        timelineSection
                            .id(GameSection.timeline)
                            .onAppear {
                                selectedSection = .timeline
                            }
                        playerStatsSection(viewModel.playerStats)
                            .id(GameSection.playerStats)
                            .onAppear {
                                selectedSection = .playerStats
                            }
                        teamStatsSection(viewModel.teamStats)
                            .id(GameSection.teamStats)
                            .onAppear {
                                selectedSection = .teamStats
                            }
                        finalScoreSection
                            .id(GameSection.final)
                            .onAppear {
                                selectedSection = .final
                            }
                        postGameSection
                    }
                    .padding(.horizontal, Layout.horizontalPadding)
                }
                .padding(.bottom, Layout.bottomPadding)
            }
            .background(GameTheme.background)
            .safeAreaInset(edge: .top, spacing: 0) {
                sectionNavigationBar { section in
                    withAnimation(.easeInOut) {
                        selectedSection = section
                        proxy.scrollTo(section, anchor: .top)
                    }
                }
            }
        }
    }

    private var overviewSection: some View {
        CollapsibleSectionCard(
            title: "Overview",
            subtitle: "Spoiler-free recap",
            isExpanded: $isOverviewExpanded
        ) {
            VStack(alignment: .leading, spacing: Layout.textSpacing) {
                Text(viewModel.overviewSummary)
                    .font(.body)
                    .foregroundColor(.primary)
                    .accessibilityLabel("Summary")
                    .accessibilityValue(viewModel.overviewSummary)

                VStack(alignment: .leading, spacing: Layout.listSpacing) {
                    ForEach(viewModel.recapBullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: Layout.listSpacing) {
                            Circle()
                                .frame(width: Layout.bulletSize, height: Layout.bulletSize)
                                .foregroundColor(.secondary)
                                .padding(.top, Layout.bulletOffset)
                            Text(bullet)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game overview")
    }

    private var preGameSection: some View {
        CollapsibleSectionCard(
            title: "Pre-Game",
            subtitle: "Before tipoff",
            isExpanded: $isPreGameExpanded
        ) {
            VStack(spacing: Layout.cardSpacing) {
                ForEach(viewModel.preGamePosts) { post in
                    HighlightCardView(post: post)
                }

                if viewModel.preGamePosts.isEmpty {
                    EmptySectionView(text: "Pre-game posts will appear here.")
                }
            }
        }
        .accessibilityHint("Expands to show pre-game posts")
    }

    private var timelineSection: some View {
        CollapsibleSectionCard(
            title: "Timeline",
            subtitle: "Play-by-play",
            isExpanded: $isTimelineExpanded
        ) {
            VStack(spacing: Layout.cardSpacing) {
                ForEach(viewModel.timelineQuarters) { quarter in
                    quarterSection(quarter)
                }

                if viewModel.timelineQuarters.isEmpty {
                    EmptySectionView(text: "No play-by-play data available.")
                }
            }
        }
        .onChange(of: viewModel.timelineQuarters) { quarters in
            guard !hasInitializedQuarters else { return }
            collapsedQuarters = Set(quarters.map(\.quarter))
            hasInitializedQuarters = true
        }
        .accessibilityElement(children: .contain)
    }

    private func quarterSection(_ quarter: GameDetailViewModel.QuarterTimeline) -> some View {
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
                }
            )
        ) {
            VStack(spacing: Layout.cardSpacing) {
                ForEach(quarter.plays) { play in
                    if let highlights = viewModel.highlightByPlayIndex[play.playIndex] {
                        ForEach(highlights) { highlight in
                            HighlightCardView(post: highlight)
                        }
                    }

                    TimelineRowView(play: play)
                }
            }
            .padding(.top, Layout.listSpacing)
        }
    }

    private func playerStatsSection(_ stats: [PlayerStat]) -> some View {
        CollapsibleSectionCard(
            title: "Player Stats",
            subtitle: "Individual performance",
            isExpanded: $isPlayerStatsExpanded
        ) {
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
                    .frame(minWidth: Layout.statsTableWidth)
                }
            }
        }
    }

    private var playerStatsHeader: some View {
        HStack(spacing: Layout.statsColumnSpacing) {
            Text("Player")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("PTS")
                .frame(width: Layout.statColumnWidth)
            Text("REB")
                .frame(width: Layout.statColumnWidth)
            Text("AST")
                .frame(width: Layout.statColumnWidth)
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(.secondary)
        .padding(.vertical, Layout.listSpacing)
        .padding(.horizontal, Layout.statsHorizontalPadding)
        .background(Color(.systemGray6))
    }

    private func playerStatsRow(_ stat: PlayerStat, isAlternate: Bool) -> some View {
        HStack(spacing: Layout.statsColumnSpacing) {
            VStack(alignment: .leading, spacing: Layout.smallSpacing) {
                Text(stat.playerName)
                    .font(.subheadline.weight(.medium))
                Text(stat.team)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(stat.points.map(String.init) ?? Constants.statFallback)
                .frame(width: Layout.statColumnWidth)
            Text(stat.rebounds.map(String.init) ?? Constants.statFallback)
                .frame(width: Layout.statColumnWidth)
            Text(stat.assists.map(String.init) ?? Constants.statFallback)
                .frame(width: Layout.statColumnWidth)
        }
        .font(.subheadline)
        .padding(.vertical, Layout.listSpacing)
        .padding(.horizontal, Layout.statsHorizontalPadding)
        .background(isAlternate ? Color(.systemGray6) : Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stat.playerName), \(stat.team)")
        .accessibilityValue("Points \(stat.points ?? 0), rebounds \(stat.rebounds ?? 0), assists \(stat.assists ?? 0)")
    }

    private func teamStatsSection(_ stats: [TeamStat]) -> some View {
        CollapsibleSectionCard(
            title: "Team Stats",
            subtitle: "How the game unfolded",
            isExpanded: $isTeamStatsExpanded
        ) {
            if viewModel.teamComparisonStats.isEmpty {
                EmptySectionView(text: "Team stats will appear once available.")
            } else {
                VStack(spacing: Layout.listSpacing) {
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
    }

    private var finalScoreSection: some View {
        CollapsibleSectionCard(
            title: "Final Score",
            subtitle: "Reveal",
            collapsedTitle: "Final Score — tap to reveal",
            isExpanded: $isFinalScoreExpanded
        ) {
            VStack(spacing: Layout.textSpacing) {
                Text(viewModel.game?.scoreDisplay ?? Constants.scoreFallback)
                    .font(.system(size: Layout.finalScoreSize, weight: .bold))
                Text("Final")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                Text("Thanks for scrolling — the game is now fully revealed.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Layout.listSpacing)
        }
    }

    private var postGameSection: some View {
        CollapsibleSectionCard(
            title: "Post-Game",
            subtitle: "Reactions & highlights",
            isExpanded: $isPostGameExpanded
        ) {
            VStack(spacing: Layout.cardSpacing) {
                ForEach(viewModel.postGamePosts) { post in
                    HighlightCardView(post: post)
                }

                if viewModel.postGamePosts.isEmpty {
                    EmptySectionView(text: "Post-game posts will appear here.")
                }
            }
        }
        .accessibilityHint("Expands to show post-game posts")
    }
    
    // MARK: - Helper Views
    
    private func sectionNavigationBar(onSelect: @escaping (GameSection) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.navigationSpacing) {
                ForEach(GameSection.navigationSections, id: \.self) { section in
                    Button {
                        onSelect(section)
                    } label: {
                        Text(section.title)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, Layout.navigationHorizontalPadding)
                            .padding(.vertical, Layout.navigationVerticalPadding)
                            .foregroundColor(selectedSection == section ? .white : .primary)
                            .background(selectedSection == section ? GameTheme.accentColor : Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Jump to \(section.title)")
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.listSpacing)
        }
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .bottom
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Section navigation")
    }

    private func quarterTitle(_ quarter: Int) -> String {
        quarter == 0 ? "Additional" : "Q\(quarter)"
    }

    private var viewModeToggleCard: some View {
        SectionCardView(title: "View Mode", subtitle: "Display only") {
            ViewModeToggleView(selection: $viewMode)
        }
    }
}

private struct CollapsibleSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let collapsedTitle: String?
    @Binding var isExpanded: Bool
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        collapsedTitle: String? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.collapsedTitle = collapsedTitle
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Button(action: toggle) {
                HStack(spacing: Layout.headerSpacing) {
                    VStack(alignment: .leading, spacing: Layout.subtitleSpacing) {
                        if let collapsedTitle, !isExpanded {
                            Text(collapsedTitle)
                                .font(.headline)
                        } else {
                            Text(title)
                                .font(.headline)
                            if let subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .transition(.opacity)
            }
        }
        .sectionCard()
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private func toggle() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isExpanded.toggle()
        }
    }
}

private struct CollapsibleQuarterCard<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: Content

    init(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Button(action: toggle) {
                HStack(spacing: Layout.headerSpacing) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .transition(.opacity)
            }
        }
        .padding(.vertical, Layout.listSpacing)
        .background(GameTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                .stroke(GameTheme.cardBorder, lineWidth: Layout.borderWidth)
        )
        .shadow(
            color: GameTheme.cardShadow,
            radius: Layout.shadowRadius,
            x: 0,
            y: Layout.shadowYOffset
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private func toggle() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isExpanded.toggle()
        }
    }
}

private enum ViewMode: String, CaseIterable {
    case full = "Full"
    case compact = "Compact"
}

private struct ViewModeToggleView: View {
    @Binding var selection: ViewMode

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.listSpacing) {
            Text("View Mode:")
                .font(.subheadline.weight(.semibold))
            HStack(spacing: Layout.toggleSpacing) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button {
                        selection = mode
                    } label: {
                        HStack(spacing: Layout.toggleIconSpacing) {
                            Image(systemName: selection == mode ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(GameTheme.accentColor)
                            Text(mode.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("View mode toggle")
    }
}

private enum Layout {
    static let sectionSpacing: CGFloat = 20
    static let textSpacing: CGFloat = 12
    static let listSpacing: CGFloat = 8
    static let smallSpacing: CGFloat = 4
    static let cardSpacing: CGFloat = 16
    static let horizontalPadding: CGFloat = 20
    static let bottomPadding: CGFloat = 32
    static let bulletSize: CGFloat = 6
    static let bulletOffset: CGFloat = 6
    static let navigationSpacing: CGFloat = 12
    static let navigationHorizontalPadding: CGFloat = 16
    static let navigationVerticalPadding: CGFloat = 8
    static let statsColumnSpacing: CGFloat = 12
    static let statColumnWidth: CGFloat = 48
    static let statsHorizontalPadding: CGFloat = 16
    static let statsTableWidth: CGFloat = 360
    static let finalScoreSize: CGFloat = 40
    static let cardCornerRadius: CGFloat = 16
    static let borderWidth: CGFloat = 1
    static let shadowRadius: CGFloat = 10
    static let shadowYOffset: CGFloat = 4
    static let headerSpacing: CGFloat = 12
    static let subtitleSpacing: CGFloat = 4
    static let toggleSpacing: CGFloat = 16
    static let toggleIconSpacing: CGFloat = 6
    static let viewModeAnchor: String = "viewMode"
}

private enum Constants {
    static let statFallback = "--"
    static let scoreFallback = "--"
}

#Preview {
    Group {
        NavigationStack {
            GameDetailView(gameId: 1, detail: PreviewFixtures.highlightsHeavyGame)
        }
        .preferredColorScheme(.light)
        .environmentObject(AppConfig.shared)

        NavigationStack {
            GameDetailView(gameId: 2, detail: PreviewFixtures.highlightsLightGame)
        }
        .preferredColorScheme(.dark)
        .environmentObject(AppConfig.shared)

        NavigationStack {
            GameDetailView(gameId: 3, detail: PreviewFixtures.overtimeGame)
        }
        .environmentObject(AppConfig.shared)

        NavigationStack {
            GameDetailView(gameId: 4, detail: PreviewFixtures.preGameOnlyGame)
        }
        .environmentObject(AppConfig.shared)
    }
}
