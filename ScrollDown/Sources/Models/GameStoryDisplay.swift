import Foundation

// MARK: - Story Display Protocol

/// Protocol for unified story display items (supports both V1 SectionEntry and V2 MomentDisplayModel)
protocol StoryDisplayItem: Identifiable {
    var displayId: Int { get }
    var header: String { get }
    var startScore: ScoreSnapshot { get }
    var endScore: ScoreSnapshot { get }
    var derivedBeatType: BeatType { get }
    var isHighlight: Bool { get }
}

// MARK: - Moment Display Model

/// Display model for V2 moments - adapter between StoryMoment and UI layer
struct MomentDisplayModel: StoryDisplayItem, Equatable {
    let momentIndex: Int
    let narrative: String
    let period: Int
    let startClock: String?
    let endClock: String?
    let startScore: ScoreSnapshot
    let endScore: ScoreSnapshot
    let playIds: [Int]
    let highlightedPlayIds: Set<Int>
    let derivedBeatType: BeatType

    var id: Int { momentIndex }
    var displayId: Int { momentIndex }
    var header: String { narrative }
    var isHighlight: Bool { derivedBeatType.isHighlight }

    /// Time range display string (e.g., "Q1 12:00-10:00")
    var timeRangeDisplay: String? {
        guard let start = startClock else { return nil }
        let periodLabel = "Q\(period)"
        if let end = endClock {
            return "\(periodLabel) \(start)-\(end)"
        }
        return "\(periodLabel) \(start)"
    }

    /// Number of highlighted plays in this moment
    var highlightedPlayCount: Int {
        highlightedPlayIds.count
    }

    /// Whether a specific play is highlighted (in explicitlyNarratedPlayIds)
    func isPlayHighlighted(_ playId: Int) -> Bool {
        highlightedPlayIds.contains(playId)
    }
}

// MARK: - SectionEntry Conformance

extension SectionEntry: StoryDisplayItem {
    var displayId: Int { sectionIndex }
    var derivedBeatType: BeatType { beatType }
}
