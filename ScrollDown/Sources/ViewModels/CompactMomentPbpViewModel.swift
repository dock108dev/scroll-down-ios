import Foundation

/// Represents a group of PBP events within a single period/quarter
struct PeriodGroup: Identifiable, Equatable {
    let period: Int
    let events: [PbpEvent]
    let isLive: Bool
    
    var id: Int { period }
    
    /// Display label for the period (e.g., "Q1", "Q2", "Period 1")
    var displayLabel: String {
        "Q\(period)"
    }
}

/// Represents a narrative moment summary inserted between event clusters
/// CRITICAL: Summaries must be neutral and observational
/// - Describe flow and momentum, not outcomes
/// - Never mention final scores or winning/losing
/// - Act as chapter headers, not conclusions
struct MomentSummary: Identifiable, Equatable {
    let id: String
    let text: String
    let position: Int // Position in the event sequence
}

@MainActor
final class CompactMomentPbpViewModel: ObservableObject {
    @Published private(set) var periodGroups: [PeriodGroup] = []
    @Published private(set) var momentSummaries: [MomentSummary] = []
    @Published private(set) var collapsedPeriods: Set<Int> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Pagination state per period
    @Published private(set) var visibleEventCounts: [Int: Int] = [:] // period -> count
    
    private var loadedMomentId: String?
    private let eventsPerChunk = 20 // Load 20 events at a time per period

    func load(moment: CompactMoment, service: GameService) async {
        let momentId = moment.id.stringValue
        guard loadedMomentId != momentId else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.fetchCompactMomentPbp(momentId: moment.id)
            let orderedEvents = orderedEvents(for: moment, events: response.events)
            
            // Group events by period
            periodGroups = groupByPeriod(orderedEvents, currentPeriod: moment.period)
            
            // Generate moment summaries
            momentSummaries = generateMomentSummaries(from: orderedEvents)
            
            // Initialize pagination: show first chunk for each period
            visibleEventCounts = Dictionary(
                uniqueKeysWithValues: periodGroups.map { ($0.period, min(eventsPerChunk, $0.events.count)) }
            )
            
            // Initialize collapsed state: current/live period expanded, others collapsed
            collapsedPeriods = Set(
                periodGroups
                    .filter { !$0.isLive }
                    .map(\.period)
            )
            
            loadedMomentId = momentId
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    /// Toggle period expansion state
    func togglePeriod(_ period: Int) {
        if collapsedPeriods.contains(period) {
            collapsedPeriods.remove(period)
        } else {
            collapsedPeriods.insert(period)
        }
    }
    
    /// Load more events for a specific period
    func loadMoreEvents(for period: Int) {
        guard let group = periodGroups.first(where: { $0.period == period }) else {
            return
        }
        
        let currentCount = visibleEventCounts[period] ?? 0
        let newCount = min(currentCount + eventsPerChunk, group.events.count)
        visibleEventCounts[period] = newCount
    }
    
    /// Get visible events for a period (respecting pagination)
    func visibleEvents(for period: Int) -> [PbpEvent] {
        guard let group = periodGroups.first(where: { $0.period == period }) else {
            return []
        }
        
        let count = visibleEventCounts[period] ?? eventsPerChunk
        return Array(group.events.prefix(count))
    }
    
    /// Check if there are more events to load for a period
    func hasMoreEvents(for period: Int) -> Bool {
        guard let group = periodGroups.first(where: { $0.period == period }) else {
            return false
        }
        
        let visibleCount = visibleEventCounts[period] ?? 0
        return visibleCount < group.events.count
    }
    
    /// Get remaining event count for a period
    func remainingEventCount(for period: Int) -> Int {
        guard let group = periodGroups.first(where: { $0.period == period }) else {
            return 0
        }
        
        let visibleCount = visibleEventCounts[period] ?? 0
        return max(0, group.events.count - visibleCount)
    }

    func orderedEvents(for moment: CompactMoment, events: [PbpEvent]) -> [PbpEvent] {
        let filtered = filteredEvents(for: moment, events: events)
        return sortChronological(filtered)
    }
    
    // MARK: - Private Helpers
    
    /// Group events by period, maintaining backend order within each period
    /// Handles edge cases:
    /// - Events with missing period data (grouped as period 0)
    /// - Partial PBP (some periods may be empty)
    /// - Delayed ingestion (events arrive incrementally)
    private func groupByPeriod(_ events: [PbpEvent], currentPeriod: Int?) -> [PeriodGroup] {
        // Group by period, using 0 for events with missing period data
        let grouped = Dictionary(grouping: events) { event in
            event.period ?? 0
        }
        
        // Sort periods and create groups
        // Filter out period 0 if it only contains events with missing data
        return grouped
            .sorted { $0.key < $1.key }
            .filter { period, periodEvents in
                // Keep all periods except 0, unless 0 is the only period
                period > 0 || grouped.count == 1
            }
            .map { period, periodEvents in
                PeriodGroup(
                    period: period,
                    events: periodEvents, // Already in backend order from sortChronological
                    isLive: period == currentPeriod
                )
            }
    }
    
    /// Generate neutral moment summaries between event clusters
    /// These act as narrative bridges without revealing outcomes
    /// CRITICAL: Summaries must be observational, not conclusive
    private func generateMomentSummaries(from events: [PbpEvent]) -> [MomentSummary] {
        guard events.count > 20 else {
            return [] // Don't add summaries for short sequences
        }
        
        var summaries: [MomentSummary] = []
        let clusterSize = 15 // Insert summary every ~15 events
        
        for i in stride(from: clusterSize, to: events.count, by: clusterSize) {
            let summary = neutralSummaryText(for: i, totalEvents: events.count)
            summaries.append(
                MomentSummary(
                    id: "summary-\(i)",
                    text: summary,
                    position: i
                )
            )
        }
        
        return summaries
    }
    
    /// Generate neutral, observational summary text
    /// CRITICAL: Must NOT mention scores, outcomes, or winning/losing
    private func neutralSummaryText(for position: Int, totalEvents: Int) -> String {
        let progress = Double(position) / Double(totalEvents)
        
        // Neutral, observational phrases that describe flow without outcomes
        let summaries: [String]
        
        switch progress {
        case 0..<0.3:
            summaries = [
                "The game begins to take shape",
                "Early sequences establish the pace",
                "Both teams find their rhythm"
            ]
        case 0.3..<0.6:
            summaries = [
                "Momentum shifts as play continues",
                "A sequence of key plays unfolds",
                "The flow of the game evolves"
            ]
        case 0.6..<0.9:
            summaries = [
                "Action intensifies down the stretch",
                "Critical moments emerge",
                "The pace quickens as time winds down"
            ]
        default:
            summaries = [
                "Final sequences play out",
                "The closing moments unfold",
                "The game reaches its conclusion"
            ]
        }
        
        return summaries.randomElement() ?? "The game continues"
    }

    private func filteredEvents(for moment: CompactMoment, events: [PbpEvent]) -> [PbpEvent] {
        guard let momentElapsed = elapsedSeconds(for: moment) else {
            return events
        }

        return events.filter { event in
            guard let eventElapsed = elapsedSeconds(for: event) else {
                return true
            }
            return eventElapsed <= momentElapsed
        }
    }

    private func sortChronological(_ events: [PbpEvent]) -> [PbpEvent] {
        events.enumerated().sorted { lhs, rhs in
            let leftKey = elapsedSeconds(for: lhs.element)
            let rightKey = elapsedSeconds(for: rhs.element)

            switch (leftKey, rightKey) {
            case let (left?, right?):
                if left == right {
                    return lhs.offset < rhs.offset
                }
                return left < right
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.offset < rhs.offset
            }
        }
        .map(\.element)
    }

    private func elapsedSeconds(for event: PbpEvent) -> Double? {
        if let elapsedSeconds = event.elapsedSeconds {
            return elapsedSeconds
        }

        return elapsedSeconds(period: event.period, gameClock: event.gameClock)
    }

    private func elapsedSeconds(for moment: CompactMoment) -> Double? {
        elapsedSeconds(period: moment.period, gameClock: moment.gameClock)
    }

    private func elapsedSeconds(period: Int?, gameClock: String?) -> Double? {
        guard let period, period > 0,
              let gameClock,
              let remainingSeconds = clockSeconds(from: gameClock) else {
            return nil
        }

        let periodLength = period <= Constants.regulationPeriods
            ? Constants.regulationPeriodSeconds
            : Constants.overtimePeriodSeconds

        let baseSeconds: Double
        if period <= Constants.regulationPeriods {
            baseSeconds = Double(period - 1) * Constants.regulationPeriodSeconds
        } else {
            let overtimeIndex = period - Constants.regulationPeriods - 1
            baseSeconds = (Double(Constants.regulationPeriods) * Constants.regulationPeriodSeconds)
                + (Double(overtimeIndex) * Constants.overtimePeriodSeconds)
        }

        let elapsedInPeriod = max(0, periodLength - remainingSeconds)
        return baseSeconds + elapsedInPeriod
    }

    private func clockSeconds(from clock: String) -> Double? {
        let parts = clock.split(separator: ":")
        guard parts.count == 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else {
            return nil
        }
        return (minutes * Constants.secondsPerMinute) + seconds
    }
}

private enum Constants {
    static let regulationPeriods = 4
    static let regulationPeriodSeconds: Double = 12 * 60
    static let overtimePeriodSeconds: Double = 5 * 60
    static let secondsPerMinute: Double = 60
}
