//
//  KnownStatDefinitions.swift
//  ScrollDown
//
//  Stat definitions for basketball and hockey team stat displays.
//  Each KnownStat maps API key variants to a display label and group.
//

import Foundation

/// A stat the app knows how to display. Keys are tried in order against the API response.
struct KnownStat {
    let keys: [String]       // All possible API key names for this stat
    let label: String        // Human-readable display label
    let group: String        // Grouping: "Overview", "Shooting", "Extra"
    let isPercentage: Bool   // If true, value is 0-1 → format as "47.7%"
}

extension GameDetailViewModel {
    /// Ordered definitions for basketball (NBA + NCAAB) team stats.
    static let basketballKnownStats: [KnownStat] = [
        // Overview
        KnownStat(keys: ["points.total", "points", "pts"], label: "Points", group: "Overview", isPercentage: false),
        KnownStat(keys: ["rebounds.total", "trb", "reb", "rebounds", "totalRebounds", "total_rebounds"], label: "Rebounds", group: "Overview", isPercentage: false),
        KnownStat(keys: ["rebounds.offensive", "orb", "offReb", "offensiveRebounds", "offensive_rebounds"], label: "Off Reb", group: "Overview", isPercentage: false),
        KnownStat(keys: ["rebounds.defensive", "drb", "defReb", "defensiveRebounds", "defensive_rebounds"], label: "Def Reb", group: "Overview", isPercentage: false),
        KnownStat(keys: ["ast", "assists"], label: "Assists", group: "Overview", isPercentage: false),
        KnownStat(keys: ["stl", "steals"], label: "Steals", group: "Overview", isPercentage: false),
        KnownStat(keys: ["blk", "blocks"], label: "Blocks", group: "Overview", isPercentage: false),
        KnownStat(keys: ["turnovers.total", "tov", "turnovers", "to"], label: "Turnovers", group: "Overview", isPercentage: false),
        KnownStat(keys: ["fouls.total", "pf", "personalFouls", "personal_fouls", "fouls"], label: "Fouls", group: "Overview", isPercentage: false),

        // Shooting
        KnownStat(keys: ["fieldGoals.made", "fg", "fgm", "fg_made", "fgMade", "fieldGoalsMade", "field_goals_made"], label: "FG Made", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["fieldGoals.attempted", "fga", "fg_attempted", "fgAttempted", "fieldGoalsAttempted", "field_goals_attempted"], label: "FG Att", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["fieldGoals.pct", "fg_pct", "fgPct", "fg_percentage", "fieldGoalPct", "field_goal_pct"], label: "FG%", group: "Shooting", isPercentage: true),
        KnownStat(keys: ["threePointFieldGoals.made", "fg3", "fg3m", "fg3Made", "three_made", "threePointersMade", "three_pointers_made", "threePointFieldGoalsMade"], label: "3PT Made", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["threePointFieldGoals.attempted", "fg3a", "fg3Attempted", "three_attempted", "threePointersAttempted", "three_pointers_attempted", "threePointFieldGoalsAttempted"], label: "3PT Att", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["threePointFieldGoals.pct", "fg3_pct", "fg3Pct", "threePtPct", "three_pct", "three_pt_pct", "fg3_percentage"], label: "3PT%", group: "Shooting", isPercentage: true),
        KnownStat(keys: ["freeThrows.made", "ft", "ftm", "ft_made", "ftMade", "freeThrowsMade", "free_throws_made"], label: "FT Made", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["freeThrows.attempted", "fta", "ft_attempted", "ftAttempted", "freeThrowsAttempted", "free_throws_attempted"], label: "FT Att", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["freeThrows.pct", "ft_pct", "ftPct", "freeThrowPct", "free_throw_pct", "ft_percentage"], label: "FT%", group: "Shooting", isPercentage: true),
        KnownStat(keys: ["twoPointFieldGoals.made", "fg2", "fg2m", "fg2_made", "fg2Made", "twoPointFieldGoalsMade", "two_point_field_goals_made"], label: "2PT Made", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["twoPointFieldGoals.attempted", "fg2a", "fg2_attempted", "fg2Attempted", "twoPointFieldGoalsAttempted", "two_point_field_goals_attempted"], label: "2PT Att", group: "Shooting", isPercentage: false),
        KnownStat(keys: ["twoPointFieldGoals.pct", "fg2_pct", "fg2Pct", "twoPtPct", "two_pt_pct", "fg2_percentage"], label: "2PT%", group: "Shooting", isPercentage: true),

        // Extra
        KnownStat(keys: ["points.fastBreak", "fast_break_points", "fastBreakPoints"], label: "Fast Break Pts", group: "Extra", isPercentage: false),
        KnownStat(keys: ["points.inPaint", "points_in_paint", "pointsInPaint", "paint_points", "paintPoints"], label: "Paint Pts", group: "Extra", isPercentage: false),
        KnownStat(keys: ["points.offTurnovers", "points_off_turnovers", "pointsOffTurnovers"], label: "Pts off TO", group: "Extra", isPercentage: false),
        KnownStat(keys: ["second_chance_points", "secondChancePoints"], label: "2nd Chance Pts", group: "Extra", isPercentage: false),
        KnownStat(keys: ["bench_points", "benchPoints"], label: "Bench Pts", group: "Extra", isPercentage: false),
        KnownStat(keys: ["points.largestLead", "biggest_lead", "biggestLead", "largest_lead", "largestLead"], label: "Biggest Lead", group: "Extra", isPercentage: false),
        KnownStat(keys: ["lead_changes", "leadChanges"], label: "Lead Changes", group: "Extra", isPercentage: false),
        KnownStat(keys: ["times_tied", "timesTied"], label: "Times Tied", group: "Extra", isPercentage: false),
        KnownStat(keys: ["possessions", "poss"], label: "Possessions", group: "Extra", isPercentage: false),
        KnownStat(keys: ["trueShooting", "true_shooting_pct", "trueShootingPct", "ts_pct", "tsPct"], label: "TS%", group: "Extra", isPercentage: true),
    ]

    /// Ordered definitions for NHL team stats.
    static let nhlKnownStats: [KnownStat] = [
        KnownStat(keys: ["shots_on_goal", "shotsOnGoal", "sog"], label: "Shots on Goal", group: "Offense", isPercentage: false),
        KnownStat(keys: ["points", "pts"], label: "Points", group: "Offense", isPercentage: false),
        KnownStat(keys: ["ast", "assists"], label: "Assists", group: "Offense", isPercentage: false),
        KnownStat(keys: ["penalty_minutes", "penaltyMinutes", "pim"], label: "Penalty Minutes", group: "Discipline", isPercentage: false),
    ]
}
