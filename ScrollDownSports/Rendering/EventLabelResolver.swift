import Foundation

enum EventLabelResolver {
    static func customerLabel(from value: String?) -> String? {
        guard let normalized = normalize(value) else { return nil }
        let key = normalized.uppercased()

        if let mapped = knownRawLabelMap[key] {
            return mapped
        }
        if suppressedRawLabels.contains(key) || isRawEnumLabel(normalized) {
            return nil
        }
        return normalized
    }

    static func customerHeadline(
        presentationHeadline: String?,
        presentationBody: String?,
        description: String?,
        displayType: String?
    ) -> String {
        [
            customerText(from: presentationHeadline),
            customerText(from: presentationBody),
            customerText(from: description),
            customerLabel(from: displayType)
        ].firstNonBlank ?? "Game update"
    }

    static func customerAccessibilityText(preferred: String?, fallbackPieces: [String?]) -> String? {
        if let preferred = customerText(from: preferred) {
            return preferred
        }
        let fallback = fallbackPieces.compactMap(customerText(from:)).joined(separator: ". ")
        return fallback.nilIfBlank ?? "Game update"
    }

    static func customerText(from value: String?) -> String? {
        guard let normalized = normalize(value) else { return nil }
        if let mapped = knownRawLabelMap[normalized.uppercased()] {
            return mapped
        }
        if suppressedRawLabels.contains(normalized.uppercased()) || isRawEnumLabel(normalized) {
            return nil
        }
        return normalized
    }

    static func isRawEnumLabel(_ value: String?) -> Bool {
        guard let normalized = normalize(value) else { return false }
        let upper = normalized.uppercased()

        if suppressedRawLabels.contains(upper) {
            return true
        }
        if normalized.contains("_") {
            return true
        }

        let allowedShortLabels: Set<String> = ["Q1", "Q2", "Q3", "Q4", "OT", "PK", "FG", "PAT"]
        let hasLetter = normalized.rangeOfCharacter(from: .letters) != nil
        return hasLetter
            && normalized.count > 3
            && normalized == upper
            && !allowedShortLabels.contains(upper)
    }

    private static func normalize(_ value: String?) -> String? {
        value?.nilIfBlank
    }

    private static let suppressedRawLabels: Set<String> = [
        "PLAY",
        "GAME_UPDATE",
        "UNKNOWN",
        "EVENT",
        "UPDATE"
    ]

    private static let knownRawLabelMap: [String: String] = [
        "PERIOD_START": "Period start",
        "PERIOD_END": "Period end",
        "TIMEOUT": "Timeout",
        "CHALLENGE": "Challenge",
        "REVIEW": "Review",
        "PENALTY": "Penalty",
        "INJURY": "Injury",
        "HOME_RUN": "Home run",
        "SINGLE": "Single",
        "DOUBLE": "Double",
        "TRIPLE": "Triple",
        "WALK": "Walk",
        "INTENTIONAL_WALK": "Intentional walk",
        "STRIKEOUT": "Strikeout",
        "FIELD_OUT": "Out",
        "FORCE_OUT": "Force out",
        "GROUND_OUT": "Ground out",
        "FLY_OUT": "Fly out",
        "LINE_OUT": "Line out",
        "POP_OUT": "Pop out",
        "DOUBLE_PLAY": "Double play",
        "TRIPLE_PLAY": "Triple play",
        "ERROR": "Error",
        "STOLEN_BASE": "Stolen base",
        "CAUGHT_STEALING": "Caught stealing",
        "WILD_PITCH": "Wild pitch",
        "PASSED_BALL": "Passed ball",
        "HIT_BY_PITCH": "Hit by pitch",
        "SAC_FLY": "Sacrifice fly",
        "SAC_BUNT": "Sacrifice bunt",
        "PICKOFF": "Pickoff",
        "PITCHING_CHANGE": "Pitching change",
        "JUMP_BALL": "Jump ball",
        "MADE_SHOT": "Made shot",
        "MISSED_SHOT": "Missed shot",
        "TWO_POINT_MADE": "2-pointer",
        "TWO_POINT_MISS": "Missed 2-pointer",
        "THREE_POINT_MADE": "3-pointer",
        "THREE_POINT_MISS": "Missed 3-pointer",
        "FREE_THROW_MADE": "Free throw",
        "FREE_THROW_MISS": "Missed free throw",
        "REBOUND": "Rebound",
        "ASSIST": "Assist",
        "STEAL": "Steal",
        "BLOCK": "Block",
        "TURNOVER": "Turnover",
        "FOUL": "Foul",
        "TECHNICAL_FOUL": "Technical foul",
        "FLAGRANT_FOUL": "Flagrant foul",
        "SUBSTITUTION": "Substitution",
        "GOAL": "Goal",
        "SHOT": "Shot",
        "SHOT_ON_GOAL": "Shot on goal",
        "BLOCKED_SHOT": "Blocked shot",
        "SAVE": "Save",
        "FACE_OFF": "Faceoff",
        "HIT": "Hit",
        "GIVEAWAY": "Giveaway",
        "TAKEAWAY": "Takeaway",
        "POWER_PLAY": "Power play",
        "SHORT_HANDED_GOAL": "Short-handed goal",
        "EMPTY_NET_GOAL": "Empty-net goal",
        "PENALTY_SHOT": "Penalty shot",
        "SHOOTOUT_GOAL": "Shootout goal",
        "SHOOTOUT_MISS": "Shootout miss",
        "TOUCHDOWN": "Touchdown",
        "FIELD_GOAL_GOOD": "Field goal",
        "FIELD_GOAL_MISSED": "Missed field goal",
        "EXTRA_POINT_GOOD": "Extra point",
        "EXTRA_POINT_MISSED": "Missed extra point",
        "TWO_POINT_CONVERSION": "2-point conversion",
        "PASS_COMPLETE": "Complete pass",
        "PASS_INCOMPLETE": "Incomplete pass",
        "RUSH": "Run",
        "SACK": "Sack",
        "INTERCEPTION": "Interception",
        "FUMBLE": "Fumble",
        "FUMBLE_RECOVERY": "Fumble recovery",
        "PUNT": "Punt",
        "KICKOFF": "Kickoff",
        "PENALTY_ACCEPTED": "Penalty",
        "PENALTY_DECLINED": "Declined penalty",
        "SAFETY": "Safety",
        "TURNOVER_ON_DOWNS": "Turnover on downs",
        "SHOT_ON_TARGET": "Shot on target",
        "MISS": "Miss",
        "CORNER_KICK": "Corner",
        "FREE_KICK": "Free kick",
        "PENALTY_KICK": "Penalty kick",
        "YELLOW_CARD": "Yellow card",
        "RED_CARD": "Red card",
        "OFFSIDE": "Offside",
        "VAR_REVIEW": "Review"
    ]
}

private extension Array where Element == String? {
    var firstNonBlank: String? {
        for value in self {
            if let trimmed = value?.nilIfBlank {
                return trimmed
            }
        }
        return nil
    }
}
