import Foundation

/// Visual hierarchy tier for play-by-play events
/// Tier 1: High-impact moments (made shots, lead changes, clutch plays)
/// Tier 2: Contextual events (fouls, turnovers, violations)
/// Tier 3: Low-signal noise (misses, rebounds, subs) - collapsed by default
enum PlayTier: Int, Comparable {
    case primary = 1    // Always visible, strongest visual weight
    case secondary = 2  // Visible but de-emphasized
    case tertiary = 3   // Collapsed by default

    static func < (lhs: PlayTier, rhs: PlayTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Classifies PBP events into visual hierarchy tiers
/// Based solely on existing event metadata - no API changes required
enum PlayTierClassifier {

    /// Classify an event into its visual tier
    /// - Parameters:
    ///   - event: The timeline event to classify
    ///   - previousScore: Previous score state (home, away) for lead change detection
    ///   - periodInfo: Period context for clutch time detection
    /// - Returns: The appropriate visual tier
    static func classify(
        event: UnifiedTimelineEvent,
        previousScore: (home: Int, away: Int)?,
        periodInfo: PeriodContext
    ) -> PlayTier {
        guard event.eventType == .pbp else { return .secondary }
        guard let desc = event.description?.lowercased() else { return .tertiary }

        // Tier 1: Primary Events (High-impact)
        if isTier1Event(desc: desc, event: event, previousScore: previousScore, periodInfo: periodInfo) {
            return .primary
        }

        // Tier 2: Secondary Events (Contextual)
        if isTier2Event(desc: desc) {
            return .secondary
        }

        // Tier 3: Tertiary Events (Low-signal)
        return .tertiary
    }

    // MARK: - Tier 1 Detection

    private static func isTier1Event(
        desc: String,
        event: UnifiedTimelineEvent,
        previousScore: (home: Int, away: Int)?,
        periodInfo: PeriodContext
    ) -> Bool {
        // Made shots (2PT, 3PT, FT)
        if isScoringPlay(desc: desc) {
            // Check for lead change or tie
            if let prev = previousScore,
               let home = event.homeScore,
               let away = event.awayScore {
                let wasLeading = prev.home > prev.away ? "home" : (prev.away > prev.home ? "away" : "tie")
                let nowLeading = home > away ? "home" : (away > home ? "away" : "tie")

                // Lead change
                if wasLeading != nowLeading && wasLeading != "tie" && nowLeading != "tie" {
                    return true
                }

                // Tie game
                if home == away && prev.home != prev.away {
                    return true
                }
            }

            // Final possessions (last 2:00 of Q4/OT) - all scoring plays are Tier 1
            if periodInfo.isFinalPeriod && periodInfo.isClutchTime {
                return true
            }

            // Go-ahead scores in last 5:00 of Q4/OT
            if periodInfo.isFinalPeriod && periodInfo.isLateGame {
                if let prev = previousScore, let home = event.homeScore, let away = event.awayScore {
                    let wasLeading = prev.home > prev.away ? "home" : (prev.away > prev.home ? "away" : "tie")
                    let nowLeading = home > away ? "home" : (away > home ? "away" : "tie")
                    if wasLeading != nowLeading {
                        return true
                    }
                }
            }

            // Regular made shots are still Tier 1
            return true
        }

        // Hockey goals
        if desc.contains("goal") && !desc.contains("no goal") {
            return true
        }

        // Football touchdowns, field goals
        if desc.contains("touchdown") || (desc.contains("field goal") && desc.contains("good")) {
            return true
        }

        return false
    }

    private static func isScoringPlay(desc: String) -> Bool {
        // Exclude missed shots first
        if desc.contains("miss") { return false }

        // Basketball made shots
        if desc.contains("makes") { return true }

        // Backend format: "Player 24' 3PT (3 PTS)" - contains "PTS" without "MISS"
        if desc.contains("pts") { return true }

        // Shot types that indicate made baskets (without "miss")
        if desc.contains("dunk") { return true }
        if desc.contains("layup") { return true }
        if desc.contains("free throw") { return true }
        if desc.contains("3pt") { return true }
        if desc.contains("jump shot") { return true }
        if desc.contains("hook shot") { return true }
        if desc.contains("tip shot") { return true }
        if desc.contains("turnaround") { return true }
        if desc.contains("fadeaway") { return true }
        if desc.contains("pullup") { return true }
        if desc.contains("floating") { return true }
        if desc.contains("driving") && desc.contains("shot") { return true }
        if desc.contains("step back") { return true }
        if desc.contains("finger roll") { return true }
        if desc.contains("alley oop") { return true }
        if desc.contains("putback") { return true }

        return false
    }

    // MARK: - Tier 2 Detection

    private static func isTier2Event(desc: String) -> Bool {
        // Fouls
        if desc.contains("foul") { return true }
        if desc.contains("personal") && desc.contains("foul") { return true }
        if desc.contains("shooting foul") { return true }
        if desc.contains("loose ball foul") { return true }
        if desc.contains("offensive foul") { return true }
        if desc.contains("flagrant") { return true }
        if desc.contains("technical") { return true }

        // Turnovers
        if desc.contains("turnover") { return true }
        if desc.contains("steal") { return true }
        if desc.contains("bad pass") { return true }
        if desc.contains("lost ball") { return true }
        if desc.contains("out of bounds") && desc.contains("turnover") { return true }

        // Violations
        if desc.contains("violation") { return true }
        if desc.contains("traveling") { return true }
        if desc.contains("double dribble") { return true }
        if desc.contains("kicked ball") { return true }
        if desc.contains("goaltending") { return true }
        if desc.contains("shot clock") { return true }
        if desc.contains("lane violation") { return true }
        if desc.contains("3 second") || desc.contains("three second") { return true }
        if desc.contains("5 second") || desc.contains("five second") { return true }
        if desc.contains("8 second") || desc.contains("eight second") { return true }
        if desc.contains("10 second") || desc.contains("ten second") { return true }

        // Hockey penalties
        if desc.contains("penalty") { return true }
        if desc.contains("minor") || desc.contains("major") { return true }
        if desc.contains("hooking") || desc.contains("tripping") || desc.contains("holding") { return true }
        if desc.contains("slashing") || desc.contains("interference") || desc.contains("roughing") { return true }

        // Blocks (defensive plays, somewhat impactful)
        if desc.contains("block") && !desc.contains("blocked shot") { return true }

        return false
    }
}

/// Context about the current period for clutch time detection
struct PeriodContext {
    let period: Int
    let gameClock: String?
    let sport: String?

    /// Whether this is the final period (Q4 for NBA, P3 for NHL, H2 for NCAAB, or OT)
    var isFinalPeriod: Bool {
        let sportUpper = sport?.uppercased()
        switch sportUpper {
        case "NHL":
            return period >= 3
        case "NCAAB":
            return period >= 2
        default: // NBA
            return period >= 4
        }
    }

    /// Whether we're in clutch time (last 2:00)
    var isClutchTime: Bool {
        guard let clock = gameClock else { return false }
        guard let seconds = parseClockToSeconds(clock) else { return false }
        return seconds <= 120 // 2:00 or less
    }

    /// Whether we're in late game (last 5:00)
    var isLateGame: Bool {
        guard let clock = gameClock else { return false }
        guard let seconds = parseClockToSeconds(clock) else { return false }
        return seconds <= 300 // 5:00 or less
    }

    /// Parse game clock string to total seconds
    private func parseClockToSeconds(_ clock: String) -> Int? {
        let parts = clock.split(separator: ":").map { String($0) }
        guard parts.count == 2,
              let minutes = Int(parts[0]),
              let seconds = Int(parts[1].prefix(2)) else { return nil }
        return minutes * 60 + seconds
    }
}

/// Represents a group of consecutive Tier 3 events that can be collapsed
struct TieredPlayGroup: Identifiable {
    let id: String
    let events: [UnifiedTimelineEvent]
    let tier: PlayTier

    /// Whether this group contains multiple events (for collapse UI)
    var isCollapsible: Bool {
        tier == .tertiary && events.count > 1
    }

    /// Summary text for collapsed Tier 3 groups
    var collapsedSummary: String {
        let count = events.count
        let missCount = events.filter { $0.description?.lowercased().contains("miss") == true }.count
        let reboundCount = events.filter { $0.description?.lowercased().contains("rebound") == true }.count

        var parts: [String] = []
        if missCount > 0 { parts.append("\(missCount) missed shot\(missCount == 1 ? "" : "s")") }
        if reboundCount > 0 { parts.append("\(reboundCount) rebound\(reboundCount == 1 ? "" : "s")") }

        let otherCount = count - missCount - reboundCount
        if otherCount > 0 && parts.isEmpty {
            return "\(count) play\(count == 1 ? "" : "s")"
        } else if otherCount > 0 {
            parts.append("\(otherCount) other")
        }

        return parts.isEmpty ? "\(count) play\(count == 1 ? "" : "s")" : parts.joined(separator: ", ")
    }
}

/// Groups events into tiered display groups
/// Consecutive Tier 3 events are grouped together for collapse behavior
enum TieredPlayGrouper {

    /// Group events by tier, collapsing consecutive Tier 3 events
    static func group(
        events: [UnifiedTimelineEvent],
        sport: String?
    ) -> [TieredPlayGroup] {
        var groups: [TieredPlayGroup] = []
        var currentTier3Group: [UnifiedTimelineEvent] = []
        var previousScore: (home: Int, away: Int)?
        var groupIndex = 0

        for event in events {
            let periodContext = PeriodContext(
                period: event.period ?? 1,
                gameClock: event.gameClock,
                sport: sport
            )

            let tier = PlayTierClassifier.classify(
                event: event,
                previousScore: previousScore,
                periodInfo: periodContext
            )

            // Update previous score for next iteration
            if let home = event.homeScore, let away = event.awayScore {
                previousScore = (home, away)
            }

            if tier == .tertiary {
                // Accumulate Tier 3 events
                currentTier3Group.append(event)
            } else {
                // Flush any accumulated Tier 3 events first
                if !currentTier3Group.isEmpty {
                    groups.append(TieredPlayGroup(
                        id: "tier3-group-\(groupIndex)",
                        events: currentTier3Group,
                        tier: .tertiary
                    ))
                    groupIndex += 1
                    currentTier3Group = []
                }

                // Add Tier 1 or 2 event as its own group
                groups.append(TieredPlayGroup(
                    id: event.id,
                    events: [event],
                    tier: tier
                ))
            }
        }

        // Flush remaining Tier 3 events
        if !currentTier3Group.isEmpty {
            groups.append(TieredPlayGroup(
                id: "tier3-group-\(groupIndex)",
                events: currentTier3Group,
                tier: .tertiary
            ))
        }

        return groups
    }
}
