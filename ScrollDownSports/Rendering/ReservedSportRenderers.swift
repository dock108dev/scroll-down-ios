struct FootballRenderer: GenericSportRendererBacked {
    let generic: GenericSportRenderer

    init(leagueCode: String) {
        generic = GenericSportRenderer(leagueCode: leagueCode, sportLabel: "Football")
    }

    func eventSituationPresentation(
        for event: GameEvent,
        context: SportRendererSituationContext
    ) -> GameEventSituationPresentation? {
        let inputs = footballSituationInputs(for: event)
        return SituationCardPolicy.presentation(
            for: event,
            context: context,
            decision: footballSituationDecision(for: event, inputs: inputs),
            densityKeyForEvent: footballDensityKey(for:)
        ) {
            footballSituationPresentation(for: event, inputs: inputs)
        }
    }

    private func footballSituationPresentation(
        for event: GameEvent,
        inputs: FootballSituationInputs
    ) -> GameEventSituationPresentation? {
        guard let fieldSituation = inputs.fieldSituation,
              case .sportDiagram = inputs.confidenceDecision else {
            return SituationConfidenceGate.pressureBoardPresentation(
                for: event,
                sport: .football,
                decision: inputs.confidenceDecision,
                tone: situationTone(for: event)
            )
        }

        let ownership = footballOwnership(for: fieldSituation)
        let strip = footballFieldStrip(for: fieldSituation, event: event)
        return GameEventSituationPresentation(
            title: "Situation",
            periodText: footballSituationPeriodText(for: event),
            setupText: "\(fieldSituation.downDistanceText) · \(fieldSituation.yardLine.label)",
            contextLine: scorePressureLine(for: event),
            pressureLine: footballPressureLine(for: event, situation: fieldSituation),
            sport: .football,
            layout: .football,
            ownership: ownership,
            diagram: .footballFieldStrip(strip),
            accent: GameEventSituationAccent(
                ownership: ownership?.participantRole ?? event.teamOwnership,
                teamAbbreviation: ownership?.teamAbbreviation ?? event.teamAbbreviation,
                teamLabel: ownership?.teamLabel ?? event.presentation?.teamLabel,
                tone: situationTone(for: event)
            ),
            dataConfidence: inputs.confidenceDecision.dataConfidence
        )
    }

    private func footballSituationDecision(
        for event: GameEvent,
        inputs: FootballSituationInputs
    ) -> SituationCardLayoutDecision {
        let priority = footballSituationPriority(for: event, inputs: inputs)
        guard priority != .routine else {
            return .suppress
        }
        switch inputs.confidenceDecision {
        case .sportDiagram:
            return .sportDiagram(priority: priority, densityKey: footballDensityKey(for: event))
        case .pressureBoardFallback:
            return .pressureBoardFallback(priority: priority, densityKey: footballDensityKey(for: event))
        case .none:
            return .suppress
        }
    }

    private func footballSituationPriority(
        for event: GameEvent,
        inputs: FootballSituationInputs
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
            if let situation = inputs.fieldSituation,
               situation.down >= 3 || situation.distance == .goalToGo || footballFieldStrip(for: situation, event: event).isRedZone {
                return .highConfidenceThreat
            }
            return .routine
        }
    }

    private func footballFieldStrip(
        for situation: FootballFieldSituation,
        event: GameEvent
    ) -> FootballFieldStripDiagram {
        let line = lineOfScrimmageX(for: situation)
        let direction: FootballFieldDirection = situation.possession == nil ? .unknown : .leftToRight
        let firstDownX = firstDownX(for: situation, lineOfScrimmageX: line)
        return FootballFieldStripDiagram(
            downDistanceText: situation.downDistanceText,
            yardLineText: situation.yardLine.label,
            possessionText: situation.possession?.teamAbbreviation,
            lineOfScrimmageX: line,
            firstDownX: firstDownX,
            offenseDirection: direction,
            eventTypeText: EventLabelResolver.customerLabel(from: event.presentation?.eventTypeLabel)
                ?? EventLabelResolver.customerLabel(from: event.eventType),
            isRedZone: line >= 80 || firstDownX == 100 || situation.distance == .goalToGo
        )
    }

    private func lineOfScrimmageX(for situation: FootballFieldSituation) -> Double {
        guard let possession = situation.possession else {
            return 50
        }
        switch situation.yardLine.side {
        case .midfield:
            return 50
        case .own:
            return Double(situation.yardLine.yardNumber)
        case .opponent:
            return 100 - Double(situation.yardLine.yardNumber)
        case .team:
            guard let yardTeam = situation.yardLine.teamAbbreviation?.nilIfBlank,
                  let possessionTeam = possession.teamAbbreviation?.nilIfBlank else {
                return 50
            }
            if yardTeam.caseInsensitiveCompare(possessionTeam) == .orderedSame {
                return Double(situation.yardLine.yardNumber)
            }
            return 100 - Double(situation.yardLine.yardNumber)
        }
    }

    private func firstDownX(
        for situation: FootballFieldSituation,
        lineOfScrimmageX: Double
    ) -> Double? {
        guard situation.possession != nil else { return nil }
        switch situation.distance {
        case .yards(let yards):
            return min(100, lineOfScrimmageX + Double(yards))
        case .goalToGo:
            return 100
        case .inches:
            return min(100, lineOfScrimmageX + 1)
        }
    }

    private func footballOwnership(for situation: FootballFieldSituation) -> GameEventSituationOwnership? {
        guard let possession = situation.possession else { return nil }
        return GameEventSituationOwnership(
            role: .offense,
            participantRole: possession.participantRole,
            teamAbbreviation: possession.teamAbbreviation,
            teamLabel: possession.teamLabel,
            confidence: .explicit
        )
    }

    private func footballSituationPeriodText(for event: GameEvent) -> String? {
        generic.periodClockText(
            periodOrdinal: event.periodOrdinal,
            periodLabel: event.periodLabel,
            clockLabel: event.clockLabel
        ).nilIfBlank
    }

    private func footballPressureLine(
        for event: GameEvent,
        situation: FootballFieldSituation
    ) -> String? {
        if event.importanceMetadata?.isLeadChange == true {
            return "Lead change"
        }
        if event.importanceMetadata?.isTyingPlay == true {
            return "Tying play"
        }
        if situation.distance == .goalToGo {
            return "Goal to go"
        }
        if situation.down >= 3 {
            return situation.down == 4 ? "Fourth down" : "Third down"
        }
        return nil
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

    private func footballDensityKey(for event: GameEvent) -> String? {
        let situation = footballFieldSituation(for: event)
        return [
            situation?.downDistanceText,
            situation?.yardLine.label,
            situation?.possession?.teamAbbreviation
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: "|")
            .nilIfBlank
    }
}

struct BasketballRenderer: GenericSportRendererBacked {
    let generic: GenericSportRenderer

    init(leagueCode: String) {
        generic = GenericSportRenderer(leagueCode: leagueCode, sportLabel: "Basketball")
    }

    func eventSituationPresentation(
        for event: GameEvent,
        context: SportRendererSituationContext
    ) -> GameEventSituationPresentation? {
        let inputs = basketballSituationInputs(for: event)
        return SituationCardPolicy.presentation(
            for: event,
            context: context,
            decision: basketballSituationDecision(for: event, inputs: inputs),
            densityKeyForEvent: basketballDensityKey(for:)
        ) {
            basketballSituationPresentation(for: event, inputs: inputs)
        }
    }

    private func basketballSituationDecision(
        for event: GameEvent,
        inputs: BasketballSituationInputs
    ) -> SituationCardLayoutDecision {
        switch inputs.confidenceDecision {
        case .sportDiagram:
            return .sportDiagram(priority: basketballSituationPriority(for: event), densityKey: basketballDensityKey(for: event))
        case .pressureBoardFallback:
            return .pressureBoardFallback(priority: basketballSituationPriority(for: event), densityKey: basketballDensityKey(for: event))
        case .none:
            return .suppress
        }
    }

    private func basketballSituationPriority(for event: GameEvent) -> SituationCardPriority {
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
            return event.importance == .primary ? .notable : .routine
        }
    }

    private func basketballDensityKey(for event: GameEvent) -> String? {
        let state = basketballSituationInputs(for: event).state
        return [
            state?.possession?.displayText,
            state?.shotClock?.metricText,
            state?.bonus?.metricText,
            state?.shot?.location?.label,
            event.periodLabel,
            event.clockLabel
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: "|")
            .nilIfBlank
    }
}

struct SoccerRenderer: GenericSportRendererBacked {
    let generic: GenericSportRenderer

    init(leagueCode: String) {
        generic = GenericSportRenderer(leagueCode: leagueCode, sportLabel: "Soccer")
    }

    func eventPresentation(for event: GameEvent) -> GameEventPresentation {
        GameEventPresentation(event: event, scoringFallbackLabel: "Goal")
    }

}

struct GolfRenderer: GenericSportRendererBacked {
    let generic: GenericSportRenderer

    init(leagueCode: String) {
        generic = GenericSportRenderer(leagueCode: leagueCode, sportLabel: "Golf")
    }

    func scoreboardPresentation(for game: Game) -> ScoreboardPresentation {
        var presentation = generic.scoreboardPresentation(for: game)
        presentation.title = "Leaderboard"
        presentation.systemImage = "list.number"
        presentation.revealTitle = "Leaderboard hidden"
        presentation.revealDescription = "Reveal only when you are ready to see the tournament standings."
        presentation.revealButtonTitle = "Reveal leaderboard"
        presentation.hideButtonTitle = "Hide leaderboard"
        return presentation
    }

    func eventSituationPresentation(
        for event: GameEvent,
        context: SportRendererSituationContext
    ) -> GameEventSituationPresentation? {
        if let board = GolfPressureClassifier.board(for: event) {
            return SituationCardPolicy.presentation(
                for: event,
                context: context,
                decision: .pressureBoardFallback(priority: board.priority, densityKey: board.densityKey),
                densityKeyForEvent: { GolfPressureClassifier.board(for: $0)?.densityKey }
            ) {
                NonFieldPressureBoardBuilder.presentation(for: event, board: board)
            }
        }
        return ReservedSportSituationBoundary(generic: generic).eventSituationPresentation(for: event, context: context)
    }
}

struct TennisRenderer: GenericSportRendererBacked {
    let generic: GenericSportRenderer

    init(leagueCode: String) {
        generic = GenericSportRenderer(leagueCode: leagueCode, sportLabel: "Tennis")
    }

    func scoreboardPresentation(for game: Game) -> ScoreboardPresentation {
        var presentation = generic.scoreboardPresentation(for: game)
        presentation.title = "Match Score"
        presentation.systemImage = "tennisball"
        presentation.revealTitle = "Match score hidden"
        presentation.revealDescription = "Reveal only when you are ready to see the current or final match score."
        presentation.revealButtonTitle = "Reveal match score"
        presentation.hideButtonTitle = "Hide match score"
        return presentation
    }

    func eventSituationPresentation(
        for event: GameEvent,
        context: SportRendererSituationContext
    ) -> GameEventSituationPresentation? {
        if let board = TennisPressureClassifier.board(for: event) {
            return SituationCardPolicy.presentation(
                for: event,
                context: context,
                decision: .pressureBoardFallback(priority: board.priority, densityKey: board.densityKey),
                densityKeyForEvent: { TennisPressureClassifier.board(for: $0)?.densityKey }
            ) {
                NonFieldPressureBoardBuilder.presentation(for: event, board: board)
            }
        }
        return ReservedSportSituationBoundary(generic: generic).eventSituationPresentation(for: event, context: context)
    }
}

struct ReservedSportSituationBoundary {
    let generic: GenericSportRenderer

    func eventSituationPresentation(
        for event: GameEvent,
        context: SportRendererSituationContext
    ) -> GameEventSituationPresentation? {
        guard let presentation = generic.eventSituationPresentation(for: event, context: context),
              presentation.layout == .pressureBoardFallback,
              case .pressureBoardFallback = presentation.diagram,
              presentation.ownership?.claimsPossession != true else {
            return nil
        }
        return presentation
    }
}
