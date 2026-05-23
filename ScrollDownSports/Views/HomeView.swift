import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if viewModel.loading && !viewModel.hasAnyHomeSourceGames {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                } else if let error = viewModel.errorMessage, !viewModel.hasAnyHomeSourceGames {
                    ErrorState(message: error) {
                        Task { await viewModel.refresh() }
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else if viewModel.showsFilteredEmptyState {
                    FilteredEmptyState {
                        viewModel.clearFilters()
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
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
                        case .today(let today):
                            TodaySectionView(
                                section: today,
                                hasActiveFilters: viewModel.hasActiveFilters,
                                clearFilters: viewModel.clearFilters
                            ) { item in
                                gameLink(for: item)
                            }
                        case .earlier(let earlier):
                            EarlierSectionView(section: earlier) { item in
                                gameLink(for: item)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(
            SportsTheme.Background.page
        )
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeStickyHeader(viewModel: viewModel)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            guard !AppEnvironment.isRunningTests else { return }
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
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .disabled(viewModel.loading)
                .accessibilityLabel("Refresh games")
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(SportsTheme.Colors.paper, for: .navigationBar)
    }

    private func gameLink(for item: HomeGameItem) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                GameDetailView(
                    gameId: item.id,
                    summary: item.game,
                    gameStateStore: viewModel.gameStateStore
                )
            } label: {
                GameRowView(item: item)
            }
            .buttonStyle(.plain)

            HomePinButton(isPinned: item.isPinned) {
                viewModel.togglePin(item.game)
            }
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
        .contextMenu {
            Button {
                viewModel.togglePin(item.game)
            } label: {
                Label(item.isPinned ? "Unpin Game" : "Pin Game", systemImage: item.isPinned ? "pin.slash" : "pin")
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
}

private struct HomeStickyHeader: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        FilterHeader(viewModel: viewModel)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SportsTheme.Colors.paper)
            .overlay(alignment: .bottom) {
                Divider()
                    .overlay(SportsTheme.Colors.hairline)
            }
    }
}

private struct FilterHeader: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("League", selection: $viewModel.league) {
                ForEach(LeagueFilter.allCases) { league in
                    Text(league.rawValue).tag(league)
                }
            }
            .pickerStyle(.segmented)

            TextField("Filter by team", text: $viewModel.teamQuery)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(10)
                .background(SportsTheme.Colors.paperRaised, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                        .stroke(SportsTheme.Stroke.subdued(), lineWidth: SportsTheme.Stroke.standard)
                }

            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
            }
        }
    }
}

private struct PinnedSectionView<Row: View>: View {
    let section: HomePinnedSection
    let row: (HomeGameItem) -> Row

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HomeSectionHeader(title: section.title, subtitle: "Saved and live-tracked games", systemImage: "pin.fill")
                .id("pinned")

            ForEach(section.games) { item in
                row(item)
            }
        }
        .padding(.top, 8)
    }
}

private struct TodaySectionView<Row: View>: View {
    let section: HomeTodaySection
    let hasActiveFilters: Bool
    let clearFilters: () -> Void
    let row: (HomeGameItem) -> Row

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HomeSectionHeader(title: section.title, subtitle: section.subtitle, systemImage: "sun.max.fill")
                .id(section.id)

            if section.games.isEmpty {
                TodayEmptyRow(hasActiveFilters: hasActiveFilters, clearFilters: clearFilters)
            } else {
                ForEach(section.games) { item in
                    row(item)
                }
            }
        }
        .padding(.top, 8)
    }
}

private struct EarlierSectionView<Row: View>: View {
    let section: HomeEarlierSection
    let row: (HomeGameItem) -> Row

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HomeSectionHeader(title: section.title, subtitle: "Recent catch-up", systemImage: "clock.arrow.circlepath")

            ForEach(section.dateSections) { dateSection in
                NestedDateHeader(section: dateSection)
                    .id(dateSection.id)
                    .padding(.top, 6)

                ForEach(dateSection.games) { item in
                    row(item)
                }
            }
        }
        .padding(.top, 16)
    }
}

private struct HomeSectionHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(SportsTheme.Tone.newPlay.accent)
            Text(title)
                .font(SportsTheme.Typography.sectionTitle)
                .foregroundStyle(SportsTheme.Colors.ink)
            Text(subtitle)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
            Spacer()
        }
        .padding(.top, 12)
    }
}

private struct NestedDateHeader: View {
    let section: HomeTimelineSection

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(section.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(SportsTheme.Colors.ink)
            Text(section.subtitle)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
            Spacer()
        }
        .textCase(nil)
        .padding(.top, 12)
    }
}

private struct TodayEmptyRow: View {
    let hasActiveFilters: Bool
    let clearFilters: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .foregroundStyle(SportsTheme.Tone.neutral.accent)
                Text("No games on today's slate for these filters.")
                    .font(.subheadline)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
            }

            if hasActiveFilters {
                Button("Clear filters") {
                    SportsFeedback.selection()
                    clearFilters()
                }
                .buttonStyle(.sportsControl(tone: .scoreboard, compact: true))
                .controlSize(.small)
            } else {
                Text("Pull to refresh or browse earlier games below.")
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sportsSurface(.eventCard)
    }
}

private struct FilteredEmptyState: View {
    let clearFilters: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ContentUnavailableView(
                "No games match these filters",
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text("Clear filters to return to today's slate.")
            )
            Button("Clear filters") {
                SportsFeedback.selection()
                clearFilters()
            }
            .buttonStyle(.sportsControl(tone: .scoreboard, filled: true))
        }
    }
}

private struct InlineErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(SportsTheme.Tone.critical.accent)
            VStack(alignment: .leading, spacing: 6) {
                Text("Showing last known games")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SportsTheme.Colors.ink)
                Text(message)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                Button("Retry") {
                    SportsFeedback.impact()
                    retry()
                }
                .buttonStyle(.sportsControl(tone: .critical, compact: true))
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sportsSurface(.eventCard, accent: SportsTheme.Tone.critical.accent)
    }
}

private struct ErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ContentUnavailableView(
                "Unable to load games",
                systemImage: "wifi.exclamationmark",
                description: Text(message)
            )
            Button("Retry") {
                SportsFeedback.impact()
                retry()
            }
            .buttonStyle(.sportsControl(tone: .critical, filled: true))
        }
    }
}
