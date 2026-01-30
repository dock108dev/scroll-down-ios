import Foundation

// MARK: - Story Moment Helpers

extension GameDetailViewModel {
    /// Get unified timeline events for a moment
    func unifiedEventsForMoment(_ moment: MomentDisplayModel) -> [UnifiedTimelineEvent] {
        let sport = detail?.game.leagueCode
        return playsForMoment(moment).map { play in
            var dict: [String: Any] = [
                "event_type": "pbp",
                "play_index": play.playIndex,
                "period": play.period
            ]
            if let clock = play.clock { dict["game_clock"] = clock }
            if let desc = play.description { dict["description"] = desc }
            if let team = play.team { dict["team"] = team }
            if let playerName = play.playerName { dict["player_name"] = playerName }
            if let home = play.homeScore { dict["home_score"] = home }
            if let away = play.awayScore { dict["away_score"] = away }
            if let playType = play.playType { dict["play_type"] = playType }
            dict["is_highlighted"] = moment.highlightedPlayIds.contains(play.playId)
            return UnifiedTimelineEvent(from: dict, index: play.playIndex, sport: sport)
        }
    }
}
