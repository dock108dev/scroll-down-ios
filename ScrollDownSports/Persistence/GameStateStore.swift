import Foundation
struct LocalGameStateSnapshot: Codable, Equatable {
    static let currentSchemaVersion = 1
    var schemaVersion: Int
    var favoriteTeamIds: Set<String>
    var favoriteNotificationKeys: Set<String>
    var pinnedGamesById: [Int: PinnedGameRecord]
    var progressByGameId: [Int: GameProgressRecord]
    var homeSnapshot: PersistedHomeSnapshot?
    var backgroundRefreshRecord: BackgroundRefreshRecord?
    var updatedAt: Date
    static func empty(now: Date) -> LocalGameStateSnapshot {
        LocalGameStateSnapshot(
            schemaVersion: currentSchemaVersion,
            favoriteTeamIds: [],
            favoriteNotificationKeys: [],
            pinnedGamesById: [:],
            progressByGameId: [:],
            homeSnapshot: nil,
            backgroundRefreshRecord: nil,
            updatedAt: now
        )
    }
    enum CodingKeys: String, CodingKey {
        case schemaVersion, favoriteTeamIds, favoriteNotificationKeys, pinnedGamesById, progressByGameId, homeSnapshot, backgroundRefreshRecord, updatedAt
    }
    init(
        schemaVersion: Int,
        favoriteTeamIds: Set<String> = [],
        favoriteNotificationKeys: Set<String> = [],
        pinnedGamesById: [Int: PinnedGameRecord],
        progressByGameId: [Int: GameProgressRecord],
        homeSnapshot: PersistedHomeSnapshot?,
        backgroundRefreshRecord: BackgroundRefreshRecord?,
        updatedAt: Date
    ) {
        self.schemaVersion = schemaVersion; self.favoriteTeamIds = favoriteTeamIds; self.favoriteNotificationKeys = favoriteNotificationKeys
        self.pinnedGamesById = pinnedGamesById; self.progressByGameId = progressByGameId
        self.homeSnapshot = homeSnapshot; self.backgroundRefreshRecord = backgroundRefreshRecord; self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        self.favoriteTeamIds = try container.decodeIfPresent(Set<String>.self, forKey: .favoriteTeamIds) ?? []
        self.favoriteNotificationKeys = try container.decodeIfPresent(Set<String>.self, forKey: .favoriteNotificationKeys) ?? []
        self.pinnedGamesById = try container.decode([Int: PinnedGameRecord].self, forKey: .pinnedGamesById)
        self.progressByGameId = try container.decode([Int: GameProgressRecord].self, forKey: .progressByGameId)
        self.homeSnapshot = try container.decodeIfPresent(PersistedHomeSnapshot.self, forKey: .homeSnapshot)
        self.backgroundRefreshRecord = try container.decodeIfPresent(BackgroundRefreshRecord.self, forKey: .backgroundRefreshRecord)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

enum FollowLivePreference: String, Codable, Equatable { case automatic, followingLiveEdge, readingAwayFromLiveEdge, pinnedToLiveEdge }

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
    mutating func setFavoriteTeam(_ teamID: String, isFavorite: Bool) {
        let normalized = teamID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        if isFavorite { favoriteTeamIds.insert(normalized) } else { favoriteTeamIds.remove(normalized) }
    }

    mutating func recordFavoriteNotificationKeys(_ keys: Set<String>) {
        favoriteNotificationKeys.formUnion(keys.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }

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
            let resumeCardID = progress.lastReadEventID
            progress.firstViewedAt = progress.firstViewedAt ?? date
            progress.lastViewedAt = date
            progress.eventIdentityBaseline = nil
            if progress.hasReadCursor {
                progress.readingHistory.recordResumed(cardID: resumeCardID, at: date)
            }
        }
        if var record = pinnedGamesById[gameId] {
            record.lastViewedAt = date
            record.newEventCount = 0
            record.lastSeenPlayCursor = record.latestPlayCursor
            pinnedGamesById[gameId] = record
        }
    }

    mutating func recordKnownEventCount(gameId: Int, count: Int, now: () -> Date) {
        let date = now()
        mutateProgress(gameId: gameId, now: now) { progress in
            let safeCount = max(0, count)
            progress.lastKnownEventCount = safeCount
            progress.newEventCount = max(0, safeCount - progress.readEventCount)
            progress.readingHistory.markRead(cardID: nil, eventIndex: progress.lastReadEventIndex, knownCount: safeCount, at: date)
        }
    }

    mutating func recordEventRefresh(
        gameId: Int,
        events: [GameEvent],
        diff: GameEventListDiff,
        now: () -> Date
    ) {
        let date = now()
        mutateProgress(gameId: gameId, now: now) { progress in
            let priorBaseline = progress.eventIdentityBaseline
            let canonicalEvents = DetailStreamMode.dedupedEvents(from: events)
            progress.readingHistory.mergeEvents(canonicalEvents, at: date)
            progress.lastKnownEventCount = canonicalEvents.count
            if diff.kind == .reset || priorBaseline == nil {
                progress.newEventCount = 0
            } else if !progress.hasReadCursor {
                progress.newEventCount += diff.insertedEvents.count
            } else {
                progress.recomputeUnreadCount(from: canonicalEvents)
            }
            let readCardID = progress.lastReadEventIndex.flatMap { index in
                canonicalEvents.indices.contains(index) ? canonicalEvents[index].readingHistoryCardID : nil
            } ?? progress.lastReadEventID
            progress.lastReadEventID = readCardID
            progress.readingHistory.markRead(
                cardID: readCardID,
                eventIndex: progress.lastReadEventIndex,
                knownCount: progress.lastKnownEventCount,
                at: date
            )
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
        let date = now()
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
            progress.readingHistory.markRead(
                cardID: progress.lastReadEventID,
                eventIndex: progress.lastReadEventIndex,
                knownCount: progress.lastKnownEventCount,
                at: date
            )
        }
    }

    mutating func clearReadPosition(gameId: Int, now: () -> Date) {
        let date = now()
        mutateProgress(gameId: gameId, now: now) { progress in
            progress.lastReadEventID = nil
            progress.lastReadEventIndex = nil
            progress.lastScrollFallback = nil
            progress.newEventCount = max(0, progress.lastKnownEventCount)
            progress.readingHistory.clearReadState(knownCount: progress.lastKnownEventCount, at: date)
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
        let date = now()
        mutateProgress(gameId: gameId, now: now) { progress in
            progress.reachedScoreboard = progress.reachedScoreboard || reached
            if reached {
                progress.readingHistory.recordRevealed(at: date)
            }
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
        let fixtureProgressIds = Set(
            progressByGameId
                .filter { _, record in record.containsFixtureData }
                .map(\.key)
        )
        let fixtureStateIds = fixturePinnedIds.union(fixtureProgressIds)
        if !fixtureStateIds.isEmpty {
            pinnedGamesById = pinnedGamesById.filter { !fixtureStateIds.contains($0.key) }
            progressByGameId = progressByGameId.filter { !fixtureStateIds.contains($0.key) }
        }

        guard let snapshot = homeSnapshot else { return }
        let filteredGames = snapshot.games.filter { !$0.containsFixtureData }
        if filteredGames.count != snapshot.games.count {
            homeSnapshot = PersistedHomeSnapshot(
                windowKey: snapshot.windowKey,
                fetchedAt: snapshot.fetchedAt,
                games: filteredGames
            )
        }
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
        if FixtureDataBoundary.containsSyntheticTeamName([homeTeam, awayTeam]) {
            return true
        }

        if latestDetail?.events.contains(where: { event in
            event.containsFixtureData
        }) == true {
            return true
        }

        return gameId <= 0
    }
}

private extension Game {
    var containsFixtureData: Bool {
        FixtureDataBoundary.containsSyntheticTeamName(participants.map(\.name))
    }
}

private extension GameEvent {
    var containsFixtureData: Bool {
        FixtureDataBoundary.isFixtureRawFeedSource(rawFeedSource)
            || FixtureDataBoundary.isFixtureSourceEventID(sourceEventID)
    }
}

private extension GameProgressRecord {
    var containsFixtureData: Bool {
        if FixtureDataBoundary.isFixtureSourceEventID(lastReadEventID) {
            return true
        }

        if readingHistory.containsFixtureData() {
            return true
        }

        return eventIdentityBaseline?.sourceEventIDs.contains(where: FixtureDataBoundary.isFixtureSourceEventID) == true
    }
}

private enum FixtureDataBoundary {
    private static let syntheticTeamNames: Set<String> = [
        "dallas wolves",
        "seattle sound",
        "new york knights",
        "bay city bridges"
    ]

    static func containsSyntheticTeamName(_ names: [String]) -> Bool { names.map(normalizedToken).contains { syntheticTeamNames.contains($0) } }

    static func isFixtureRawFeedSource(_ value: String?) -> Bool { normalizedToken(value) == "fixture" }

    static func isFixtureSourceEventID(_ value: String?) -> Bool { normalizedToken(value).hasPrefix("fixture-") }

    private static func normalizedToken(_ value: String?) -> String { value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "" }
}
