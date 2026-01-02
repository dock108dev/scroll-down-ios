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
            return "Overview"
        case .timeline:
            return "Timeline"
        case .playerStats:
            return "Player Stats"
        case .teamStats:
            return "Team Stats"
        case .final:
            return "Final"
        }
    }
}
