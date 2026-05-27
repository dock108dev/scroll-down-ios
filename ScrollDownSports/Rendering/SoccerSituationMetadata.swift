import Foundation

extension SoccerRenderer {
    func soccerSituationInputs(for event: GameEvent) -> SoccerSituationInputs {
        let candidate = firstClassSoccerMetadata(for: event) ?? explicitSoccerMetadata(from: event.sportMetadata)
        let state = candidate.flatMap { soccerSituationState(from: $0, event: event) }
        let hasPartialExplicit = candidate != nil && state == nil
        let evidence = SituationConfidenceEvidence(
            hasExplicitPreEventState: state != nil,
            hasExplicitGenericContext: SituationConfidenceGate.hasGenericContext(for: event),
            hasDerivedState: false,
            hasAmbiguousMetadata: hasPartialExplicit || hasAmbiguousSoccerMetadata(event.sportMetadata),
            hasEventLocalContext: SituationConfidenceGate.hasEventLocalContext(for: event)
        )
        return SoccerSituationInputs(
            state: state,
            confidenceDecision: SituationConfidenceGate.decision(for: evidence)
        )
    }

    private func firstClassSoccerMetadata(for event: GameEvent) -> [String: JSONValue]? {
        guard let snapshot = event.situationBefore,
              ["soccer", "mls", "epl"].contains(snapshot.normalizedSport),
              snapshot.hasRenderableConfidence,
              let soccer = snapshot.sportState?.soccer,
              !soccer.isEmpty else {
            return nil
        }
        var metadata = soccer
        metadata["stateTiming"] = metadata["stateTiming"] ?? .string("preEvent")
        if let label = snapshot.clock?.label?.nilIfBlank {
            metadata["clock"] = metadata["clock"] ?? .object(["label": .string(label)])
        }
        return metadata
    }

    private func explicitSoccerMetadata(from metadata: [String: JSONValue]) -> [String: JSONValue]? {
        if case .object(let nested)? = soccerValue(for: "soccerSituation", in: metadata) {
            return nested
        }
        var explicit: [String: JSONValue] = [:]
        var foundContainer = false
        for key in ["preEvent", "pre_event", "preShot", "pre_shot", "before", "situationBefore", "stateBefore"] {
            if case .object(let nested)? = soccerValue(for: key, in: metadata) {
                explicit.merge(nested) { current, _ in current }
                foundContainer = true
            }
        }
        guard foundContainer || hasExplicitSoccerTiming(in: metadata) else {
            return nil
        }
        for key in soccerExplicitKeys {
            if explicit[key] == nil, let value = soccerValue(for: key, in: metadata) {
                explicit[key] = value
            }
        }
        return explicit.isEmpty ? nil : explicit
    }

    private func soccerSituationState(
        from metadata: [String: JSONValue],
        event: GameEvent
    ) -> SoccerSituationState? {
        guard stateTiming(from: soccerText(["stateTiming", "timing", "sourceTiming"], in: metadata)) == "pre_event",
              let restartKind = soccerRestartKind(from: metadata),
              restartKind != .unknown,
              let attackingTeam = soccerAttackingTeam(from: metadata, event: event),
              attackingTeam.hasTeamIdentity,
              let location = soccerLocation(from: metadata),
              location.hasExplicitContext,
              let clockText = soccerClockText(from: metadata, event: event),
              let scoreText = ScorePressurePresentation.line(
                for: event,
                teamLabel: attackingTeam.teamLabel ?? attackingTeam.teamAbbreviation
              )?.text else {
            return nil
        }
        let phase = soccerSetPiecePhase(from: metadata)
        let confidence = soccerNumber(["confidenceScore", "confidence"], in: metadata) ?? 0.85
        guard soccerCardCanRender(restartKind: restartKind, phase: phase, location: location, confidence: confidence) else {
            return nil
        }
        return SoccerSituationState(
            clockText: clockText,
            scoreText: scoreText,
            attackingTeam: attackingTeam,
            restartKind: restartKind,
            phase: phase,
            location: location,
            confidenceScore: confidence
        )
    }

    private func soccerCardCanRender(
        restartKind: SoccerRestartKind,
        phase: SoccerSetPiecePhase,
        location: SoccerLocationState,
        confidence: Double
    ) -> Bool {
        switch restartKind {
        case .corner:
            return [.awarded, .setup].contains(phase) && confidence >= 0.70
        case .directFreeKick, .indirectFreeKick:
            return freeKickDangerLabel(for: location, restartKind: restartKind) != nil && confidence >= 0.80
        case .penaltyKick:
            return [.awarded, .setup].contains(phase) && confidence >= 0.90
        case .unknown:
            return false
        }
    }

    func freeKickDangerLabel(for location: SoccerLocationState, restartKind: SoccerRestartKind) -> String? {
        guard let distance = location.distanceToGoal, distance <= 45 else { return nil }
        let angle = abs(location.angleToGoalDegrees ?? 18)
        let centralBonus = location.side == .center ? 10.0 : 0
        let directBonus = restartKind == .directFreeKick ? 8.0 : 0
        let score = 100 - min(distance, 45) * 1.6 - angle * 0.45 + centralBonus + directBonus
        if score >= 75 { return "Prime shooting range" }
        if score >= 55 { return "Dangerous delivery range" }
        if score >= 35 { return "Useful set piece" }
        return nil
    }

    private func soccerRestartKind(from metadata: [String: JSONValue]) -> SoccerRestartKind? {
        let source = soccerObject(["setPiece", "set_piece"], in: metadata) ?? metadata
        switch soccerNormalized(soccerText(["restartKind", "kind", "type", "setPieceType"], in: source)) {
        case "corner", "corner_kick", "cornerkick":
            return .corner
        case "direct_free_kick", "directfreekick", "free_kick", "freekick":
            return .directFreeKick
        case "indirect_free_kick", "indirectfreekick":
            return .indirectFreeKick
        case "penalty", "penalty_kick", "penaltykick":
            return .penaltyKick
        case "unknown":
            return .unknown
        default:
            return nil
        }
    }

    private func soccerSetPiecePhase(from metadata: [String: JSONValue]) -> SoccerSetPiecePhase {
        let source = soccerObject(["setPiece", "set_piece"], in: metadata) ?? metadata
        switch soccerNormalized(soccerText(["phase"], in: source)) {
        case "awarded":
            return .awarded
        case "setup", "pre_kick", "prekick":
            return .setup
        default:
            return .unknown
        }
    }

    private func soccerAttackingTeam(from metadata: [String: JSONValue], event: GameEvent) -> SoccerAttackingTeam? {
        let source = soccerObject(["attackingTeam", "attacking_team", "possession"], in: metadata) ?? metadata
        let role = soccerText(["participantRole", "role", "side", "teamRole"], in: source).flatMap(situationParticipantRole(from:))
        let abbreviation = soccerText(["teamAbbreviation", "teamAbbr", "abbreviation"], in: source)
            ?? soccerText(["attackingTeamAbbreviation", "possessionTeamAbbreviation"], in: metadata)
        let label = soccerText(["teamLabel", "teamDisplayName", "teamName"], in: source)
        return SoccerAttackingTeam(
            participantRole: role,
            teamAbbreviation: abbreviation?.nilIfBlank,
            teamLabel: label?.nilIfBlank ?? (role == event.teamOwnership ? event.presentation?.teamLabel : nil)
        )
    }

    private func soccerLocation(from metadata: [String: JSONValue]) -> SoccerLocationState? {
        let source = soccerObject(["location"], in: metadata) ?? metadata
        let attackingSource = soccerObject(["attackingThird"], in: metadata) ?? metadata
        let attackingThird = soccerBool(["isInAttackingThird", "attackingThird"], in: attackingSource) == true
        let coordinateSystem = soccerText(["coordinateSystem"], in: source)
        let location = SoccerLocationState(
            x: soccerNormalizedCoordinate(["x"], in: source, coordinateSystem: coordinateSystem),
            y: soccerNormalizedCoordinate(["y"], in: source, coordinateSystem: coordinateSystem),
            zone: soccerText(["zone"], in: source).flatMap(soccerZone(from:)),
            side: soccerText(["side"], in: source).flatMap(soccerSide(from:)),
            distanceToGoal: soccerNumber(["distanceToGoal", "distanceToGoalMeters"], in: source),
            angleToGoalDegrees: soccerNumber(["angleToGoalDegrees", "angleToGoal"], in: source),
            attackingThird: attackingThird
        )
        return location.hasExplicitContext ? location : nil
    }

    private func soccerClockText(from metadata: [String: JSONValue], event: GameEvent) -> String? {
        let source = soccerObject(["clock"], in: metadata) ?? metadata
        if let display = soccerText(["displayLabel", "label", "rawLabel"], in: source)?.nilIfBlank {
            return display
        }
        guard let minute = soccerInteger(["minute"], in: source), minute >= 0 else {
            return event.clockLabel?.nilIfBlank
        }
        if let stoppage = soccerInteger(["stoppageMinute"], in: source), stoppage > 0 {
            return "\(minute)'+\(stoppage)'"
        }
        return "\(minute)'"
    }

    private func hasExplicitSoccerTiming(in metadata: [String: JSONValue]) -> Bool {
        stateTiming(from: soccerText(["stateTiming", "timing", "sourceTiming"], in: metadata)) == "pre_event"
    }

    private func hasAmbiguousSoccerMetadata(_ metadata: [String: JSONValue]) -> Bool {
        !hasExplicitSoccerTiming(in: metadata)
            && ["setPiece", "set_piece", "restartKind", "attackingThird", "ballLocation", "location", "possession"].contains {
                soccerValue(for: $0, in: metadata) != nil
            }
    }

    private var soccerExplicitKeys: [String] {
        [
            "stateTiming", "clock", "minute", "stoppageMinute", "setPiece", "restartKind", "phase",
            "attackingTeam", "attackingTeamAbbreviation", "possession", "possessionTeamAbbreviation",
            "location", "zone", "side", "distanceToGoal", "angleToGoalDegrees", "attackingThird",
            "confidenceScore", "confidence"
        ]
    }

    private func stateTiming(from value: String?) -> String {
        switch soccerNormalized(value) {
        case "pre_event", "preevent", "before", "pre_shot", "preshot", "setup":
            return "pre_event"
        default:
            return "unknown"
        }
    }

    private func soccerZone(from value: String) -> SoccerFieldZone? {
        switch soccerNormalized(value) {
        case "attacking_third", "attackingthird", "final_third", "finalthird":
            return .attackingThird
        case "final_eighth", "finaleighth", "near_goal":
            return .finalEighth
        case "penalty_area", "penaltyarea", "box":
            return .penaltyArea
        case "six_yard_box", "sixyardbox":
            return .sixYardBox
        case "unknown":
            return .unknown
        default:
            return nil
        }
    }

    private func soccerSide(from value: String) -> SoccerFieldSide? {
        switch soccerNormalized(value) {
        case "left", "wide_left":
            return .left
        case "right", "wide_right":
            return .right
        case "center", "central", "middle":
            return .center
        case "unknown":
            return .unknown
        default:
            return nil
        }
    }

}
