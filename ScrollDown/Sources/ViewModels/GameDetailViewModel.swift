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
    @Published private(set) var loadState: GameDetailLoadState = .idle
    @Published var errorMessage: String?

    var isLoading: Bool { loadState == .loading }
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

    // Flow state
    @Published private(set) var flowState: FlowState = .idle
    @Published private(set) var flowResponse: GameFlowResponse?
    @Published private(set) var blockDisplayModels: [BlockDisplayModel] = []
    @Published private(set) var flowPlays: [FlowPlay] = []

    enum FlowState: Equatable {
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

    enum GameDetailLoadState: Equatable {
        case idle, loading, loaded, failed(String)
    }

    @Published private(set) var serverUnifiedTimeline: [UnifiedTimelineEvent]?
    @Published private(set) var unifiedTimelineState: UnifiedTimelineState = .idle

    enum UnifiedTimelineState: Equatable {
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
        self.loadState = detail == nil ? .idle : .loaded
    }

    // MARK: - Loading Methods

    func load(gameId: Int, league: String?, service: GameService) async {
        guard detail == nil else {
            loadState = .loaded
            return
        }

        loadState = .loading
        errorMessage = nil
        isUnavailable = false

        do {
            let response = try await service.fetchGame(id: gameId)
            guard response.game.id == gameId else {
                GameRoutingLogger.logMismatch(tappedId: gameId, destinationId: response.game.id, league: league)
                detail = nil
                isUnavailable = true
                loadState = .idle
                return
            }
            detail = response
            injectTeamColors(from: response.game)
            loadState = .loaded
        } catch {
            errorMessage = error.localizedDescription
            loadState = .failed(error.localizedDescription)
        }
    }

    /// Push API-provided team colors into the shared cache so all UI picks them up.
    private func injectTeamColors(from game: Game) {
        if let light = game.homeTeamColorLight, let dark = game.homeTeamColorDark {
            TeamColorCache.shared.inject(teamName: game.homeTeam, lightHex: light, darkHex: dark)
        }
        if let light = game.awayTeamColorLight, let dark = game.awayTeamColorDark {
            TeamColorCache.shared.inject(teamName: game.awayTeam, lightHex: light, darkHex: dark)
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

    func loadFlow(gameId: Int, service: GameService) async {
        switch flowState {
        case .loaded, .loading:
            return
        case .idle, .failed:
            break
        }

        flowState = .loading

        do {
            let response = try await service.fetchFlow(gameId: gameId)
            flowResponse = response
            flowPlays = response.plays
            let sport = game?.leagueCode ?? response.sport ?? "NBA"
            blockDisplayModels = FlowAdapter.convertToDisplayModels(from: response, sport: sport, socialPosts: detail?.socialPosts ?? [])
            flowState = .loaded
            logger.info("📖 Loaded flow: \(response.blocks.count, privacy: .public) blocks, \(response.plays.count, privacy: .public) plays")
        } catch {
            logger.error("📖 Flow fetch failed: \(error.localizedDescription, privacy: .public)")
            flowState = .failed(error.localizedDescription)
        }
    }

    /// Build unified timeline events from flow plays.
    /// Flow plays contain all PBP data needed for the full play-by-play view.
    /// Tier 1: key plays (from flow blocks) + scoring plays (score changed from previous play).
    /// All others get nil (defaults to tier 2). Server groupedPlays handle tertiary collapsing.
    func buildUnifiedTimelineFromFlow() {
        guard unifiedTimelineState != .loaded else { return }
        guard !flowPlays.isEmpty else { return }

        let sport = detail?.game.leagueCode
        let keyPlayIds = allKeyPlayIds

        let events = flowPlays.enumerated().map { index, play -> UnifiedTimelineEvent in
            var dict: [String: Any] = [
                "event_type": "pbp",
                "event_id": "play-\(play.playId)",
                "period": play.period,
                "game_clock": play.clock as Any,
                "description": play.description as Any,
                "team": play.team as Any,
                "player_name": play.playerName as Any,
                "home_score": play.homeScore as Any,
                "away_score": play.awayScore as Any,
                "play_type": play.playType as Any
            ]
            // Tier 1: key plays or actual scoring plays (score changed from previous play)
            let isKeyPlay = keyPlayIds.contains(play.playId)
            let isScoringPlay: Bool = {
                guard let home = play.homeScore, let away = play.awayScore, index > 0 else { return false }
                let prev = flowPlays[index - 1]
                return home != prev.homeScore || away != prev.awayScore
            }()
            if isKeyPlay || isScoringPlay {
                dict["tier"] = 1
            }
            return UnifiedTimelineEvent(from: dict, index: index, sport: sport)
        }
        serverUnifiedTimeline = events
        unifiedTimelineState = .loaded
        logger.info("Built unified timeline from flow: \(events.count, privacy: .public) plays")
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

    // MARK: - Flow Computed Properties

    /// Flow is available if we have loaded blocks
    var hasFlowData: Bool {
        flowState == .loaded && !blockDisplayModels.isEmpty
    }

    /// PBP is available from either main detail or separate fetch
    var hasPbpData: Bool {
        let playsFromDetail = detail?.plays ?? []
        return !playsFromDetail.isEmpty || !pbpEvents.isEmpty
    }

    /// Combined loading state for flow and PBP
    var isLoadingAnyData: Bool {
        isLoading || flowState == .loading || pbpState == .loading
    }

    /// No content available after all loading attempts completed
    var hasNoContent: Bool {
        flowState != .loading && pbpState != .loading && !isLoading &&
        !hasFlowData && !hasPbpData
    }

    /// Get plays for a specific block
    func playsForBlock(_ block: BlockDisplayModel) -> [FlowPlay] {
        let ids = Set(block.playIds)
        return flowPlays.filter { ids.contains($0.playId) }
    }

    /// Check if a play is a key play within a block
    func isKeyPlay(_ playId: Int, in block: BlockDisplayModel) -> Bool {
        block.keyPlayIds.contains(playId)
    }

    /// Whether to show the Flow View (completed games with flow data)
    var shouldShowFlowView: Bool {
        guard let game = game else { return false }
        let isCompleted = game.status == .completed || game.status == .final
        return isCompleted && hasFlowData
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

        let keys = isNHL ? ViewModelConstants.nhlTeamComparisonKeys : ViewModelConstants.teamComparisonKeys
        return keys.map { key in
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

    // MARK: - Pregame Odds Lines

    /// Main betting lines for the pregame section — spread, total, moneyline without outcomes
    struct PregameOddsLine: Identifiable {
        let id: String
        let label: String
        let detail: String
    }

    var pregameOddsLines: [PregameOddsLine] {
        guard let detail else { return [] }
        let metrics = DerivedMetrics(detail.derivedMetrics)
        var lines: [PregameOddsLine] = []
        if let spread = metrics.pregameSpreadLabel {
            lines.append(PregameOddsLine(id: "spread", label: "Spread", detail: spread))
        }
        if let total = metrics.pregameTotalLabel {
            lines.append(PregameOddsLine(id: "total", label: "O/U", detail: total))
        }
        if let mlHome = metrics.pregameMLHomeLabel, let mlAway = metrics.pregameMLAwayLabel {
            lines.append(PregameOddsLine(id: "ml", label: "ML", detail: "\(mlAway) / \(mlHome)"))
        }
        return lines
    }

    // MARK: - Odds Result

    var oddsResult: OddsResult? {
        guard let detail else { return nil }
        let metrics = DerivedMetrics(detail.derivedMetrics)

        var spreadResult: OddsResult.SpreadResult?
        if let line = metrics.spreadLine, let team = metrics.spreadFavoredTeam {
            spreadResult = OddsResult.SpreadResult(
                favoredTeam: team,
                line: line,
                covered: metrics.spreadCovered ?? false,
                push: metrics.spreadPush ?? false
            )
        }

        var totalResult: OddsResult.TotalResult?
        if let line = metrics.totalLine, let actual = metrics.actualTotal {
            totalResult = OddsResult.TotalResult(
                line: line,
                actualTotal: actual,
                wentOver: metrics.totalWentOver ?? false,
                push: metrics.totalPush ?? false
            )
        }

        var moneylineResult: OddsResult.MoneylineResult?
        if let favTeam = metrics.mlFavoredTeam, let favPrice = metrics.mlFavoredPrice,
           let undTeam = metrics.mlUnderdogTeam, let undPrice = metrics.mlUnderdogPrice {
            moneylineResult = OddsResult.MoneylineResult(
                favoredTeam: favTeam,
                favoredPrice: favPrice,
                underdogTeam: undTeam,
                underdogPrice: undPrice,
                favoriteWon: metrics.mlFavoriteWon ?? false
            )
        }

        guard spreadResult != nil || totalResult != nil || moneylineResult != nil else { return nil }

        return OddsResult(
            bookName: metrics.bookName ?? "DraftKings",
            spread: spreadResult,
            total: totalResult,
            moneyline: moneylineResult
        )
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

// MARK: - Odds Result Types

struct OddsResult {
    let bookName: String
    let spread: SpreadResult?
    let total: TotalResult?
    let moneyline: MoneylineResult?

    struct SpreadResult {
        let favoredTeam: String
        let line: Double
        let covered: Bool
        let push: Bool
    }

    struct TotalResult {
        let line: Double
        let actualTotal: Int
        let wentOver: Bool
        let push: Bool
    }

    struct MoneylineResult {
        let favoredTeam: String
        let favoredPrice: Int
        let underdogTeam: String
        let underdogPrice: Int
        let favoriteWon: Bool
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
    static let nhlTeamComparisonKeys: [(key: String, label: String)] = [
        ("shots_on_goal", "Shots on Goal"),
        ("points", "Points"),
        ("assists", "Assists"),
        ("penalty_minutes", "Penalty Minutes")
    ]
    static let defaultTimelineGameId = 401585601
}
