import Foundation

// MARK: - Story Adapter

/// Adapter for converting story response to display models
enum StoryAdapter {
    /// Convert response to display models
    static func convertToDisplayModels(from response: GameStoryResponse) -> [MomentDisplayModel] {
        let total = response.story.moments.count
        return response.story.moments.enumerated().map { index, moment in
            MomentDisplayModel(
                momentIndex: index,
                narrative: moment.narrative,
                period: moment.period,
                startClock: moment.startClock,
                endClock: moment.endClock,
                startScore: moment.startScore,
                endScore: moment.endScore,
                playIds: moment.playIds,
                highlightedPlayIds: Set(moment.explicitlyNarratedPlayIds),
                derivedBeatType: deriveBeatType(from: moment, index: index, total: total)
            )
        }
    }

    /// Derive beat type from moment data (score deltas, position in game)
    static func deriveBeatType(from moment: StoryMoment, index: Int, total: Int) -> BeatType {
        let homeScoreAfter = moment.scoreAfter.count > 1 ? moment.scoreAfter[1] : 0
        let homeScoreBefore = moment.scoreBefore.count > 1 ? moment.scoreBefore[1] : 0
        let awayScoreAfter = moment.scoreAfter.first ?? 0
        let awayScoreBefore = moment.scoreBefore.first ?? 0

        let homeScored = homeScoreAfter - homeScoreBefore
        let awayScored = awayScoreAfter - awayScoreBefore
        let totalScored = homeScored + awayScored
        let diff = abs(homeScored - awayScored)

        // Last moment is always closing sequence
        if index == total - 1 {
            return .closingSequence
        }

        // First moment with high scoring = fast start
        if index == 0 && totalScored > 15 {
            return .fastStart
        }

        // Big scoring differential = scoring run
        if diff >= 8 {
            return .run
        }

        // Late in game = crunch setup
        if index > total * 3 / 4 {
            return .crunchSetup
        }

        // Low scoring = stall
        if totalScored < 5 {
            return .stall
        }

        // Default to back and forth
        return .backAndForth
    }
}
