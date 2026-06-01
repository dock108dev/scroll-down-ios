import SwiftUI

enum HomeGameActivationMode {
    case push
    case select(selectedGameId: Int?, select: (HomeGameItem) -> Void)
}

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.sportsLayoutMetrics) private var inheritedLayout
    @State private var scrollCoordinator = HomeScrollCoordinator()
    @State private var viewportSize = CGSize.zero
    private let gameActivation: HomeGameActivationMode

    init(
        viewModel: HomeViewModel,
        gameActivation: HomeGameActivationMode = .push
    ) {
        self.viewModel = viewModel
        self.gameActivation = gameActivation
    }

    var body: some View {
        let layout = SportsLayoutMetrics(
            availableWidth: viewportSize.width > 0 ? viewportSize.width : inheritedLayout.availableWidth,
            availableHeight: viewportSize.height > 0 ? viewportSize.height : inheritedLayout.availableHeight,
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: layout.stackSpacing) {
                    if viewModel.loading && !viewModel.hasAnyHomeSourceGames {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: layout.emptyStateMinHeight, alignment: .center)
                            .accessibilityIdentifier("home.empty.loading")
                    } else if let error = viewModel.errorMessage, !viewModel.hasAnyHomeSourceGames {
                        ErrorState(message: error) {
                            Task { await viewModel.refresh() }
                        }
                        .frame(maxWidth: .infinity, minHeight: layout.emptyStateMinHeight)
                    } else if viewModel.showsNoGamesEmptyState {
                        NoGamesEmptyState()
                            .frame(maxWidth: .infinity, minHeight: layout.emptyStateMinHeight)
                    } else if viewModel.showsFilteredEmptyState {
                        FilteredEmptyState {
                            viewModel.clearFilters()
                        }
                        .frame(maxWidth: .infinity, minHeight: layout.emptyStateMinHeight)
                    } else {
                        if let error = viewModel.errorMessage {
                            InlineErrorState(message: error) {
                                Task { await viewModel.refresh() }
                            }
                        }

                        ForEach(viewModel.filteredHomeSections) { section in
                            switch section {
                            case .pinned(let pinned):
                                PinnedSectionView(section: pinned) { item in
                                    gameLink(for: item)
                                }
                            case .timeline(let timeline):
                                TimelineSectionView(
                                    section: timeline,
                                    hasActiveFilters: viewModel.hasActiveFilters,
                                    clearFilters: viewModel.clearFilters
                                ) { item in
                                    gameLink(for: item)
                                }
                            }
                        }
                    }
                }
                .sportsReadableContent()
                .padding(.top, layout.homeScrollTopPadding)
                .padding(.bottom, layout.homeScrollBottomPadding)
            }
            .accessibilityIdentifier("home.scroll")
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                requestInitialHomeScroll(proxy)
            }
            .onChange(of: viewModel.initialHomeAnchorID) { _, _ in
                requestInitialHomeScroll(proxy, invalidatingPendingScrolls: true)
            }
            .onChange(of: viewModel.filteredVisibleGameCount) { _, _ in
                requestVisibleCountHomeScroll(proxy)
            }
            .onChange(of: viewModel.homeFilterSignature) { _, signature in
                requestFilterHomeScroll(proxy, filterSignature: signature)
            }
        }
        .environment(\.sportsLayoutMetrics, layout)
        .background { SportsPageBackground() }
        .overlay {
            HomeViewportSizeReader()
                .allowsHitTesting(false)
        }
        .onPreferenceChange(HomeViewportSizePreferenceKey.self) { size in
            if size != .zero, size != viewportSize {
                viewportSize = size
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeStickyHeader(viewModel: viewModel)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            #if DEBUG
            let allowsUITestFixtureRefresh = AppEnvironment.uiTestFixtureName != nil
            #else
            let allowsUITestFixtureRefresh = false
            #endif
            guard !AppEnvironment.isRunningTests || allowsUITestFixtureRefresh else { return }
            await viewModel.refresh()
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .onChange(of: viewModel.league) { _, _ in
            Task { await viewModel.refresh() }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .disabled(viewModel.loading)
                .accessibilityLabel("Refresh games")
                .accessibilityIdentifier("home.refresh")
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(SportsTheme.Colors.paper, for: .navigationBar)
    }

    private func requestInitialHomeScroll(
        _ proxy: ScrollViewProxy,
        invalidatingPendingScrolls: Bool = false
    ) {
        if invalidatingPendingScrolls {
            scrollCoordinator.invalidatePendingScrolls()
        }
        guard let request = scrollCoordinator.initialRequest(
            anchorID: viewModel.initialHomeAnchorID,
            visibleCount: viewModel.filteredVisibleGameCount,
            filterSignature: viewModel.homeFilterSignature
        ) else { return }

        scheduleHomeScroll(request, proxy: proxy)
    }

    private func requestFilterHomeScroll(_ proxy: ScrollViewProxy, filterSignature: String) {
        guard let request = scrollCoordinator.filterChanged(
            to: filterSignature,
            anchorID: viewModel.firstVisibleHomeAnchorID,
            visibleCount: viewModel.filteredVisibleGameCount
        ) else { return }

        scheduleHomeScroll(request, proxy: proxy)
    }

    private func requestVisibleCountHomeScroll(_ proxy: ScrollViewProxy) {
        guard let request = scrollCoordinator.visibleCountChanged(
            anchorID: viewModel.firstVisibleHomeAnchorID,
            visibleCount: viewModel.filteredVisibleGameCount,
            filterSignature: viewModel.homeFilterSignature
        ) else { return }

        scheduleHomeScroll(request, proxy: proxy)
    }

    private func scheduleHomeScroll(_ request: HomeScrollRequest, proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            guard isCurrentHomeScrollRequest(request) else { return }
            proxy.scrollTo(request.anchorID, anchor: unitPoint(for: request.position))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                guard isCurrentHomeScrollRequest(request) else { return }
                proxy.scrollTo(request.anchorID, anchor: unitPoint(for: request.position))
                scrollCoordinator.complete(request)
            }
        }
    }

    private func isCurrentHomeScrollRequest(_ request: HomeScrollRequest) -> Bool {
        guard viewModel.isRenderableHomeAnchorID(request.anchorID) else { return false }
        return scrollCoordinator.isCurrent(request, currentValidationKey: currentValidationKey(for: request))
    }

    private func currentValidationKey(for request: HomeScrollRequest) -> String {
        let reason = request.completedFilterSignature == nil ? "initial" : "filter"
        return scrollCoordinator.validationKey(
            reason: reason,
            anchorID: request.anchorID,
            visibleCount: viewModel.filteredVisibleGameCount,
            filterSignature: viewModel.homeFilterSignature
        )
    }

    private func unitPoint(for anchor: HomeProgrammaticScrollAnchor) -> UnitPoint {
        switch anchor {
        case .center:
            return .center
        case .top:
            return .top
        case .bottom:
            return .bottom
        }
    }

    private func gameLink(for item: HomeGameItem) -> some View {
        ZStack(alignment: .topTrailing) {
            gameSelectionControl(for: item)

            HomePinButton(isPinned: item.isPinned) {
                viewModel.togglePin(item.game)
            }
            .accessibilityIdentifier("home.gameRow.\(item.id).pin")
            .padding(.top, HomeGameCardLayout.pinOverlayPadding)
            .padding(.trailing, HomeGameCardLayout.pinOverlayPadding)
        }
        .contextMenu {
            Button {
                viewModel.togglePin(item.game)
            } label: {
                Label(item.isPinned ? "Unpin Game" : "Pin Game", systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            ForEach(favoriteParticipants(for: item.game)) { participant in
                Button {
                    viewModel.toggleFavoriteTeam(participant)
                } label: {
                    Label(
                        favoriteLabel(for: participant),
                        systemImage: viewModel.isFavoriteTeam(participant) ? "star.slash" : "star"
                    )
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                viewModel.togglePin(item.game)
            } label: {
                Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            .tint(SportsTheme.Tone.pinned.accent)
        }
    }

    @ViewBuilder
    private func gameSelectionControl(for item: HomeGameItem) -> some View {
        switch gameActivation {
        case .push:
            NavigationLink(value: HomeGameRoute(item: item)) {
                GameRowView(item: item)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.gameRow.\(item.id)")
        case .select(let selectedGameId, let select):
            let isSelected = selectedGameId == item.id
            Button {
                SportsFeedback.selection()
                select(item)
            } label: {
                GameRowView(item: item)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                                .stroke(SportsTheme.Tone.newPlay.accent, lineWidth: 2.4)
                        }
                    }
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                                .fill(SportsTheme.Tone.newPlay.subtleFill)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.gameRow.\(item.id)")
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        }
    }

    private func favoriteParticipants(for game: Game) -> [GameParticipant] {
        game.participants.filter { $0.favoriteTeamID != nil }
    }

    private func favoriteLabel(for participant: GameParticipant) -> String {
        let teamLabel = participant.abbreviation?.nilIfBlank ?? participant.name
        return viewModel.isFavoriteTeam(participant) ? "Unfavorite \(teamLabel)" : "Favorite \(teamLabel)"
    }
}
