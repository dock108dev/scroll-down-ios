struct SportRendererSituationContext {
    let game: Game
    let selectedMode: DetailStreamMode
    let visibleEvents: [GameEvent]
    let eventIndex: Int
    let scoreSpoilerPolicy: ScoreSpoilerPolicy

    init(
        game: Game,
        selectedMode: DetailStreamMode,
        visibleEvents: [GameEvent],
        eventIndex: Int,
        scoreSpoilerPolicy: ScoreSpoilerPolicy = .revealed
    ) {
        self.game = game
        self.selectedMode = selectedMode
        self.visibleEvents = visibleEvents
        self.eventIndex = eventIndex
        self.scoreSpoilerPolicy = scoreSpoilerPolicy
    }
}

struct PlayCardContextItemPresentation: Identifiable, Hashable {
    let id: String
    let kind: NormalizedPlayCardContextKind
    let text: String
    let tone: NormalizedPlayCardTone?
    let teamAbbreviation: String?
}

struct PlayCardResultItemPresentation: Identifiable, Hashable {
    let id: String
    let text: String
    let tone: NormalizedPlayCardTone?
}

extension GameEventPresentation {
    init(card: NormalizedPlayCard, game: Game, scoreSpoilerPolicy: ScoreSpoilerPolicy) {
        self.init(
            clockText: card.clock?.text ?? card.contextItems.first { $0.kind == .clock }?.text ?? "",
            leadIn: card.leadIn?.text,
            headline: card.headline.text,
            detail: card.body?.text,
            contextItems: card.contextItems.map {
                PlayCardContextItemPresentation(
                    id: $0.id,
                    kind: $0.kind,
                    text: $0.text,
                    tone: $0.tone,
                    teamAbbreviation: $0.teamAbbreviation
                )
            },
            resultItems: card.resultItems.map {
                PlayCardResultItemPresentation(id: $0.id, text: $0.text, tone: $0.tone)
            },
            eventLabel: card.contextItems.first { $0.kind == .eventLabel }?.text,
            teamAbbreviation: card.team?.abbreviation ?? card.contextItems.first { $0.kind == .teamBadge }?.teamAbbreviation,
            teamLabel: card.team?.label,
            scoringLabel: card.score?.isScoringPlay == true ? card.score?.label?.nilIfBlank : nil,
            scoreLabel: Self.visibleScoreValue(card.score, game: game, scoreSpoilerPolicy: scoreSpoilerPolicy),
            rawFeedText: card.rawFeed?.text,
            rawFeedSource: card.rawFeed?.source,
            rawFeedDisclosureTitle: card.rawFeed?.disclosureTitle,
            accessibilityLabel: card.accessibility.label,
            accessibilityValue: card.accessibility.value,
            accessibilityHint: card.accessibility.hint,
            situation: card.situation.map(GameEventSituationPresentation.init(normalized:)),
            situationAccessibilityText: card.accessibility.situationSummary,
            isNormalizedCard: true
        )
    }

    private static func visibleScoreValue(
        _ score: NormalizedPlayCardScore?,
        game: Game,
        scoreSpoilerPolicy: ScoreSpoilerPolicy
    ) -> String? {
        guard let score else { return nil }
        switch score.spoilerPolicy {
        case .alwaysShow:
            return score.value?.nilIfBlank
        case .hideUntilReveal:
            return scoreSpoilerPolicy == .revealed ? score.value?.nilIfBlank : nil
        case .finalOnly:
            return game.status.isFinal && scoreSpoilerPolicy == .revealed ? score.value?.nilIfBlank : nil
        }
    }
}

extension GameEventSituationPresentation {
    init(normalized: NormalizedPlayCardSituation) {
        self.init(
            title: normalized.title,
            periodText: normalized.periodText,
            setupText: normalized.setupText,
            contextLine: normalized.contextLine,
            pressureLine: normalized.pressureLine,
            sport: GameEventSituationSport(rawValue: normalized.sport) ?? .generic,
            layout: GameEventSituationLayout(rawValue: normalized.layout) ?? .pressureBoardFallback,
            ownership: normalized.ownership.map(GameEventSituationOwnership.init(normalized:)),
            diagram: nil,
            accent: GameEventSituationAccent(
                ownership: normalized.accent?.participantRole,
                teamAbbreviation: normalized.accent?.teamAbbreviation,
                teamLabel: normalized.ownership?.teamLabel,
                tone: normalized.accent?.tone?.sportsTone ?? .newPlay
            ),
            dataConfidence: GameEventSituationDataConfidence(rawValue: normalized.dataConfidence) ?? .contract
        )
    }
}

private extension GameEventSituationOwnership {
    init(normalized: NormalizedPlayCardSituationOwnership) {
        self.init(
            role: GameEventSituationOwnershipRole(rawValue: normalized.role) ?? .association,
            participantRole: normalized.participantRole,
            teamAbbreviation: normalized.teamAbbreviation,
            teamLabel: normalized.teamLabel,
            confidence: GameEventSituationOwnershipConfidence(rawValue: normalized.confidence) ?? .explicit
        )
    }
}

private extension NormalizedPlayCardTone {
    var sportsTone: SportsTheme.Tone {
        switch self {
        case .critical:
            return .critical
        case .scoring:
            return .scoring
        case .possession, .context:
            return .newPlay
        case .neutral, .secondary, .muted:
            return .neutral
        }
    }
}

protocol SportRenderer {
    var theme: SportRenderingTheme { get }

    func gameCardPresentation(for game: Game) -> GameCardPresentation
    func gameHeaderPresentation(for game: Game) -> GameHeaderPresentation
    func eventPresentation(for event: GameEvent) -> GameEventPresentation
    func eventSituationPresentation(for event: GameEvent) -> GameEventSituationPresentation?
    func eventSituationPresentation(
        for event: GameEvent,
        context: SportRendererSituationContext
    ) -> GameEventSituationPresentation?
    func eventPresentation(for event: GameEvent, periodGroupLabel: String?) -> GameEventPresentation
    func eventPresentation(
        for event: GameEvent,
        periodGroupLabel: String?,
        context: SportRendererSituationContext?
    ) -> GameEventPresentation
    func periodGroupLabel(for event: GameEvent) -> String
    func periodGroupKey(for event: GameEvent) -> String
    func rowClockText(for event: GameEvent, periodGroupLabel: String?) -> String
    func scoreboardPresentation(for game: Game) -> ScoreboardPresentation
    func statsPresentation(for detail: GameDetail) -> GameStatsPresentation
}

struct GameEventPeriodGroup: Identifiable, Hashable {
    let id: String
    let label: String
    let events: [GameEvent]
}

extension SportRenderer {
    func periodGroups(for events: [GameEvent]) -> [GameEventPeriodGroup] {
        let orderedEvents = events.sorted { left, right in
            if left.sequence != right.sequence {
                return left.sequence < right.sequence
            }
            return left.id < right.id
        }
        var groups: [(key: String, label: String, events: [GameEvent])] = []

        for event in orderedEvents {
            let key = periodGroupKey(for: event)
            if let index = groups.firstIndex(where: { $0.key == key }) {
                groups[index].events.append(event)
            } else {
                groups.append((key: key, label: periodGroupLabel(for: event), events: [event]))
            }
        }

        return groups.map { GameEventPeriodGroup(id: $0.key, label: $0.label, events: $0.events) }
    }

    func eventPresentation(for event: GameEvent, periodGroupLabel: String?) -> GameEventPresentation {
        eventPresentation(for: event, periodGroupLabel: periodGroupLabel, context: nil)
    }

    func eventPresentation(
        for event: GameEvent,
        periodGroupLabel: String?,
        context: SportRendererSituationContext?
    ) -> GameEventPresentation {
        var presentation = eventPresentation(for: event)
        presentation.clockText = rowClockText(for: event, periodGroupLabel: periodGroupLabel)
        if presentation.situation == nil, let context {
            presentation.situation = eventSituationPresentation(for: event, context: context)
            presentation.situationAccessibilityText = presentation.situation?.accessibilitySummary
        }
        if let context {
            presentation = EventScoreSpoilerFilter.filtered(
                presentation: presentation,
                game: context.game,
                policy: context.scoreSpoilerPolicy
            )
        }
        return presentation
    }

    func eventSituationPresentation(for event: GameEvent) -> GameEventSituationPresentation? {
        nil
    }

    func eventSituationPresentation(
        for event: GameEvent,
        context: SportRendererSituationContext
    ) -> GameEventSituationPresentation? {
        eventSituationPresentation(for: event)
    }
}

protocol GenericSportRendererBacked: SportRenderer {
    var generic: GenericSportRenderer { get }
}

extension GenericSportRendererBacked {
    var theme: SportRenderingTheme {
        generic.theme
    }

    func gameCardPresentation(for game: Game) -> GameCardPresentation {
        generic.gameCardPresentation(for: game)
    }

    func gameHeaderPresentation(for game: Game) -> GameHeaderPresentation {
        generic.gameHeaderPresentation(for: game)
    }

    func eventPresentation(for event: GameEvent) -> GameEventPresentation {
        generic.eventPresentation(for: event)
    }

    func eventSituationPresentation(for event: GameEvent) -> GameEventSituationPresentation? {
        generic.eventSituationPresentation(for: event)
    }

    func eventSituationPresentation(
        for event: GameEvent,
        context: SportRendererSituationContext
    ) -> GameEventSituationPresentation? {
        generic.eventSituationPresentation(for: event, context: context)
    }

    func eventPresentation(for event: GameEvent, periodGroupLabel: String?) -> GameEventPresentation {
        eventPresentation(for: event, periodGroupLabel: periodGroupLabel, context: nil)
    }

    func eventPresentation(
        for event: GameEvent,
        periodGroupLabel: String?,
        context: SportRendererSituationContext?
    ) -> GameEventPresentation {
        var presentation = eventPresentation(for: event)
        presentation.clockText = rowClockText(for: event, periodGroupLabel: periodGroupLabel)
        if presentation.situation == nil, let context {
            presentation.situation = eventSituationPresentation(for: event, context: context)
            presentation.situationAccessibilityText = presentation.situation?.accessibilitySummary
        }
        if let context {
            presentation = EventScoreSpoilerFilter.filtered(
                presentation: presentation,
                game: context.game,
                policy: context.scoreSpoilerPolicy
            )
        }
        return presentation
    }

    func periodGroupLabel(for event: GameEvent) -> String {
        generic.periodGroupLabel(for: event)
    }

    func periodGroupKey(for event: GameEvent) -> String {
        generic.periodGroupKey(for: event)
    }

    func rowClockText(for event: GameEvent, periodGroupLabel: String?) -> String {
        generic.rowClockText(for: event, periodGroupLabel: periodGroupLabel)
    }

    func scoreboardPresentation(for game: Game) -> ScoreboardPresentation {
        generic.scoreboardPresentation(for: game)
    }

    func statsPresentation(for detail: GameDetail) -> GameStatsPresentation {
        generic.statsPresentation(for: detail)
    }
}
