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
                introHeaderView
                headerView
                contentView
            }
        }
        .navigationTitle(Strings.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                dataModeIndicator
            }
        }
        .task {
            await loadGames()
        }
    }
    
    // MARK: - Subviews
    
    private var introHeaderView: some View {
        VStack(alignment: .leading, spacing: Layout.introSpacing) {
            Text(Strings.introTitle)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            Text(Strings.introSubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.top, Layout.introTopPadding)
        .padding(.bottom, Layout.introBottomPadding)
    }
    
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
            Task { await loadGames() }
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
        List {
            ForEach(sectionedGames) { section in
                Section {
                    ForEach(section.games) { game in
                        NavigationLink(value: game) {
                            GameRowView(game: game)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            triggerHapticIfNeeded(for: game)
                        })
                        .listRowInsets(EdgeInsets(
                            top: Layout.listRowVerticalPadding,
                            leading: Layout.horizontalPadding,
                            bottom: Layout.listRowVerticalPadding,
                            trailing: Layout.horizontalPadding
                        ))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                } header: {
                    Text(section.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                        .textCase(nil)
                        .padding(.horizontal, Layout.horizontalPadding)
                        .padding(.top, Layout.sectionHeaderTopPadding)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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
    
    private func loadGames() async {
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
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Sectioning
    
    private var sectionedGames: [GameListSection] {
        var buckets: [String: [GameSummary]] = [:]
        for game in games {
            let title = sectionTitle(for: game)
            buckets[title, default: []].append(game)
        }
        return Strings.sectionOrder.compactMap { title in
            guard let games = buckets[title], !games.isEmpty else { return nil }
            return GameListSection(title: title, games: games)
        }
    }
    
    private func sectionTitle(for game: GameSummary) -> String {
        guard let date = game.parsedGameDate else { return Strings.sectionEarlier }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return Strings.sectionToday
        }
        if calendar.isDateInYesterday(date) {
            return Strings.sectionYesterday
        }
        return Strings.sectionEarlier
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
    static let introSpacing: CGFloat = 4
    static let introTopPadding: CGFloat = 12
    static let introBottomPadding: CGFloat = 8
    static let filterSpacing: CGFloat = 12
    static let filterHorizontalPadding: CGFloat = 16
    static let filterVerticalPadding: CGFloat = 8
    static let stateSpacing: CGFloat = 16
    static let statePadding: CGFloat = 24
    static let errorIconSize: CGFloat = 48
    static let emptyIconSize: CGFloat = 48
    static let progressScale: CGFloat = 1.5
    static let listRowVerticalPadding: CGFloat = 6
    static let sectionHeaderTopPadding: CGFloat = 8
    static let dataModeSpacing: CGFloat = 4
    static let dataModeIndicatorSize: CGFloat = 8
    static let requestLimit = 50
    static let requestOffset = 0
}

private enum Strings {
    static let navigationTitle = "Scroll Down Sports"
    static let introTitle = "Scroll Down Sports"
    static let introSubtitle = "Catch up — without spoilers."
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
    static let sectionToday = "Today"
    static let sectionYesterday = "Yesterday"
    static let sectionEarlier = "Earlier"
    static let sectionOrder = [sectionToday, sectionYesterday, sectionEarlier]
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(AppConfig.shared)
}
