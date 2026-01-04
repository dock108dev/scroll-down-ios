import Foundation

/// Game preview metadata for spoiler-safe summaries.
struct GamePreview: Codable {
    let gameId: String
    let excitementScore: Int
    let qualityScore: Int
    let tags: [String]
    let nugget: String

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case excitementScore = "excitement_score"
        case qualityScore = "quality_score"
        case tags
        case nugget
    }
}
