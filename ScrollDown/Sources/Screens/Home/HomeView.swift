import Combine
import SwiftUI
import UIKit

/// Main home screen displaying list of games
/// iPad: Wider layout with constrained content width for optimal readability
struct HomeView: View {
    @EnvironmentObject var appConfig: AppConfig
    @EnvironmentObject var readStateStore: ReadStateStore
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @State var earlierSection: HomeSectionState
    @State var yesterdaySection: HomeSectionState
    @State var todaySection: HomeSectionState
    @State var tomorrowSection: HomeSectionState
    @State var errorMessage: String?
    @State var lastUpdatedAt: Date?
    @State var selectedLeague: LeagueCode?
    @State private var showingAdminSettings = false // Beta admin access
    @State private var hasLoadedInitialData = false // Prevents reload on back navigation
    @State private var viewMode: HomeViewMode = .recaps
    @State var searchText = ""
    @StateObject private var oddsViewModel = OddsComparisonViewModel()
    @State private var selectedOddsLeague: FairBetLeague?
    @State private var selectedOddsMarket: MarketKey?
    @State private var loadTask: Task<Void, Never>?
    @State var isUpdating = false
    private let refreshTimer = Timer.publish(every: 900, on: .main, in: .common).autoconnect()

    init() {
        let prefs = UserDefaults.standard.string(forKey: "homeExpandedSections") ?? ""
        let expandedSet = Set(prefs.split(separator: ",").map(String.init))
        _earlierSection = State(initialValue: HomeSectionState(range: .earlier, title: HomeStrings.sectionEarlier, isExpanded: expandedSet.contains("earlier")))
        _yesterdaySection = State(initialValue: HomeSectionState(range: .yesterday, title: HomeStrings.sectionYesterday, isExpanded: expandedSet.contains("yesterday")))
        _todaySection = State(initialValue: HomeSectionState(range: .current, title: HomeStrings.sectionToday, isExpanded: expandedSet.contains("current")))
        _tomorrowSection = State(initialValue: HomeSectionState(range: .tomorrow, title: HomeStrings.sectionTomorrow, isExpanded: expandedSet.contains("tomorrow")))
    }

    var body: some View {
        ZStack {
            HomeTheme.background
                .ignoresSafeArea()
            VStack(spacing: 0) {
                headerView
                contentView
            }
            // iPad: Constrain content width for better readability and density
            .frame(maxWidth: horizontalSizeClass == .regular ? 900 : .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                    Text(HomeStrings.navigationTitle)
                        .font(.headline)
                }
            }
        }
        .task {
            // Only load on first appearance — preserve data on back navigation
            guard !hasLoadedInitialData else { return }
            hasLoadedInitialData = true
            startLoadGames()
        }
        .sheet(isPresented: $showingAdminSettings, onDismiss: {
            // Reload data after admin settings changed (e.g., snapshot mode)
            startLoadGames(scrollToToday: false)
        }) {
            AdminSettingsView()
                .environmentObject(appConfig)
        }
        .onReceive(refreshTimer) { _ in
            guard hasLoadedInitialData, viewMode == .recaps else { return }
            startLoadGames(scrollToToday: false, priority: .background)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, hasLoadedInitialData else { return }
            let cache = HomeGameCache.shared
            let dayChanged = !cache.isSameCalendarDay(range: .current, league: selectedLeague)
            let cacheStale = !cache.isFresh(range: .current, league: selectedLeague, maxAge: 900)
            guard dayChanged || cacheStale else { return }
            startLoadGames(scrollToToday: dayChanged)
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Beta admin: snapshot mode indicator
            #if DEBUG
            if appConfig.isSnapshotModeActive, let display = TimeService.shared.snapshotDateDisplay {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.caption2)
                    Text("Testing mode: \(display)")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.8))
                .clipShape(Capsule())
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 8)
            }
            #endif

            // Recaps / Odds segmented toggle
            Picker("Mode", selection: $viewMode) {
                ForEach(HomeViewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Conditional league filter
            if viewMode == .recaps {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HomeLayout.filterSpacing) {
                        leagueFilterButton(nil, label: HomeStrings.allLeaguesLabel)
                        ForEach(LeagueCode.allCases, id: \.self) { league in
                            leagueFilterButton(league, label: league.rawValue)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.trailing, 44)
                    .padding(.vertical, HomeLayout.filterVerticalPadding)
                }
                .overlay(alignment: .trailing) {
                    HStack(spacing: 0) {
                        LinearGradient(
                            colors: [HomeTheme.background.opacity(0), HomeTheme.background],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 20)
                        refreshButton {
                            startLoadGames(scrollToToday: false)
                        }
                        .padding(.trailing, horizontalPadding)
                        .background(HomeTheme.background)
                    }
                }
                .background(HomeTheme.background)

                // Subtle updating indicator during stale-while-revalidate
                if isUpdating {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Updating…")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 2)
                    .transition(.opacity)
                }

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    TextField("Search teams…", text: $searchText)
                        .font(.subheadline)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 4)
            } else if viewMode == .odds {
                // Combined filter bar: league pills, separator, market pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // League filters
                        oddsLeagueFilterButton(nil, label: HomeStrings.allLeaguesLabel)
                        ForEach(FairBetLeague.allCases) { league in
                            oddsLeagueFilterButton(league, label: league.rawValue)
                        }

                        // Separator
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 1, height: 20)

                        // Market filters
                        oddsMarketFilterButton(nil, label: "All")
                        ForEach(MarketKey.mainlineMarkets) { market in
                            oddsMarketFilterButton(market, label: market.displayName)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, HomeLayout.filterVerticalPadding)
                }
                .background(HomeTheme.background)

                // Controls row: search + sort + parlay + refresh
                HStack(spacing: 8) {
                    // Search field
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        TextField("Search teams…", text: $oddsViewModel.searchText)
                            .font(.subheadline)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        if !oddsViewModel.searchText.isEmpty {
                            Button {
                                oddsViewModel.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Sort menu
                    Menu {
                        ForEach(OddsComparisonViewModel.SortOption.allCases, id: \.self) { option in
                            Button {
                                oddsViewModel.sortOption = option
                            } label: {
                                if oddsViewModel.sortOption == option {
                                    Label(option.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(option.rawValue)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Parlay badge
                    if oddsViewModel.parlayCount > 0 {
                        Button {
                            if oddsViewModel.canShowParlay {
                                oddsViewModel.showParlaySheet = true
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.caption2)
                                Text("\(oddsViewModel.parlayCount)")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundColor(oddsViewModel.canShowParlay ? FairBetTheme.info : .secondary)
                            .frame(height: 32)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(oddsViewModel.canShowParlay ? FairBetTheme.info.opacity(0.12) : Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(oddsViewModel.canShowParlay ? FairBetTheme.info.opacity(0.6) : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!oddsViewModel.canShowParlay)
                    }

                    // Refresh button
                    Button {
                        Task { await oddsViewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(oddsViewModel.isLoading)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 6)
            }
        }
    }

    private func leagueFilterButton(_ league: LeagueCode?, label: String) -> some View {
        Button(action: {
            selectedLeague = league
            startLoadGames(scrollToToday: false)
        }) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, HomeLayout.filterHorizontalPadding)
                .padding(.vertical, HomeLayout.filterVerticalPadding)
                .background(selectedLeague == league ? HomeTheme.accentColor : Color(.systemGray5))
                .foregroundColor(selectedLeague == league ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func oddsLeagueFilterButton(_ league: FairBetLeague?, label: String) -> some View {
        Button(action: {
            selectedOddsLeague = league
            oddsViewModel.selectLeague(league)
        }) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, HomeLayout.filterHorizontalPadding)
                .padding(.vertical, HomeLayout.filterVerticalPadding)
                .background(selectedOddsLeague == league ? HomeTheme.accentColor : Color(.systemGray5))
                .foregroundColor(selectedOddsLeague == league ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func oddsMarketFilterButton(_ market: MarketKey?, label: String) -> some View {
        Button(action: {
            selectedOddsMarket = market
            oddsViewModel.selectedMarket = market
        }) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, HomeLayout.filterHorizontalPadding)
                .padding(.vertical, HomeLayout.filterVerticalPadding)
                .background(selectedOddsMarket == market ? HomeTheme.accentColor : Color(.systemGray5))
                .foregroundColor(selectedOddsMarket == market ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private var contentView: some View {
        Group {
            if viewMode == .recaps {
                if let error = errorMessage {
                    errorView(error)
                } else {
                    gameListView
                }
            } else if viewMode == .odds {
                OddsComparisonView(viewModel: oddsViewModel)
            } else {
                SettingsView(oddsViewModel: oddsViewModel, completedGameIds: allCompletedGameIds)
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: HomeLayout.stateSpacing) {
            Image(systemName: HomeStrings.errorIconName)
                .font(.system(size: HomeLayout.errorIconSize))
                .foregroundColor(.orange)
            Text(HomeStrings.errorTitle)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(HomeStrings.retryLabel) {
                startLoadGames()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(HomeLayout.statePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var gameListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: HomeLayout.cardSpacing(horizontalSizeClass)) {
                    // Earlier section (2+ days ago)
                    sectionHeader(for: earlierSection, isExpanded: $earlierSection.isExpanded)
                        .id(earlierSection.title)
                    if earlierSection.isExpanded {
                        sectionContent(for: earlierSection)
                    }

                    // Yesterday section
                    sectionHeader(for: yesterdaySection, isExpanded: $yesterdaySection.isExpanded)
                        .id(yesterdaySection.title)
                    if yesterdaySection.isExpanded {
                        sectionContent(for: yesterdaySection)
                    }

                    // Today section (all games — completed recaps + scheduled/in-progress)
                    sectionHeader(for: todaySection, isExpanded: $todaySection.isExpanded)
                        .id(todaySection.title)
                    if todaySection.isExpanded {
                        sectionContent(for: todaySection)
                    }

                    // Tomorrow section
                    sectionHeader(for: tomorrowSection, isExpanded: $tomorrowSection.isExpanded)
                        .id(tomorrowSection.title)
                    if tomorrowSection.isExpanded {
                        sectionContent(for: tomorrowSection)
                    }
                }
                .padding(.bottom, HomeLayout.bottomPadding(horizontalSizeClass))
            }
            .refreshable {
                loadTask?.cancel()
                await loadGames(scrollToToday: false)
            }
            .onReceive(NotificationCenter.default.publisher(for: .scrollToYesterday)) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(HomeStrings.sectionYesterday, anchor: .top)
                }
            }
        }
    }

    private var sectionsInOrder: [HomeSectionState] {
        [earlierSection, yesterdaySection, todaySection, tomorrowSection]
    }

    private var allCompletedGameIds: [Int] {
        sectionsInOrder.flatMap { $0.completedGames.map(\.id) }
    }

    // MARK: - Adaptive Layout

    var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 32 : HomeLayout.horizontalPadding
    }

    // MARK: - Refresh Button

    private func refreshButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "arrow.clockwise")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .padding(8)
                .background(
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Load Task Management

    /// Cancels any in-flight load and starts a new one. All callers should go through this.
    func startLoadGames(scrollToToday: Bool = true, priority: TaskPriority = .userInitiated) {
        loadTask?.cancel()
        loadTask = Task(priority: priority) {
            await loadGames(scrollToToday: scrollToToday)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(AppConfig.shared)
    .environmentObject(ReadStateStore.shared)
}
