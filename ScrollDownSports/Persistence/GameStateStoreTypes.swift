import Combine
import Foundation

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
