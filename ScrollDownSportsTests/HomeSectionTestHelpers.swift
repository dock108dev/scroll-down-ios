import Foundation
@testable import ScrollDownSports

enum HomeSectionTestHelpers {
    static func pinnedIDs(in sections: [HomeSection]) -> [Int] {
        guard case .pinned(let section) = sections.first(where: { $0.id == "pinned" }) else {
            return []
        }
        return section.games.map(\.id)
    }

    static func timelineSectionIDs(in sections: [HomeSection]) -> [String] {
        guard case .timeline(let section) = sections.first(where: { $0.id == "timeline" }) else {
            return []
        }
        return section.dateSections.map(\.id)
    }

    static func timelineIDs(in sections: [HomeSection], sectionID: String) -> [Int] {
        guard case .timeline(let section) = sections.first(where: { $0.id == "timeline" }),
              let dateSection = section.dateSections.first(where: { $0.id == sectionID }) else {
            return []
        }
        return dateSection.games.map(\.id)
    }

    static func allTimelineIDs(in sections: [HomeSection]) -> [Int] {
        guard case .timeline(let section) = sections.first(where: { $0.id == "timeline" }) else {
            return []
        }
        return section.dateSections.flatMap { $0.games.map(\.id) }
    }
}
