import Foundation

// MARK: - Story Generation Extension

extension MockGameService {
    /// Generate game story from game detail
    func generateStory(from detail: GameDetailResponse, gameId: Int) -> GameStoryResponse {
        let plays = detail.plays
        let game = detail.game

        // Convert PlayEntry to StoryPlay
        let storyPlays = plays.enumerated().map { index, play in
            StoryPlay(
                playId: play.playIndex,
                playIndex: index,
                period: play.quarter ?? 1,
                clock: play.gameClock,
                playType: play.playType?.rawValue,
                description: play.description,
                homeScore: play.homeScore,
                awayScore: play.awayScore
            )
        }

        // Group plays into moments (3-8 per game)
        let moments = generateMoments(from: plays, game: game)
        let storyContent = StoryContent(moments: moments)

        return GameStoryResponse(
            gameId: gameId,
            story: storyContent,
            plays: storyPlays,
            validationPassed: true,
            validationErrors: []
        )
    }

    /// Generate moments by grouping plays
    private func generateMoments(from plays: [PlayEntry], game: Game) -> [StoryMoment] {
        guard !plays.isEmpty else { return [] }

        var moments: [StoryMoment] = []
        let homeTeam = game.homeTeam
        let awayTeam = game.awayTeam

        // Target 3-8 moments based on play count
        let targetMomentCount = min(8, max(3, plays.count / 25))
        let playsPerMoment = max(1, plays.count / targetMomentCount)

        for momentIndex in 0..<targetMomentCount {
            let startIdx = momentIndex * playsPerMoment
            let endIdx = (momentIndex == targetMomentCount - 1) ? plays.count - 1 : (momentIndex + 1) * playsPerMoment - 1

            guard startIdx <= endIdx && startIdx < plays.count else { continue }

            let momentPlays = Array(plays[startIdx...min(endIdx, plays.count - 1)])
            guard let firstPlay = momentPlays.first, let lastPlay = momentPlays.last else { continue }

            // Extract play IDs
            let playIds = momentPlays.map { $0.playIndex }

            // Find scoring plays to mark as explicitly narrated
            let scoringPlayIds = momentPlays.compactMap { play -> Int? in
                guard let home = play.homeScore, let away = play.awayScore else { return nil }
                let prevPlay = plays.first { $0.playIndex == play.playIndex - 1 }
                let prevHome = prevPlay?.homeScore ?? 0
                let prevAway = prevPlay?.awayScore ?? 0
                if home != prevHome || away != prevAway {
                    return play.playIndex
                }
                return nil
            }

            // Extract scores [away, home]
            let scoreBefore = [firstPlay.awayScore ?? 0, firstPlay.homeScore ?? 0]
            let scoreAfter = [lastPlay.awayScore ?? 0, lastPlay.homeScore ?? 0]

            // Generate narrative
            let narrative = generateMomentNarrative(
                momentIndex: momentIndex,
                totalMoments: targetMomentCount,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                scoreBefore: scoreBefore,
                scoreAfter: scoreAfter
            )

            let moment = StoryMoment(
                playIds: playIds,
                explicitlyNarratedPlayIds: scoringPlayIds,
                period: firstPlay.quarter ?? 1,
                startClock: firstPlay.gameClock,
                endClock: lastPlay.gameClock,
                scoreBefore: scoreBefore,
                scoreAfter: scoreAfter,
                narrative: narrative
            )
            moments.append(moment)
        }

        return moments
    }

    /// Generate narrative text for a moment
    private func generateMomentNarrative(
        momentIndex: Int,
        totalMoments: Int,
        homeTeam: String,
        awayTeam: String,
        scoreBefore: [Int],
        scoreAfter: [Int]
    ) -> String {
        let homeScored = scoreAfter[1] - scoreBefore[1]
        let awayScored = scoreAfter[0] - scoreBefore[0]
        let leadingTeam = scoreAfter[1] > scoreAfter[0] ? homeTeam : awayTeam
        let scoringTeam = homeScored > awayScored ? homeTeam : awayTeam

        // Last moment
        if momentIndex == totalMoments - 1 {
            return "\(leadingTeam) close out the game with a strong finish."
        }

        // First moment
        if momentIndex == 0 {
            if homeScored + awayScored > 20 {
                return "Both teams come out firing in a high-scoring start."
            }
            return "The game gets underway with both teams finding their rhythm."
        }

        // Big run
        let diff = abs(homeScored - awayScored)
        if diff >= 8 {
            return "\(scoringTeam) go on a \(max(homeScored, awayScored))-\(min(homeScored, awayScored)) run to take control."
        }

        // Tied or close
        if scoreAfter[0] == scoreAfter[1] {
            return "Teams trade baskets as the score remains knotted."
        }

        // Default
        return "Competitive play continues as \(leadingTeam) maintain their edge."
    }
}
