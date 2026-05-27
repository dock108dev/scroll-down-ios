extension SoccerRenderer {
    func eventSituationPresentation(
        for event: GameEvent,
        context: SportRendererSituationContext
    ) -> GameEventSituationPresentation? {
        let inputs = soccerSituationInputs(for: event)
        return SituationCardPolicy.presentation(
            for: event,
            context: context,
            decision: soccerSituationDecision(for: event, inputs: inputs),
            densityKeyForEvent: soccerDensityKey(for:)
        ) {
            soccerSituationPresentation(for: event, inputs: inputs)
        }
    }

    private func soccerSituationPresentation(
        for event: GameEvent,
        inputs: SoccerSituationInputs
    ) -> GameEventSituationPresentation? {
        guard let state = inputs.state,
              case .sportDiagram = inputs.confidenceDecision else {
            return SituationConfidenceGate.pressureBoardPresentation(
                for: event,
                sport: .soccer,
                decision: inputs.confidenceDecision,
                title: "Context",
                tone: situationTone(for: event)
            )
        }

        let ownership = soccerOwnership(for: state)
        return GameEventSituationPresentation(
            title: soccerTitle(for: state),
            periodText: state.clockText,
            setupText: state.setupText,
            contextLine: state.scoreText,
            pressureLine: soccerPressureLine(for: state),
            sport: .soccer,
            layout: .soccer,
            ownership: ownership,
            diagram: .soccerPitchStrip(soccerPitchStrip(for: state)),
            accent: GameEventSituationAccent(
                ownership: ownership.participantRole ?? event.teamOwnership,
                teamAbbreviation: ownership.teamAbbreviation ?? event.teamAbbreviation,
                teamLabel: ownership.teamLabel ?? event.presentation?.teamLabel,
                tone: situationTone(for: event)
            ),
            dataConfidence: inputs.confidenceDecision.dataConfidence
        )
    }

    private func soccerSituationDecision(
        for event: GameEvent,
        inputs: SoccerSituationInputs
    ) -> SituationCardLayoutDecision {
        let priority = soccerSituationPriority(for: event, inputs: inputs)
        guard priority != .routine else {
            return .suppress
        }
        switch inputs.confidenceDecision {
        case .sportDiagram:
            return .sportDiagram(priority: priority, densityKey: soccerDensityKey(for: event))
        case .pressureBoardFallback:
            return .pressureBoardFallback(priority: priority, densityKey: soccerDensityKey(for: event))
        case .none:
            return .suppress
        }
    }

    private func soccerSituationPriority(
        for event: GameEvent,
        inputs: SoccerSituationInputs
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
            guard let state = inputs.state else {
                return event.importance == .primary ? .notable : .routine
            }
            switch state.restartKind {
            case .penaltyKick:
                return .bigMoment
            case .directFreeKick, .indirectFreeKick:
                return .highConfidenceThreat
            case .corner:
                return .notable
            case .unknown:
                return .routine
            }
        }
    }

    private func soccerPitchStrip(for state: SoccerSituationState) -> SoccerPitchStripDiagram {
        SoccerPitchStripDiagram(
            setPieceText: state.restartKind.shortLabel ?? "Set piece",
            locationText: state.location.label,
            attackingTeamAbbreviation: state.attackingTeam.teamAbbreviation,
            ballX: state.location.x,
            ballY: state.location.y,
            highlightsGoalArea: [.penaltyArea, .sixYardBox, .finalEighth].contains(state.location.zone)
                || state.restartKind == .penaltyKick
        )
    }

    private func soccerOwnership(for state: SoccerSituationState) -> GameEventSituationOwnership {
        GameEventSituationOwnership(
            role: .attackingSide,
            participantRole: state.attackingTeam.participantRole,
            teamAbbreviation: state.attackingTeam.teamAbbreviation,
            teamLabel: state.attackingTeam.teamLabel,
            confidence: .explicit
        )
    }

    private func soccerTitle(for state: SoccerSituationState) -> String {
        switch state.restartKind {
        case .corner:
            return "Corner"
        case .directFreeKick, .indirectFreeKick:
            return "Free kick in range"
        case .penaltyKick:
            return "Penalty awarded"
        case .unknown:
            return "Set piece"
        }
    }

    private func soccerPressureLine(for state: SoccerSituationState) -> String? {
        switch state.restartKind {
        case .directFreeKick, .indirectFreeKick:
            return freeKickDangerLabel(for: state.location, restartKind: state.restartKind)
        case .corner:
            return "Set-piece pressure"
        case .penaltyKick:
            return "Penalty"
        case .unknown:
            return nil
        }
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

    private func soccerDensityKey(for event: GameEvent) -> String? {
        let state = soccerSituationInputs(for: event).state
        return [
            event.periodLabel,
            event.clockLabel,
            state?.restartKind.rawValue,
            state?.attackingTeam.teamAbbreviation,
            state?.location.label
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: "|")
            .nilIfBlank
    }
}
