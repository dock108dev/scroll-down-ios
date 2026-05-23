struct HockeyRenderer: GenericSportRendererBacked {
    let generic = GenericSportRenderer(leagueCode: "NHL", sportLabel: "Hockey")

    func statsPresentation(for detail: GameDetail) -> GameStatsPresentation {
        GameStatsPresentation(
            playerSections: StatPresentationBuilder.hockeyPlayerSections(for: detail),
            teamSection: generic.teamStatSection(for: detail)
        )
    }
}
