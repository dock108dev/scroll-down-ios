import Foundation

// MARK: - Block Display Model

/// Display model for story blocks
struct BlockDisplayModel: Identifiable, Equatable {
    let blockIndex: Int
    let role: BlockRole
    let narrative: String
    let periodStart: Int
    let periodEnd: Int
    let startScore: ScoreSnapshot
    let endScore: ScoreSnapshot
    let playIds: [Int]
    let keyPlayIds: Set<Int>
    let miniBox: BlockMiniBox?
    let embeddedTweet: EmbeddedTweet?

    var id: Int { blockIndex }

    var periodDisplay: String {
        if periodStart == periodEnd {
            return "Q\(periodStart)"
        }
        return "Q\(periodStart)-Q\(periodEnd)"
    }

    func isKeyPlay(_ playId: Int) -> Bool {
        keyPlayIds.contains(playId)
    }

    var blockStars: [String] {
        miniBox?.blockStars ?? []
    }

    func isBlockStar(_ name: String) -> Bool {
        miniBox?.isBlockStar(name) ?? false
    }
}
