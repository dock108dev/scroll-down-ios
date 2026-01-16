import SwiftUI
import UIKit

/// Main home screen displaying list of games
struct HomeView: View {
    @EnvironmentObject var appConfig: AppConfig
    @State private var earlierSection = HomeSectionState(range: .earlier, title: Strings.sectionEarlier, isExpanded: false)
    @State private var yesterdaySection = HomeSectionState(range: .yesterday, title: Strings.sectionYesterday, isExpanded: true)
    @State private var todaySection = HomeSectionState(range: .current, title: Strings.sectionToday, isExpanded: true)
    @State private var upcomingSection = HomeSectionState(range: .next24, title: Strings.sectionUpcoming, isExpanded: false)
    @State private var errorMessage: String?
    @State private var lastUpdatedAt: Date?
    @State private var selectedLeague: LeagueCode?
    @State private var showingAdminSettings = false // Beta admin access

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
        .sheet(isPresented: $showingAdminSettings, onDismiss: {
            // Reload data after admin settings changed (e.g., snapshot mode)
            Task {
                await loadGames(scrollToToday: false)
            }
        }) {
            AdminSettingsView()
                .environmentObject(appConfig)
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
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, 8)
            }
            #endif
            
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

            dataFreshnessView
        }
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

    private var dataFreshnessView: some View {
        HStack {
            Text(dataFreshnessText)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.bottom, Layout.freshnessBottomPadding)
        .onLongPressGesture(minimumDuration: 2.0) {
            // Beta admin: long press to access admin settings
            #if DEBUG
            showingAdminSettings = true
            #endif
        }
    }

    private var contentView: some View {
        Group {
            if let error = errorMessage {
                errorView(error)
            } else {
                gameListView
            }
        }
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

    private var gameListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Layout.cardSpacing) {
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
                    
                    // Today section
                    sectionHeader(for: todaySection, isExpanded: $todaySection.isExpanded)
                        .id(todaySection.title)
                    if todaySection.isExpanded {
                        sectionContent(for: todaySection)
                    }
                    
                    // Upcoming section
                    sectionHeader(for: upcomingSection, isExpanded: $upcomingSection.isExpanded)
                        .id(upcomingSection.title)
                    if upcomingSection.isExpanded {
                        sectionContent(for: upcomingSection)
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
    private func sectionHeader(for section: HomeSectionState, isExpanded: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if section.title != Strings.sectionEarlier {
                Divider()
                    .padding(.horizontal, Layout.horizontalPadding)
                    .padding(.bottom, Layout.sectionDividerPadding)
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
                    
                    Spacer()
                    
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, Layout.sectionHeaderTopPadding)
                .padding(.bottom, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func sectionContent(for section: HomeSectionState) -> some View {
        if section.isLoading {
            // Minimal loading indicator - just a subtle spinner
            HStack {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            }
            .padding(.vertical, Layout.sectionStatePadding)
        } else if let error = section.errorMessage {
            EmptySectionView(
                text: sectionErrorMessage(for: section, error: error),
                icon: "exclamationmark.triangle"
            )
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.sectionStatePadding)
            .transition(.opacity)
        } else if section.games.isEmpty {
            EmptySectionView(
                text: sectionEmptyMessage(for: section),
                icon: sectionEmptyIcon(for: section)
            )
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.sectionStatePadding)
            .transition(.opacity)
        } else {
            ForEach(section.games) { game in
                NavigationLink(value: AppRoute.game(id: game.id, league: game.league)) {
                    GameRowView(game: game)
                }
                .buttonStyle(CardPressButtonStyle())
                .padding(.horizontal, Layout.horizontalPadding)
                .simultaneousGesture(TapGesture().onEnded {
                    GameRoutingLogger.logTap(gameId: game.id, league: game.league)
                    triggerHapticIfNeeded(for: game)
                })
            }
            .transition(.opacity.animation(.easeIn(duration: 0.2)))
        }
    }

    private var dataModeIndicator: some View {
        HStack(spacing: Layout.dataModeSpacing) {
            Circle()
                .fill(appConfig.environment == .mock ? Color.orange : HomeTheme.accentColor)
                .frame(width: Layout.dataModeIndicatorSize, height: Layout.dataModeIndicatorSize)
            Text(appConfig.environment == .mock ? Strings.mockLabel : Strings.liveLabel)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Data Loading

    private func loadGames(scrollToToday: Bool = true) async {
        errorMessage = nil

        earlierSection.isLoading = true
        yesterdaySection.isLoading = true
        todaySection.isLoading = true
        upcomingSection.isLoading = true
        earlierSection.errorMessage = nil
        yesterdaySection.errorMessage = nil
        todaySection.errorMessage = nil
        upcomingSection.errorMessage = nil

        let service = appConfig.gameService

        async let earlierResult = loadSection(range: .earlier, service: service)
        async let yesterdayResult = loadSection(range: .yesterday, service: service)
        async let todayResult = loadSection(range: .current, service: service)
        async let upcomingResult = loadSection(range: .next24, service: service)

        let results = await [earlierResult, yesterdayResult, todayResult, upcomingResult]

        applySectionResults(results)
        updateLastUpdatedAt(from: results)

        if results.allSatisfy({ $0.errorMessage != nil }) {
            errorMessage = Strings.globalErrorMessage
        }

        if scrollToToday {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(name: .scrollToToday, object: nil)
            }
        }
    }

    private func loadSection(range: GameRange, service: GameService) async -> SectionResult {
        do {
            let response = try await service.fetchGames(range: range, league: selectedLeague)
            
            // #region agent log
            DebugLogger.log(hypothesisId: "E", location: "HomeView.swift:286", message: "📥 Games received for section", data: ["range": range.rawValue, "count": response.games.count, "firstGameId": response.games.first?.id as Any])
            // #endregion

            // Beta Admin: Apply snapshot mode filtering if active
            // This excludes live/in-progress games to ensure deterministic replay
            let filteredGames = appConfig.filterGamesForSnapshotMode(response.games)
            
            return SectionResult(range: range, games: filteredGames, lastUpdatedAt: response.lastUpdatedAt, errorMessage: nil)
        } catch {
            // #region agent log
            DebugLogger.log(hypothesisId: "E", location: "HomeView.swift:294", message: "❌ Section load failed", data: ["range": range.rawValue, "error": error.localizedDescription])
            // #endregion
            return SectionResult(range: range, games: [], lastUpdatedAt: nil, errorMessage: error.localizedDescription)
        }
    }

    private func applySectionResults(_ results: [SectionResult]) {
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
                earlierSection.games = sortedGames
                earlierSection.errorMessage = result.errorMessage
                earlierSection.isLoading = false
            case .yesterday:
                yesterdaySection.games = sortedGames
                yesterdaySection.errorMessage = result.errorMessage
                yesterdaySection.isLoading = false
            case .current:
                todaySection.games = sortedGames
                todaySection.errorMessage = result.errorMessage
                todaySection.isLoading = false
            case .next24:
                upcomingSection.games = sortedGames
                upcomingSection.errorMessage = result.errorMessage
                upcomingSection.isLoading = false
            }
        }
    }

    private func updateLastUpdatedAt(from results: [SectionResult]) {
        let dates = results.compactMap { parseLastUpdatedAt($0.lastUpdatedAt) }
        lastUpdatedAt = dates.max()
    }

    private func parseLastUpdatedAt(_ value: String?) -> Date? {
        guard let value else { return nil }
        if let date = dateFormatterWithFractional.date(from: value) {
            return date
        }
        return dateFormatter.date(from: value)
    }

    private var dataFreshnessText: String {
        guard let lastUpdatedAt else {
            return Strings.updateUnavailable
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relative = formatter.localizedString(for: lastUpdatedAt, relativeTo: Date())
        return String(format: Strings.updatedTemplate, relative)
    }

    private var sectionsInOrder: [HomeSectionState] {
        [earlierSection, yesterdaySection, todaySection, upcomingSection]
    }

    private func sectionEmptyMessage(for section: HomeSectionState) -> String {
        switch section.range {
        case .earlier:
            return Strings.earlierEmpty
        case .yesterday:
            return Strings.yesterdayEmpty
        case .current:
            return Strings.todayEmpty
        case .next24:
            return Strings.upcomingEmpty
        }
    }
    
    /// Phase F: Contextual icons for empty states
    private func sectionEmptyIcon(for section: HomeSectionState) -> String {
        switch section.range {
        case .earlier:
            return "clock.arrow.circlepath"
        case .yesterday:
            return "clock.arrow.circlepath"
        case .current:
            return "calendar"
        case .next24:
            return "clock"
        }
    }

    private func sectionErrorMessage(for section: HomeSectionState, error: String) -> String {
        switch section.range {
        case .earlier:
            return String(format: Strings.earlierError, error)
        case .yesterday:
            return String(format: Strings.yesterdayError, error)
        case .current:
            return String(format: Strings.todayError, error)
        case .next24:
            return String(format: Strings.upcomingError, error)
        }
    }

    // MARK: - Feedback

    private func triggerHapticIfNeeded(for game: GameSummary) {
        guard game.status?.isCompleted == true else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}

private struct HomeSectionState: Identifiable {
    let id = UUID()
    let range: GameRange
    let title: String
    var games: [GameSummary] = []
    var isLoading = true
    var errorMessage: String?
    var isExpanded: Bool
    
    init(range: GameRange, title: String, isExpanded: Bool = true) {
        self.range = range
        self.title = title
        self.isExpanded = isExpanded
    }
}

private struct SectionResult {
    let range: GameRange
    let games: [GameSummary]
    let lastUpdatedAt: String?
    let errorMessage: String?
}

private enum Layout {
    static let horizontalPadding: CGFloat = 16
    static let filterSpacing: CGFloat = 12
    static let filterHorizontalPadding: CGFloat = 16
    static let filterVerticalPadding: CGFloat = 8
    static let stateSpacing: CGFloat = 16
    static let statePadding: CGFloat = 24
    static let errorIconSize: CGFloat = 48
    static let cardSpacing: CGFloat = 12
    static let sectionHeaderTopPadding: CGFloat = 12
    static let sectionDividerPadding: CGFloat = 8
    static let sectionStatePadding: CGFloat = 12
    static let skeletonSpacing: CGFloat = 12 // Phase F: Skeleton placeholder spacing
    static let bottomPadding: CGFloat = 32
    static let dataModeSpacing: CGFloat = 4
    static let dataModeIndicatorSize: CGFloat = 8
    static let freshnessBottomPadding: CGFloat = 8
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
    static let errorIconName = "exclamationmark.triangle"
    static let errorTitle = "Error"
    static let retryLabel = "Retry"
    static let mockLabel = "Mock"
    static let liveLabel = "Live"
    static let sectionEarlier = "Earlier"
    static let sectionYesterday = "Yesterday"
    static let sectionToday = "Today"
    static let sectionUpcoming = "Coming Up"
    static let sectionLoading = "Loading section..."
    static let earlierEmpty = "No games from earlier."
    static let yesterdayEmpty = "No games from yesterday."
    static let todayEmpty = "No games scheduled for today."
    static let upcomingEmpty = "No games scheduled in the next 24 hours."
    static let updatedTemplate = "Updated %@"
    static let updateUnavailable = "Update time unavailable"
    static let globalErrorMessage = "We couldn't reach the latest game feeds."
    static let earlierError = "Earlier games unavailable. %@"
    static let yesterdayError = "Yesterday's games unavailable. %@"
    static let todayError = "Today's games unavailable. %@"
    static let upcomingError = "Coming up games unavailable. %@"
}

private let dateFormatterWithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

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
