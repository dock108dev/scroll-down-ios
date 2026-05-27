struct HockeyRenderer: GenericSportRendererBacked {
    let generic = GenericSportRenderer(leagueCode: "NHL", sportLabel: "Hockey")

    func statsPresentation(for detail: GameDetail) -> GameStatsPresentation {
        GameStatsPresentation(
            playerSections: StatPresentationBuilder.hockeyPlayerSections(for: detail),
            teamSection: generic.teamStatSection(for: detail)
        )
    }

    func eventSituationPresentation(
        for event: GameEvent,
        context: SportRendererSituationContext
    ) -> GameEventSituationPresentation? {
        let inputs = hockeySituationInputs(for: event)
        return SituationCardPolicy.presentation(
            for: event,
            context: context,
            decision: hockeySituationDecision(for: event, inputs: inputs),
            densityKeyForEvent: hockeyDensityKey(for:)
        ) {
            hockeySituationPresentation(for: event, inputs: inputs)
        }
    }

    private func hockeySituationPresentation(
        for event: GameEvent,
        inputs: HockeySituationInputs
    ) -> GameEventSituationPresentation? {
        guard let state = inputs.pressureState,
              case .sportDiagram = inputs.confidenceDecision else {
            return SituationConfidenceGate.pressureBoardPresentation(
                for: event,
                sport: .hockey,
                decision: inputs.confidenceDecision,
                title: "Context",
                tone: situationTone(for: event)
            )
        }

        let ownership = hockeyOwnership(for: state)
        let diagram = state.zone.map {
            GameEventSituationDiagram.hockeyRinkStrip(
                HockeyRinkStripDiagram(
                    zone: $0,
                    puckLocation: state.puckLocation,
                    attackingTeamAbbreviation: state.attackingTeam?.teamAbbreviation
                )
            )
        }

        return GameEventSituationPresentation(
            title: "Situation",
            periodText: hockeySituationPeriodText(for: event),
            setupText: state.setupText,
            contextLine: scorePressureLine(for: event),
            pressureLine: hockeyPressureLine(for: event, state: state),
            sport: .hockey,
            layout: .hockey,
            ownership: ownership,
            diagram: diagram,
            accent: GameEventSituationAccent(
                ownership: ownership?.participantRole ?? event.teamOwnership,
                teamAbbreviation: ownership?.teamAbbreviation ?? event.teamAbbreviation,
                teamLabel: ownership?.teamLabel ?? event.presentation?.teamLabel,
                tone: situationTone(for: event)
            ),
            dataConfidence: inputs.confidenceDecision.dataConfidence
        )
    }

    private func hockeySituationDecision(
        for event: GameEvent,
        inputs: HockeySituationInputs
    ) -> SituationCardLayoutDecision {
        let priority = hockeySituationPriority(for: event, inputs: inputs)
        guard priority != .routine else {
            return .suppress
        }
        switch inputs.confidenceDecision {
        case .sportDiagram:
            return .sportDiagram(priority: priority, densityKey: hockeyDensityKey(for: event))
        case .pressureBoardFallback:
            return .pressureBoardFallback(priority: priority, densityKey: hockeyDensityKey(for: event))
        case .none:
            return .suppress
        }
    }

    private func hockeySituationPriority(
        for event: GameEvent,
        inputs: HockeySituationInputs
    ) -> SituationCardPriority {
        switch event.visualImportance {
        case .critical:
            return .bigMoment
        case .high:
            return .keyMoment
        case .medium, .low:
            if event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
                return .scoringSwing
            }
            if event.importanceMetadata?.isKeyMoment == true || event.isKeyMoment {
                return .keyMoment
            }
            guard let state = inputs.pressureState else {
                return .routine
            }
            if state.zone == .offensive && state.strength != .penaltyKill {
                return .highConfidenceThreat
            }
            if state.strength == .powerPlay && isPressureEvent(event) {
                return .notable
            }
            return .routine
        }
    }

    private func hockeyOwnership(for state: HockeyPressureState) -> GameEventSituationOwnership? {
        guard let attackingTeam = state.attackingTeam else { return nil }
        return GameEventSituationOwnership(
            role: .attackingSide,
            participantRole: attackingTeam.participantRole,
            teamAbbreviation: attackingTeam.teamAbbreviation,
            teamLabel: attackingTeam.teamLabel,
            confidence: .explicit
        )
    }

    private func hockeySituationPeriodText(for event: GameEvent) -> String? {
        generic.periodClockText(
            periodOrdinal: event.periodOrdinal,
            periodLabel: event.periodLabel,
            clockLabel: event.clockLabel
        ).nilIfBlank
    }

    private func hockeyPressureLine(
        for event: GameEvent,
        state: HockeyPressureState
    ) -> String? {
        if event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
            return state.strength.scoringPressureLabel
        }
        if event.importanceMetadata?.isLeadChange == true {
            return "Lead change"
        }
        if event.importanceMetadata?.isTyingPlay == true {
            return "Tying play"
        }
        if state.zone == .offensive {
            return state.strength.zonePressureLabel
        }
        return state.strength.pressureLabel
    }

    private func scorePressureLine(for event: GameEvent) -> String? {
        ScorePressurePresentation.line(
            for: event,
            teamLabel: event.presentation?.teamLabel ?? event.teamAbbreviation
        )?.text
    }

    private func situationTone(for event: GameEvent) -> SportsTheme.Tone {
        if event.importanceMetadata?.isLeadChange == true || event.importanceMetadata?.isTyingPlay == true {
            return .critical
        }
        if event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
            return .scoring
        }
        return .neutral
    }

    private func hockeyDensityKey(for event: GameEvent) -> String? {
        let state = hockeySituationInputs(for: event).pressureState
        return [
            event.periodLabel,
            event.clockLabel,
            state?.attackingTeam?.teamAbbreviation ?? event.teamAbbreviation,
            event.eventType,
            state?.strength.rawValue,
            state?.zone?.rawValue
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: "|")
            .nilIfBlank
    }

    private func isPressureEvent(_ event: GameEvent) -> Bool {
        guard let eventType = event.eventType?.nilIfBlank else {
            return false
        }
        switch normalizedSituationMetadataKey(eventType) {
        case "shot", "goal", "missed_shot", "missedshot", "blocked_shot", "blockedshot",
             "save", "rebound", "takeaway", "giveaway", "penalty_drawn", "penaltydrawn":
            return true
        default:
            return false
        }
    }
}
