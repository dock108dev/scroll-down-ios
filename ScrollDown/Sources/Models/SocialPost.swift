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
    }
}

/// Social post list response as defined in the OpenAPI spec (SocialPostListResponse schema)
struct SocialPostListResponse: Codable {
    let posts: [SocialPostResponse]
    let total: Int
}

/// Related post entry as defined in the OpenAPI spec (RelatedPost schema)
struct RelatedPost: Codable, Identifiable {
    let id: Int
    let postUrl: String
    let postedAt: String
    let containsScore: Bool
    let text: String?
    let imageUrl: String?
    let sourceHandle: String?

    enum CodingKeys: String, CodingKey {
        case id
        case postUrl = "post_url"
        case postedAt = "posted_at"
        case containsScore = "contains_score"
        case text
        case imageUrl = "image_url"
        case sourceHandle = "source_handle"
    }
}

/// Related post list response as defined in the OpenAPI spec (RelatedPostListResponse schema)
struct RelatedPostListResponse: Codable {
    let posts: [RelatedPost]
    let total: Int
}


