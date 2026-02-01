import Foundation

// MARK: - Moment Display Model

/// Display model for story moments - adapter between API response and UI
struct MomentDisplayModel: Identifiable, Equatable {
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
    let cumulativeBoxScore: MomentBoxScore?

    var id: Int { momentIndex }
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
