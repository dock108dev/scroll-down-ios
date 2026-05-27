import Foundation

enum SituationStateConfidence: String, Hashable, Sendable {
    case explicitPreEvent
    case explicitGenericEventContext
    case derivedState
    case ambiguousMetadata
    case missingState
}

enum SituationBlockDecision: Hashable, Sendable {
    case sportDiagram(SituationStateConfidence)
    case pressureBoardFallback(SituationStateConfidence)
    case none(SituationStateConfidence)

    var confidence: SituationStateConfidence {
        switch self {
        case .sportDiagram(let confidence),
             .pressureBoardFallback(let confidence),
             .none(let confidence):
            return confidence
        }
    }

    var dataConfidence: GameEventSituationDataConfidence {
        switch confidence {
        case .explicitPreEvent:
            return .explicitPreEvent
        case .explicitGenericEventContext:
            return .explicitGenericEventContext
        case .derivedState:
            return .derivedState
        case .ambiguousMetadata:
            return .ambiguousMetadata
        case .missingState:
            return .missingState
        }
    }
}

struct SituationConfidenceEvidence: Hashable, Sendable {
    let hasExplicitPreEventState: Bool
    let hasExplicitGenericContext: Bool
    let hasDerivedState: Bool
    let hasAmbiguousMetadata: Bool
    let hasEventLocalContext: Bool
}

enum SituationConfidenceGate {
    static func decision(for evidence: SituationConfidenceEvidence) -> SituationBlockDecision {
        if evidence.hasExplicitPreEventState {
            return .sportDiagram(.explicitPreEvent)
        }
        if evidence.hasAmbiguousMetadata, evidence.hasEventLocalContext {
            return .pressureBoardFallback(.ambiguousMetadata)
        }
        if evidence.hasExplicitGenericContext, evidence.hasEventLocalContext {
            return .pressureBoardFallback(.explicitGenericEventContext)
        }
        if evidence.hasDerivedState {
            return .none(.derivedState)
        }
        return .none(.missingState)
    }

    static func genericEvidence(for event: GameEvent) -> SituationConfidenceEvidence {
        SituationConfidenceEvidence(
            hasExplicitPreEventState: false,
            hasExplicitGenericContext: hasGenericContext(for: event),
            hasDerivedState: false,
            hasAmbiguousMetadata: false,
            hasEventLocalContext: hasEventLocalContext(for: event)
        )
    }

    static func hasEventLocalContext(for event: GameEvent) -> Bool {
        let hasTime = [
            event.clockText,
            event.periodLabel,
            event.clockLabel,
            event.presentation?.timeLabel
        ].contains { $0?.nilIfBlank != nil }
        let hasTeam = event.teamOwnership != nil
            || event.teamAbbreviation?.nilIfBlank != nil
            || event.presentation?.teamLabel?.nilIfBlank != nil
        return hasScoreContext(for: event) || (hasTime && hasTeam)
    }

    static func hasGenericContext(for event: GameEvent) -> Bool {
        hasScoreContext(for: event) || hasEventMeaning(for: event)
    }

    static func pressureBoardPresentation(
        for event: GameEvent,
        sport: GameEventSituationSport,
        decision: SituationBlockDecision,
        title: String = "Context",
        periodText: String? = nil,
        contextLine: String? = nil,
        pressureLine: String? = nil,
        tone: SportsTheme.Tone = .neutral
    ) -> GameEventSituationPresentation? {
        guard case .pressureBoardFallback = decision else {
            return nil
        }
        let association = association(for: event)
        let resolvedPeriodText = periodText?.nilIfBlank
        let setupText = sport == .baseball ? nil : event.clockText.nilIfBlank
        let scorePressure = scorePressureLine(for: event)
        let resolvedContextLine = contextLine?.nilIfBlank ?? scorePressure?.text
        let resolvedPressureLine = pressureLine?.nilIfBlank ?? genericPressureLine(for: event, sport: sport)
        let metrics = pressureBoardMetrics(
            for: event,
            sport: sport,
            periodText: resolvedPeriodText,
            association: association,
            scoreLine: scorePressure?.before.shortText,
            pressureLine: resolvedPressureLine
        )

        guard [setupText, resolvedContextLine, resolvedPressureLine].contains(where: { $0?.nilIfBlank != nil })
            || association != nil
            || !metrics.isEmpty else {
            return nil
        }

        return GameEventSituationPresentation(
            title: title.nilIfBlank ?? "Context",
            periodText: sport == .baseball ? resolvedPeriodText : nil,
            setupText: setupText,
            contextLine: resolvedContextLine,
            pressureLine: resolvedPressureLine,
            sport: sport,
            layout: .pressureBoardFallback,
            ownership: association,
            diagram: .pressureBoardFallback(
                PressureBoardSituationDiagram(
                    associations: association.map { [$0] } ?? [],
                    metrics: metrics
                )
            ),
            accent: GameEventSituationAccent(
                ownership: association?.participantRole ?? event.teamOwnership,
                teamAbbreviation: association?.teamAbbreviation ?? event.teamAbbreviation,
                teamLabel: association?.teamLabel ?? event.presentation?.teamLabel,
                tone: tone
            ),
            dataConfidence: decision.dataConfidence
        )
    }

    private static func pressureBoardMetrics(
        for event: GameEvent,
        sport: GameEventSituationSport,
        periodText: String?,
        association: GameEventSituationOwnership?,
        scoreLine: String?,
        pressureLine: String?
    ) -> [PressureBoardSituationMetric] {
        var metrics: [PressureBoardSituationMetric] = []
        let timingMetric = timingMetric(for: sport, event: event, periodText: periodText)
        appendMetric(
            label: timingMetric.label,
            value: timingMetric.value,
            emphasis: .primary,
            to: &metrics
        )
        appendMetric(
            label: "Team",
            value: association?.teamAbbreviation ?? association?.teamLabel ?? event.teamAbbreviation ?? event.presentation?.teamLabel,
            emphasis: .team,
            to: &metrics
        )
        appendMetric(label: "Play", value: eventLabel(for: event), emphasis: .secondary, to: &metrics)
        appendMetric(label: "Score", value: scoreLine, emphasis: .pressure, to: &metrics)
        if scoreLine?.nilIfBlank == nil, !isResultSensitivePressureLine(pressureLine) {
            appendMetric(label: "Pressure", value: pressureLine, emphasis: .pressure, to: &metrics)
        }
        return metrics
    }

    private static func timingMetric(
        for sport: GameEventSituationSport,
        event: GameEvent,
        periodText: String?
    ) -> (label: String, value: String?) {
        switch sport {
        case .baseball:
            return ("Inning", periodText ?? event.clockText)
        case .football, .basketball:
            return ("Quarter", event.clockText)
        case .hockey:
            return ("Period", event.clockText)
        case .soccer:
            return ("Minute", event.clockText)
        case .golf:
            return ("Hole", event.clockText)
        case .tennis:
            return ("Set", event.clockText)
        case .generic:
            return ("Time", event.clockText)
        }
    }

    private static func isResultSensitivePressureLine(_ text: String?) -> Bool {
        guard let normalized = text?.nilIfBlank.map(normalizedSituationMetadataKey) else {
            return false
        }
        return normalized.contains("lead_change")
            || normalized.contains("tying_play")
            || normalized.contains("scoring_play")
            || normalized.contains("scoring_swing")
            || normalized.contains("finish")
            || normalized.contains("go_ahead")
            || normalized.contains("cuts_deficit")
            || normalized.contains("extends_lead")
    }

    private static func appendMetric(
        label: String,
        value: String?,
        emphasis: PressureBoardSituationMetricEmphasis,
        to metrics: inout [PressureBoardSituationMetric]
    ) {
        guard let value = value?.nilIfBlank,
              !metrics.contains(where: { $0.label == label && $0.value == value }) else {
            return
        }
        metrics.append(PressureBoardSituationMetric(label: label, value: value, emphasis: emphasis))
    }

    private static func hasScoreContext(for event: GameEvent) -> Bool {
        event.scoreBefore != nil
    }

    private static func hasEventMeaning(for event: GameEvent) -> Bool {
        event.importance == .primary
            || event.importance == .secondary
            || event.importanceMetadata?.isKeyMoment == true
            || event.importanceMetadata?.isScoringPlay == true
            || event.importanceMetadata?.isLeadChange == true
            || event.importanceMetadata?.isTyingPlay == true
            || eventLabel(for: event)?.nilIfBlank != nil
    }

    private static func association(for event: GameEvent) -> GameEventSituationOwnership? {
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

    private static func scorePressureLine(for event: GameEvent) -> ScorePressureLine? {
        ScorePressurePresentation.line(
            for: event,
            teamLabel: event.presentation?.teamLabel ?? event.teamAbbreviation
        )
    }

    private static func eventLabel(for event: GameEvent) -> String? {
        [
            EventLabelResolver.customerLabel(from: event.presentation?.eventTypeLabel),
            EventLabelResolver.customerLabel(from: event.presentation?.primaryLabel),
            EventLabelResolver.customerLabel(from: event.eventType)
        ].firstNonBlank
    }

    private static func genericPressureLine(for event: GameEvent, sport: GameEventSituationSport) -> String? {
        if event.importanceMetadata?.isLeadChange == true {
            return "Lead change"
        }
        if event.importanceMetadata?.isTyingPlay == true {
            return "Tying play"
        }
        if event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
            if sport == .baseball {
                return nil
            }
            return "Scoring play"
        }
        if event.importanceMetadata?.isKeyMoment == true || event.importance == .primary {
            return "Key play"
        }
        if event.importance == .secondary {
            return "Notable play"
        }
        return nil
    }
}
