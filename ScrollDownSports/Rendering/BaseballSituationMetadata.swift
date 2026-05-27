import Foundation

extension BaseballRenderer {
    func baseballPrePitchState(for event: GameEvent) -> BaseballPrePitchState {
        if let situationBefore = event.situationBefore {
            return firstClassBaseballPrePitchState(from: situationBefore)
        }

        let explicitMetadata = explicitPrePitchMetadata(from: event.sportMetadata)
        let genericMetadata = hasExplicitPreEventTiming(in: event.sportMetadata) ? event.sportMetadata : [:]
        let baseState = baseballBaseState(from: explicitMetadata)
            ?? baseballBaseState(from: genericMetadata)
        let outs = outsCount(from: explicitMetadata)
            ?? outsCount(from: genericMetadata)
        let count = pitchCount(from: explicitMetadata)
            ?? pitchCount(from: genericMetadata)
        let explicitPeriod = inningState(from: explicitMetadata)
        let genericPeriod = inningState(from: genericMetadata)
        let eventPeriod = inningState(from: event.periodLabel)
        let presentationPeriod = inningState(from: event.presentation?.timeLabel)
        let period = BaseballInningState(
            inning: explicitPeriod.inning ?? genericPeriod.inning ?? eventPeriod.inning ?? presentationPeriod.inning,
            inningHalf: explicitPeriod.inningHalf ?? genericPeriod.inningHalf ?? eventPeriod.inningHalf ?? presentationPeriod.inningHalf
        )
        var battingTeam = battingTeam(from: explicitMetadata) ?? battingTeam(from: genericMetadata)
        if battingTeam == nil, let inningHalf = period.inningHalf {
            battingTeam = BaseballBattingTeam(side: inningHalf == .top ? .away : .home)
        }
        let confidence = sourceConfidence(
            explicitMetadata: explicitMetadata,
            genericMetadata: genericMetadata,
            hasDerivedPeriod: eventPeriod.inning != nil || eventPeriod.inningHalf != nil
                || presentationPeriod.inning != nil || presentationPeriod.inningHalf != nil,
            originalMetadata: event.sportMetadata
        )

        return BaseballPrePitchState(
            baseState: baseState,
            outs: outs,
            inning: period.inning,
            inningHalf: period.inningHalf,
            count: count,
            battingTeam: battingTeam,
            sourceConfidence: confidence
        )
    }

    func baseballBaseState(from metadata: [String: JSONValue], allowGenericKeys: Bool) -> BaseballBaseState? {
        let acceptedMetadata = allowGenericKeys ? metadata : explicitPrePitchMetadata(from: metadata)
        return baseballBaseState(from: acceptedMetadata)
    }

    func outsCount(for event: GameEvent, allowGenericKeys: Bool) -> Int? {
        let acceptedMetadata = allowGenericKeys ? event.sportMetadata : explicitPrePitchMetadata(from: event.sportMetadata)
        if let outs = outsCount(from: acceptedMetadata) {
            return outs
        }
        guard allowGenericKeys else { return nil }
        return outsCount(fromClockLabel: event.clockLabel)
    }

    func countValue(from metadata: [String: JSONValue], allowGenericKeys: Bool) -> String? {
        let acceptedMetadata = allowGenericKeys ? metadata : explicitPrePitchMetadata(from: metadata)
        return pitchCount(from: acceptedMetadata)?.label
    }

    func hasExplicitPreEventTiming(in metadata: [String: JSONValue]) -> Bool {
        guard let timing = situationMetadataText(
            ["situationTiming", "stateTiming", "timing", "metadataTiming", "sourceTiming"],
            in: metadata
        ).map(normalizedSituationMetadataKey) else {
            return false
        }
        return [
            "before", "before_play", "pre_event", "pre_play", "pre_pitch",
            "preplay", "prepitch", "situation_before"
        ].contains(timing)
    }

    func hasDerivedBaseballState(
        for event: GameEvent,
        battingOwnership: GameEventSituationOwnership?
    ) -> Bool {
        outsCount(fromClockLabel: event.clockLabel) != nil
            || battingOwnership?.confidence == .derivedFromPeriod
            || battingOwnership?.confidence == .eventFallback
    }

    func hasAmbiguousBaseballMetadata(_ metadata: [String: JSONValue]) -> Bool {
        !hasExplicitPreEventTiming(in: metadata)
            && containsMetadataValue(
                genericBaseStateKeys + genericOutsKeys + genericCountTextKeys + genericBallCountKeys + genericStrikeCountKeys,
                in: metadata
            )
    }

    private func explicitPrePitchMetadata(from metadata: [String: JSONValue]) -> [String: JSONValue] {
        var explicit: [String: JSONValue] = [:]
        for key in explicitContainerKeys {
            if case .object(let nested)? = situationMetadataValue(for: key, in: metadata) {
                explicit.merge(nested) { current, _ in current }
            }
        }
        for key in explicitBaseStateKeys + explicitBaseArrayKeys + explicitBaseMaskKeys
            + explicitOutsKeys + explicitCountTextKeys + explicitBallCountKeys + explicitStrikeCountKeys
            + explicitCountObjectKeys + explicitInningKeys + explicitBattingTeamKeys {
            if explicit[key] == nil, let value = situationMetadataValue(for: key, in: metadata) {
                explicit[key] = value
            }
        }
        return explicit
    }

    private func baseballBaseState(from metadata: [String: JSONValue]) -> BaseballBaseState? {
        for key in explicitBaseStateKeys + genericBaseStateKeys {
            if let state = situationMetadataValue(for: key, in: metadata).flatMap(baseState(from:)) {
                return state
            }
        }
        for key in explicitBaseArrayKeys + genericBaseArrayKeys {
            if let state = situationMetadataValue(for: key, in: metadata).flatMap(baseState(fromArrayValue:)) {
                return state
            }
        }
        for key in explicitBaseMaskKeys + genericBaseMaskKeys {
            if let state = situationMetadataValue(for: key, in: metadata).flatMap(baseState(fromMaskValue:)) {
                return state
            }
        }
        if let state = baseState(fromBooleansIn: metadata) {
            return state
        }
        for key in ["bases", "runners", "situation"] {
            if let state = situationMetadataValue(for: key, in: metadata).flatMap(baseState(from:)) {
                return state
            }
        }
        return nil
    }

    private func baseState(from value: JSONValue) -> BaseballBaseState? {
        switch value {
        case .string(let raw):
            return baseState(fromString: raw)
        case .array:
            return baseState(fromArrayValue: value)
        case .object(let object):
            return baseballBaseState(from: object)
                ?? situationMetadataObjectValue(["occupied", "occupiedBases", "basesOccupied", "runnersOn"], in: object)
                    .flatMap(baseState(fromArrayValue:))
                ?? baseState(fromBooleansIn: object)
        case .number, .bool, .null:
            return nil
        }
    }

    private func baseState(fromString raw: String) -> BaseballBaseState? {
        let occupiedBases: Set<BaseballBase>
        switch normalizedSituationMetadataKey(raw) {
        case "empty", "bases_empty", "none", "no_runners", "nobody_on":
            occupiedBases = []
        case "runner_on_first", "runner_on_1st", "man_on_first", "man_on_1st", "first", "1b", "1st":
            occupiedBases = [.first]
        case "runner_on_second", "runner_on_2nd", "man_on_second", "man_on_2nd", "second", "2b", "2nd":
            occupiedBases = [.second]
        case "runner_on_third", "runner_on_3rd", "man_on_third", "man_on_3rd", "third", "3b", "3rd":
            occupiedBases = [.third]
        case "runners_on_first_and_second", "runners_on_1st_and_2nd", "men_on_first_and_second", "first_and_second", "1st_and_2nd":
            occupiedBases = [.first, .second]
        case "runners_on_first_and_third", "runners_on_1st_and_3rd", "men_on_first_and_third", "first_and_third", "1st_and_3rd", "runners_on_corners":
            occupiedBases = [.first, .third]
        case "runners_on_second_and_third", "runners_on_2nd_and_3rd", "men_on_second_and_third", "second_and_third", "2nd_and_3rd":
            occupiedBases = [.second, .third]
        case "bases_loaded", "loaded", "full", "loaded_bases":
            occupiedBases = [.first, .second, .third]
        default:
            return nil
        }
        return BaseballBaseState(occupiedBases: occupiedBases, label: baseballBaseStateLabel(for: occupiedBases))
    }

    private func baseState(fromArrayValue value: JSONValue) -> BaseballBaseState? {
        guard case .array(let values) = value else { return nil }
        var bases = Set<BaseballBase>()
        for value in values {
            guard let base = base(from: value) else { return nil }
            bases.insert(base)
        }
        return BaseballBaseState(occupiedBases: bases, label: baseballBaseStateLabel(for: bases))
    }

    private func baseState(fromMaskValue value: JSONValue) -> BaseballBaseState? {
        guard let mask = situationInteger(from: value), (0...7).contains(mask) else { return nil }
        var bases = Set<BaseballBase>()
        if mask & 1 != 0 { bases.insert(.first) }
        if mask & 2 != 0 { bases.insert(.second) }
        if mask & 4 != 0 { bases.insert(.third) }
        return BaseballBaseState(occupiedBases: bases, label: baseballBaseStateLabel(for: bases))
    }

    private func baseState(fromBooleansIn metadata: [String: JSONValue]) -> BaseballBaseState? {
        let first = situationMetadataBool(["runnerOnFirst", "onFirst", "firstOccupied", "occupiedFirst"], in: metadata)
            ?? situationMetadataBool(["first"], in: metadata)
        let second = situationMetadataBool(["runnerOnSecond", "onSecond", "secondOccupied", "occupiedSecond"], in: metadata)
            ?? situationMetadataBool(["second"], in: metadata)
        let third = situationMetadataBool(["runnerOnThird", "onThird", "thirdOccupied", "occupiedThird"], in: metadata)
            ?? situationMetadataBool(["third"], in: metadata)
        guard first != nil || second != nil || third != nil else { return nil }
        var bases = Set<BaseballBase>()
        if first == true { bases.insert(.first) }
        if second == true { bases.insert(.second) }
        if third == true { bases.insert(.third) }
        return BaseballBaseState(occupiedBases: bases, label: baseballBaseStateLabel(for: bases))
    }

    private func base(from value: JSONValue) -> BaseballBase? {
        switch value {
        case .number, .string:
            guard let text = value.textValue else { return nil }
            switch normalizedSituationMetadataKey(text) {
            case "1", "1b", "first", "1st": return .first
            case "2", "2b", "second", "2nd": return .second
            case "3", "3b", "third", "3rd": return .third
            default: return nil
            }
        default:
            return nil
        }
    }

    private func outsCount(from metadata: [String: JSONValue]) -> Int? {
        for key in explicitOutsKeys + genericOutsKeys {
            if let outs = situationMetadataValue(for: key, in: metadata).flatMap(outsCount(from:)) {
                return outs
            }
        }
        return nil
    }

    private func outsCount(from value: JSONValue) -> Int? {
        if let outs = situationInteger(from: value), (0...2).contains(outs) {
            return outs
        }
        guard let text = value.textValue.map(normalizedSituationMetadataKey), text.contains("out") else {
            return nil
        }
        if text.hasPrefix("one_out") { return 1 }
        if text.hasPrefix("two_out") { return 2 }
        let firstToken = text.split(separator: "_").first.flatMap { Int($0) }
        return firstToken.flatMap { (0...2).contains($0) ? $0 : nil }
    }

    private func outsCount(fromClockLabel label: String?) -> Int? {
        guard let label, normalizedSituationMetadataKey(label).contains("out") else { return nil }
        return outsCount(from: .string(label))
    }

    private func pitchCount(from metadata: [String: JSONValue]) -> BaseballPitchCount? {
        for key in explicitCountObjectKeys + explicitCountTextKeys + genericCountTextKeys {
            if let count = situationMetadataValue(for: key, in: metadata).flatMap(pitchCount(from:)) {
                return count
            }
        }
        let balls = situationMetadataInteger(explicitBallCountKeys + genericBallCountKeys, in: metadata)
        let strikes = situationMetadataInteger(explicitStrikeCountKeys + genericStrikeCountKeys, in: metadata)
        guard let balls, let strikes else { return nil }
        return BaseballPitchCount(balls: balls, strikes: strikes)
    }

    private func pitchCount(from value: JSONValue) -> BaseballPitchCount? {
        if case .object(let object) = value {
            let balls = situationMetadataInteger(explicitBallCountKeys + genericBallCountKeys, in: object)
            let strikes = situationMetadataInteger(explicitStrikeCountKeys + genericStrikeCountKeys, in: object)
            guard let balls, let strikes else { return nil }
            return BaseballPitchCount(balls: balls, strikes: strikes)
        }
        guard let raw = value.textValue?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        if normalizedSituationMetadataKey(raw) == "full_count" {
            return BaseballPitchCount(balls: 3, strikes: 2)
        }
        if let match = raw.range(of: #"([0-3])\s*[-/]\s*([0-2])"#, options: .regularExpression) {
            let parts = raw[match].split { $0 == "-" || $0 == "/" }
                .compactMap { Int(String($0).trimmingCharacters(in: .whitespaces)) }
            if parts.count == 2 {
                return BaseballPitchCount(balls: parts[0], strikes: parts[1])
            }
        }
        let normalized = normalizedSituationMetadataKey(raw)
        let tokens = normalized.split(separator: "_")
        guard let ballIndex = tokens.firstIndex(of: "balls") ?? tokens.firstIndex(of: "ball"),
              let strikeIndex = tokens.firstIndex(of: "strikes") ?? tokens.firstIndex(of: "strike"),
              ballIndex > tokens.startIndex,
              strikeIndex > tokens.startIndex,
              let balls = Int(tokens[tokens.index(before: ballIndex)]),
              let strikes = Int(tokens[tokens.index(before: strikeIndex)]) else {
            return nil
        }
        return BaseballPitchCount(balls: balls, strikes: strikes)
    }

    private func inningState(from metadata: [String: JSONValue]) -> BaseballInningState {
        let inning = situationMetadataInteger(["inning", "inningNumber", "currentInning", "period", "quarter"], in: metadata)
            .flatMap { $0 >= 1 ? $0 : nil }
        let half = situationMetadataText(["inningHalf", "halfInning", "half", "topBottom", "inningState"], in: metadata)
            .flatMap(inningHalf(from:))
        let label = situationMetadataText(["periodLabel", "inningLabel"], in: metadata)
        let parsedLabel = inningState(from: label)
        return BaseballInningState(inning: inning ?? parsedLabel.inning, inningHalf: half ?? parsedLabel.inningHalf)
    }

    private func inningState(from label: String?) -> BaseballInningState {
        guard let label else { return BaseballInningState() }
        let normalized = normalizedSituationMetadataKey(label)
        let half: BaseballInningHalf?
        if normalized.hasPrefix("top") || normalized.hasPrefix("t_") || normalized.range(of: #"^t\d+$"#, options: .regularExpression) != nil || normalized.hasSuffix("_top") {
            half = .top
        } else if normalized.hasPrefix("bottom") || normalized.hasPrefix("bot") || normalized.hasPrefix("b_") || normalized.range(of: #"^b\d+$"#, options: .regularExpression) != nil || normalized.hasSuffix("_bottom") {
            half = .bottom
        } else {
            half = nil
        }
        let inning = normalized.range(of: #"\d+"#, options: .regularExpression)
            .flatMap { Int(normalized[$0]) }
            .flatMap { $0 >= 1 ? $0 : nil }
        return BaseballInningState(inning: inning, inningHalf: half)
    }

    private func inningHalf(from value: String) -> BaseballInningHalf? {
        switch normalizedSituationMetadataKey(value) {
        case "top", "top_half", "t", "away":
            return .top
        case "bottom", "bot", "bottom_half", "b", "home":
            return .bottom
        default:
            return nil
        }
    }

    private func battingTeam(from metadata: [String: JSONValue]) -> BaseballBattingTeam? {
        let abbreviation = situationMetadataText(["battingTeamAbbreviation", "offenseTeamAbbreviation"], in: metadata)
        let id = situationMetadataText(["battingTeamId", "offenseTeamId"], in: metadata)
        let side = situationMetadataText(["battingTeamRole", "battingSide", "offenseTeamRole"], in: metadata)
            .flatMap(situationParticipantRole(from:))
        guard abbreviation?.nilIfBlank != nil || id?.nilIfBlank != nil || side != nil else { return nil }
        return BaseballBattingTeam(id: id?.nilIfBlank, abbreviation: abbreviation?.nilIfBlank, side: side)
    }

    private func sourceConfidence(
        explicitMetadata: [String: JSONValue],
        genericMetadata: [String: JSONValue],
        hasDerivedPeriod: Bool,
        originalMetadata: [String: JSONValue]
    ) -> BaseballPrePitchSourceConfidence {
        let explicitPeriod = inningState(from: explicitMetadata)
        let hasExplicitState = baseballBaseState(from: explicitMetadata) != nil
            || outsCount(from: explicitMetadata) != nil
            || pitchCount(from: explicitMetadata) != nil
            || explicitPeriod.inning != nil
            || explicitPeriod.inningHalf != nil
            || battingTeam(from: explicitMetadata) != nil
        let genericPeriod = inningState(from: genericMetadata)
        let hasGenericState = baseballBaseState(from: genericMetadata) != nil
            || outsCount(from: genericMetadata) != nil
            || pitchCount(from: genericMetadata) != nil
            || genericPeriod.inning != nil
            || genericPeriod.inningHalf != nil
            || battingTeam(from: genericMetadata) != nil
        if hasExplicitState { return .explicitPrePitch }
        if hasGenericState { return .explicitGeneric }
        if hasAmbiguousBaseballMetadata(originalMetadata) { return .ambiguousResultMetadata }
        if hasDerivedPeriod { return .derivedFromPeriod }
        return .missing
    }

    func baseballBaseStateLabel(for occupiedBases: Set<BaseballBase>) -> String {
        switch occupiedBases {
        case []: return "Bases empty"
        case [.first]: return "Runner on 1st"
        case [.second]: return "Runner on 2nd"
        case [.third]: return "Runner on 3rd"
        case [.first, .second]: return "Runners on 1st and 2nd"
        case [.first, .third]: return "Runners on 1st and 3rd"
        case [.second, .third]: return "Runners on 2nd and 3rd"
        case [.first, .second, .third]: return "Bases loaded"
        default: return "Runners aboard"
        }
    }

    private func containsMetadataValue(_ keys: [String], in metadata: [String: JSONValue]) -> Bool {
        keys.contains { situationMetadataValue(for: $0, in: metadata) != nil }
    }
}
