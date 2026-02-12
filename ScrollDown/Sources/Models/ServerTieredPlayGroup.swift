import Foundation

/// Play grouping from the game detail response
struct ServerTieredPlayGroup: Codable {
    let startIndex: Int
    let endIndex: Int
    let playIndices: [Int]
    let summaryLabel: String
}
