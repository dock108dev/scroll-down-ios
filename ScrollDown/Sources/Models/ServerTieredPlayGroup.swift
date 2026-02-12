import Foundation

/// Play grouping from the game detail response
struct ServerTieredPlayGroup: Codable {
    let startIndex: Int
    let endIndex: Int
    let playIndices: [Int]
    let summaryLabel: String

    enum CodingKeys: String, CodingKey {
        case startIndex = "start_index"
        case endIndex = "end_index"
        case playIndices = "play_indices"
        case summaryLabel = "summary_label"
    }
}
