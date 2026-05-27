extension HockeyRenderer {
    func hockeySituationInputs(for event: GameEvent) -> HockeySituationInputs {
        let firstClass = firstClassHockeyMetadata(for: event)
        let explicitMetadata = firstClass ?? explicitHockeyMetadata(from: event.sportMetadata)
        let pressureState = explicitMetadata.flatMap {
            hockeyPressureState(from: $0, event: event)
        }
        let hasExplicit = explicitMetadata != nil
        let hasPartialExplicit = hasExplicit && pressureState == nil
        let hasAmbiguous = hasAmbiguousHockeyMetadata(event.sportMetadata) || hasPartialExplicit
        let evidence = SituationConfidenceEvidence(
            hasExplicitPreEventState: pressureState != nil,
            hasExplicitGenericContext: SituationConfidenceGate.hasGenericContext(for: event),
            hasDerivedState: false,
            hasAmbiguousMetadata: hasAmbiguous,
            hasEventLocalContext: SituationConfidenceGate.hasEventLocalContext(for: event)
        )
        return HockeySituationInputs(
            pressureState: pressureState,
            confidenceDecision: SituationConfidenceGate.decision(for: evidence)
        )
    }

    private func firstClassHockeyMetadata(for event: GameEvent) -> [String: JSONValue]? {
        guard let snapshot = event.situationBefore,
              snapshot.normalizedSport == "hockey" || snapshot.normalizedSport == "nhl",
              snapshot.hasRenderableConfidence,
              let hockey = snapshot.sportState?.hockey,
              !hockey.isEmpty else {
            return nil
        }
        var metadata = hockey
        if let possession = snapshot.possession {
            metadata.merge(possession) { current, _ in current }
        }
        if let label = snapshot.clock?.label?.nilIfBlank {
            metadata["clockLabel"] = .string(label)
        }
        return metadata
    }

    private func explicitHockeyMetadata(from metadata: [String: JSONValue]) -> [String: JSONValue]? {
        var explicit: [String: JSONValue] = [:]
        var foundContainer = false
        for key in hockeyExplicitContainerKeys {
            if case .object(let nested)? = situationMetadataValue(for: key, in: metadata) {
                explicit.merge(nested) { current, _ in current }
                foundContainer = true
            }
        }
        guard foundContainer || hasExplicitHockeyTiming(in: metadata) else {
            return nil
        }
        for key in hockeyExplicitKeys {
            if explicit[key] == nil, let value = situationMetadataValue(for: key, in: metadata) {
                explicit[key] = value
            }
        }
        return explicit.isEmpty ? nil : explicit
    }

    private func hockeyPressureState(
        from metadata: [String: JSONValue],
        event: GameEvent
    ) -> HockeyPressureState? {
        guard let strength = hockeyStrength(from: metadata) else {
            return nil
        }
        return HockeyPressureState(
            strength: strength,
            zone: hockeyZone(from: metadata),
            attackingTeam: hockeyAttackingTeam(from: metadata, event: event),
            puckLocation: hockeyPuckLocation(from: metadata)
        )
    }

    private func hockeyStrength(from metadata: [String: JSONValue]) -> HockeyStrengthState? {
        guard let value = situationMetadataText(
            ["strength", "strengthState", "manpower", "manpowerState", "skaterStrength"],
            in: metadata
        ) else {
            return nil
        }
        switch normalizedSituationMetadataKey(value) {
        case "even", "even_strength", "ev", "5v5", "4v4", "3v3":
            return .even
        case "power_play", "powerplay", "pp", "man_advantage", "advantage", "5v4", "5v3", "4v3":
            return .powerPlay
        case "penalty_kill", "penaltykill", "pk", "short_handed", "shorthanded", "man_down", "4v5", "3v5", "3v4":
            return .penaltyKill
        default:
            return nil
        }
    }

    private func hockeyZone(from metadata: [String: JSONValue]) -> HockeyRinkZone? {
        guard let value = situationMetadataText(
            ["zone", "zoneState", "rinkZone", "attackingZone", "pressureZone"],
            in: metadata
        ) else {
            return nil
        }
        switch normalizedSituationMetadataKey(value) {
        case "offensive", "offense", "attacking", "attack", "oz", "o_zone":
            return .offensive
        case "neutral", "nz", "neutral_zone":
            return .neutral
        case "defensive", "defense", "dz", "d_zone":
            return .defensive
        default:
            return nil
        }
    }

    private func hockeyPuckLocation(from metadata: [String: JSONValue]) -> HockeyPuckLocation? {
        guard let value = situationMetadataText(
            ["puckLocation", "puckLocationBefore", "shotLocation", "pressureLocation"],
            in: metadata
        ) else {
            return nil
        }
        switch normalizedSituationMetadataKey(value) {
        case "slot":
            return .slot
        case "high_slot", "highslot":
            return .highSlot
        case "left_circle", "leftcircle":
            return .leftCircle
        case "right_circle", "rightcircle":
            return .rightCircle
        case "point", "blue_line", "blueline":
            return .point
        case "crease", "net_front", "netfront":
            return .crease
        case "behind_net", "behindnet":
            return .behindNet
        default:
            return nil
        }
    }

    private func hockeyAttackingTeam(
        from metadata: [String: JSONValue],
        event: GameEvent
    ) -> HockeyAttackingTeam? {
        let abbreviation = situationMetadataText(
            [
                "attackingTeam",
                "attackingTeamAbbreviation",
                "attackTeam",
                "offenseTeam",
                "offenseTeamAbbreviation",
                "possessionTeam",
                "possessionTeamAbbreviation"
            ],
            in: metadata
        )
        let role = situationMetadataText(
            ["attackingTeamRole", "attackingRole", "offenseRole", "possessionRole"],
            in: metadata
        ).flatMap(situationParticipantRole(from:))
        guard abbreviation?.nilIfBlank != nil || role != nil else {
            return nil
        }
        return HockeyAttackingTeam(
            teamAbbreviation: abbreviation?.nilIfBlank,
            participantRole: role,
            teamLabel: role == event.teamOwnership ? event.presentation?.teamLabel : nil
        )
    }

    private func hasExplicitHockeyTiming(in metadata: [String: JSONValue]) -> Bool {
        guard let timing = situationMetadataText(
            ["situationTiming", "stateTiming", "timing", "metadataTiming", "sourceTiming"],
            in: metadata
        ).map(normalizedSituationMetadataKey) else {
            return false
        }
        return ["before", "before_play", "pre_event", "pre_play", "pre_shot", "preshot"].contains(timing)
    }

    private func hasAmbiguousHockeyMetadata(_ metadata: [String: JSONValue]) -> Bool {
        !hasExplicitHockeyTiming(in: metadata)
            && hockeyAmbiguousKeys.contains {
                situationMetadataValue(for: $0, in: metadata) != nil
            }
    }

    private var hockeyExplicitContainerKeys: [String] {
        [
            "preEvent", "pre_event", "prePlay", "pre_play", "preShot", "pre_shot",
            "before", "situationBefore", "situation_before", "stateBefore", "state_before",
            "pressureState", "pressure_state"
        ]
    }

    private var hockeyExplicitKeys: [String] {
        [
            "strength", "strengthState", "manpower", "manpowerState", "skaterStrength",
            "zone", "zoneState", "rinkZone", "attackingZone", "pressureZone",
            "attackingTeam", "attackingTeamAbbreviation", "attackingTeamRole", "attackingRole",
            "attackTeam", "offenseTeam", "offenseTeamAbbreviation", "offenseRole",
            "possessionTeam", "possessionTeamAbbreviation", "possessionRole",
            "puckLocation", "puckLocationBefore", "shotLocation", "pressureLocation"
        ]
    }

    private var hockeyAmbiguousKeys: [String] {
        [
            "strength", "strengthState", "manpower", "zone", "zoneState", "attackingZone",
            "puckLocation", "shotLocation", "goaliePulled"
        ]
    }

}

struct HockeySituationInputs: Hashable, Sendable {
    let pressureState: HockeyPressureState?
    let confidenceDecision: SituationBlockDecision
}

struct HockeyPressureState: Hashable, Sendable {
    let strength: HockeyStrengthState
    let zone: HockeyRinkZone?
    let attackingTeam: HockeyAttackingTeam?
    let puckLocation: HockeyPuckLocation?

    var setupText: String {
        [
            strength.label,
            zone?.label,
            puckLocation?.label
        ].compactMap(\.self)
            .joined(separator: " · ")
    }
}

enum HockeyStrengthState: String, Hashable, Sendable {
    case even
    case powerPlay
    case penaltyKill

    var label: String {
        switch self {
        case .even:
            return "Even strength"
        case .powerPlay:
            return "Power play"
        case .penaltyKill:
            return "Penalty kill"
        }
    }

    var scoringPressureLabel: String {
        switch self {
        case .even:
            return "Even-strength finish"
        case .powerPlay:
            return "Power-play finish"
        case .penaltyKill:
            return "Short-handed finish"
        }
    }

    var zonePressureLabel: String {
        switch self {
        case .even:
            return "Attacking-zone pressure"
        case .powerPlay:
            return "Power-play pressure"
        case .penaltyKill:
            return "Short-handed pressure"
        }
    }

    var pressureLabel: String {
        switch self {
        case .even:
            return "Even-strength setup"
        case .powerPlay:
            return "Man advantage"
        case .penaltyKill:
            return "Short-handed setup"
        }
    }
}

struct HockeyAttackingTeam: Hashable, Sendable {
    let teamAbbreviation: String?
    let participantRole: GameParticipantRole?
    let teamLabel: String?
}
