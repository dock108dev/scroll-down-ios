import Foundation
struct PeriodLabelInput: Equatable {
    let sport: Sport
    let leagueCode: String
    let periodOrdinal: Int?
    let periodLabel: String?
    let clockLabel: String?
    let presentationTimeLabel: String?
}
struct PeriodLabelOutput: Equatable {
    let groupLabel: String?
    let groupKey: String
    let rowClockText: String
    let combinedText: String?
    let situationText: String?
    let resumeText: String?
}
enum PeriodLabelFormatter {
    static func output(
        sport: Sport,
        leagueCode: String,
        periodOrdinal: Int?,
        periodLabel: String?,
        clockLabel: String?,
        presentationTimeLabel: String? = nil
    ) -> PeriodLabelOutput {
        output(
            PeriodLabelInput(
                sport: sport,
                leagueCode: leagueCode,
                periodOrdinal: periodOrdinal,
                periodLabel: periodLabel,
                clockLabel: clockLabel,
                presentationTimeLabel: presentationTimeLabel
            )
        )
    }
    static func output(_ input: PeriodLabelInput) -> PeriodLabelOutput {
        let canonical = canonicalPeriod(from: input)
        let rawClock = input.presentationTimeLabel.cleanPeriodInput ?? input.clockLabel.cleanPeriodInput
        let rowClockText = rowClockText(rawClock: rawClock, canonical: canonical)
        let combinedText = combinedText(canonical: canonical, rowClockText: rowClockText, rawClock: rawClock)
        let situationText = situationText(sport: input.sport, canonical: canonical, rowClockText: rowClockText, rawClock: rawClock)

        return PeriodLabelOutput(
            groupLabel: canonical?.displayLabel,
            groupKey: canonical?.key ?? "period:game",
            rowClockText: rowClockText,
            combinedText: combinedText,
            situationText: situationText,
            resumeText: combinedText
        )
    }
    private static func canonicalPeriod(from input: PeriodLabelInput) -> CanonicalPeriod? {
        switch input.sport {
        case .mlb:
            return baseballPeriod(from: input)
        case .nba, .nfl:
            return quarterPeriod(from: input)
        case .nhl:
            return hockeyPeriod(from: input)
        case .soccer:
            return soccerPeriod(from: input)
        case .golf, .tennis, .other:
            return genericPeriod(from: input)
        }
    }
    private static func baseballPeriod(from input: PeriodLabelInput) -> CanonicalPeriod? {
        let parsed = [
            parseBaseballInning(input.periodLabel),
            parseBaseballInning(input.clockLabel),
            parseBaseballInning(input.presentationTimeLabel)
        ].compactMap(\.self).first
        let inning = parsed?.inning ?? input.periodOrdinal
        guard let inning else { return genericPeriod(from: input) }
        let half = parsed?.half
        let label: String
        switch half {
        case .top:
            label = "Top \(ordinal(inning))"
        case .bottom:
            label = "Bottom \(ordinal(inning))"
        case nil:
            label = ordinal(inning)
        }
        let halfKey = half?.rawValue ?? "unknown"
        let aliases = baseballAliases(inning: inning, half: half)
        return CanonicalPeriod(
            displayLabel: label,
            key: "mlb:inning:\(inning):\(halfKey)",
            aliases: aliases,
            compactLabel: half.map { "\($0.compactPrefix)\(inning)" } ?? ordinal(inning)
        )
    }
    private static func quarterPeriod(from input: PeriodLabelInput) -> CanonicalPeriod? {
        let period = [
            parseQuarter(input.periodLabel),
            parseQuarter(input.clockLabel),
            parseQuarter(input.presentationTimeLabel),
            input.periodOrdinal
        ].compactMap(\.self).first
        guard let period else { return genericPeriod(from: input) }
        let label: String
        if period <= 4 {
            label = "Q\(period)"
        } else if period == 5 {
            label = "OT"
        } else {
            label = "\(period - 4)OT"
        }
        return CanonicalPeriod(
            displayLabel: label,
            key: "\(input.leagueCode.periodKeyPrefix):period:\(period)",
            aliases: quarterAliases(period: period)
        )
    }
    private static func hockeyPeriod(from input: PeriodLabelInput) -> CanonicalPeriod? {
        let period = [
            parseHockey(input.periodLabel),
            parseHockey(input.clockLabel),
            parseHockey(input.presentationTimeLabel),
            input.periodOrdinal
        ].compactMap(\.self).first
        guard let period else { return genericPeriod(from: input) }
        let label: String
        if period == 4 {
            label = "OT"
        } else if period >= 5 {
            label = "SO"
        } else {
            label = ordinal(period)
        }
        return CanonicalPeriod(
            displayLabel: label,
            key: "nhl:period:\(period)",
            aliases: hockeyAliases(period: period)
        )
    }
    private static func soccerPeriod(from input: PeriodLabelInput) -> CanonicalPeriod? {
        let explicit = parseSoccerPeriod(input.periodLabel) ?? input.periodOrdinal.flatMap(soccerPeriodFromOrdinal)
        let minute = parseSoccerMinute(input.clockLabel) ?? parseSoccerMinute(input.presentationTimeLabel)

        if let explicit {
            return CanonicalPeriod(
                displayLabel: explicit.label,
                key: explicit.key,
                aliases: explicit.aliases
            )
        }

        if let minute {
            let inferred = soccerPeriodFromMinute(minute.minute)
            return CanonicalPeriod(
                displayLabel: inferred.label,
                key: inferred.key,
                aliases: inferred.aliases
            )
        }

        return genericPeriod(from: input)
    }
    private static func genericPeriod(from input: PeriodLabelInput) -> CanonicalPeriod? {
        if let periodLabel = input.periodLabel.cleanPeriodInput {
            return CanonicalPeriod(
                displayLabel: periodLabel,
                key: "period:\(periodLabel.normalizedPeriodAliasKey)",
                aliases: [periodLabel]
            )
        }
        if let periodOrdinal = input.periodOrdinal {
            let label = "Period \(periodOrdinal)"
            return CanonicalPeriod(
                displayLabel: label,
                key: "period:\(input.leagueCode.periodKeyPrefix):\(periodOrdinal)",
                aliases: [label, String(periodOrdinal)]
            )
        }
        return nil
    }
    private static func rowClockText(rawClock: String?, canonical: CanonicalPeriod?) -> String {
        guard let rawClock else { return "" }
        guard let canonical else { return rawClock }

        let soccerMinute = parseSoccerMinute(rawClock)?.displayLabel
        let aliases = canonical.aliases.map(\.normalizedPeriodAliasKey)
        var remainder = rawClock

        var removedPrefix = true
        while removedPrefix {
            removedPrefix = false
            for alias in aliases.sorted(by: { $0.count > $1.count }) {
                if let stripped = remainder.strippingPrefix(aliasKey: alias) {
                    remainder = stripped.cleanPeriodInput ?? ""
                    removedPrefix = true
                    break
                }
            }
        }

        if let soccerMinute, remainder.normalizedPeriodAliasKey == rawClock.normalizedPeriodAliasKey {
            return soccerMinute
        }
        return remainder.cleanPeriodInput ?? ""
    }
    private static func combinedText(canonical: CanonicalPeriod?, rowClockText: String, rawClock: String?) -> String? {
        guard let canonical else { return rawClock }
        guard !rowClockText.isEmpty else { return canonical.displayLabel }
        if rowClockText.normalizedPeriodAliasKey == canonical.displayLabel.normalizedPeriodAliasKey {
            return canonical.displayLabel
        }
        return "\(canonical.displayLabel) · \(rowClockText)"
    }
    private static func situationText(sport: Sport, canonical: CanonicalPeriod?, rowClockText: String, rawClock: String?) -> String? {
        guard let canonical else { return rawClock }
        if case .soccer = sport, !rowClockText.isEmpty {
            return rowClockText
        }
        if case .mlb = sport {
            guard !rowClockText.isEmpty else { return canonical.displayLabel }
            if rowClockText.normalizedPeriodAliasKey == canonical.displayLabel.normalizedPeriodAliasKey {
                return canonical.displayLabel
            }
            return "\(canonical.displayLabel) \(rowClockText)"
        }
        let label = canonical.compactLabel ?? canonical.displayLabel
        guard !rowClockText.isEmpty else { return label }
        if rowClockText.normalizedPeriodAliasKey == label.normalizedPeriodAliasKey {
            return label
        }
        return "\(label) \(rowClockText)"
    }
    private static func parseBaseballInning(_ value: String?) -> (inning: Int, half: InningHalf?)? {
        guard let raw = value.cleanPeriodInput else { return nil }
        let lower = raw.lowercased()

        if lower.count > 1 {
            let marker = lower[lower.startIndex]
            let digits = String(lower.dropFirst()).leadingDigits
            if let inning = Int(digits), marker == "t" {
                return (inning, .top)
            }
            if let inning = Int(digits), marker == "b" {
                return (inning, .bottom)
            }
        }

        let half: InningHalf?
        if lower.hasPrefix("top") || lower.contains(" top ") {
            half = .top
        } else if lower.hasPrefix("bot") || lower.hasPrefix("bottom") || lower.contains(" bottom ") {
            half = .bottom
        } else {
            half = nil
        }

        guard let inning = raw.firstInteger else { return nil }
        return (inning, half)
    }
    private static func parseQuarter(_ value: String?) -> Int? {
        guard let raw = value.cleanPeriodInput else { return nil }
        let lower = raw.lowercased()
        let compact = lower.replacingOccurrences(of: " ", with: "")

        if compact == "ot" || compact == "overtime" || compact == "1ot" { return 5 }
        if compact == "2ot" || lower == "double ot" { return 6 }
        if let first = lower.first, first == "q", let period = Int(String(lower.dropFirst()).leadingDigits) {
            return period
        }
        if compact.hasSuffix("q"), let period = Int(String(compact.dropLast()).leadingDigits) {
            return period
        }
        if lower.contains("first") { return 1 }
        if lower.contains("second") { return 2 }
        if lower.contains("third") { return 3 }
        if lower.contains("fourth") { return 4 }
        guard lower.contains("quarter") || lower.contains("q") else { return nil }
        return raw.firstInteger
    }
    private static func parseHockey(_ value: String?) -> Int? {
        guard let raw = value.cleanPeriodInput else { return nil }
        let lower = raw.lowercased()
        let compact = lower.replacingOccurrences(of: " ", with: "")

        if compact == "ot" || compact == "overtime" { return 4 }
        if compact == "so" || compact == "shootout" { return 5 }
        if lower.hasPrefix("p"), let period = Int(String(lower.dropFirst()).leadingDigits) {
            return period
        }
        if lower.contains("period") || ["1st", "2nd", "3rd"].contains(where: lower.hasPrefix) {
            return raw.firstInteger
        }
        return nil
    }
    private static func parseSoccerPeriod(_ value: String?) -> SoccerPeriod? {
        guard let raw = value.cleanPeriodInput else { return nil }
        let lower = raw.lowercased()
        if lower.contains("penalt") {
            return soccerPeriod(label: "Penalties", key: "soccer:period:penalties", aliases: ["Penalties", "Penalty Kicks"])
        }
        if lower.contains("extra") {
            return soccerPeriod(label: "Extra Time", key: "soccer:period:extra-time", aliases: ["Extra Time", "ET"])
        }
        if lower.contains("1st half") || lower.contains("first half") {
            return soccerPeriod(label: "1st Half", key: "soccer:half:1", aliases: ["1st Half", "First Half"])
        }
        if lower.contains("2nd half") || lower.contains("second half") {
            return soccerPeriod(label: "2nd Half", key: "soccer:half:2", aliases: ["2nd Half", "Second Half"])
        }
        return nil
    }
    private static func soccerPeriodFromOrdinal(_ ordinal: Int) -> SoccerPeriod? {
        switch ordinal {
        case 1:
            return soccerPeriod(label: "1st Half", key: "soccer:half:1", aliases: ["1st Half", "First Half"])
        case 2:
            return soccerPeriod(label: "2nd Half", key: "soccer:half:2", aliases: ["2nd Half", "Second Half"])
        case 3:
            return soccerPeriod(label: "Extra Time", key: "soccer:period:extra-time", aliases: ["Extra Time", "ET"])
        case 4:
            return soccerPeriod(label: "Penalties", key: "soccer:period:penalties", aliases: ["Penalties", "Penalty Kicks"])
        default:
            return nil
        }
    }
    private static func soccerPeriodFromMinute(_ minute: Int) -> SoccerPeriod {
        if minute <= 45 {
            return soccerPeriod(label: "1st Half", key: "soccer:half:1", aliases: ["1st Half", "First Half"])
        }
        if minute <= 90 {
            return soccerPeriod(label: "2nd Half", key: "soccer:half:2", aliases: ["2nd Half", "Second Half"])
        }
        return soccerPeriod(label: "Extra Time", key: "soccer:period:extra-time", aliases: ["Extra Time", "ET"])
    }
    private static func soccerPeriod(label: String, key: String, aliases: Set<String>) -> SoccerPeriod {
        SoccerPeriod(label: label, key: key, aliases: aliases)
    }
    private static func parseSoccerMinute(_ value: String?) -> SoccerMinute? {
        guard let raw = value.cleanPeriodInput else { return nil }
        let compact = raw
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "'", with: "")
        let parts = compact.split(separator: "+", maxSplits: 1).map(String.init)
        guard let minute = Int(parts[0]), minute >= 0 else { return nil }
        let stoppage = parts.count > 1 ? Int(parts[1]) : nil
        return SoccerMinute(minute: minute, stoppage: stoppage)
    }
    private static func baseballAliases(inning: Int, half: InningHalf?) -> Set<String> {
        let ordinal = ordinal(inning)
        switch half {
        case .top:
            return ["T\(inning)", "Top \(inning)", "Top \(ordinal)", "Top of \(ordinal)", "Top of the \(ordinal)"]
        case .bottom:
            return ["B\(inning)", "Bot \(inning)", "Bottom \(inning)", "Bot \(ordinal)", "Bottom \(ordinal)", "Bottom of \(ordinal)", "Bottom of the \(ordinal)"]
        case nil:
            return [String(inning), ordinal]
        }
    }
    private static func quarterAliases(period: Int) -> Set<String> {
        if period <= 4 {
            return ["Q\(period)", "\(period)Q", ordinal(period), "\(ordinal(period)) Quarter", "Quarter \(period)"]
        }
        if period == 5 {
            return ["OT", "Overtime", "1OT"]
        }
        return ["\(period - 4)OT", "\(period - 4) Overtime"]
    }
    private static func hockeyAliases(period: Int) -> Set<String> {
        if period == 4 {
            return ["OT", "Overtime"]
        }
        if period >= 5 {
            return ["SO", "Shootout"]
        }
        return [String(period), ordinal(period), "\(ordinal(period)) Period", "Period \(period)", "P\(period)"]
    }
    private static func ordinal(_ value: Int) -> String {
        let suffix: String
        if (11...13).contains(value % 100) {
            suffix = "th"
        } else {
            switch value % 10 {
            case 1:
                suffix = "st"
            case 2:
                suffix = "nd"
            case 3:
                suffix = "rd"
            default:
                suffix = "th"
            }
        }
        return "\(value)\(suffix)"
    }
}
private struct CanonicalPeriod {
    let displayLabel: String
    let key: String
    let aliases: Set<String>
    let compactLabel: String?

    init(displayLabel: String, key: String, aliases: Set<String>, compactLabel: String? = nil) {
        self.displayLabel = displayLabel
        self.key = key
        self.aliases = aliases
        self.compactLabel = compactLabel
    }
}
private enum InningHalf: String {
    case top
    case bottom

    var compactPrefix: String { self == .top ? "T" : "B" }
}
private struct SoccerPeriod {
    let label: String
    let key: String
    let aliases: Set<String>
}
private struct SoccerMinute {
    let minute: Int
    let stoppage: Int?

    var displayLabel: String {
        if let stoppage {
            return "\(minute)'+\(stoppage)'"
        }
        return "\(minute)'"
    }
}
private extension Optional where Wrapped == String {
    var cleanPeriodInput: String? {
        self?.cleanPeriodInput
    }
}
private extension String {
    var cleanPeriodInput: String? {
        if let soccerMinute = PeriodLabelFormatter.outputSoccerMinuteDisplayForCleaning(self) {
            return soccerMinute
        }
        return cleanDisplayLabel
    }
    var firstInteger: Int? {
        let match = range(of: #"\d+"#, options: .regularExpression)
        return match.map { Int(self[$0]) } ?? nil
    }
    var leadingDigits: String {
        String(prefix(while: \.isNumber))
    }
    var normalizedPeriodAliasKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: " of the ", with: " ")
            .replacingOccurrences(of: " of ", with: " ")
            .replacingOccurrences(of: "'", with: "")
            .lowercased()
    }
    func strippingPrefix(aliasKey: String) -> String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.normalizedPeriodAliasKey

        guard normalized == aliasKey || normalized.hasPrefix(aliasKey + " ") else {
            return nil
        }

        if normalized == aliasKey {
            return ""
        }

        var remainder = trimmed
        let rawTokens = trimmed.split(separator: " ", omittingEmptySubsequences: false)
        for tokenCount in stride(from: rawTokens.count, through: 1, by: -1) {
            let candidate = rawTokens.prefix(tokenCount).joined(separator: " ")
            if candidate.normalizedPeriodAliasKey == aliasKey {
                remainder = rawTokens.dropFirst(tokenCount).joined(separator: " ")
                break
            }
        }
        return remainder.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var periodKeyPrefix: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.isEmpty ? "generic" : trimmed
    }
}

private extension PeriodLabelFormatter {
    static func outputSoccerMinuteDisplayForCleaning(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let compact = trimmed
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "'", with: "")
        let parts = compact.split(separator: "+", maxSplits: 1).map(String.init)
        guard let minute = parts.first.flatMap(Int.init), minute >= 0 else { return nil }
        if parts.count == 2, let stoppage = Int(parts[1]) {
            return "\(minute)'+\(stoppage)'"
        }
        guard trimmed.contains("'") else { return nil }
        return "\(minute)'"
    }
}
