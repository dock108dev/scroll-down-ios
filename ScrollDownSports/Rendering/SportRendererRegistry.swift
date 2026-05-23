enum SportRendererRegistry {
    static func renderer(for game: Game) -> any SportRenderer {
        renderer(for: game.leagueCode, sport: game.sport)
    }

    static func renderer(for leagueCode: String) -> any SportRenderer {
        renderer(for: leagueCode, sport: Sport(leagueCode: leagueCode))
    }

    private static func renderer(for leagueCode: String, sport: Sport) -> any SportRenderer {
        switch sport {
        case .mlb:
            BaseballRenderer()
        case .nhl:
            HockeyRenderer()
        case .nfl:
            FootballRenderer(leagueCode: leagueCode)
        case .nba:
            BasketballRenderer(leagueCode: leagueCode)
        case .soccer:
            SoccerRenderer(leagueCode: leagueCode)
        case .golf:
            GolfRenderer(leagueCode: leagueCode)
        case .tennis, .other:
            GenericSportRenderer(leagueCode: leagueCode, sportLabel: sport.displayName)
        }
    }
}
