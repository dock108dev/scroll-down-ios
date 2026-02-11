import Combine
import SwiftUI
import UIKit

/// Main home screen displaying list of games
/// iPad: Wider layout with constrained content width for optimal readability
struct HomeView: View {
    @EnvironmentObject var appConfig: AppConfig
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var earlierSection: HomeSectionState
    @State private var yesterdaySection: HomeSectionState
    @State private var todaySection: HomeSectionState
    @State private var tomorrowSection: HomeSectionState
    @State private var errorMessage: String?
    @State private var lastUpdatedAt: Date?
    @State private var selectedLeague: LeagueCode?
    @State private var showingAdminSettings = false // Beta admin access
    @State private var hasLoadedInitialData = false // Prevents reload on back navigation
    @State private var viewMode: HomeViewMode = .recaps
    @State private var refreshId = UUID()
    @StateObject private var oddsViewModel = OddsComparisonViewModel()
    @State private var selectedOddsLeague: FairBetLeague?
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
            await loadGames()
        }
        .sheet(isPresented: $showingAdminSettings, onDismiss: {
            // Reload data after admin settings changed (e.g., snapshot mode)
            Task {
                await loadGames(scrollToToday: false)
            }
        }) {
            AdminSettingsView()
                .environmentObject(appConfig)
        }
        .onReceive(refreshTimer) { _ in
            guard hasLoadedInitialData, viewMode == .recaps else { return }
            Task { await loadGames(scrollToToday: false) }
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
                    .padding(.vertical, HomeLayout.filterVerticalPadding)
                }
                .background(HomeTheme.background)
            } else if viewMode == .odds {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HomeLayout.filterSpacing) {
                        oddsLeagueFilterButton(nil, label: HomeStrings.allLeaguesLabel)
                        ForEach(FairBetLeague.allCases) { league in
                            oddsLeagueFilterButton(league, label: league.rawValue)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, HomeLayout.filterVerticalPadding)
                }
                .background(HomeTheme.background)
            }
        }
    }

    private func leagueFilterButton(_ league: LeagueCode?, label: String) -> some View {
        Button(action: {
            selectedLeague = league
            Task { await loadGames(scrollToToday: false) }
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

    private var dataFreshnessView: some View {
        HStack {
            Text(dataFreshnessText)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, HomeLayout.horizontalPadding)
        .padding(.bottom, HomeLayout.freshnessBottomPadding)
        .onLongPressGesture(minimumDuration: 2.0) {
            // Beta admin: long press to access admin settings
            #if DEBUG
            showingAdminSettings = true
            #endif
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
                Task { await loadGames() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(HomeLayout.statePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var gameListView: some View {
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
                .id(refreshId)
                .padding(.bottom, HomeLayout.bottomPadding(horizontalSizeClass))
            }
            .refreshable {
                await loadGames(scrollToToday: false)
            }
            .onAppear { refreshId = UUID() }
            .onReceive(NotificationCenter.default.publisher(for: .scrollToYesterday)) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(HomeStrings.sectionYesterday, anchor: .top)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(for section: HomeSectionState, isExpanded: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if section.title != HomeStrings.sectionEarlier {
                Divider()
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, HomeLayout.sectionDividerPadding)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Text(section.title.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color(.secondaryLabel))
                        .tracking(0.8)

                    if !isExpanded.wrappedValue && !section.isLoading && !section.games.isEmpty {
                        let readCount = section.readCount
                        Text(readCount > 0
                             ? "\(section.games.count) games \u{00B7} \(readCount) read"
                             : "\(section.games.count) games")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }

                    Spacer()

                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, HomeLayout.sectionHeaderTopPadding(horizontalSizeClass))
                .padding(.bottom, horizontalSizeClass == .regular ? 6 : 8) // iPad: tighter bottom padding
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func sectionContent(for section: HomeSectionState, completedOnly: Bool = false) -> some View {
        let gamesToShow = completedOnly ? section.completedGames : section.games

        if section.isLoading {
            // Minimal loading indicator - just a subtle spinner
            HStack {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            }
            .padding(.vertical, HomeLayout.sectionStatePadding(horizontalSizeClass))
        } else if let error = section.errorMessage {
            EmptySectionView(text: sectionErrorMessage(for: section, error: error))
                .padding(.horizontal, HomeLayout.horizontalPadding)
                .padding(.vertical, HomeLayout.sectionStatePadding(horizontalSizeClass))
                .transition(.opacity)
        } else if gamesToShow.isEmpty {
            EmptySectionView(text: sectionEmptyMessage(for: section))
                .padding(.horizontal, HomeLayout.horizontalPadding)
                .padding(.vertical, HomeLayout.sectionStatePadding(horizontalSizeClass))
                .transition(.opacity)
        } else {
            // iPad: 4 columns, iPhone: 2 columns
            let columnCount = horizontalSizeClass == .regular ? 4 : 2
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(gamesToShow) { game in
                    gameCard(for: game)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .transition(.opacity.animation(.easeIn(duration: 0.2)))
        }
    }

    /// Game card with conditional navigation based on flow availability
    @ViewBuilder
    private func gameCard(for game: GameSummary) -> some View {
        let rowView = GameRowView(game: game)

        if rowView.cardState.isTappable {
            // Flow available - enable navigation
            NavigationLink(value: AppRoute.game(id: game.id, league: game.league)) {
                rowView
            }
            .buttonStyle(CardPressButtonStyle())
            .simultaneousGesture(TapGesture().onEnded {
                GameRoutingLogger.logTap(gameId: game.id, league: game.league)
                triggerHapticIfNeeded(for: game)
            })
        } else {
            // Flow pending or upcoming - no navigation, static card
            rowView
                .allowsHitTesting(false)
        }
    }


    // MARK: - Data Loading

    private func loadGames(scrollToToday: Bool = true) async {
        errorMessage = nil
        earlierSection.errorMessage = nil
        yesterdaySection.errorMessage = nil
        todaySection.errorMessage = nil
        tomorrowSection.errorMessage = nil

        // 1. Load cached data first (instant UI, no spinners)
        let cache = HomeGameCache.shared
        let hasCachedData = loadCachedSections(from: cache)

        // 2. Only show loading spinners if no cached data exists
        if !hasCachedData {
            earlierSection.isLoading = true
            yesterdaySection.isLoading = true
            todaySection.isLoading = true
            tomorrowSection.isLoading = true
        }

        // 3. Fetch fresh data from network
        let service = appConfig.gameService

        async let earlierResult = loadSection(range: .earlier, service: service)
        async let yesterdayResult = loadSection(range: .yesterday, service: service)
        async let todayResult = loadSection(range: .current, service: service)
        async let tomorrowResult = loadSection(range: .tomorrow, service: service)

        let results = await [earlierResult, yesterdayResult, todayResult, tomorrowResult]

        // 4. Silent swap — apply results + save to cache
        applyHomeSectionResults(results)
        updateLastUpdatedAt(from: results)
        saveSectionsToCache(results, cache: cache)

        // 5. Only show global error if ALL sections failed AND no data to display
        let hasAnyData = !earlierSection.games.isEmpty || !yesterdaySection.games.isEmpty
            || !todaySection.games.isEmpty || !tomorrowSection.games.isEmpty
        if results.allSatisfy({ $0.errorMessage != nil }) && !hasAnyData {
            errorMessage = HomeStrings.globalErrorMessage
        }

        if scrollToToday {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(name: .scrollToYesterday, object: nil)
            }
        }
    }

    private func loadSection(range: GameRange, service: GameService) async -> HomeSectionResult {
        do {
            let response = try await service.fetchGames(range: range, league: selectedLeague)

            // Beta Admin: Apply snapshot mode filtering if active
            // This excludes live/in-progress games to ensure deterministic replay
            let filteredGames = appConfig.filterGamesForSnapshotMode(response.games)
            
            return HomeSectionResult(range: range, games: filteredGames, lastUpdatedAt: response.lastUpdatedAt, errorMessage: nil)
        } catch {
            return HomeSectionResult(range: range, games: [], lastUpdatedAt: nil, errorMessage: error.localizedDescription)
        }
    }

    private func applyHomeSectionResults(_ results: [HomeSectionResult]) {
        for result in results {
            // Sort games by date (chronologically) within each section
            let sortedGames = result.games.sorted { lhs, rhs in
                guard let lhsDate = lhs.parsedGameDate,
                      let rhsDate = rhs.parsedGameDate else {
                    return false
                }
                return lhsDate < rhsDate
            }

            switch result.range {
            case .earlier:
                if result.errorMessage == nil {
                    earlierSection.games = sortedGames.reversed()
                }
                earlierSection.errorMessage = earlierSection.games.isEmpty ? result.errorMessage : nil
                earlierSection.isLoading = false
            case .yesterday:
                if result.errorMessage == nil {
                    yesterdaySection.games = sortedGames
                }
                yesterdaySection.errorMessage = yesterdaySection.games.isEmpty ? result.errorMessage : nil
                yesterdaySection.isLoading = false
            case .current:
                if result.errorMessage == nil {
                    todaySection.games = sortedGames
                }
                todaySection.errorMessage = todaySection.games.isEmpty ? result.errorMessage : nil
                todaySection.isLoading = false
            case .tomorrow:
                if result.errorMessage == nil {
                    tomorrowSection.games = sortedGames
                }
                tomorrowSection.errorMessage = tomorrowSection.games.isEmpty ? result.errorMessage : nil
                tomorrowSection.isLoading = false
            case .next24:
                break
            }
        }
    }

    private func updateLastUpdatedAt(from results: [HomeSectionResult]) {
        let dates = results.compactMap { parseLastUpdatedAt($0.lastUpdatedAt) }
        lastUpdatedAt = dates.max()
    }

    private func parseLastUpdatedAt(_ value: String?) -> Date? {
        guard let value else { return nil }
        if let date = homeDateFormatterWithFractional.date(from: value) {
            return date
        }
        return homeDateFormatter.date(from: value)
    }

    /// Load cached sections. Returns true if at least one section had cached data.
    private func loadCachedSections(from cache: HomeGameCache) -> Bool {
        var hasCachedData = false

        if let cached = cache.load(range: .earlier, league: selectedLeague) {
            earlierSection.games = cached.games
            earlierSection.isLoading = false
            hasCachedData = true
        }
        if let cached = cache.load(range: .yesterday, league: selectedLeague) {
            yesterdaySection.games = cached.games
            yesterdaySection.isLoading = false
            hasCachedData = true
        }
        if let cached = cache.load(range: .current, league: selectedLeague) {
            todaySection.games = cached.games
            todaySection.isLoading = false
            hasCachedData = true
        }
        if let cached = cache.load(range: .tomorrow, league: selectedLeague) {
            tomorrowSection.games = cached.games
            tomorrowSection.isLoading = false
            hasCachedData = true
        }

        return hasCachedData
    }

    /// Save successful results to disk cache.
    private func saveSectionsToCache(_ results: [HomeSectionResult], cache: HomeGameCache) {
        for result in results where result.errorMessage == nil {
            cache.save(games: result.games, lastUpdatedAt: result.lastUpdatedAt,
                       range: result.range, league: selectedLeague)
        }
    }

    private var dataFreshnessText: String {
        guard let lastUpdatedAt else {
            return HomeStrings.updateUnavailable
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relative = formatter.localizedString(for: lastUpdatedAt, relativeTo: Date())
        return String(format: HomeStrings.updatedTemplate, relative)
    }

    private var sectionsInOrder: [HomeSectionState] {
        [earlierSection, yesterdaySection, todaySection, tomorrowSection]
    }

    private var allCompletedGameIds: [Int] {
        sectionsInOrder.flatMap { $0.completedGames.map(\.id) }
    }

    private func sectionEmptyMessage(for section: HomeSectionState) -> String {
        switch section.range {
        case .earlier:
            return HomeStrings.earlierEmpty
        case .yesterday:
            return HomeStrings.yesterdayEmpty
        case .current:
            return HomeStrings.todayEmpty
        case .tomorrow:
            return HomeStrings.tomorrowEmpty
        case .next24:
            return HomeStrings.upcomingEmpty
        }
    }

    private func sectionErrorMessage(for section: HomeSectionState, error: String) -> String {
        switch section.range {
        case .earlier:
            return String(format: HomeStrings.earlierError, error)
        case .yesterday:
            return String(format: HomeStrings.yesterdayError, error)
        case .current:
            return String(format: HomeStrings.todayError, error)
        case .tomorrow:
            return String(format: HomeStrings.tomorrowError, error)
        case .next24:
            return String(format: HomeStrings.upcomingError, error)
        }
    }

    // MARK: - Feedback

    private func triggerHapticIfNeeded(for game: GameSummary) {
        guard game.status?.isCompleted == true else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    // MARK: - Adaptive Layout

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 32 : HomeLayout.horizontalPadding
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(AppConfig.shared)
}
