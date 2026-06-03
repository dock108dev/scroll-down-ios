import Foundation

// Size note: Baseball situation parsing, confidence gating, and diagram assembly stay together; see cleanup report.
struct BaseballRenderer: GenericSportRendererBacked {
    let generic = GenericSportRenderer(leagueCode: "MLB", sportLabel: "Baseball")

    func eventPresentation(for event: GameEvent) -> GameEventPresentation {
        GameEventPresentation(
            event: event,
            detail: baseballDetail(for: event),
            usesEventDetailFallback: false
        )
    }

    func eventSituationPresentation(for event: GameEvent) -> GameEventSituationPresentation? {
        nil
    }

    func eventSituationPresentation(
        for event: GameEvent,
        context: SportRendererSituationContext
    ) -> GameEventSituationPresentation? {
        let inputs = baseballSituationInputs(for: event, game: context.game)
        return SituationCardPolicy.presentation(
            for: event,
            context: context,
            decision: baseballSituationDecision(for: event, inputs: inputs),
            densityKeyForEvent: baseballDensityKey(for:)
        ) {
            baseballSituationPresentation(for: event, inputs: inputs)
        }
    }

    private func baseballSituationPresentation(
        for event: GameEvent,
        inputs: BaseballSituationInputs
    ) -> GameEventSituationPresentation? {
        let baseState = inputs.baseState
        let outs = inputs.outs
        let count = inputs.count
        let battingOwnership = inputs.battingOwnership
        let pressureLine = inputs.pressureLine
        let contextLine = inputs.contextLine
        let decision = inputs.confidenceDecision

        if case .pressureBoardFallback = decision {
            return SituationConfidenceGate.pressureBoardPresentation(
                for: event,
                sport: .baseball,
                decision: decision,
                periodText: inputs.fallbackPeriodText,
                contextLine: contextLine,
                tone: self.situationTone(for: event)
            )
        }

        guard case .sportDiagram = decision else {
            return nil
        }

        let setupText = [
            baseState?.label,
            self.outsLabel(from: outs),
            count.map { "\($0) count" }
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: " · ")
            .nilIfBlank
        let diagram = self.baseballDiagram(
            baseState: baseState,
            battingOwnership: battingOwnership,
            outs: outs,
            count: count
        )

        guard diagram != nil,
              [setupText, pressureLine, contextLine].contains(where: { $0?.nilIfBlank != nil }) else {
            return nil
        }

        return GameEventSituationPresentation(
            title: "Situation",
            periodText: inputs.periodText,
            setupText: setupText,
            contextLine: contextLine,
            pressureLine: pressureLine,
            sport: .baseball,
            layout: .baseball,
            ownership: battingOwnership,
            diagram: diagram,
            accent: GameEventSituationAccent(
                ownership: battingOwnership?.participantRole ?? event.teamOwnership,
                teamAbbreviation: battingOwnership?.teamAbbreviation ?? event.teamAbbreviation,
                teamLabel: battingOwnership?.teamLabel ?? event.presentation?.teamLabel,
                tone: self.situationTone(for: event)
            ),
            dataConfidence: decision.dataConfidence
        )
    }

    private func baseballSituationInputs(for event: GameEvent, game: Game?) -> BaseballSituationInputs {
        let prePitchState = baseballPrePitchState(for: event)
        let baseState = prePitchState.baseState
        let outs = prePitchState.outs
        let count = prePitchState.count?.label
        let battingOwnership = self.battingOwnership(for: event, prePitchState: prePitchState, game: game)
        let periodText = self.baseballSituationPeriodText(
            for: event,
            prePitchState: prePitchState,
            battingOwnership: battingOwnership,
            style: .compact
        )
        let fallbackPeriodText = self.baseballSituationPeriodText(
            for: event,
            prePitchState: prePitchState,
            battingOwnership: battingOwnership,
            style: .expanded
        )
        let pressureLine = self.importanceContext(for: event, hasBaseState: baseState != nil)
        let contextLine = self.scorePressureLine(for: event)
        let evidence = SituationConfidenceEvidence(
            hasExplicitPreEventState: baseState != nil && prePitchState.sourceConfidence.allowsSportDiagram,
            hasExplicitGenericContext: SituationConfidenceGate.hasGenericContext(for: event),
            hasDerivedState: hasDerivedBaseballState(for: event, battingOwnership: battingOwnership),
            hasAmbiguousMetadata: hasAmbiguousBaseballMetadata(event.sportMetadata),
            hasEventLocalContext: SituationConfidenceGate.hasEventLocalContext(for: event)
        )
        let confidenceDecision = baseballConfidenceDecision(
            for: event,
            decision: SituationConfidenceGate.decision(for: evidence)
        )
        return BaseballSituationInputs(
            baseState: baseState,
            battingOwnership: battingOwnership,
            outs: outs,
            periodText: periodText,
            fallbackPeriodText: fallbackPeriodText,
            contextLine: contextLine,
            pressureLine: pressureLine,
            count: count,
            confidenceDecision: confidenceDecision
        )
    }

    private func baseballSituationDecision(
        for event: GameEvent,
        inputs: BaseballSituationInputs
    ) -> SituationCardLayoutDecision {
        let priority = baseballSituationPriority(for: event, inputs: inputs)
        guard priority != .routine else {
            return .suppress
        }
        switch inputs.confidenceDecision {
        case .sportDiagram:
            return .sportDiagram(priority: priority, densityKey: baseballDensityKey(for: event))
        case .pressureBoardFallback:
            return .pressureBoardFallback(priority: priority, densityKey: baseballDensityKey(for: event))
        case .none:
            return .suppress
        }
    }

    private func baseballSituationPriority(
        for event: GameEvent,
        inputs: BaseballSituationInputs
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
            if isUsefulBaseballCardEvent(event), isHighConfidenceThreat(inputs) {
                return .highConfidenceThreat
            }
            return .routine
        }
    }

    private func baseballConfidenceDecision(
        for event: GameEvent,
        decision: SituationBlockDecision
    ) -> SituationBlockDecision {
        guard case .sportDiagram(let confidence) = decision,
              skipsBaseballDiagram(for: event) else {
            return decision
        }
        return .pressureBoardFallback(confidence)
    }

    private func isHighConfidenceThreat(_ inputs: BaseballSituationInputs) -> Bool {
        guard case .sportDiagram(.explicitPreEvent) = inputs.confidenceDecision,
              let baseState = inputs.baseState else {
            return false
        }
        return baseState.occupiedBases.contains(.second)
            || baseState.occupiedBases.contains(.third)
            || baseState.occupiedBases == [.first, .second, .third]
    }

    private func isUsefulBaseballCardEvent(_ event: GameEvent) -> Bool {
        baseballEventDescriptors(for: event).contains(where: descriptorMatchesUsefulBaseballEvent)
    }

    private func skipsBaseballDiagram(for event: GameEvent) -> Bool {
        baseballEventDescriptors(for: event).contains(where: descriptorSkipsBaseballDiagram)
    }

    private func baseballEventDescriptors(for event: GameEvent) -> [String] {
        [
            event.eventType,
            event.presentation?.eventTypeLabel,
            event.presentation?.primaryLabel,
            event.headline
        ].compactMap { $0?.nilIfBlank }
            .map(normalizedSituationMetadataKey)
    }

    private func descriptorMatchesUsefulBaseballEvent(_ descriptor: String) -> Bool {
        let tokens = Set(descriptor.split(separator: "_").map(String.init))
        if descriptor.contains("base_on_balls") || tokens.contains("walk") || tokens.contains("walks") || tokens.contains("walked") {
            return true
        }
        if descriptor.contains("strikeout") || descriptor.contains("strikes_out") || descriptor.contains("struck_out") {
            return true
        }
        if descriptor.contains("home_run") || tokens.contains("homer") || tokens.contains("homers") || tokens.contains("homered") {
            return true
        }
        if tokens.contains("single") || tokens.contains("singles") || tokens.contains("singled") {
            return true
        }
        if !descriptor.contains("double_play"),
           tokens.contains("double") || tokens.contains("doubles") || tokens.contains("doubled") {
            return true
        }
        if tokens.contains("triple") || tokens.contains("triples") || tokens.contains("tripled") {
            return true
        }
        if descriptor.contains("groundout") || descriptor.contains("grounds_out") || descriptor.contains("ground_out") {
            return true
        }
        return descriptor.contains("flyout") || descriptor.contains("flies_out") || descriptor.contains("fly_out")
    }

    private func descriptorSkipsBaseballDiagram(_ descriptor: String) -> Bool {
        if descriptor == "final" || descriptor.contains("game_over") || descriptor.contains("end_of_game") || descriptor.contains("game_end") {
            return true
        }
        if descriptor.contains("end_of_inning") || descriptor.contains("inning_end") || descriptor.contains("middle_of_inning") {
            return true
        }
        if descriptor.contains("end_of_top") || descriptor.contains("end_of_bottom") || descriptor.contains("middle_of") {
            return true
        }
        return false
    }

    private func baseballDensityKey(for event: GameEvent) -> String? {
        let prePitchState = baseballPrePitchState(for: event)
        return [
            prePitchState.baseState?.label,
            prePitchState.outs.map(String.init),
            prePitchState.count?.label
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: "|")
            .nilIfBlank
    }

    func scoreboardPresentation(for game: Game) -> ScoreboardPresentation {
        var presentation = generic.scoreboardPresentation(for: game)
        presentation.title = presentation.segments.isEmpty ? "Final Score" : "Line Score"
        presentation.totalHeader = "R"
        return presentation
    }

    func statsPresentation(for detail: GameDetail) -> GameStatsPresentation {
        GameStatsPresentation(
            playerSections: StatPresentationBuilder.baseballPlayerSections(for: detail),
            teamSection: generic.teamStatSection(for: detail)
        )
    }
}
