import Foundation

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
                tone: situationTone(for: event)
            )
        }

        guard case .sportDiagram = decision else {
            return nil
        }

        let setupText = [
            baseState?.label,
            outsLabel(from: outs),
            count.map { "\($0) count" }
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: " · ")
            .nilIfBlank
        let diagram = baseballDiagram(
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
                tone: situationTone(for: event)
            ),
            dataConfidence: decision.dataConfidence
        )
    }

    private func baseballSituationInputs(for event: GameEvent, game: Game?) -> BaseballSituationInputs {
        let prePitchState = baseballPrePitchState(for: event)
        let baseState = prePitchState.baseState
        let outs = prePitchState.outs
        let count = prePitchState.count?.label
        let battingOwnership = battingOwnership(for: event, prePitchState: prePitchState, game: game)
        let periodText = baseballSituationPeriodText(
            for: event,
            prePitchState: prePitchState,
            battingOwnership: battingOwnership,
            style: .compact
        )
        let fallbackPeriodText = baseballSituationPeriodText(
            for: event,
            prePitchState: prePitchState,
            battingOwnership: battingOwnership,
            style: .expanded
        )
        let pressureLine = importanceContext(for: event, hasBaseState: baseState != nil)
        let contextLine = scorePressureLine(for: event)
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

    private func baseballDetail(for event: GameEvent) -> String? {
        event.detail?.nilIfBlank.flatMap { value in
            event.headline.range(of: value, options: [.caseInsensitive, .diacriticInsensitive]) == nil ? value : nil
        }
    }

    private func importanceContext(for event: GameEvent, hasBaseState: Bool) -> String? {
        if event.importanceMetadata?.isLeadChange == true {
            return "Lead change"
        }
        if event.importanceMetadata?.isTyingPlay == true {
            return "Tying play"
        }

        for reason in event.importanceMetadata?.reasons ?? [] {
            switch normalizedSituationMetadataKey(reason) {
            case "runner_aboard":
                if !hasBaseState { return "Runner aboard" }
            case "runners_in_scoring_position", "runner_in_scoring_position":
                return "Runner in scoring position"
            case "bases_loaded":
                if !hasBaseState { return "Bases loaded" }
            case "late_game":
                return "Late inning"
            default:
                continue
            }
        }
        return nil
    }

    private func scorePressureLine(for event: GameEvent) -> String? {
        ScorePressurePresentation.line(
            for: event,
            teamLabel: event.presentation?.teamLabel ?? event.teamAbbreviation
        )?.text
    }

    private func baseballSituationPeriodText(
        for event: GameEvent,
        prePitchState: BaseballPrePitchState,
        battingOwnership: GameEventSituationOwnership?,
        style: BaseballSituationPeriodTextStyle
    ) -> String? {
        let formatterOutput = PeriodLabelFormatter.output(
            sport: .mlb,
            leagueCode: "MLB",
            periodOrdinal: event.periodOrdinal,
            periodLabel: event.periodLabel,
            clockLabel: event.clockLabel
        )
        let inferredHalf = prePitchState.inningHalf
            ?? baseballInningHalf(from: prePitchState.battingTeam?.side)
            ?? baseballInningHalf(from: battingOwnership?.participantRole)
        let inning = prePitchState.inning ?? event.periodOrdinal
        if let inning, let inferredHalf {
            switch style {
            case .compact:
                return [
                    "\(inferredHalf.compactPrefix)\(inning)",
                    formatterOutput.rowClockText.nilIfBlank
                ]
                .compactMap(\.self)
                .joined(separator: " ")
            case .expanded:
                return "\(inferredHalf.displayName) \(ordinal(inning))"
            }
        }
        return formatterOutput.situationText
    }

    private func baseballInningHalf(from role: GameParticipantRole?) -> BaseballInningHalf? {
        switch role {
        case .away:
            return .top
        case .home:
            return .bottom
        case .other, nil:
            return nil
        }
    }

    private func ordinal(_ value: Int) -> String {
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

    private func situationTone(for event: GameEvent) -> SportsTheme.Tone {
        if event.importanceMetadata?.isLeadChange == true || event.importanceMetadata?.isTyingPlay == true {
            return .critical
        }
        if event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
            return .scoring
        }
        return .neutral
    }

    private func baseballDiagram(
        baseState: BaseballBaseState?,
        battingOwnership: GameEventSituationOwnership?,
        outs: Int?,
        count: String?
    ) -> GameEventSituationDiagram? {
        guard let baseState else {
            return nil
        }
        return .baseballDiamond(
            BaseballSituationDiagram(
                occupiedBases: baseState.occupiedBases,
                batting: battingOwnership,
                outs: outs,
                count: count
            )
        )
    }

    private func outsLabel(from outs: Int?) -> String? {
        guard let outs else { return nil }
        return outs == 1 ? "1 out" : "\(outs) outs"
    }

    private func battingOwnership(
        for event: GameEvent,
        prePitchState: BaseballPrePitchState,
        game: Game?
    ) -> GameEventSituationOwnership? {
        if let explicit = explicitBattingOwnership(for: event, game: game) {
            return explicit
        }
        if let inningHalf = prePitchState.inningHalf {
            let participantRole: GameParticipantRole = inningHalf == .top ? .away : .home
            let participant = game?.participants.first { $0.role == participantRole }
            return GameEventSituationOwnership(
                role: .batting,
                participantRole: participantRole,
                teamAbbreviation: participant?.abbreviation,
                teamLabel: participant?.name,
                confidence: .derivedFromPeriod
            )
        }
        return eventFallbackOwnership(for: event)
    }

    private func eventFallbackOwnership(for event: GameEvent) -> GameEventSituationOwnership? {
        guard event.teamOwnership != nil
            || event.teamAbbreviation?.nilIfBlank != nil
            || event.presentation?.teamLabel?.nilIfBlank != nil else {
            return nil
        }
        return GameEventSituationOwnership(
            role: .association,
            participantRole: event.teamOwnership,
            teamAbbreviation: event.teamAbbreviation,
            teamLabel: event.presentation?.teamLabel,
            confidence: .eventFallback
        )
    }

    private func explicitBattingOwnership(for event: GameEvent, game: Game?) -> GameEventSituationOwnership? {
        let abbreviation = [
            event.situationBefore?.sportState?.baseball?.battingTeamAbbreviation,
            situationMetadataText(
                [
                    "battingTeamAbbreviation",
                    "batting_team_abbreviation",
                    "offenseTeamAbbreviation",
                    "offense_team_abbreviation",
                    "attackingTeamAbbreviation",
                    "attacking_team_abbreviation"
                ],
                in: event.sportMetadata
            )
        ].firstNonBlank
        let explicitRole = situationMetadataText(
            [
                "battingTeamRole",
                "batting_team_role",
                "battingSide",
                "batting_side",
                "offenseTeamRole",
                "offense_team_role"
            ],
            in: event.sportMetadata
        ).flatMap(situationParticipantRole(from:))
        let roleParticipant = explicitRole.flatMap { role in
            game?.participants.first { $0.role == role }
        }
        let abbreviationParticipant = abbreviation.flatMap { abbreviation in
            game?.participants.first { participant in
                participant.abbreviation?.caseInsensitiveCompare(abbreviation) == .orderedSame
            }
        }

        guard abbreviation?.nilIfBlank != nil || explicitRole != nil || roleParticipant != nil || abbreviationParticipant != nil else {
            return nil
        }
        if let explicitRole {
            let abbreviationMatchesRole = abbreviationParticipant?.role == explicitRole || abbreviationParticipant == nil
            return GameEventSituationOwnership(
                role: .batting,
                participantRole: explicitRole,
                teamAbbreviation: roleParticipant?.abbreviation ?? (abbreviationMatchesRole ? abbreviation?.nilIfBlank : nil),
                teamLabel: roleParticipant?.name
                    ?? (abbreviationMatchesRole ? abbreviationParticipant?.name : nil)
                    ?? event.presentation?.teamLabel,
                confidence: .explicit
            )
        }
        let participant = abbreviationParticipant
        return GameEventSituationOwnership(
            role: .batting,
            participantRole: participant?.role,
            teamAbbreviation: abbreviation?.nilIfBlank ?? participant?.abbreviation,
            teamLabel: participant?.name ?? event.presentation?.teamLabel,
            confidence: .explicit
        )
    }

}

private struct BaseballSituationInputs {
    let baseState: BaseballBaseState?
    let battingOwnership: GameEventSituationOwnership?
    let outs: Int?
    let periodText: String?
    let fallbackPeriodText: String?
    let contextLine: String?
    let pressureLine: String?
    let count: String?
    let confidenceDecision: SituationBlockDecision
}

private enum BaseballSituationPeriodTextStyle {
    case compact
    case expanded
}
