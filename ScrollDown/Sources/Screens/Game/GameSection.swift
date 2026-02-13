import Foundation

enum GameSection: String, CaseIterable, Hashable {
    case header
    case overview
    case timeline
    case playerStats
    case teamStats
    case final

    static var navigationSections: [GameSection] {
        [.overview, .timeline, .playerStats, .teamStats, .final]
    }

    var title: String {
        switch self {
        case .header:
            return "Header"
        case .overview:
            return "Pregame"
        case .timeline:
            return "Flow"
        case .playerStats:
            return "Players"
        case .teamStats:
            return "Teams"
        case .final:
            return "Wrap-up"
        }
    }

    /// Unique ID for content section anchors (separate from nav button IDs)
    var anchorId: String {
        "content-anchor-\(rawValue)"
    }
}
