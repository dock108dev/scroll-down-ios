import Foundation

enum GameSection: String, CaseIterable, Hashable {
    case header
    case overview
    case timeline
    case social
    case playerStats
    case teamStats
    case final

    static var navigationSections: [GameSection] {
        // NOTE: .social removed - tweets are now integrated into unified timeline
        [.overview, .timeline, .playerStats, .teamStats, .final]
    }

    var title: String {
        switch self {
        case .header:
            return "Header"
        case .overview:
            return "Pregame"
        case .timeline:
            return "Timeline"
        case .social:
            return "Social"
        case .playerStats:
            return "Player Stats"
        case .teamStats:
            return "Team Stats"
        case .final:
            return "Wrap-up"
        }
    }
}
