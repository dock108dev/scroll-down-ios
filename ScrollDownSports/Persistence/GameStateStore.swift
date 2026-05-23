import Combine
import Foundation

struct LocalGameStateSnapshot: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var pinnedGamesById: [Int: PinnedGameRecord]
    var progressByGameId: [Int: GameProgressRecord]
    var homeSnapshot: PersistedHomeSnapshot?
    var backgroundRefreshRecord: BackgroundRefreshRecord?
    var updatedAt: Date

    static func empty(now: Date) -> LocalGameStateSnapshot {
        LocalGameStateSnapshot(
            schemaVersion: currentSchemaVersion,
            pinnedGamesById: [:],
            progressByGameId: [:],
            homeSnapshot: nil,
            backgroundRefreshRecord: nil,
            updatedAt: now
        )
    }
}

enum FollowLivePreference: String, Codable, Equatable {
    case automatic
    case followingLiveEdge
    case readingAwayFromLiveEdge
    case pinnedToLiveEdge
}

struct PinnedGameRecord: Codable, Equatable, Identifiable {
    var id: Int { gameId }

    let gameId: Int
    var isPinned: Bool
    var pinnedAt: Date
    var sportCode: String
    var leagueCode: String
    var gameDate: Date
    var homeTeam: String
    var awayTeam: String
    var homeTeamAbbr: String?
    var awayTeamAbbr: String?
    var statusRawValue: String
    var homeScore: Int?
    var awayScore: Int?
    var lastViewedAt: Date?
    var lastReadEventID: String?
    var lastReadEventIndex: Int?
    var newEventCount: Int
    var summaryPlayCountBaseline: Int?
    var followLivePreference: FollowLivePreference
    var lastSummaryRefreshAt: Date?
    var latestDetail: GameDetail?
    var latestPlayCursor: PlayCursor?
    var lastSeenPlayCursor: PlayCursor?
    var lastBackgroundRefreshAt: Date?
    var lastBackgroundError: String?
}

extension PinnedGameRecord {
    init(game: Game, now: Date) {
        self.gameId = game.id
        self.isPinned = true
        self.pinnedAt = now
        self.sportCode = game.sport.persistenceCode
        self.leagueCode = game.leagueCode
        self.gameDate = game.scheduledStart
        self.homeTeam = game.homeParticipant?.name ?? "Home"
        self.awayTeam = game.awayParticipant?.name ?? "Away"
        self.homeTeamAbbr = game.homeParticipant?.abbreviation
        self.awayTeamAbbr = game.awayParticipant?.abbreviation
        self.statusRawValue = game.status.rawValue
        self.homeScore = game.scoreState.home
        self.awayScore = game.scoreState.away
        self.lastViewedAt = nil
        self.lastReadEventID = game.progress.lastReadEventID
        self.lastReadEventIndex = nil
        self.newEventCount = 0
        self.summaryPlayCountBaseline = game.progress.eventCount
        self.followLivePreference = .automatic
        self.lastSummaryRefreshAt = now
        self.latestDetail = nil
        self.latestPlayCursor = nil
        self.lastSeenPlayCursor = nil
        self.lastBackgroundRefreshAt = nil
        self.lastBackgroundError = nil
    }

    mutating func mergeRefreshMetadata(from game: Game, existing: PinnedGameRecord?, now: Date) {
        if let existing {
            pinnedAt = existing.pinnedAt
            lastViewedAt = existing.lastViewedAt
            lastReadEventID = existing.lastReadEventID
            lastReadEventIndex = existing.lastReadEventIndex
            newEventCount = existing.newEventCount
            summaryPlayCountBaseline = existing.summaryPlayCountBaseline
            followLivePreference = existing.followLivePreference
            latestDetail = existing.latestDetail
            latestPlayCursor = existing.latestPlayCursor
            lastSeenPlayCursor = existing.lastSeenPlayCursor
            lastBackgroundRefreshAt = existing.lastBackgroundRefreshAt
            lastBackgroundError = existing.lastBackgroundError
        }

        if let lastReadEventID = game.progress.lastReadEventID {
            self.lastReadEventID = lastReadEventID
        }

        defer {
            lastSummaryRefreshAt = now
        }

        guard let currentCount = game.progress.eventCount else {
            summaryPlayCountBaseline = nil
            newEventCount = 0
            return
        }

        guard let previousCount = summaryPlayCountBaseline else {
            summaryPlayCountBaseline = currentCount
            return
        }

        if currentCount < previousCount {
            summaryPlayCountBaseline = currentCount
            newEventCount = 0
            return
        }

        if currentCount > previousCount,
           !game.status.isPregame,
           game.availableFeatures.hasTimeline || game.status.isLive || game.status.isFinal {
            newEventCount += currentCount - previousCount
        }
        summaryPlayCountBaseline = currentCount
    }
}

extension LocalGameStateSnapshot {
    mutating func pin(
        _ game: Game,
        now: () -> Date,
        preserveMirroredProgressFields: Bool
    ) {
        var record = PinnedGameRecord(game: game, now: now())
        if let existing = pinnedGamesById[game.id] {
            record.pinnedAt = existing.pinnedAt
            record.summaryPlayCountBaseline = existing.summaryPlayCountBaseline
            record.followLivePreference = existing.followLivePreference

            if preserveMirroredProgressFields {
                record.lastViewedAt = existing.lastViewedAt
                record.lastReadEventID = existing.lastReadEventID
                record.lastReadEventIndex = existing.lastReadEventIndex
                record.newEventCount = existing.newEventCount
            }
        }
        pinnedGamesById[game.id] = record
    }

    mutating func updatePinnedGame(_ game: Game, now: () -> Date) {
        var record = PinnedGameRecord(game: game, now: now())
        record.mergeRefreshMetadata(from: game, existing: pinnedGamesById[game.id], now: now())
        pinnedGamesById[game.id] = record
    }

    mutating func markViewed(gameId: Int, now: () -> Date) {
        let date = now()
        mutateProgress(gameId: gameId, now: now) { progress in
            progress.firstViewedAt = progress.firstViewedAt ?? date
            progress.lastViewedAt = date
            progress.eventIdentityBaseline = nil
        }
        if var record = pinnedGamesById[gameId] {
            record.lastViewedAt = date
            record.newEventCount = 0
            record.lastSeenPlayCursor = record.latestPlayCursor
            pinnedGamesById[gameId] = record
        }
    }

    mutating func recordKnownEventCount(gameId: Int, count: Int, now: () -> Date) {
        mutateProgress(gameId: gameId, now: now) { progress in
            let safeCount = max(0, count)
            progress.lastKnownEventCount = safeCount
            progress.newEventCount = max(0, safeCount - progress.readEventCount)
        }
    }

    mutating func recordEventRefresh(
        gameId: Int,
        events: [GameEvent],
        diff: GameEventListDiff,
        now: () -> Date
    ) {
        mutateProgress(gameId: gameId, now: now) { progress in
            let priorBaseline = progress.eventIdentityBaseline
            progress.lastKnownEventCount = events.count
            if diff.kind == .reset || priorBaseline == nil {
                progress.newEventCount = 0
            } else if let priorBaseline {
                let duplicateIDs = GameEventIdentityBaseline.duplicateSourceEventIDs(in: events)
                let insertedCount = events.filter { !priorBaseline.contains($0, duplicateSourceEventIDs: duplicateIDs) }.count
                progress.newEventCount += insertedCount
            }
            progress.eventIdentityBaseline = GameEventIdentityBaseline(events: events)
        }
    }

    mutating func recordReadEvent(
        gameId: Int,
        eventID: String?,
        eventIndex: Int?,
        knownEventCount: Int?,
        now: () -> Date
    ) {
        mutateProgress(gameId: gameId, now: now) { progress in
            let existingIndex = progress.lastReadEventIndex ?? -1
            if let eventIndex {
                let nextIndex = max(existingIndex, eventIndex)
                progress.lastReadEventIndex = nextIndex
                if eventIndex >= existingIndex, let eventID {
                    progress.lastReadEventID = eventID
                }
            } else if let eventID {
                progress.lastReadEventID = eventID
            }
            if let knownEventCount {
                progress.lastKnownEventCount = max(0, knownEventCount)
            }
            progress.newEventCount = max(0, progress.lastKnownEventCount - progress.readEventCount)
        }
    }

    mutating func clearReadPosition(gameId: Int, now: () -> Date) {
        mutateProgress(gameId: gameId, now: now) { progress in
            progress.lastReadEventID = nil
            progress.lastReadEventIndex = nil
            progress.lastScrollFallback = nil
            progress.newEventCount = max(0, progress.lastKnownEventCount)
        }
    }

    mutating func setSelectedMode(gameId: Int, mode: GameMode, now: () -> Date) {
        mutateProgress(gameId: gameId, now: now) { $0.selectedMode = mode }
    }

    mutating func setScrollFallback(gameId: Int, fallback: GameScrollFallbackRecord?, now: () -> Date) {
        mutateProgress(gameId: gameId, now: now) { $0.lastScrollFallback = fallback }
    }

    mutating func setExpandedSectionIDs(gameId: Int, sectionIDs: Set<String>, now: () -> Date) {
        mutateProgress(gameId: gameId, now: now) { $0.expandedSectionIDs = sectionIDs }
    }

    mutating func setRawFeedExpanded(gameId: Int, key: String, isExpanded: Bool, now: () -> Date) {
        mutateProgress(gameId: gameId, now: now) { progress in
            if isExpanded {
                progress.expandedRawFeedKeys.insert(key)
            } else {
                progress.expandedRawFeedKeys.remove(key)
            }
        }
    }

    mutating func setReachedScoreboard(gameId: Int, reached: Bool, now: () -> Date) {
        mutateProgress(gameId: gameId, now: now) { progress in
            progress.reachedScoreboard = progress.reachedScoreboard || reached
        }
    }

    mutating func setFollowLivePreference(gameId: Int, preference: FollowLivePreference, now: () -> Date) {
        mutateProgress(gameId: gameId, now: now) { $0.followLivePreference = preference }
        pinnedGamesById[gameId]?.followLivePreference = preference
    }

    mutating func pruneProgress(now: Date) {
        pruneFixtureState()
        let pinnedIds = Set(pinnedGamesById.keys)
        progressByGameId = progressByGameId.filter { gameId, progress in
            pinnedIds.contains(gameId) || now.timeIntervalSince(progress.updatedAt) < 30 * 24 * 60 * 60
        }
    }

    mutating func pruneFixtureState() {
        let fixturePinnedIds = Set(
            pinnedGamesById
                .filter { _, record in record.containsFixtureData }
                .map(\.key)
        )
        guard !fixturePinnedIds.isEmpty else { return }
        pinnedGamesById = pinnedGamesById.filter { !fixturePinnedIds.contains($0.key) }
        progressByGameId = progressByGameId.filter { !fixturePinnedIds.contains($0.key) }
    }

    mutating func mirrorProgressToPinnedGame(gameId: Int) {
        guard let progress = progressByGameId[gameId],
              var record = pinnedGamesById[gameId] else {
            return
        }
        record.lastViewedAt = progress.lastViewedAt
        record.lastReadEventID = progress.lastReadEventID
        record.lastReadEventIndex = progress.lastReadEventIndex
        record.newEventCount = progress.newEventCount
        record.followLivePreference = progress.followLivePreference
        pinnedGamesById[gameId] = record
    }

    private mutating func mutateProgress(
        gameId: Int,
        now: () -> Date,
        update: (inout GameProgressRecord) -> Void
    ) {
        var progress = progressByGameId[gameId] ?? .empty(gameId: gameId, now: now())
        update(&progress)
        progress.updatedAt = now()
        progressByGameId[gameId] = progress
    }
}

private extension PinnedGameRecord {
    var containsFixtureData: Bool {
        let names = [homeTeam, awayTeam].map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let syntheticNames: Set<String> = [
            "dallas wolves",
            "seattle sound",
            "new york knights",
            "bay city bridges"
        ]
        if names.contains(where: syntheticNames.contains) {
            return true
        }

        if latestDetail?.events.contains(where: { event in
            event.rawFeedSource?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "fixture"
                || event.sourceEventID?.hasPrefix("fixture-") == true
        }) == true {
            return true
        }

        return gameId <= 0
    }
}

struct GameScrollFallbackRecord: Codable, Equatable {
    var eventSequence: Int?
    var approximateOffset: Double?
}

struct GameProgressRecord: Codable, Equatable {
    let gameId: Int
    var selectedMode: GameMode
    var firstViewedAt: Date?
    var lastViewedAt: Date?
    var lastReadEventID: String?
    var lastReadEventIndex: Int?
    var lastScrollFallback: GameScrollFallbackRecord?
    var expandedSectionIDs: Set<String>
    var expandedRawFeedKeys: Set<String>
    var reachedScoreboard: Bool
    var followLivePreference: FollowLivePreference
    var lastKnownEventCount: Int
    var newEventCount: Int
    var eventIdentityBaseline: GameEventIdentityBaseline?
    var updatedAt: Date

    static func empty(gameId: Int, now: Date) -> GameProgressRecord {
        GameProgressRecord(
            gameId: gameId,
            selectedMode: .timeline,
            firstViewedAt: nil,
            lastViewedAt: nil,
            lastReadEventID: nil,
            lastReadEventIndex: nil,
            lastScrollFallback: nil,
            expandedSectionIDs: [],
            expandedRawFeedKeys: [],
            reachedScoreboard: false,
            followLivePreference: .automatic,
            lastKnownEventCount: 0,
            newEventCount: 0,
            eventIdentityBaseline: nil,
            updatedAt: now
        )
    }

    var readEventCount: Int {
        guard let lastReadEventIndex else { return 0 }
        return max(0, lastReadEventIndex + 1)
    }

    enum CodingKeys: String, CodingKey {
        case gameId
        case selectedMode
        case firstViewedAt
        case lastViewedAt
        case lastReadEventID
        case lastReadEventIndex
        case lastScrollFallback
        case expandedSectionIDs
        case expandedRawFeedKeys
        case reachedScoreboard
        case followLivePreference
        case lastKnownEventCount
        case newEventCount
        case eventIdentityBaseline
        case updatedAt
    }

    init(
        gameId: Int,
        selectedMode: GameMode,
        firstViewedAt: Date?,
        lastViewedAt: Date?,
        lastReadEventID: String?,
        lastReadEventIndex: Int?,
        lastScrollFallback: GameScrollFallbackRecord?,
        expandedSectionIDs: Set<String>,
        expandedRawFeedKeys: Set<String>,
        reachedScoreboard: Bool,
        followLivePreference: FollowLivePreference,
        lastKnownEventCount: Int,
        newEventCount: Int,
        eventIdentityBaseline: GameEventIdentityBaseline?,
        updatedAt: Date
    ) {
        self.gameId = gameId
        self.selectedMode = selectedMode
        self.firstViewedAt = firstViewedAt
        self.lastViewedAt = lastViewedAt
        self.lastReadEventID = lastReadEventID
        self.lastReadEventIndex = lastReadEventIndex
        self.lastScrollFallback = lastScrollFallback
        self.expandedSectionIDs = expandedSectionIDs
        self.expandedRawFeedKeys = expandedRawFeedKeys
        self.reachedScoreboard = reachedScoreboard
        self.followLivePreference = followLivePreference
        self.lastKnownEventCount = lastKnownEventCount
        self.newEventCount = newEventCount
        self.eventIdentityBaseline = eventIdentityBaseline
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            gameId: try container.decode(Int.self, forKey: .gameId),
            selectedMode: try container.decode(GameMode.self, forKey: .selectedMode),
            firstViewedAt: try container.decodeIfPresent(Date.self, forKey: .firstViewedAt),
            lastViewedAt: try container.decodeIfPresent(Date.self, forKey: .lastViewedAt),
            lastReadEventID: try container.decodeIfPresent(String.self, forKey: .lastReadEventID),
            lastReadEventIndex: try container.decodeIfPresent(Int.self, forKey: .lastReadEventIndex),
            lastScrollFallback: try container.decodeIfPresent(GameScrollFallbackRecord.self, forKey: .lastScrollFallback),
            expandedSectionIDs: try container.decodeIfPresent(Set<String>.self, forKey: .expandedSectionIDs) ?? [],
            expandedRawFeedKeys: try container.decodeIfPresent(Set<String>.self, forKey: .expandedRawFeedKeys) ?? [],
            reachedScoreboard: try container.decode(Bool.self, forKey: .reachedScoreboard),
            followLivePreference: try container.decode(FollowLivePreference.self, forKey: .followLivePreference),
            lastKnownEventCount: try container.decode(Int.self, forKey: .lastKnownEventCount),
            newEventCount: try container.decode(Int.self, forKey: .newEventCount),
            eventIdentityBaseline: try container.decodeIfPresent(GameEventIdentityBaseline.self, forKey: .eventIdentityBaseline),
            updatedAt: try container.decode(Date.self, forKey: .updatedAt)
        )
    }
}

@MainActor
protocol GameStateStore: AnyObject {
    var snapshot: LocalGameStateSnapshot { get }
    var snapshots: AnyPublisher<LocalGameStateSnapshot, Never> { get }

    func isPinned(gameId: Int) -> Bool
    func pin(_ game: Game)
    func unpin(gameId: Int)
    func togglePin(_ game: Game)
    func updatePinnedGame(_ game: Game)
    func saveHomeSnapshot(games: [Game], windowKey: String, fetchedAt: Date)
    func updatePinnedGameDetail(_ detail: GameDetail, fetchedAt: Date)
    func recordPinnedGameRefreshFailure(gameId: Int, message: String, at: Date)
    func recordBackgroundRefresh(_ record: BackgroundRefreshRecord)

    func progress(for gameId: Int) -> GameProgressRecord?
    func markViewed(gameId: Int)
    func recordKnownEventCount(gameId: Int, count: Int)
    func recordEventRefresh(gameId: Int, events: [GameEvent], diff: GameEventListDiff)
    func recordReadEvent(gameId: Int, eventID: String?, eventIndex: Int?, knownEventCount: Int?)
    func clearReadPosition(gameId: Int)
    func setSelectedMode(gameId: Int, mode: GameMode)
    func setScrollFallback(gameId: Int, fallback: GameScrollFallbackRecord?)
    func setExpandedSectionIDs(gameId: Int, sectionIDs: Set<String>)
    func setRawFeedExpanded(gameId: Int, key: String, isExpanded: Bool)
    func setReachedScoreboard(gameId: Int, reached: Bool)
    func setFollowLivePreference(gameId: Int, preference: FollowLivePreference)

    func prune(now: Date)
}

extension GameStateStore {
    func isPinned(gameId: Int) -> Bool {
        snapshot.pinnedGamesById[gameId]?.isPinned == true
    }

    func togglePin(_ game: Game) {
        isPinned(gameId: game.id) ? unpin(gameId: game.id) : pin(game)
    }

    func progress(for gameId: Int) -> GameProgressRecord? {
        snapshot.progressByGameId[gameId]
    }
}

extension Sport {
    var persistenceCode: String {
        switch self {
        case .mlb:
            return "mlb"
        case .nfl:
            return "nfl"
        case .nba:
            return "nba"
        case .nhl:
            return "nhl"
        case .soccer:
            return "soccer"
        case .golf:
            return "golf"
        case .tennis:
            return "tennis"
        case .other(let value):
            return value
        }
    }
}
