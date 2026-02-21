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

    // Live polling
    @Published private(set) var isLivePolling: Bool = false
    private var pollingTask: Task<Void, Never>?

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

    func load(gameId: Int, league: String?, service: GameService, isRefresh: Bool = false) async {
        guard isRefresh || detail == nil else {
            loadState = .loaded
            return
        }

        if !isRefresh {
            loadState = .loading
        }
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
            let previousStatus = detail?.game.status
            detail = response
            injectTeamColors(from: response.game)
            logger.info("📊 Game \(gameId): teamStats count=\(response.teamStats.count), playerStats count=\(response.playerStats.count)")
            if response.teamStats.isEmpty {
                logger.info("📊 Game \(gameId): No teamStats returned by API")
            } else {
                for ts in response.teamStats {
                    logger.info("📊 Game \(gameId): TeamStat team=\(ts.team, privacy: .public) isHome=\(ts.isHome) statKeys=[\(Array(ts.stats.keys).sorted().joined(separator: ", "), privacy: .public)]")
                }
            }
            loadState = .loaded

            // Detect transition from live to final
            if let prev = previousStatus, prev.isLive, response.game.status.isFinal {
                stopLivePolling()
                logger.info("🏁 Game \(gameId) transitioned to final — stopping live polling")
            }
        } catch {
            if !isRefresh {
                errorMessage = error.localizedDescription
                loadState = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: - Live Polling

    func startLivePolling(gameId: Int, service: GameService) {
        guard !isLivePolling else { return }
        isLivePolling = true
        pollingTask = Task { [weak self] in
            // Sleep-first: caller just loaded fresh data, so wait before first poll
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 45_000_000_000) // ~45 seconds
                guard !Task.isCancelled else { break }
                await self?.refreshLiveData(gameId: gameId, service: service)
            }
        }
        logger.info("▶️ Started live polling for game \(gameId)")
    }

    func stopLivePolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isLivePolling = false
        logger.info("⏹️ Stopped live polling")
    }

    private func refreshLiveData(gameId: Int, service: GameService) async {
        await load(gameId: gameId, league: game?.leagueCode, service: service, isRefresh: true)
        // Refresh PBP for live games
        pbpState = .idle
        await loadPbp(gameId: gameId, service: service)
    }

    /// Push API-provided team colors and abbreviations into the shared caches.
    private func injectTeamColors(from game: Game) {
        if let light = game.homeTeamColorLight, let dark = game.homeTeamColorDark {
            TeamColorCache.shared.inject(teamName: game.homeTeam, lightHex: light, darkHex: dark)
        }
        if let light = game.awayTeamColorLight, let dark = game.awayTeamColorDark {
            TeamColorCache.shared.inject(teamName: game.awayTeam, lightHex: light, darkHex: dark)
        }
        if let abbr = game.homeTeamAbbr {
            TeamAbbreviations.inject(teamName: game.homeTeam, abbreviation: abbr)
        }
        if let abbr = game.awayTeamAbbr {
            TeamAbbreviations.inject(teamName: game.awayTeam, abbreviation: abbr)
        }
    }

    /// Push API-provided team colors and abbreviations from a flow response into the shared caches.
    private func injectTeamColors(from flow: GameFlowResponse) {
        if let team = flow.homeTeam, let light = flow.homeTeamColorLight, let dark = flow.homeTeamColorDark {
            TeamColorCache.shared.inject(teamName: team, lightHex: light, darkHex: dark)
        }
        if let team = flow.awayTeam, let light = flow.awayTeamColorLight, let dark = flow.awayTeamColorDark {
            TeamColorCache.shared.inject(teamName: team, lightHex: light, darkHex: dark)
        }
        if let team = flow.homeTeam, let abbr = flow.homeTeamAbbr {
            TeamAbbreviations.inject(teamName: team, abbreviation: abbr)
        }
        if let team = flow.awayTeam, let abbr = flow.awayTeamAbbr {
            TeamAbbreviations.inject(teamName: team, abbreviation: abbr)
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
            let response = try await service.fetchTimeline(gameId: gameId)
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
            injectTeamColors(from: response)
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
        let homeTeamName = detail?.game.homeTeam
        let awayTeamName = detail?.game.awayTeam

        let events = flowPlays.enumerated().map { index, play -> UnifiedTimelineEvent in
            var dict: [String: Any] = [
                "event_type": "pbp",
                "event_id": "play-\(play.playId)",
                "period": play.period,
                "game_clock": play.clock as Any,
                "description": play.description as Any,
                "player_name": play.playerName as Any,
                "home_score": play.homeScore as Any,
                "away_score": play.awayScore as Any,
                "play_type": play.playType as Any
            ]

            // Populate team — use play.team if present, otherwise derive from score change
            let isKeyPlay = keyPlayIds.contains(play.playId)
            var scoringTeam: String?
            let isScoringPlay: Bool = {
                guard let home = play.homeScore, let away = play.awayScore else { return false }
                let prevHome = index > 0 ? (flowPlays[index - 1].homeScore ?? 0) : 0
                let prevAway = index > 0 ? (flowPlays[index - 1].awayScore ?? 0) : 0
                let homeChanged = home != prevHome
                let awayChanged = away != prevAway
                if homeChanged { scoringTeam = homeTeamName }
                else if awayChanged { scoringTeam = awayTeamName }
                return homeChanged || awayChanged
            }()

            // Set team: prefer play.team from API, fall back to derived scoring team
            if let team = play.team {
                dict["team"] = team
            } else if let derived = scoringTeam {
                dict["team"] = derived
            }

            // Tier 1: key plays or actual scoring plays (score changed from previous play)
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
        // Always attempt to build unified timeline — uses pbpEvents if available, falls back to detail.plays
        buildUnifiedTimelineFromPbp()
    }

    /// Build unified timeline events from PBP events or detail plays (for live games without flow data).
    /// Flow-based timeline takes priority; this only runs when flow plays are absent.
    /// Sources tried in order: pbpEvents (separate PBP endpoint), then detail.plays (main response).
    func buildUnifiedTimelineFromPbp() {
        guard flowPlays.isEmpty else { return }

        let sport = detail?.game.leagueCode
        let homeTeamName = detail?.game.homeTeam
        let awayTeamName = detail?.game.awayTeam

        // Source 1: Separately fetched PBP events
        if !pbpEvents.isEmpty {
            let events = pbpEvents.enumerated().map { index, event -> UnifiedTimelineEvent in
                var scoringTeam: String?
                if let home = event.homeScore, let away = event.awayScore, index > 0 {
                    let prev = pbpEvents[index - 1]
                    if home != (prev.homeScore ?? 0) { scoringTeam = homeTeamName }
                    else if away != (prev.awayScore ?? 0) { scoringTeam = awayTeamName }
                }

                var dict: [String: Any] = [
                    "event_type": "pbp",
                    "event_id": "pbp-\(event.id.stringValue)",
                    "period": event.period as Any,
                    "game_clock": event.gameClock as Any,
                    "description": event.description as Any,
                    "player_name": event.playerName as Any,
                    "home_score": event.homeScore as Any,
                    "away_score": event.awayScore as Any,
                    "play_type": event.eventType as Any,
                    "team": (event.team ?? scoringTeam) as Any
                ]
                if scoringTeam != nil { dict["tier"] = 1 }
                return UnifiedTimelineEvent(from: dict, index: index, sport: sport)
            }
            serverUnifiedTimeline = events
            unifiedTimelineState = .loaded
            logger.info("📋 Built unified timeline from PBP events: \(events.count, privacy: .public)")
            return
        }

        // Source 2: Plays from the main game detail response
        let detailPlays = detail?.plays ?? []
        guard !detailPlays.isEmpty else { return }

        let events = detailPlays.enumerated().map { index, play -> UnifiedTimelineEvent in
            var scoringTeam: String?
            if let home = play.homeScore, let away = play.awayScore, index > 0 {
                let prev = detailPlays[index - 1]
                if home != (prev.homeScore ?? 0) { scoringTeam = homeTeamName }
                else if away != (prev.awayScore ?? 0) { scoringTeam = awayTeamName }
            }

            var dict: [String: Any] = [
                "event_type": "pbp",
                "event_id": "play-\(play.playIndex)",
                "period": play.quarter as Any,
                "game_clock": play.gameClock as Any,
                "description": play.description as Any,
                "player_name": play.playerName as Any,
                "home_score": play.homeScore as Any,
                "away_score": play.awayScore as Any,
                "play_type": play.playType?.rawValue as Any,
                "team": (play.teamAbbreviation ?? scoringTeam) as Any,
                "period_label": play.periodLabel as Any,
                "time_label": play.timeLabel as Any
            ]
            if let tier = play.tier {
                dict["tier"] = tier
            } else if scoringTeam != nil {
                dict["tier"] = 1
            }
            return UnifiedTimelineEvent(from: dict, index: index, sport: sport)
        }
        serverUnifiedTimeline = events
        unifiedTimelineState = .loaded
        logger.info("📋 Built unified timeline from detail plays: \(events.count, privacy: .public)")
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

    /// Best available live score from team stats points (most current) or game object (fallback).
    var liveHomeScore: Int? {
        if let ts = detail?.teamStats.first(where: { $0.isHome }),
           let pts = extractPoints(from: ts.stats) {
            return pts
        }
        return game?.homeScore
    }

    var liveAwayScore: Int? {
        if let ts = detail?.teamStats.first(where: { !$0.isHome }),
           let pts = extractPoints(from: ts.stats) {
            return pts
        }
        return game?.awayScore
    }

    private func extractPoints(from stats: [String: AnyCodable]) -> Int? {
        // Try nested "points.total" first, then flat keys
        if let nested = stats["points"]?.value as? [String: Any],
           let total = nested["total"] as? NSNumber {
            return total.intValue
        }
        for key in ["points", "pts"] {
            if let val = stats[key]?.value {
                if let num = val as? NSNumber { return num.intValue }
                if let str = val as? String, let d = Double(str) { return Int(d) }
            }
        }
        return nil
    }

    var highlights: [SocialPostEntry] {
        detail?.socialPosts.filter { $0.hasVideo || $0.imageUrl != nil } ?? []
    }

    // MARK: - Score Markers

    var liveScoreMarker: TimelineScoreMarker? {
        guard game?.status.isLive == true else { return nil }
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

        let definitions = isNHL ? Self.nhlKnownStats : Self.basketballKnownStats

        #if DEBUG
        // Log unmatched API keys to diagnose missing stat coverage
        let allKnownKeys = Set(definitions.flatMap { $0.keys })
        let allApiKeys = Set(home.stats.keys).union(Set(away.stats.keys))
        let unmatched = allApiKeys.subtracting(allKnownKeys)
        if !unmatched.isEmpty {
            logger.debug("⚠️ Unmatched team stat keys: \(unmatched.sorted(), privacy: .public)")
        }
        #endif

        return definitions.compactMap { known in
            let homeValue = resolveValue(keys: known.keys, in: home.stats)
            let awayValue = resolveValue(keys: known.keys, in: away.stats)
            guard homeValue != nil || awayValue != nil else { return nil }
            return TeamComparisonStat(
                name: known.label,
                homeValue: homeValue,
                awayValue: awayValue,
                homeDisplay: formatStatValue(homeValue, isPercentage: known.isPercentage),
                awayDisplay: formatStatValue(awayValue, isPercentage: known.isPercentage)
            )
        }
    }

    var playerStats: [PlayerStat] {
        detail?.playerStats ?? []
    }

    var teamStats: [TeamStat] {
        detail?.teamStats ?? []
    }

    /// Whether the game is truly completed — guards wrap-up from showing prematurely.
    /// Requires status == completed/final AND at least one confirmation signal:
    /// either derived-metric outcomes exist or 3+ hours have elapsed since game start.
    var isGameTrulyCompleted: Bool {
        guard game?.status.isFinal == true else { return false }

        // Signal 1: Derived metrics have outcome labels (backend only sets these after final)
        if let detail {
            let m = DerivedMetrics(detail.derivedMetrics)
            if m.spreadOutcomeLabel != nil || m.totalOutcomeLabel != nil || m.mlOutcomeLabel != nil {
                return true
            }
        }

        // Signal 2: Game started 3+ hours ago (games last ~2.5-3 hours)
        if let gameDate = game?.parsedGameDate {
            if Date().timeIntervalSince(gameDate) / 3600 >= 3 { return true }
        }

        return false
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

    /// Try each key in order, return the first value found as a Double.
    /// Supports dot-path keys for nested dicts (e.g., "points.total", "fieldGoals.pct").
    private func resolveValue(keys: [String], in stats: [String: AnyCodable]) -> Double? {
        for key in keys {
            if key.contains(".") {
                // Nested dot-path: "fieldGoals.pct" → stats["fieldGoals"]["pct"]
                let parts = key.split(separator: ".", maxSplits: 1).map(String.init)
                guard parts.count == 2,
                      let parent = stats[parts[0]]?.value as? [String: Any],
                      let raw = parent[parts[1]] else { continue }
                if let number = raw as? NSNumber { return number.doubleValue }
                if let string = raw as? String {
                    return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            } else {
                if let raw = stats[key]?.value {
                    if let number = raw as? NSNumber { return number.doubleValue }
                    if let string = raw as? String {
                        return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            }
        }
        return nil
    }

    /// Format a stat value for display.
    /// Percentages (0-1 range) are shown as "47.7%". Integers as "26".
    private func formatStatValue(_ value: Double?, isPercentage: Bool) -> String {
        guard let value else { return "--" }
        if isPercentage {
            let pct = value <= 1.0 ? value * 100 : value
            return String(format: "%.1f%%", pct)
        }
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
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
    static let halftimeQuarter = 2
    static let halftimeLabel = "Halftime"
    static let periodEndLabel = "Period End"
    static let liveScoreLabel = "Live Score"
    static let liveMarkerId = "live-score"
}

// MARK: - Known Stat Definitions

/// A stat the app knows how to display. Keys are tried in order against the API response.
private struct KnownStat {
    let keys: [String]       // All possible API key names for this stat
    let label: String        // Human-readable display label
    let group: String        // Grouping: "Overview", "Shooting", "Extra"
    let isPercentage: Bool   // If true, value is 0-1 → format as "47.7%"
}

extension GameDetailViewModel {
    /// Ordered definitions for basketball (NBA + NCAAB) team stats.
    fileprivate static let basketballKnownStats: [KnownStat] = [
        // Overview
        // API returns: points.total (nested) or pts/points (flat)
        KnownStat(keys: ["points.total", "points", "pts"], label: "Points", group: "Overview", isPercentage: false),
        KnownStat(keys: ["rebounds.total", "trb", "reb", "rebounds", "totalRebounds", "total_rebounds"], label: "Rebounds", group: "Overview", isPercentage: false),
        KnownStat(keys: ["rebounds.offensive", "orb", "offReb", "offensiveRebounds", "offensive_rebounds"], label: "Off Reb", group: "Overview", isPercentage: false),
        KnownStat(keys: ["rebounds.defensive", "drb", "defReb", "defensiveRebounds", "defensive_rebounds"], label: "Def Reb", group: "Overview", isPercentage: false),
        KnownStat(keys: ["ast", "assists"], label: "Assists", group: "Overview", isPercentage: false),
        KnownStat(keys: ["stl", "steals"], label: "Steals", group: "Overview", isPercentage: false),
        KnownStat(keys: ["blk", "blocks"], label: "Blocks", group: "Overview", isPercentage: false),
        KnownStat(keys: ["turnovers.total", "tov", "turnovers", "to"], label: "Turnovers", group: "Overview", isPercentage: false),
        KnownStat(keys: ["fouls.total", "pf", "personalFouls", "personal_fouls", "fouls"], label: "Fouls", group: "Overview", isPercentage: false),

        // Shooting
        // API returns nested: fieldGoals.made / fieldGoals.attempted / fieldGoals.pct
        KnownStat(keys: ["fieldGoals.made", "fg", "fgm", "fg_made", "fgMade", "fieldGoalsMade", "field_goals_made"], label: "FG Made", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["fieldGoals.attempted", "fga", "fg_attempted", "fgAttempted", "fieldGoalsAttempted", "field_goals_attempted"], label: "FG Att", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["fieldGoals.pct", "fg_pct", "fgPct", "fg_percentage", "fieldGoalPct", "field_goal_pct"], label: "FG%", group: "Shooting", isPercentage: true),
        KnownStat(keys: ["threePointFieldGoals.made", "fg3", "fg3m", "fg3Made", "three_made", "threePointersMade", "three_pointers_made", "threePointFieldGoalsMade"], label: "3PT Made", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["threePointFieldGoals.attempted", "fg3a", "fg3Attempted", "three_attempted", "threePointersAttempted", "three_pointers_attempted", "threePointFieldGoalsAttempted"], label: "3PT Att", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["threePointFieldGoals.pct", "fg3_pct", "fg3Pct", "threePtPct", "three_pct", "three_pt_pct", "fg3_percentage"], label: "3PT%", group: "Shooting", isPercentage: true),
        KnownStat(keys: ["freeThrows.made", "ft", "ftm", "ft_made", "ftMade", "freeThrowsMade", "free_throws_made"], label: "FT Made", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["freeThrows.attempted", "fta", "ft_attempted", "ftAttempted", "freeThrowsAttempted", "free_throws_attempted"], label: "FT Att", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["freeThrows.pct", "ft_pct", "ftPct", "freeThrowPct", "free_throw_pct", "ft_percentage"], label: "FT%", group: "Shooting", isPercentage: true),

        // 2PT Shooting
        KnownStat(keys: ["twoPointFieldGoals.made", "fg2", "fg2m", "fg2_made", "fg2Made", "twoPointFieldGoalsMade", "two_point_field_goals_made"], label: "2PT Made", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["twoPointFieldGoals.attempted", "fg2a", "fg2_attempted", "fg2Attempted", "twoPointFieldGoalsAttempted", "two_point_field_goals_attempted"], label: "2PT Att", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["twoPointFieldGoals.pct", "fg2_pct", "fg2Pct", "twoPtPct", "two_pt_pct", "fg2_percentage"], label: "2PT%", group: "Shooting", isPercentage: true),

        // Extra
        KnownStat(keys: ["points.fastBreak", "fast_break_points", "fastBreakPoints"], label: "Fast Break Pts", group: "Extra", isPercentage: false),
        KnownStat(keys: ["points.inPaint", "points_in_paint", "pointsInPaint", "paint_points", "paintPoints"], label: "Paint Pts", group: "Extra", isPercentage: false),
        KnownStat(keys: ["points.offTurnovers", "points_off_turnovers", "pointsOffTurnovers"], label: "Pts off TO", group: "Extra", isPercentage: false),
        KnownStat(keys: ["second_chance_points", "secondChancePoints"], label: "2nd Chance Pts", group: "Extra", isPercentage: false),
        KnownStat(keys: ["bench_points", "benchPoints"], label: "Bench Pts", group: "Extra", isPercentage: false),
        KnownStat(keys: ["points.largestLead", "biggest_lead", "biggestLead", "largest_lead", "largestLead"], label: "Biggest Lead", group: "Extra", isPercentage: false),
        KnownStat(keys: ["lead_changes", "leadChanges"], label: "Lead Changes", group: "Extra", isPercentage: false),
        KnownStat(keys: ["times_tied", "timesTied"], label: "Times Tied", group: "Extra", isPercentage: false),
        KnownStat(keys: ["possessions", "poss"], label: "Possessions", group: "Extra", isPercentage: false),
        KnownStat(keys: ["trueShooting", "true_shooting_pct", "trueShootingPct", "ts_pct", "tsPct"], label: "TS%", group: "Extra", isPercentage: true),
    ]

    /// Ordered definitions for NHL team stats.
    fileprivate static let nhlKnownStats: [KnownStat] = [
        KnownStat(keys: ["shots_on_goal", "shotsOnGoal", "sog"], label: "Shots on Goal", group: "Offense", isPercentage: false),
        KnownStat(keys: ["points", "pts"], label: "Points", group: "Offense", isPercentage: false),
        KnownStat(keys: ["ast", "assists"], label: "Assists", group: "Offense", isPercentage: false),
        KnownStat(keys: ["penalty_minutes", "penaltyMinutes", "pim"], label: "Penalty Minutes", group: "Discipline", isPercentage: false),
    ]
}
