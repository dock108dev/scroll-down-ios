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
    @State private var selectedMarketFilter: MarketFilter?
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
                        ForEach(LeagueCode.allCases.filter { leaguesWithGames.contains($0.rawValue) }, id: \.self) { league in
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
                        HStack(spacing: 8) {
                            // iPad: catch-up + reset in filter bar; iPhone: in action row below
                            if horizontalSizeClass == .regular && showSpoilerActions && uncaughtUpCount > 0 {
                                Button(action: catchUpToLive) {
                                    Image(systemName: "eye")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(HomeTheme.accentColor)
                                        .padding(8)
                                        .background(
                                            Circle()
                                                .stroke(HomeTheme.accentColor.opacity(0.4), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            if horizontalSizeClass == .regular && showSpoilerActions && caughtUpCount > 0 {
                                Button(action: resetAllReadState) {
                                    Image(systemName: "eye.slash")
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
                            // iPad: always show refresh here; iPhone: only when no action row
                            if horizontalSizeClass == .regular || !showSpoilerActions {
                                refreshButton {
                                    startLoadGames(scrollToToday: false)
                                }
                            }
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
                FairBetHeaderView(
                    viewModel: oddsViewModel,
                    selectedLeague: $selectedOddsLeague,
                    selectedMarket: $selectedMarketFilter,
                    horizontalPadding: horizontalPadding
                )
            }
        }
    }

    private func leagueFilterButton(_ league: LeagueCode?, label: String) -> some View {
        Button(action: {
            selectedLeague = league
            let cache = HomeGameCache.shared
            // If no cache exists for this league, clear sections to show loading spinners
            let hasCache = cache.isSameCalendarDay(range: .current, league: league)
                || cache.isSameCalendarDay(range: .yesterday, league: league)
            if !hasCache {
                earlierSection.games = []
                earlierSection.isLoading = true
                yesterdaySection.games = []
                yesterdaySection.isLoading = true
                todaySection.games = []
                todaySection.isLoading = true
                tomorrowSection.games = []
                tomorrowSection.isLoading = true
            } else {
                let _ = loadCachedSections(from: cache)
            }
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

    private var contentView: some View {
        ZStack {
            if viewMode == .recaps {
                if let error = errorMessage {
                    errorView(error)
                } else {
                    gameListView
                }
            }
            OddsComparisonView(viewModel: oddsViewModel)
                .opacity(viewMode == .odds ? 1 : 0)
                .allowsHitTesting(viewMode == .odds)
            if viewMode == .settings {
                SettingsView(oddsViewModel: oddsViewModel)
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
                    // Spoiler-free action bar (iPhone only — iPad has these in the filter bar)
                    if horizontalSizeClass != .regular && showSpoilerActions {
                        HStack(spacing: 8) {
                            if uncaughtUpCount > 0 {
                                Button(action: catchUpToLive) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "eye")
                                            .font(.caption2.weight(.semibold))
                                        Text("Catch up")
                                            .font(.caption.weight(.medium))
                                        Text("\(uncaughtUpCount)")
                                            .font(.caption2.weight(.bold).monospacedDigit())
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Color.white.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(HomeTheme.accentColor.opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }

                            if caughtUpCount > 0 {
                                Button(action: resetAllReadState) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "eye.slash")
                                            .font(.caption2.weight(.semibold))
                                        Text("Reset")
                                            .font(.caption.weight(.medium))
                                        Text("\(caughtUpCount)")
                                            .font(.caption2.weight(.bold).monospacedDigit())
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Color(.systemGray4))
                                            .clipShape(Capsule())
                                    }
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            // iPhone only: refresh button in this row
                            if horizontalSizeClass != .regular {
                                refreshButton {
                                    startLoadGames(scrollToToday: false)
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

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

    /// All games across sections (for catch-up)
    private var allGames: [GameSummary] {
        sectionsInOrder.flatMap(\.games)
    }

    /// Leagues that have at least one game in the loaded sections
    private var leaguesWithGames: Set<String> {
        Set(allGames.map(\.leagueCode))
    }

    /// Number of games the user hasn't caught up on yet (unread finals + unrevealed live)
    private var uncaughtUpCount: Int {
        allGames.filter { game in
            if game.status?.isFinal == true {
                return !readStateStore.isRead(gameId: game.id)
            }
            if game.status?.isLive == true {
                return ReadingPositionStore.shared.savedScores(for: game.id) == nil
            }
            return false
        }.count
    }

    /// Number of games that have been caught up on (read finals + revealed live)
    private var caughtUpCount: Int {
        allGames.filter { game in
            if game.status?.isFinal == true {
                return readStateStore.isRead(gameId: game.id)
            }
            if game.status?.isLive == true {
                return ReadingPositionStore.shared.savedScores(for: game.id) != nil
            }
            return false
        }.count
    }

    /// Whether the spoiler-free action bar should show at all
    private var showSpoilerActions: Bool {
        readStateStore.scoreRevealMode == .onMarkRead && (uncaughtUpCount > 0 || caughtUpCount > 0)
    }

    /// Catch up to live: mark all finals as read + reveal all live scores
    private func catchUpToLive() {
        readStateStore.markAllRead(gameIds: allCompletedGameIds)
        for game in allGames where game.status?.isLive == true {
            if let away = game.awayScore, let home = game.homeScore {
                ReadingPositionStore.shared.updateScores(for: game.id, awayScore: away, homeScore: home)
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Reset all: mark everything unread + clear saved scores
    private func resetAllReadState() {
        let allIds = allGames.map(\.id)
        readStateStore.markAllUnread(gameIds: allIds)
        for id in allIds {
            ReadingPositionStore.shared.clear(gameId: id)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
