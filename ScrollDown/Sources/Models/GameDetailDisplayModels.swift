import Foundation

/// Internal models for organizing game detail display state

/// Represents a period or quarter's worth of play-by-play events
struct QuarterTimeline: Identifiable, Equatable {
    let quarter: Int
    let plays: [PlayEntry]
    var id: Int { quarter }
}

/// Represents a specific point in the timeline where a score should be displayed (e.g. End of 1st)
struct TimelineScoreMarker: Identifiable, Equatable {
    let id: String
    let label: String
    let score: String
}

/// Represents a team comparison statistic for the boxscore
struct TeamComparisonStat: Identifiable {
    let name: String
    let homeValue: Double?
    let awayValue: Double?
    let homeDisplay: String
    let awayDisplay: String

    var id: String { name }
}
