struct BaseballRenderer: GenericSportRendererBacked {
    let generic = GenericSportRenderer(leagueCode: "MLB", sportLabel: "Baseball")

    func eventPresentation(for event: GameEvent) -> GameEventPresentation {
        GameEventPresentation(event: event, detail: baseballDetail(for: event))
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
        let metadata = event.sportMetadata
        let baseState = [
            metadata["balls"].map(\.displayString).map { "\($0)-" },
            metadata["strikes"].map(\.displayString),
            metadata["outs"].map(\.displayString).map { "\($0) out" }
        ]
        .compactMap { $0 }
        .joined()
        .nilIfEmpty

        if let baseState, let detail = event.detail?.nilIfEmpty {
            return "\(detail) · \(baseState)"
        }
        return event.detail
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
