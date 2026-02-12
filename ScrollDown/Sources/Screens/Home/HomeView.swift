import Combine
import SwiftUI
import UIKit

/// Main home screen displaying list of games
/// iPad: Wider layout with constrained content width for optimal readability
struct HomeView: View {
    @EnvironmentObject var appConfig: AppConfig
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
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

    // MARK: - Adaptive Layout

    var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 32 : HomeLayout.horizontalPadding
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(AppConfig.shared)
}
