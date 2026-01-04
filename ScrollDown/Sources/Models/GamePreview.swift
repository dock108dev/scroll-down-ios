import Foundation

/// Game preview metadata for spoiler-safe summaries.
struct GamePreview: Codable {
    let gameId: String
    let excitementScore: Int
    let qualityScore: Int
    let tags: [String]
    let nugget: String
}
