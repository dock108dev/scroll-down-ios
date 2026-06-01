import Foundation

enum LeagueFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case mlb = "MLB"
    case nba = "NBA"
    case nhl = "NHL"
    case nfl = "NFL"
    case ncaab = "NCAAB"
    case ncaaf = "NCAAF"

    var id: String { rawValue }
    var apiValue: String? { self == .all ? nil : rawValue.lowercased() }
    var displayName: String { rawValue }
    var menuTitle: String { rawValue }
    var segmentedTitle: String { rawValue }
}

struct HomeTimelineSection: Identifiable, Equatable {
    let id: String
    let date: Date
    let title: String
    let subtitle: String
    let anchorRole: HomeTimelineAnchorRole
    let isToday: Bool
    let games: [HomeGameItem]
    var emptyState: HomeTimelineEmptyState? = nil
}

enum HomeTimelineAnchorRole: Equatable {
    case olderCatchUp
    case yesterday
    case today
    case live
    case laterToday
    case upcoming
}

enum HomeTimelineEmptyState: Equatable {
    case laterToday
    case upcoming
}

struct HomeGameItem: Identifiable, Equatable {
    let game: Game
    let isPinned: Bool
    let pinnedRecord: PinnedGameRecord?
    let progress: GameProgressRecord?
    let favoriteTeamIds: Set<String>

    init(
        game: Game,
        isPinned: Bool,
        pinnedRecord: PinnedGameRecord?,
        progress: GameProgressRecord?,
        favoriteTeamIds: Set<String> = []
    ) {
        self.game = game
        self.isPinned = isPinned
        self.pinnedRecord = pinnedRecord
        self.progress = progress
        self.favoriteTeamIds = favoriteTeamIds
    }

    var id: Int { game.id }

    var homeAnchorID: String {
        "timeline-game-\(id)"
    }

    var newEventCount: Int {
        progress?.newEventCount ?? pinnedRecord?.newEventCount ?? 0
    }

    var hasResumeState: Bool {
        guard let progress else { return false }
        return progress.lastReadEventIndex != nil
            || progress.lastReadEventID != nil
            || progress.reachedScoreboard
            || progress.selectedMode != .timeline
    }

    var reachedScoreboard: Bool {
        progress?.reachedScoreboard ?? false
    }
}

enum HomeSection: Identifiable, Equatable {
    case pinned(HomePinnedSection)
    case timeline(HomeTimelineFeedSection)

    var id: String {
        switch self {
        case .pinned:
            return "pinned"
        case .timeline:
            return "timeline"
        }
    }

    var gameCount: Int {
        switch self {
        case .pinned(let section):
            return section.games.count
        case .timeline(let section):
            return section.dateSections.reduce(0) { $0 + $1.games.count }
        }
    }
}

struct HomePinnedSection: Equatable {
    let title: String
    let games: [HomeGameItem]
}

struct HomeTimelineFeedSection: Equatable {
    let title: String
    let dateSections: [HomeTimelineSection]
}
