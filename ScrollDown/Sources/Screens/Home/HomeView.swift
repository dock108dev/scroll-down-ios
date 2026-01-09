import SwiftUI
import UIKit

/// Main home screen displaying list of games
struct HomeView: View {
    @EnvironmentObject var appConfig: AppConfig
    @State private var games: [GameSummary] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedLeague: LeagueCode?
    
    var body: some View {
        ZStack {
            HomeTheme.background
                .ignoresSafeArea()
            VStack(spacing: 0) {
                headerView
                contentView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                    Text(Strings.navigationTitle)
                        .font(.headline)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                dataModeIndicator
            }
        }
        .task {
            await loadGames()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.filterSpacing) {
                leagueFilterButton(nil, label: Strings.allLeaguesLabel)
                ForEach(LeagueCode.allCases, id: \.self) { league in
                    leagueFilterButton(league, label: league.rawValue)
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.filterVerticalPadding)
        }
        .background(HomeTheme.background)
    }
    
    private func leagueFilterButton(_ league: LeagueCode?, label: String) -> some View {
        Button(action: {
            selectedLeague = league
            Task { await loadGames(scrollToToday: false) }
        }) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, Layout.filterHorizontalPadding)
                .padding(.vertical, Layout.filterVerticalPadding)
                .background(selectedLeague == league ? HomeTheme.accentColor : Color(.systemGray5))
                .foregroundColor(selectedLeague == league ? .white : .primary)
                .clipShape(Capsule())
        }
    }
    
    private var contentView: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if games.isEmpty {
                emptyView
            } else {
                gameListView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: Layout.stateSpacing) {
            ProgressView()
                .scaleEffect(Layout.progressScale)
            Text(Strings.loadingTitle)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: Layout.stateSpacing) {
            Image(systemName: Strings.errorIconName)
                .font(.system(size: Layout.errorIconSize))
                .foregroundColor(.orange)
            Text(Strings.errorTitle)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(Strings.retryLabel) {
                Task { await loadGames() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Layout.statePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: Layout.stateSpacing) {
            Image(systemName: Strings.emptyIconName)
                .font(.system(size: Layout.emptyIconSize))
                .foregroundColor(.secondary)
            Text(Strings.emptyTitle)
                .font(.headline)
            Text(Strings.emptySubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var gameListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Layout.cardSpacing) {
                    ForEach(sectionedGames) { section in
                        // Section header with ID for scrolling
                        sectionHeader(for: section)
                            .id(section.title)
                        
                        if section.games.isEmpty && section.title == Strings.sectionToday {
                            Text("No games scheduled for today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, Layout.horizontalPadding)
                                .padding(.vertical, Layout.emptyStatePadding)
                        } else {
                            ForEach(section.games) { game in
                                NavigationLink(value: AppRoute.game(id: game.id, league: game.leagueCode)) {
                                    // Trust the backend-provided game.id for routing; never derive IDs locally.
                                    GameRowView(game: game)
                                }
                                .buttonStyle(CardPressButtonStyle())
                                .padding(.horizontal, Layout.horizontalPadding)
                                .simultaneousGesture(TapGesture().onEnded {
                                    GameRoutingLogger.logTap(gameId: game.id, league: game.leagueCode)
                                    triggerHapticIfNeeded(for: game)
                                })
                            }
                        }
                    }
                }
                .padding(.bottom, Layout.bottomPadding)
            }
            .onReceive(NotificationCenter.default.publisher(for: .scrollToToday)) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(Strings.sectionToday, anchor: .top)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sectionHeader(for section: GameListSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if section.title != Strings.sectionEarlier {
                Divider()
                    .padding(.horizontal, Layout.horizontalPadding)
                    .padding(.bottom, Layout.sectionDividerPadding)
            }
            
            Text(section.title)
                .font(.title3.weight(.bold))
                .foregroundColor(.primary)
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, Layout.sectionHeaderTopPadding)
        }
    }
    
    private var dataModeIndicator: some View {
        HStack(spacing: Layout.dataModeSpacing) {
            Circle()
                .fill(appConfig.dataMode == .mock ? Color.orange : HomeTheme.accentColor)
                .frame(width: Layout.dataModeIndicatorSize, height: Layout.dataModeIndicatorSize)
            Text(appConfig.dataMode == .mock ? Strings.mockLabel : Strings.liveLabel)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadGames(scrollToToday: Bool = true) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let service = appConfig.gameService
            let response = try await service.fetchGames(
                league: selectedLeague,
                limit: Layout.requestLimit,
                offset: Layout.requestOffset
            )
            games = response.games
            isLoading = false
            
            // Trigger scroll to today after data is loaded
            if scrollToToday {
                // Delay to ensure views are rendered
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NotificationCenter.default.post(name: .scrollToToday, object: nil)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Sectioning
    
    private var sectionedGames: [GameListSection] {
        let calendar = Calendar.current
        let todayStart = AppDate.startOfToday
        let todayEnd = AppDate.endOfToday
        let historyStart = AppDate.historyWindowStart
        
        var earlier: [GameSummary] = []
        var todayGames: [GameSummary] = []
        var upcoming: [GameSummary] = []
        
        for game in games {
            guard let gameDate = game.parsedGameDate else {
                continue // Skip games without valid dates
            }
            
            // Exclude games older than history window (2 days ago)
            if gameDate < historyStart {
                continue
            }
            
            if gameDate < todayStart {
                earlier.append(game)
            } else if gameDate <= todayEnd {
                todayGames.append(game)
            } else {
                upcoming.append(game)
            }
        }
        
        // Sort each bucket
        earlier.sort { ($0.parsedGameDate ?? .distantPast) > ($1.parsedGameDate ?? .distantPast) } // desc (newest first)
        todayGames.sort { ($0.parsedGameDate ?? .distantPast) < ($1.parsedGameDate ?? .distantPast) } // asc
        upcoming.sort { ($0.parsedGameDate ?? .distantFuture) < ($1.parsedGameDate ?? .distantFuture) } // asc
        
        // Build sections in order: Earlier → Today → Upcoming
        var sections: [GameListSection] = []
        
        if !earlier.isEmpty {
            sections.append(GameListSection(title: Strings.sectionEarlier, games: earlier))
        }
        
        // Always show Today section (even if empty, for anchor)
        sections.append(GameListSection(title: Strings.sectionToday, games: todayGames))
        
        if !upcoming.isEmpty {
            sections.append(GameListSection(title: Strings.sectionUpcoming, games: upcoming))
        }
        
        return sections
    }
    
    // MARK: - Feedback
    
    private func triggerHapticIfNeeded(for game: GameSummary) {
        guard game.inferredStatus == .completed else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}

private struct GameListSection: Identifiable {
    let id = UUID()
    let title: String
    let games: [GameSummary]
}

private enum Layout {
    static let horizontalPadding: CGFloat = 16
    static let filterSpacing: CGFloat = 12
    static let filterHorizontalPadding: CGFloat = 16
    static let filterVerticalPadding: CGFloat = 8
    static let stateSpacing: CGFloat = 16
    static let statePadding: CGFloat = 24
    static let errorIconSize: CGFloat = 48
    static let emptyIconSize: CGFloat = 48
    static let progressScale: CGFloat = 1.5
    static let cardSpacing: CGFloat = 12
    static let sectionHeaderTopPadding: CGFloat = 12
    static let sectionDividerPadding: CGFloat = 8
    static let emptyStatePadding: CGFloat = 24
    static let bottomPadding: CGFloat = 32
    static let dataModeSpacing: CGFloat = 4
    static let dataModeIndicatorSize: CGFloat = 8
    static let requestLimit = 50
    static let requestOffset = 0
}

/// Button style with subtle press animation for cards
private struct CardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

private enum Strings {
    static let navigationTitle = "Scroll Down Sports"
    static let allLeaguesLabel = "All"
    static let loadingTitle = "Loading games..."
    static let errorIconName = "exclamationmark.triangle"
    static let errorTitle = "Error"
    static let retryLabel = "Retry"
    static let emptyIconName = "sportscourt"
    static let emptyTitle = "No Games"
    static let emptySubtitle = "No games found for the selected filters"
    static let mockLabel = "Mock"
    static let liveLabel = "Live"
    static let sectionEarlier = "Earlier"
    static let sectionToday = "Today"
    static let sectionUpcoming = "Upcoming"
}

// MARK: - Notification Names

extension Notification.Name {
    static let scrollToToday = Notification.Name("scrollToToday")
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(AppConfig.shared)
}
