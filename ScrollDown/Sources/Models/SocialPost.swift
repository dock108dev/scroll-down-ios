import Foundation

/// Social post entry in game detail as defined in the OpenAPI spec (SocialPostEntry schema)
struct SocialPostEntry: Codable, Identifiable {
    let id: Int
    let postUrl: String
    let postedAt: String
    let hasVideo: Bool
    let teamAbbreviation: String
    let tweetText: String?
    let videoUrl: String?
    let imageUrl: String?
    let sourceHandle: String?
    let mediaType: MediaType?
    
    enum CodingKeys: String, CodingKey {
        case id
        case postUrl = "post_url"
        case postedAt = "posted_at"
        case hasVideo = "has_video"
        case teamAbbreviation = "team_abbreviation"
        case tweetText = "tweet_text"
        case videoUrl = "video_url"
        case imageUrl = "image_url"
        case sourceHandle = "source_handle"
        case mediaType = "media_type"
    }
}

/// Social post API response as defined in the OpenAPI spec (SocialPostResponse schema)
/// REVEAL PHILOSOPHY:
/// - Posts include reveal_level from backend (pre or post)
/// - Client filters based on user's outcome visibility preference
/// - Default behavior: show only "pre" posts until outcome is revealed
struct SocialPostResponse: Codable, Identifiable {
    let id: Int
    let gameId: Int
    let teamId: String
    let postUrl: String
    let postedAt: String
    let hasVideo: Bool
    let videoUrl: String?
    let imageUrl: String?
    let tweetText: String?
    let sourceHandle: String?
    let mediaType: MediaType?
    let revealLevel: RevealLevel? // Backend-provided reveal level
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case teamId = "team_id"
        case postUrl = "post_url"
        case postedAt = "posted_at"
        case hasVideo = "has_video"
        case videoUrl = "video_url"
        case imageUrl = "image_url"
        case tweetText = "tweet_text"
        case sourceHandle = "source_handle"
        case mediaType = "media_type"
        case revealLevel = "reveal_level"
    }
    
    /// Whether this post is safe to show given current reveal state
    /// If reveal_level is unknown, treat as post (hide until revealed)
    func isSafeToShow(outcomeRevealed: Bool) -> Bool {
        guard let revealLevel else {
            // Unknown reveal level: treat as post (hide until revealed)
            return outcomeRevealed
        }
        
        switch revealLevel {
        case .pre:
            // Pre-reveal posts are always safe
            return true
        case .post:
            // Post-reveal posts only shown when outcome is revealed
            return outcomeRevealed
        }
    }
}

/// Social post list response
struct SocialPostListResponse: Codable {
    let posts: [SocialPostResponse]
    let total: Int
}

