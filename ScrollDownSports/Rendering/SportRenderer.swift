protocol SportRenderer {
    var theme: SportRenderingTheme { get }

    func gameCardPresentation(for game: Game) -> GameCardPresentation
    func gameHeaderPresentation(for game: Game) -> GameHeaderPresentation
    func eventPresentation(for event: GameEvent) -> GameEventPresentation
    func eventPresentation(for event: GameEvent, periodGroupLabel: String?) -> GameEventPresentation
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
        var presentation = eventPresentation(for: event)
        presentation.clockText = rowClockText(for: event, periodGroupLabel: periodGroupLabel)
        return presentation
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

    func eventPresentation(for event: GameEvent, periodGroupLabel: String?) -> GameEventPresentation {
        var presentation = eventPresentation(for: event)
        presentation.clockText = rowClockText(for: event, periodGroupLabel: periodGroupLabel)
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
