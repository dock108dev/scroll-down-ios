import Foundation

enum SituationCardPriority: Hashable, Sendable {
    case routine
    case notable
    case highConfidenceThreat
    case keyMoment
    case scoringSwing
    case bigMoment
}

enum SituationCardLayoutDecision: Hashable, Sendable {
    case suppress
    case sportDiagram(priority: SituationCardPriority, densityKey: String?)
    case pressureBoardFallback(priority: SituationCardPriority, densityKey: String?)

    var priority: SituationCardPriority? {
        switch self {
        case .suppress:
            return nil
        case .sportDiagram(let priority, _),
             .pressureBoardFallback(let priority, _):
            return priority
        }
    }

    var densityKey: String? {
        switch self {
        case .suppress:
            return nil
        case .sportDiagram(_, let densityKey),
             .pressureBoardFallback(_, let densityKey):
            return densityKey?.nilIfBlank
        }
    }
}

enum SituationCardPolicy {
    static func presentation(
        for event: GameEvent,
        context: SportRendererSituationContext,
        decision: SituationCardLayoutDecision,
        densityKeyForEvent: (GameEvent) -> String?,
        buildPresentation: () -> GameEventSituationPresentation?
    ) -> GameEventSituationPresentation? {
        guard isVisible(event, in: context),
              let priority = decision.priority,
              priority != .routine,
              allowsDensity(for: priority, densityKey: decision.densityKey, context: context, densityKeyForEvent: densityKeyForEvent) else {
            return nil
        }

        guard let presentation = buildPresentation(), !presentation.isEmpty else {
            return nil
        }

        switch decision {
        case .suppress:
            return nil
        case .sportDiagram:
            return presentation
        case .pressureBoardFallback:
            return presentation.layout == .pressureBoardFallback ? presentation : nil
        }
    }

    static func isVisible(_ event: GameEvent, in context: SportRendererSituationContext) -> Bool {
        guard event.isEligible(for: context.selectedMode),
              context.visibleEvents.indices.contains(context.eventIndex) else {
            return false
        }
        return context.visibleEvents[context.eventIndex] == event
    }

    private static func allowsDensity(
        for priority: SituationCardPriority,
        densityKey: String?,
        context: SportRendererSituationContext,
        densityKeyForEvent: (GameEvent) -> String?
    ) -> Bool {
        switch priority {
        case .bigMoment, .scoringSwing, .keyMoment:
            return true
        case .highConfidenceThreat, .notable:
            guard let densityKey else {
                return true
            }
            let lowerBound = max(0, context.eventIndex - 2)
            guard lowerBound < context.eventIndex else {
                return true
            }
            let recentEvents = context.visibleEvents[lowerBound..<context.eventIndex]
            return !recentEvents.contains { densityKeyForEvent($0)?.nilIfBlank == densityKey }
        case .routine:
            return false
        }
    }
}
