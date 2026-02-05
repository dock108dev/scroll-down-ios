import Foundation

// MARK: - Story Adapter

/// Converts story response to display models
enum StoryAdapter {
    static func convertToDisplayModels(from response: GameStoryResponse, sport: String? = nil) -> [BlockDisplayModel] {
        let sportCode = sport ?? response.sport ?? "NBA"
        let playsById = Dictionary(uniqueKeysWithValues: response.plays.map { ($0.playId, $0) })

        return response.blocks.map { block in
            // Derive clock times from plays, sorted by playIndex (chronological)
            let blockPlays = block.playIds.compactMap { playsById[$0] }
                .sorted { $0.playIndex < $1.playIndex }

            // First play (chronologically) has the start time
            // Last play (chronologically) has the end time
            let startClock = blockPlays.first?.clock
            let endClock = blockPlays.last?.clock

            return BlockDisplayModel(
                blockIndex: block.blockIndex,
                role: block.role,
                narrative: block.narrative,
                periodStart: block.periodStart,
                periodEnd: block.periodEnd,
                startClock: startClock,
                endClock: endClock,
                startScore: block.startScore,
                endScore: block.endScore,
                playIds: block.playIds,
                keyPlayIds: Set(block.keyPlayIds),
                miniBox: block.miniBox,
                embeddedTweet: block.embeddedTweet,
                sport: sportCode
            )
        }
    }
}
