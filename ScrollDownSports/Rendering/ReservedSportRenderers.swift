struct FootballRenderer: GenericSportRendererBacked {
    let generic: GenericSportRenderer

    init(leagueCode: String) {
        generic = GenericSportRenderer(leagueCode: leagueCode, sportLabel: "Football")
    }
}

struct BasketballRenderer: GenericSportRendererBacked {
    let generic: GenericSportRenderer

    init(leagueCode: String) {
        generic = GenericSportRenderer(leagueCode: leagueCode, sportLabel: "Basketball")
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
}
