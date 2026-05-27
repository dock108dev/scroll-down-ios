enum BasketballSituationParser {
    static func inputs(for event: GameEvent) -> BasketballSituationInputs {
        let candidate = candidateMetadata(for: event)
        let state: BasketballSituationState?
        if let metadata = candidate.metadata {
            state = Self.state(from: metadata, event: event)
        } else {
            state = nil
        }
        let hasRenderableState = state.map(BasketballSituationValidator.canRenderSportDiagram) == true
        let hasPartialExplicit = candidate.hasExplicitCandidate && !hasRenderableState
        let hasAmbiguous = hasPartialExplicit || hasAmbiguousLooseMetadata(event.sportMetadata)
        let evidence = SituationConfidenceEvidence(
            hasExplicitPreEventState: hasRenderableState,
            hasExplicitGenericContext: SituationConfidenceGate.hasGenericContext(for: event),
            hasDerivedState: false,
            hasAmbiguousMetadata: hasAmbiguous,
            hasEventLocalContext: SituationConfidenceGate.hasEventLocalContext(for: event)
        )
        return BasketballSituationInputs(
            state: state,
            confidenceDecision: SituationConfidenceGate.decision(for: evidence)
        )
    }

    private static func candidateMetadata(for event: GameEvent) -> (metadata: [String: JSONValue]?, hasExplicitCandidate: Bool) {
        if let firstClass = firstClassMetadata(for: event) {
            return (firstClass, true)
        }
        if case .object(let value)? = situationMetadataValue(for: "basketballSituation", in: event.sportMetadata) {
            return (value, true)
        }
        return (nil, false)
    }

    private static func firstClassMetadata(for event: GameEvent) -> [String: JSONValue]? {
        guard let snapshot = event.situationBefore,
              ["basketball", "nba"].contains(snapshot.normalizedSport),
              snapshot.hasRenderableConfidence,
              let basketball = snapshot.sportState?.basketball,
              !basketball.isEmpty else {
            return nil
        }
        let metadata: [String: JSONValue]
        if case .object(let nested)? = situationMetadataValue(for: "basketballSituation", in: basketball) {
            metadata = nested
        } else {
            metadata = basketball
        }
        return metadata.merging(snapshotContext(from: snapshot)) { current, _ in current }
    }

    private static func snapshotContext(from snapshot: GameEventSituationSnapshot) -> [String: JSONValue] {
        var context: [String: JSONValue] = [:]
        if let period = snapshot.period {
            var periodObject: [String: JSONValue] = [:]
            if let ordinal = period.ordinal { periodObject["ordinal"] = .number(Double(ordinal)) }
            if let label = period.label { periodObject["label"] = .string(label) }
            if !periodObject.isEmpty { context["period"] = .object(periodObject) }
        }
        if let clock = snapshot.clock {
            var clockObject: [String: JSONValue] = [:]
            if let label = clock.label { clockObject["label"] = .string(label) }
            if let seconds = clock.secondsRemaining { clockObject["secondsRemaining"] = .number(seconds) }
            if !clockObject.isEmpty { context["clock"] = .object(clockObject) }
        }
        return context
    }

    private static func state(from metadata: [String: JSONValue], event: GameEvent) -> BasketballSituationState? {
        guard situationMetadataInteger(["schemaVersion"], in: metadata) == 1,
              timing(from: situationMetadataText(["stateTiming", "timing"], in: metadata)) == .preEvent else {
            return nil
        }
        let possession: BasketballPossessionState? = situationMetadataObject(["possession"], in: metadata).flatMap(Self.possession(from:))
        let shotClock: BasketballShotClockState? = situationMetadataObject(["shotClock", "shot_clock"], in: metadata).flatMap(Self.shotClock(from:))
        let bonus: BasketballBonusState? = situationMetadataObject(["bonus"], in: metadata).flatMap { Self.bonus(from: $0, possession: possession) }
        let shot: BasketballShotState? = situationMetadataObject(["shot"], in: metadata).flatMap(Self.shot(from:))
        let freeThrows: BasketballFreeThrowState? = situationMetadataObject(["freeThrows", "free_throws"], in: metadata).flatMap(Self.freeThrows(from:))
        return BasketballSituationState(
            schemaVersion: 1,
            stateTiming: .preEvent,
            periodText: periodText(from: metadata, event: event),
            clockText: clockText(from: metadata, event: event),
            possession: possession,
            shotClock: shotClock,
            bonus: bonus,
            shot: shot,
            freeThrows: freeThrows
        )
    }

    private static func possession(from metadata: [String: JSONValue]) -> BasketballPossessionState? {
        let role = situationMetadataText(["participantRole", "role", "side"], in: metadata).flatMap(situationParticipantRole(from:))
        let abbreviation = situationMetadataText(["teamAbbreviation", "team", "teamAbbr"], in: metadata)
        let label = situationMetadataText(["teamLabel", "teamName"], in: metadata)
        let phase = possessionPhase(from: situationMetadataText(["phase"], in: metadata))
        let confidence = fieldConfidence(from: situationMetadataText(["confidence"], in: metadata))
        let possession = BasketballPossessionState(
            participantRole: role,
            teamAbbreviation: abbreviation,
            teamLabel: label,
            phase: phase,
            confidence: confidence
        )
        return possession.hasTeamIdentity ? possession : nil
    }

    private static func shotClock(from metadata: [String: JSONValue]) -> BasketballShotClockState? {
        let seconds = situationMetadataNumber(["seconds"], in: metadata)
        let displayText = situationMetadataText(["displayText", "label"], in: metadata)
        let status = shotClockStatus(from: situationMetadataText(["status"], in: metadata))
        let confidence = fieldConfidence(from: situationMetadataText(["confidence"], in: metadata))
        guard seconds != nil || displayText?.nilIfBlank != nil else { return nil }
        return BasketballShotClockState(
            seconds: seconds,
            displayText: displayText,
            status: status,
            confidence: confidence
        )
    }

    private static func bonus(
        from metadata: [String: JSONValue],
        possession: BasketballPossessionState?
    ) -> BasketballBonusState? {
        let status = situationMetadataText(["possessionTeamBonusStatus", "status"], in: metadata).flatMap(bonusStatus(from:))
        let foulsToBonus = situationMetadataInteger(["possessionTeamFoulsToBonus", "foulsToBonus"], in: metadata)
            ?? possession.flatMap { teamBonus(from: metadata, possession: $0)?.foulsToBonus }
        let confidence = fieldConfidence(from: situationMetadataText(["confidence"], in: metadata))
        guard status != nil || foulsToBonus != nil else { return nil }
        return BasketballBonusState(
            possessionTeamStatus: status,
            possessionTeamFoulsToBonus: foulsToBonus,
            confidence: confidence
        )
    }

    private static func teamBonus(
        from metadata: [String: JSONValue],
        possession: BasketballPossessionState
    ) -> (status: BasketballBonusStatus?, foulsToBonus: Int?)? {
        let key: String?
        switch possession.participantRole {
        case .home:
            key = "home"
        case .away:
            key = "away"
        default:
            key = nil
        }
        guard let key, let team = situationMetadataObject([key], in: metadata) else { return nil }
        return (
            situationMetadataText(["status"], in: team).flatMap(bonusStatus(from:)),
            situationMetadataInteger(["foulsToBonus"], in: team)
        )
    }

    private static func shot(from metadata: [String: JSONValue]) -> BasketballShotState? {
        let result = situationMetadataText(["result"], in: metadata).flatMap(shotResult(from:))
        let value = situationMetadataInteger(["value", "points"], in: metadata)
        let location = situationMetadataObject(["location"], in: metadata).flatMap { shotLocation(from: $0) }
        let confidence = fieldConfidence(from: situationMetadataText(["confidence"], in: metadata))
        guard result != nil || value != nil || location != nil else { return nil }
        return BasketballShotState(result: result, value: value, location: location, confidence: confidence)
    }

    private static func shotLocation(from metadata: [String: JSONValue]) -> BasketballShotLocation? {
        let coordinateSystem = coordinateSystem(from: situationMetadataText(["coordinateSystem"], in: metadata))
        let x = situationMetadataNumber(["x"], in: metadata)
        let y = situationMetadataNumber(["y"], in: metadata)
        let zone = situationMetadataText(["zone"], in: metadata).flatMap(shotZone(from:))
        let confidence = fieldConfidence(from: situationMetadataText(["confidence"], in: metadata))
        guard x != nil || y != nil || zone != nil else { return nil }
        return BasketballShotLocation(
            coordinateSystem: coordinateSystem,
            x: x,
            y: y,
            zone: zone,
            confidence: confidence
        )
    }

    private static func freeThrows(from metadata: [String: JSONValue]) -> BasketballFreeThrowState? {
        let attempt = situationMetadataInteger(["attemptNumber", "attempt"], in: metadata)
        let total = situationMetadataInteger(["totalAttempts", "total"], in: metadata)
        guard attempt != nil || total != nil else { return nil }
        return BasketballFreeThrowState(attemptNumber: attempt, totalAttempts: total)
    }

    private static func periodText(from metadata: [String: JSONValue], event: GameEvent) -> String? {
        guard let period = situationMetadataObject(["period"], in: metadata) else {
            return event.periodLabel?.nilIfBlank
        }
        return situationMetadataText(["label"], in: period) ?? situationMetadataInteger(["ordinal"], in: period).map { "Q\($0)" }
    }

    private static func clockText(from metadata: [String: JSONValue], event: GameEvent) -> String? {
        guard let clock = situationMetadataObject(["clock"], in: metadata) else {
            return event.clockLabel?.nilIfBlank
        }
        return situationMetadataText(["label"], in: clock) ?? event.clockLabel?.nilIfBlank
    }

    private static func hasAmbiguousLooseMetadata(_ metadata: [String: JSONValue]) -> Bool {
        guard situationMetadataValue(for: "basketballSituation", in: metadata) == nil else { return false }
        return ["possession", "shotClock", "bonus", "shotLocation", "shot_location"].contains {
            situationMetadataValue(for: $0, in: metadata) != nil
        }
    }

    private static func timing(from value: String?) -> BasketballStateTiming {
        switch normalizedSituationMetadataKey(value) {
        case "pre_event", "preevent", "before", "before_play", "pre_possession", "pre_shot":
            return .preEvent
        case "event_moment", "eventmoment", "event":
            return .eventMoment
        case "post_event", "postevent", "after":
            return .postEvent
        case "interval":
            return .interval
        default:
            return .unknown
        }
    }

    private static func possessionPhase(from value: String?) -> BasketballPossessionPhase {
        switch normalizedSituationMetadataKey(value) {
        case "live_ball", "liveball", "live":
            return .liveBall
        case "inbound":
            return .inbound
        case "free_throw", "freethrow":
            return .freeThrow
        case "jump_ball", "jumpball":
            return .jumpBall
        case "dead_ball", "deadball":
            return .deadBall
        default:
            return .unknown
        }
    }

    private static func shotClockStatus(from value: String?) -> BasketballShotClockStatus {
        switch normalizedSituationMetadataKey(value) {
        case "running":
            return .running
        case "stopped":
            return .stopped
        case "off":
            return .off
        case "expired":
            return .expired
        default:
            return .unknown
        }
    }

    private static func bonusStatus(from value: String?) -> BasketballBonusStatus? {
        switch normalizedSituationMetadataKey(value) {
        case "none":
            return BasketballBonusStatus.none
        case "bonus":
            return .bonus
        case "double_bonus", "doublebonus":
            return .doubleBonus
        case "unknown":
            return .unknown
        default:
            return nil
        }
    }

    private static func shotResult(from value: String?) -> BasketballShotResult? {
        switch normalizedSituationMetadataKey(value) {
        case "made":
            return .made
        case "missed":
            return .missed
        case "blocked":
            return .blocked
        case "fouled":
            return .fouled
        case "unknown":
            return .unknown
        default:
            return nil
        }
    }

    private static func coordinateSystem(from value: String?) -> BasketballShotCoordinateSystem {
        switch normalizedSituationMetadataKey(value) {
        case "normalized_half_court", "normalizedhalfcourt":
            return .normalizedHalfCourt
        case "normalized_full_court", "normalizedfullcourt":
            return .normalizedFullCourt
        case "feet_from_basket", "feetfrombasket":
            return .feetFromBasket
        case "provider_native", "providernative":
            return .providerNative
        default:
            return .unknown
        }
    }

    private static func shotZone(from value: String?) -> BasketballShotZone? {
        switch normalizedSituationMetadataKey(value) {
        case "restricted_area", "restrictedarea":
            return .restrictedArea
        case "paint":
            return .paint
        case "midrange", "mid_range":
            return .midrange
        case "left_corner_three", "leftcornerthree":
            return .leftCornerThree
        case "right_corner_three", "rightcornerthree":
            return .rightCornerThree
        case "above_break_three", "abovebreakthree":
            return .aboveBreakThree
        case "backcourt":
            return .backcourt
        case "unknown":
            return .unknown
        default:
            return nil
        }
    }

    private static func fieldConfidence(from value: String?) -> BasketballFieldConfidence {
        switch normalizedSituationMetadataKey(value) {
        case "explicit", "verified":
            return .explicit
        case "verified_derived", "verifiedderived":
            return .verifiedDerived
        case "derived":
            return .derived
        case "ambiguous":
            return .ambiguous
        default:
            return .missing
        }
    }
}

enum BasketballSituationValidator {
    static func canRenderSportDiagram(_ state: BasketballSituationState) -> Bool {
        guard state.schemaVersion == 1,
              state.stateTiming == .preEvent,
              let possession = state.possession,
              possession.hasTeamIdentity,
              possession.phase != .unknown,
              possession.confidence.canRenderAssertiveState else {
            return false
        }
        return true
    }
}
