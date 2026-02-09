import Foundation

// MARK: - Block Display Model

/// Display model for flow blocks
struct BlockDisplayModel: Identifiable, Equatable {
    let blockIndex: Int
    let role: BlockRole
    let narrative: String
    let periodStart: Int
    let periodEnd: Int
    let startClock: String?
    let endClock: String?
    let startScore: ScoreSnapshot
    let endScore: ScoreSnapshot
    let playIds: [Int]
    let keyPlayIds: Set<Int>
    let miniBox: BlockMiniBox?
    let embeddedSocialPost: SocialPostEntry?
    let sport: String

    var id: Int { blockIndex }

    var periodDisplay: String {
        let startPeriod = formatPeriod(periodStart)
        let endPeriod = formatPeriod(periodEnd)

        // Format: "Q3 · 12:00-3:33" or "Q3 3:32 - Q4 8:37"
        if periodStart == periodEnd {
            if let start = startClock, let end = endClock, !start.isEmpty, !end.isEmpty {
                return "\(startPeriod) · \(start)-\(end)"
            }
            return startPeriod
        } else {
            // Crossing periods
            let startTime = startClock ?? ""
            let endTime = endClock ?? ""
            if !startTime.isEmpty && !endTime.isEmpty {
                return "\(startPeriod) \(startTime) - \(endPeriod) \(endTime)"
            }
            return "\(startPeriod)-\(endPeriod)"
        }
    }

    private func formatPeriod(_ period: Int) -> String {
        switch sport {
        case "NHL":
            return formatNHLPeriod(period)
        case "NCAAB":
            return formatNCAABPeriod(period)
        default: // NBA and others
            return formatNBAPeriod(period)
        }
    }

    /// NBA: Q1-Q4, then OT, 2OT, 3OT...
    private func formatNBAPeriod(_ period: Int) -> String {
        switch period {
        case 1...4:
            return "Q\(period)"
        case 5:
            return "OT"
        default:
            return "\(period - 4)OT"
        }
    }

    /// NHL: P1-P3, then OT, SO (regular season) or 2OT, 3OT... (playoffs)
    private func formatNHLPeriod(_ period: Int) -> String {
        switch period {
        case 1...3:
            return "P\(period)"
        case 4:
            return "OT"
        case 5:
            return "SO"  // Shootout in regular season
        default:
            return "\(period - 3)OT"  // Playoffs: 2OT, 3OT...
        }
    }

    /// NCAAB: H1, H2, then OT, 2OT, 3OT...
    private func formatNCAABPeriod(_ period: Int) -> String {
        switch period {
        case 1:
            return "H1"
        case 2:
            return "H2"
        case 3:
            return "OT"
        default:
            return "\(period - 2)OT"
        }
    }

    func isKeyPlay(_ playId: Int) -> Bool {
        keyPlayIds.contains(playId)
    }

    var blockStars: [String] {
        miniBox?.blockStars ?? []
    }

    func isBlockStar(_ name: String) -> Bool {
        miniBox?.isBlockStar(name) ?? false
    }
}
