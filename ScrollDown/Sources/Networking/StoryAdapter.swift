import Foundation

// MARK: - Story Adapter

/// Converts story response to display models
enum StoryAdapter {
    static func convertToDisplayModels(from response: GameStoryResponse) -> [BlockDisplayModel] {
        response.blocks.map { block in
            BlockDisplayModel(
                blockIndex: block.blockIndex,
                role: block.role,
                narrative: block.narrative,
                periodStart: block.periodStart,
                periodEnd: block.periodEnd,
                startScore: block.startScore,
                endScore: block.endScore,
                playIds: block.playIds,
                keyPlayIds: Set(block.keyPlayIds),
                miniBox: block.miniBox,
                embeddedTweet: block.embeddedTweet
            )
        }
    }
}
