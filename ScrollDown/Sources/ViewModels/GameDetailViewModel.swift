import Foundation
import OSLog

/// ViewModel for GameDetailView - manages game data, timeline, and progressive disclosure state.
@MainActor
final class GameDetailViewModel: ObservableObject {
    /// Summary state derived from timeline artifact
    enum SummaryState: Equatable {
        case unavailable
        case available(String)
    }

    @Published private(set) var detail: GameDetailResponse?
    @Published var isLoading: Bool
    @Published var errorMessage: String?
    @Published private(set) var isUnavailable: Bool = false

    // Outcome is always hidden per progressive disclosure principles
    var isOutcomeRevealed: Bool { false }

    // Social posts
    @Published private(set) var socialPosts: [SocialPostResponse] = []
    @Published private(set) var socialPostsState: SocialPostsState = .idle
    @Published var isSocialTabEnabled: Bool = false

    // Timeline artifact
    @Published private(set) var timelineArtifact: TimelineArtifactResponse?
    @Published private(set) var timelineArtifactState: TimelineArtifactState = .idle

    // Story state
    @Published private(set) var storyState: StoryState = .idle
    @Published private(set) var storyResponse: GameStoryResponse?
    @Published private(set) var momentDisplayModels: [MomentDisplayModel] = []
    @Published private(set) var storyPlays: [StoryPlay] = []

    enum StoryState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum SocialPostsState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum TimelineArtifactState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum PbpState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // PBP data (fetched separately when not included in main detail)
    @Published private(set) var pbpEvents: [PbpEvent] = []
    @Published private(set) var pbpState: PbpState = .idle

    struct TimelineArtifactSummary: Equatable {
        let eventCount: Int
        let firstTimestamp: String?
        let lastTimestamp: String?
    }

    private let logger = Logger(subsystem: "com.scrolldown.app", category: "timeline")

    init(detail: GameDetailResponse? = nil) {
        self.detail = detail
        self.isLoading = detail == nil
    }

    // MARK: - Loading Methods

    func load(gameId: Int, league: String?, service: GameService) async {
        guard detail == nil else {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        isUnavailable = false

        do {
            let response = try await service.fetchGame(id: gameId)
            guard response.game.id == gameId else {
                GameRoutingLogger.logMismatch(tappedId: gameId, destinationId: response.game.id, league: league)
                detail = nil
                isUnavailable = true
                isLoading = false
                return
            }
            detail = response
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func loadSocialPosts(gameId: Int, service: GameService) async {
        guard isSocialTabEnabled else { return }

        switch socialPostsState {
        case .loaded, .loading:
            return
        case .idle, .failed:
            break
        }

        socialPostsState = .loading

        do {
            let response = try await service.fetchSocialPosts(gameId: gameId)
            socialPosts = response.posts
            socialPostsState = .loaded
        } catch {
            socialPostsState = .failed(error.localizedDescription)
        }
    }

    func loadTimeline(gameId: Int, service: GameService) async {
        switch timelineArtifactState {
        case .loaded, .loading:
            return
        case .idle, .failed:
            break
        }

        timelineArtifactState = .loading

        do {
            let resolvedGameId = timelineGameId(for: gameId)
            let response = try await service.fetchTimeline(gameId: resolvedGameId)
            timelineArtifact = response
            timelineArtifactState = .loaded
        } catch {
            logger.error("Timeline fetch failed: \(error.localizedDescription, privacy: .public)")
            timelineArtifactState = .failed(error.localizedDescription)
        }
    }

    func loadStory(gameId: Int, service: GameService) async {
        switch storyState {
        case .loaded, .loading:
            return
        case .idle, .failed:
            break
        }

        storyState = .loading

        do {
            let response = try await service.fetchStory(gameId: gameId)
            storyResponse = response
            storyPlays = response.plays
            momentDisplayModels = StoryAdapter.convertToDisplayModels(from: response)
            storyState = .loaded
            logger.info("📖 Loaded story: \(response.story.moments.count, privacy: .public) moments, \(response.plays.count, privacy: .public) plays")
        } catch {
            logger.error("📖 Story fetch failed: \(error.localizedDescription, privacy: .public)")
            storyState = .failed(error.localizedDescription)
        }
    }

    /// Load PBP data separately when not included in main game detail
    func loadPbp(gameId: Int, service: GameService) async {
        switch pbpState {
        case .loaded, .loading:
            return
        case .idle, .failed:
            break
        }

        pbpState = .loading

        do {
            let response = try await service.fetchPbp(gameId: gameId)
            pbpEvents = response.events
            pbpState = .loaded
            logger.info("📋 Loaded PBP: \(response.events.count, privacy: .public) events")
        } catch {
            logger.error("📋 PBP fetch failed: \(error.localizedDescription, privacy: .public)")
            pbpState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Story Computed Properties

    var hasStoryData: Bool {
        storyState == .loaded && !momentDisplayModels.isEmpty
    }

    /// Get plays for a specific moment
    func playsForMoment(_ moment: MomentDisplayModel) -> [StoryPlay] {
        let ids = Set(moment.playIds)
        return storyPlays.filter { ids.contains($0.playId) }
    }

    /// Check if a play is highlighted within a moment
    func isPlayHighlighted(_ playId: Int, in moment: MomentDisplayModel) -> Bool {
        moment.highlightedPlayIds.contains(playId)
    }

    /// Whether to show the Story View (completed games with story data)
    var shouldShowStoryView: Bool {
        guard let game = game else { return false }
        let isCompleted = game.status == .completed || game.status == .final
        return isCompleted && hasStoryData
    }

    /// Get social posts filtered by reveal level
    var filteredSocialPosts: [SocialPostResponse] {
        socialPosts.filter { $0.isSafeToShow(outcomeRevealed: isOutcomeRevealed) }
    }

    /// Enable social tab and load posts
    func enableSocialTab(gameId: Int, service: GameService) async {
        isSocialTabEnabled = true
        UserDefaults.standard.set(true, forKey: socialTabEnabledKey(for: gameId))
        await loadSocialPosts(gameId: gameId, service: service)
    }

    /// Load social tab preference
    func loadSocialTabPreference(for gameId: Int) {
        isSocialTabEnabled = UserDefaults.standard.bool(forKey: socialTabEnabledKey(for: gameId))
    }

    private func socialTabEnabledKey(for gameId: Int) -> String {
        "game.socialTabEnabled.\(gameId)"
    }

    // MARK: - Game Properties

    var game: Game? {
        detail?.game
    }

    var gameContext: String? {
        guard let game = detail?.game else { return nil }
        let context = generateBasicContext(for: game)
        return context.isEmpty ? nil : context
    }

    private func generateBasicContext(for game: Game) -> String {
        var contextParts: [String] = []

        switch game.leagueCode {
        case "NBA":
            contextParts.append("NBA matchup")
        case "NCAAB":
            contextParts.append("College basketball")
        case "NHL":
            contextParts.append("NHL game")
        default:
            contextParts.append("\(game.leagueCode) game")
        }

        contextParts.append("featuring \(game.awayTeam) at \(game.homeTeam)")

        switch game.status {
        case .scheduled:
            if let date = game.parsedGameDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                contextParts.append("scheduled for \(formatter.string(from: date))")
            }
        case .inProgress:
            contextParts.append("currently in progress")
        case .completed, .final:
            contextParts.append("played on \(game.formattedDate)")
        default:
            break
        }

        return contextParts.joined(separator: ", ") + "."
    }

    var recapBullets: [String] {
        guard let game = detail?.game else { return [] }
        let statusText = game.status.rawValue.capitalized
        return [
            String(format: ViewModelConstants.recapTeamsTemplate, game.awayTeam, game.homeTeam),
            String(format: ViewModelConstants.recapStatusTemplate, statusText),
            ViewModelConstants.recapHighlightsTemplate
        ]
    }

    var highlights: [SocialPostEntry] {
        detail?.socialPosts.filter { $0.hasVideo || $0.imageUrl != nil } ?? []
    }

    // MARK: - Score Markers

    var liveScoreMarker: TimelineScoreMarker? {
        guard game?.status == .inProgress else { return nil }
        guard let score = latestScoreDisplay() else { return nil }
        return TimelineScoreMarker(
            id: ViewModelConstants.liveMarkerId,
            label: ViewModelConstants.liveScoreLabel,
            score: score
        )
    }

    func scoreMarker(for play: PlayEntry) -> TimelineScoreMarker? {
        guard play.playType == .periodEnd else { return nil }
        guard let score = scoreDisplay(home: play.homeScore, away: play.awayScore) else { return nil }
        let label = play.quarter == ViewModelConstants.halftimeQuarter
            ? ViewModelConstants.halftimeLabel
            : ViewModelConstants.periodEndLabel
        return TimelineScoreMarker(
            id: "period-end-\(play.playIndex)",
            label: label,
            score: score
        )
    }

    // MARK: - Team Stats

    var teamComparisonStats: [TeamComparisonStat] {
        guard let home = detail?.teamStats.first(where: { $0.isHome }),
              let away = detail?.teamStats.first(where: { !$0.isHome }) else {
            return []
        }

        return ViewModelConstants.teamComparisonKeys.map { key in
            let homeValue = statValue(for: key.key, in: home.stats)
            let awayValue = statValue(for: key.key, in: away.stats)
            return TeamComparisonStat(
                name: key.label,
                homeValue: homeValue,
                awayValue: awayValue,
                homeDisplay: formattedStat(homeValue, placeholder: ViewModelConstants.statPlaceholder),
                awayDisplay: formattedStat(awayValue, placeholder: ViewModelConstants.statPlaceholder)
            )
        }
    }

    var playerStats: [PlayerStat] {
        detail?.playerStats ?? []
    }

    var teamStats: [TeamStat] {
        detail?.teamStats ?? []
    }

    // MARK: - NHL-Specific Stats

    var isNHL: Bool {
        game?.leagueCode == "NHL"
    }

    var nhlSkaters: [NHLSkaterStat] {
        detail?.nhlSkaters ?? []
    }

    var nhlGoalies: [NHLGoalieStat] {
        detail?.nhlGoalies ?? []
    }

    var nhlDataHealth: NHLDataHealth? {
        detail?.dataHealth
    }

    var isNHLDataHealthy: Bool {
        detail?.dataHealth?.isHealthy ?? true
    }

    // MARK: - Private Helpers

    private func timelineGameId(for gameId: Int) -> Int {
        gameId > 0 ? gameId : ViewModelConstants.defaultTimelineGameId
    }

    private func statValue(for key: String, in stats: [String: AnyCodable]) -> Double? {
        guard let value = stats[key]?.value else { return nil }
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let string = value as? String {
            return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private func formattedStat(_ value: Double?, placeholder: String) -> String {
        guard let value else { return placeholder }

        if value >= ViewModelConstants.percentageFloor && value <= ViewModelConstants.percentageCeiling {
            return String(format: ViewModelConstants.percentageFormat, value)
        }
        if value == floor(value) {
            return String(format: ViewModelConstants.integerFormat, value)
        }
        return String(format: ViewModelConstants.decimalFormat, value)
    }

    private func latestScoreDisplay() -> String? {
        let plays = detail?.plays ?? []
        if let scoredPlay = plays.reversed().first(where: { $0.homeScore != nil && $0.awayScore != nil }) {
            return scoreDisplay(home: scoredPlay.homeScore, away: scoredPlay.awayScore)
        }
        return scoreDisplay(home: game?.homeScore, away: game?.awayScore)
    }

    private func scoreDisplay(home: Int?, away: Int?) -> String? {
        guard let home, let away else { return nil }
        return "\(away) - \(home)"
    }
}

// MARK: - Constants

private enum ViewModelConstants {
    static let recapTeamsTemplate = "Matchup: %@ at %@."
    static let recapStatusTemplate = "Status: %@."
    static let recapHighlightsTemplate = "Key moments and highlights below."
    static let halftimeQuarter = 2
    static let halftimeLabel = "Halftime"
    static let periodEndLabel = "Period End"
    static let liveScoreLabel = "Live Score"
    static let liveMarkerId = "live-score"
    static let percentageFloor = 0.0
    static let percentageCeiling = 1.0
    static let percentageFormat = "%.3f"
    static let integerFormat = "%.0f"
    static let decimalFormat = "%.1f"
    static let statPlaceholder = "--"
    static let teamComparisonKeys: [(key: String, label: String)] = [
        ("fg_pct", "Field Goal %"),
        ("fg", "Field Goals Made"),
        ("fga", "Field Goals Attempted"),
        ("fg3_pct", "3-Point %"),
        ("fg3", "3-Pointers Made"),
        ("fg3a", "3-Pointers Attempted"),
        ("ft_pct", "Free Throw %"),
        ("ft", "Free Throws Made"),
        ("fta", "Free Throws Attempted"),
        ("trb", "Total Rebounds"),
        ("orb", "Offensive Rebounds"),
        ("drb", "Defensive Rebounds"),
        ("ast", "Assists"),
        ("stl", "Steals"),
        ("blk", "Blocks"),
        ("tov", "Turnovers"),
        ("pf", "Personal Fouls")
    ]
    static let defaultTimelineGameId = 401585601
}
