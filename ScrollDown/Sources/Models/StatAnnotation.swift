import Foundation

/// Generates contextual annotations for team stats that explain why stats mattered
/// All annotations are factual, neutral, and derived from existing data only
enum StatAnnotationGenerator {

    /// Generate an annotation for a specific stat, using context from all available stats
    /// Returns nil if no meaningful insight exists (silence is preferred)
    static func annotation(
        for stat: TeamComparisonStat,
        allStats: [TeamComparisonStat],
        homeAbbrev: String,
        awayAbbrev: String
    ) -> String? {
        switch stat.name {
        case "Offensive Rebounds":
            return offensiveReboundsAnnotation(stat, allStats: allStats, homeAbbrev: homeAbbrev, awayAbbrev: awayAbbrev)

        case "Turnovers":
            return turnoversAnnotation(stat, allStats: allStats, homeAbbrev: homeAbbrev, awayAbbrev: awayAbbrev)

        case "Assists":
            return assistsAnnotation(stat, homeAbbrev: homeAbbrev, awayAbbrev: awayAbbrev)

        case "Total Rebounds", "Defensive Rebounds":
            return reboundsAnnotation(stat, homeAbbrev: homeAbbrev, awayAbbrev: awayAbbrev)

        case "Steals":
            return stealsAnnotation(stat, homeAbbrev: homeAbbrev, awayAbbrev: awayAbbrev)

        case "Blocks":
            return blocksAnnotation(stat, homeAbbrev: homeAbbrev, awayAbbrev: awayAbbrev)

        case "Personal Fouls":
            return foulsAnnotation(stat, allStats: allStats, homeAbbrev: homeAbbrev, awayAbbrev: awayAbbrev)

        case "Free Throws Made":
            return freeThrowsAnnotation(stat, allStats: allStats, homeAbbrev: homeAbbrev, awayAbbrev: awayAbbrev)

        case "Field Goal %":
            return fieldGoalAnnotation(stat, homeAbbrev: homeAbbrev, awayAbbrev: awayAbbrev)

        case "3-Point %":
            return threePointAnnotation(stat, allStats: allStats, homeAbbrev: homeAbbrev, awayAbbrev: awayAbbrev)

        default:
            return nil
        }
    }

    // MARK: - Offensive Rebounds

    private static func offensiveReboundsAnnotation(
        _ stat: TeamComparisonStat,
        allStats: [TeamComparisonStat],
        homeAbbrev: String,
        awayAbbrev: String
    ) -> String? {
        guard let home = stat.homeValue, let away = stat.awayValue else { return nil }
        let diff = abs(home - away)

        // Trigger: OREB differential >= 5
        guard diff >= 5 else { return nil }

        let leader = home > away ? homeAbbrev : awayAbbrev
        let extraPossessions = Int(diff)

        // Check if we have second chance points (would need to be in stats)
        // For now, use possessions language
        return "+\(extraPossessions) extra possessions for \(leader)"
    }

    // MARK: - Turnovers

    private static func turnoversAnnotation(
        _ stat: TeamComparisonStat,
        allStats: [TeamComparisonStat],
        homeAbbrev: String,
        awayAbbrev: String
    ) -> String? {
        guard let home = stat.homeValue, let away = stat.awayValue else { return nil }
        let diff = abs(home - away)

        // Turnovers are a negative stat - fewer is better
        if diff <= 2 {
            // Turnovers roughly even
            return nil
        }

        // More turnovers is bad, so the team with fewer had the advantage
        let betterTeam = home < away ? homeAbbrev : awayAbbrev
        let worseTeam = home < away ? awayAbbrev : homeAbbrev

        return "\(worseTeam) +\(Int(diff)) giveaways"
    }

    // MARK: - Assists

    private static func assistsAnnotation(
        _ stat: TeamComparisonStat,
        homeAbbrev: String,
        awayAbbrev: String
    ) -> String? {
        guard let home = stat.homeValue, let away = stat.awayValue else { return nil }
        let diff = abs(home - away)

        // Trigger: Assist differential >= 5
        guard diff >= 5 else { return nil }

        let leader = home > away ? homeAbbrev : awayAbbrev
        return "Ball movement favored \(leader)"
    }

    // MARK: - Rebounds (Total/Defensive)

    private static func reboundsAnnotation(
        _ stat: TeamComparisonStat,
        homeAbbrev: String,
        awayAbbrev: String
    ) -> String? {
        guard let home = stat.homeValue, let away = stat.awayValue else { return nil }
        let diff = abs(home - away)

        // Trigger: Total rebound differential >= 8
        guard diff >= 8 else { return nil }

        let leader = home > away ? homeAbbrev : awayAbbrev
        return "\(leader) controlled the glass"
    }

    // MARK: - Steals

    private static func stealsAnnotation(
        _ stat: TeamComparisonStat,
        homeAbbrev: String,
        awayAbbrev: String
    ) -> String? {
        guard let home = stat.homeValue, let away = stat.awayValue else { return nil }
        let diff = abs(home - away)

        // Trigger: Steal differential >= 3
        guard diff >= 3 else { return nil }

        let leader = home > away ? homeAbbrev : awayAbbrev
        return "Led to transition opportunities for \(leader)"
    }

    // MARK: - Blocks

    private static func blocksAnnotation(
        _ stat: TeamComparisonStat,
        homeAbbrev: String,
        awayAbbrev: String
    ) -> String? {
        guard let home = stat.homeValue, let away = stat.awayValue else { return nil }
        let diff = abs(home - away)

        // Trigger: Block differential >= 3
        guard diff >= 3 else { return nil }

        let leader = home > away ? homeAbbrev : awayAbbrev
        return "\(leader) rim protection limited paint scoring"
    }

    // MARK: - Personal Fouls

    private static func foulsAnnotation(
        _ stat: TeamComparisonStat,
        allStats: [TeamComparisonStat],
        homeAbbrev: String,
        awayAbbrev: String
    ) -> String? {
        // Check for FT attempt differential
        guard let ftStat = allStats.first(where: { $0.name == "Free Throws Made" }),
              let homeFT = ftStat.homeValue, let awayFT = ftStat.awayValue else {
            return nil
        }

        let ftDiff = abs(homeFT - awayFT)

        // Trigger: FT differential >= 6
        guard ftDiff >= 6 else { return nil }

        let beneficiary = homeFT > awayFT ? homeAbbrev : awayAbbrev
        return "\(beneficiary) +\(Int(ftDiff)) free throw attempts"
    }

    // MARK: - Free Throws

    private static func freeThrowsAnnotation(
        _ stat: TeamComparisonStat,
        allStats: [TeamComparisonStat],
        homeAbbrev: String,
        awayAbbrev: String
    ) -> String? {
        guard let home = stat.homeValue, let away = stat.awayValue else { return nil }
        let diff = abs(home - away)

        // Trigger: FTM differential >= 6
        guard diff >= 6 else { return nil }

        let leader = home > away ? homeAbbrev : awayAbbrev
        return "+\(Int(diff)) points from the line for \(leader)"
    }

    // MARK: - Field Goal %

    private static func fieldGoalAnnotation(
        _ stat: TeamComparisonStat,
        homeAbbrev: String,
        awayAbbrev: String
    ) -> String? {
        guard let home = stat.homeValue, let away = stat.awayValue else { return nil }

        // Convert from percentage display format if needed
        let homePct = home > 1 ? home : home * 100
        let awayPct = away > 1 ? away : away * 100
        let diff = abs(homePct - awayPct)

        // Trigger: FG% differential >= 8 percentage points
        guard diff >= 8 else { return nil }

        let leader = homePct > awayPct ? homeAbbrev : awayAbbrev
        return "\(leader) more efficient from the field"
    }

    // MARK: - 3-Point %

    private static func threePointAnnotation(
        _ stat: TeamComparisonStat,
        allStats: [TeamComparisonStat],
        homeAbbrev: String,
        awayAbbrev: String
    ) -> String? {
        guard let home = stat.homeValue, let away = stat.awayValue else { return nil }

        // Convert from percentage display format if needed
        let homePct = home > 1 ? home : home * 100
        let awayPct = away > 1 ? away : away * 100
        let diff = abs(homePct - awayPct)

        // Trigger: 3P% differential >= 10 percentage points
        guard diff >= 10 else { return nil }

        // Check 3PM for volume context
        if let threePM = allStats.first(where: { $0.name == "3-Pointers Made" }),
           let home3PM = threePM.homeValue, let away3PM = threePM.awayValue {
            let leader = homePct > awayPct ? homeAbbrev : awayAbbrev
            let leaderMakes = homePct > awayPct ? Int(home3PM) : Int(away3PM)

            if leaderMakes >= 10 {
                return "\(leader) hot from deep (\(leaderMakes) threes)"
            }
        }

        let leader = homePct > awayPct ? homeAbbrev : awayAbbrev
        return "\(leader) shot better from three"
    }
}
