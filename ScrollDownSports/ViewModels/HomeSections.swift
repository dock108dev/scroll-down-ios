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
}

struct HomeTimelineSection: Identifiable, Equatable {
    let id: String
    let date: Date
    let title: String
    let subtitle: String
    let anchorRole: HomeTimelineAnchorRole
    let isToday: Bool
    let games: [HomeGameItem]
}

enum HomeTimelineAnchorRole: Equatable {
    case olderCatchUp
    case yesterday
    case today
    case live
    case laterToday
    case upcoming
}

struct HomeGameItem: Identifiable, Equatable {
    let game: Game
    let isPinned: Bool
    let pinnedRecord: PinnedGameRecord?
    let progress: GameProgressRecord?

    var id: Int { game.id }

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
