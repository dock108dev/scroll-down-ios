import Foundation

extension BasketballRenderer {
    func basketballSituationInputs(for event: GameEvent) -> BasketballSituationInputs {
        BasketballSituationParser.inputs(for: event)
    }

    func basketballSituationPresentation(
        for event: GameEvent,
        inputs: BasketballSituationInputs
    ) -> GameEventSituationPresentation? {
        guard let state = inputs.state,
              case .sportDiagram = inputs.confidenceDecision,
              BasketballSituationValidator.canRenderSportDiagram(state),
              let possession = state.possession else {
            return SituationConfidenceGate.pressureBoardPresentation(
                for: event,
                sport: .basketball,
                decision: inputs.confidenceDecision,
                tone: basketballTone(for: event, state: inputs.state)
            )
        }

        let ownership = GameEventSituationOwnership(
            role: .possession,
            participantRole: possession.participantRole,
            teamAbbreviation: possession.teamAbbreviation,
            teamLabel: possession.teamLabel,
            confidence: .explicit
        )
        let scoreText = basketballScoreText(for: event, possession: possession)
        let diagram = basketballHalfCourtDiagram(for: state, event: event, possession: possession, scoreText: scoreText)
        return GameEventSituationPresentation(
            title: basketballTitle(for: state),
            periodText: basketballPeriodClockText(for: state, event: event),
            setupText: basketballSetupText(for: state),
            contextLine: scoreText,
            pressureLine: basketballPressureLine(for: state, event: event, scoreText: scoreText),
            sport: .basketball,
            layout: .basketball,
            ownership: ownership,
            diagram: .basketballHalfCourt(diagram),
            accent: GameEventSituationAccent(
                ownership: ownership.participantRole,
                teamAbbreviation: ownership.teamAbbreviation,
                teamLabel: ownership.teamLabel,
                tone: basketballTone(for: event, state: state)
            ),
            dataConfidence: inputs.confidenceDecision.dataConfidence
        )
    }

    private func basketballHalfCourtDiagram(
        for state: BasketballSituationState,
        event: GameEvent,
        possession: BasketballPossessionState,
        scoreText: String?
    ) -> BasketballHalfCourtDiagram {
        let location = basketballDiagramShotLocation(for: state.shot?.location)
        return BasketballHalfCourtDiagram(
            possessionText: possessionText(for: possession),
            clockText: basketballPeriodClockText(for: state, event: event),
            shotClockText: state.shotClock?.metricText,
            scoreText: scoreText,
            bonusText: state.bonus?.metricText,
            shotText: state.shot?.metricText,
            locationText: state.shot?.location?.label,
            freeThrowText: state.freeThrows?.metricText,
            shotLocation: location,
            pressure: basketballPressure(for: state, event: event, possession: possession)
        )
    }

    private func basketballDiagramShotLocation(
        for location: BasketballShotLocation?
    ) -> BasketballDiagramShotLocation? {
        guard let location,
              location.confidence.canRenderAssertiveState,
              location.coordinateSystem == .normalizedHalfCourt,
              let x = location.x,
              let y = location.y,
              (0...1).contains(x),
              (0...1).contains(y) else {
            return nil
        }
        return BasketballDiagramShotLocation(x: x, y: y, label: location.label)
    }

    private func basketballTitle(for state: BasketballSituationState) -> String {
        if state.shot?.location?.label != nil {
            return "Shot profile"
        }
        if state.bonus?.metricText != nil || state.possession?.phase == .freeThrow {
            return "Foul pressure"
        }
        if state.shotClock?.pressureLabel != nil {
            return "Clock pressure"
        }
        return "Possession pressure"
    }

    private func basketballSetupText(for state: BasketballSituationState) -> String? {
        [
            state.possession?.phase.label,
            state.freeThrows?.metricText,
            state.shotClock?.metricText.map { "\($0) on clock" },
            state.bonus?.metricText,
            state.shot?.location?.label
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: " · ")
            .nilIfBlank
    }

    private func basketballPeriodClockText(for state: BasketballSituationState, event: GameEvent) -> String? {
        [
            state.periodText,
            state.clockText
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: " ")
            .nilIfBlank
            ?? generic.periodClockText(
                periodOrdinal: event.periodOrdinal,
                periodLabel: event.periodLabel,
                clockLabel: event.clockLabel
            ).nilIfBlank
    }

    private func basketballPressureLine(
        for state: BasketballSituationState,
        event: GameEvent,
        scoreText: String?
    ) -> String? {
        if let shotClock = state.shotClock?.pressureLabel {
            return shotClock
        }
        if state.bonus?.possessionTeamStatus == .doubleBonus {
            return "Double bonus"
        }
        if state.bonus?.possessionTeamStatus == .bonus {
            return "In bonus"
        }
        if let pressure = state.possession.flatMap({ basketballPressure(for: state, event: event, possession: $0) }) {
            if pressure >= 0.85 { return "Maximum pressure" }
            if pressure >= 0.65 { return "High leverage" }
            if pressure >= 0.40 { return "Pressure possession" }
            if pressure >= 0.20 { return "Building pressure" }
        }
        return scoreText
    }

    private func basketballTone(for event: GameEvent, state: BasketballSituationState?) -> SportsTheme.Tone {
        if event.importanceMetadata?.isLeadChange == true || event.importanceMetadata?.isTyingPlay == true {
            return .critical
        }
        if state?.shotClock?.pressure ?? 0 >= 0.60 {
            return .critical
        }
        if event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
            return .scoring
        }
        return .neutral
    }

    private func possessionText(for possession: BasketballPossessionState) -> String {
        switch possession.phase {
        case .freeThrow:
            return "\(possession.displayText) FT"
        case .inbound:
            return "\(possession.displayText) inbound"
        default:
            return "\(possession.displayText) ball"
        }
    }

    private func basketballScoreText(
        for event: GameEvent,
        possession: BasketballPossessionState
    ) -> String? {
        guard let scoreBefore = event.scoreBefore,
              let possessionScore = possession.participantRole.flatMap({ scoreBefore.score(for: $0) }) else {
            return nil
        }
        let opponentRole: GameParticipantRole? = switch possession.participantRole {
        case .home: .away
        case .away: .home
        default: nil
        }
        guard let opponentRole,
              let opponentScore = scoreBefore.score(for: opponentRole) else {
            return nil
        }
        let margin = possessionScore - opponentScore
        if margin == 0 { return "Tied" }
        return margin > 0 ? "Up \(margin)" : "Down \(abs(margin))"
    }

    private func basketballPressure(
        for state: BasketballSituationState,
        event: GameEvent,
        possession: BasketballPossessionState
    ) -> Double? {
        var weighted = 0.0
        var available = 0.0
        appendComponent(scorePressure(for: event, possession: possession), weight: 0.40, weighted: &weighted, available: &available)
        appendComponent(timePressure(for: state, event: event), weight: 0.25, weighted: &weighted, available: &available)
        appendComponent(state.shotClock?.pressure, weight: 0.20, weighted: &weighted, available: &available)
        appendComponent(state.bonus?.pressure, weight: 0.10, weighted: &weighted, available: &available)
        appendComponent(shotValuePressure(for: state.shot), weight: 0.05, weighted: &weighted, available: &available)
        guard available > 0 else { return nil }
        return weighted / available
    }

    private func appendComponent(
        _ component: Double?,
        weight: Double,
        weighted: inout Double,
        available: inout Double
    ) {
        guard let component else { return }
        weighted += component * weight
        available += weight
    }

    private func scorePressure(for event: GameEvent, possession: BasketballPossessionState) -> Double? {
        guard let text = basketballScoreText(for: event, possession: possession) else { return nil }
        let margin = Double(text.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init).first ?? 0)
        return max(0, min(1, (12 - margin) / 12))
    }

    private func timePressure(for state: BasketballSituationState, event: GameEvent) -> Double? {
        let isLate = [state.periodText, event.periodLabel]
            .compactMap { $0?.lowercased() }
            .contains { $0.contains("4") || $0.contains("ot") }
        guard isLate,
              let seconds = clockSeconds(from: state.clockText ?? event.clockLabel) else {
            return nil
        }
        return max(0, min(1, (300 - seconds) / 300))
    }

    private func shotValuePressure(for shot: BasketballShotState?) -> Double? {
        switch shot?.value {
        case 3:
            return 1
        case 2:
            return 0.6
        default:
            return nil
        }
    }

    private func clockSeconds(from text: String?) -> Double? {
        guard let text = text?.nilIfBlank else { return nil }
        let parts = text.split(separator: ":").compactMap { Double($0) }
        if parts.count == 2 {
            return parts[0] * 60 + parts[1]
        }
        return Double(text)
    }
}
