import Foundation

/// Social post entry in game detail as defined in the OpenAPI spec (SocialPostEntry schema)
/// Handles both snake_case (app endpoint) and camelCase (admin endpoint) JSON formats
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
        case postUrlSnake = "post_url"
        case postUrlCamel = "postUrl"
        case postedAtSnake = "posted_at"
        case postedAtCamel = "postedAt"
        case hasVideoSnake = "has_video"
        case hasVideoCamel = "hasVideo"
        case teamAbbreviationSnake = "team_abbreviation"
        case teamAbbreviationCamel = "teamAbbreviation"
        case tweetTextSnake = "tweet_text"
        case tweetTextCamel = "tweetText"
        case videoUrlSnake = "video_url"
        case videoUrlCamel = "videoUrl"
        case imageUrlSnake = "image_url"
        case imageUrlCamel = "imageUrl"
        case sourceHandleSnake = "source_handle"
        case sourceHandleCamel = "sourceHandle"
        case mediaTypeSnake = "media_type"
        case mediaTypeCamel = "mediaType"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)

        postUrl = (try? container.decode(String.self, forKey: .postUrlSnake))
            ?? (try? container.decode(String.self, forKey: .postUrlCamel))
            ?? ""

        postedAt = (try? container.decode(String.self, forKey: .postedAtSnake))
            ?? (try? container.decode(String.self, forKey: .postedAtCamel))
            ?? ""

        hasVideo = (try? container.decode(Bool.self, forKey: .hasVideoSnake))
            ?? (try? container.decode(Bool.self, forKey: .hasVideoCamel))
            ?? false

        teamAbbreviation = (try? container.decode(String.self, forKey: .teamAbbreviationSnake))
            ?? (try? container.decode(String.self, forKey: .teamAbbreviationCamel))
            ?? ""

        tweetText = (try? container.decode(String.self, forKey: .tweetTextSnake))
            ?? (try? container.decode(String.self, forKey: .tweetTextCamel))

        videoUrl = (try? container.decode(String.self, forKey: .videoUrlSnake))
            ?? (try? container.decode(String.self, forKey: .videoUrlCamel))

        imageUrl = (try? container.decode(String.self, forKey: .imageUrlSnake))
            ?? (try? container.decode(String.self, forKey: .imageUrlCamel))

        sourceHandle = (try? container.decode(String.self, forKey: .sourceHandleSnake))
            ?? (try? container.decode(String.self, forKey: .sourceHandleCamel))

        mediaType = (try? container.decode(MediaType.self, forKey: .mediaTypeSnake))
            ?? (try? container.decode(MediaType.self, forKey: .mediaTypeCamel))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(postUrl, forKey: .postUrlSnake)
        try container.encode(postedAt, forKey: .postedAtSnake)
        try container.encode(hasVideo, forKey: .hasVideoSnake)
        try container.encode(teamAbbreviation, forKey: .teamAbbreviationSnake)
        try container.encodeIfPresent(tweetText, forKey: .tweetTextSnake)
        try container.encodeIfPresent(videoUrl, forKey: .videoUrlSnake)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrlSnake)
        try container.encodeIfPresent(sourceHandle, forKey: .sourceHandleSnake)
        try container.encodeIfPresent(mediaType, forKey: .mediaTypeSnake)
    }

    init(
        id: Int,
        postUrl: String,
        postedAt: String,
        hasVideo: Bool,
        teamAbbreviation: String,
        tweetText: String? = nil,
        videoUrl: String? = nil,
        imageUrl: String? = nil,
        sourceHandle: String? = nil,
        mediaType: MediaType? = nil
    ) {
        self.id = id
        self.postUrl = postUrl
        self.postedAt = postedAt
        self.hasVideo = hasVideo
        self.teamAbbreviation = teamAbbreviation
        self.tweetText = tweetText
        self.videoUrl = videoUrl
        self.imageUrl = imageUrl
        self.sourceHandle = sourceHandle
        self.mediaType = mediaType
    }
}

/// Social post API response as defined in the OpenAPI spec (SocialPostResponse schema)
/// REVEAL PHILOSOPHY:
/// - Posts include reveal_level from backend (pre or post)
/// - Client filters based on user's outcome visibility preference
/// - Default behavior: show only "pre" posts until outcome is revealed
/// Handles both snake_case (app endpoint) and camelCase (admin endpoint) JSON formats
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
        case gameIdSnake = "game_id"
        case gameIdCamel = "gameId"
        case teamIdSnake = "team_id"
        case teamIdCamel = "teamId"
        case postUrlSnake = "post_url"
        case postUrlCamel = "postUrl"
        case postedAtSnake = "posted_at"
        case postedAtCamel = "postedAt"
        case hasVideoSnake = "has_video"
        case hasVideoCamel = "hasVideo"
        case videoUrlSnake = "video_url"
        case videoUrlCamel = "videoUrl"
        case imageUrlSnake = "image_url"
        case imageUrlCamel = "imageUrl"
        case tweetTextSnake = "tweet_text"
        case tweetTextCamel = "tweetText"
        case sourceHandleSnake = "source_handle"
        case sourceHandleCamel = "sourceHandle"
        case mediaTypeSnake = "media_type"
        case mediaTypeCamel = "mediaType"
        case revealLevelSnake = "reveal_level"
        case revealLevelCamel = "revealLevel"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)

        gameId = (try? container.decode(Int.self, forKey: .gameIdSnake))
            ?? (try? container.decode(Int.self, forKey: .gameIdCamel))
            ?? 0

        teamId = (try? container.decode(String.self, forKey: .teamIdSnake))
            ?? (try? container.decode(String.self, forKey: .teamIdCamel))
            ?? ""

        postUrl = (try? container.decode(String.self, forKey: .postUrlSnake))
            ?? (try? container.decode(String.self, forKey: .postUrlCamel))
            ?? ""

        postedAt = (try? container.decode(String.self, forKey: .postedAtSnake))
            ?? (try? container.decode(String.self, forKey: .postedAtCamel))
            ?? ""

        hasVideo = (try? container.decode(Bool.self, forKey: .hasVideoSnake))
            ?? (try? container.decode(Bool.self, forKey: .hasVideoCamel))
            ?? false

        videoUrl = (try? container.decode(String.self, forKey: .videoUrlSnake))
            ?? (try? container.decode(String.self, forKey: .videoUrlCamel))

        imageUrl = (try? container.decode(String.self, forKey: .imageUrlSnake))
            ?? (try? container.decode(String.self, forKey: .imageUrlCamel))

        tweetText = (try? container.decode(String.self, forKey: .tweetTextSnake))
            ?? (try? container.decode(String.self, forKey: .tweetTextCamel))

        sourceHandle = (try? container.decode(String.self, forKey: .sourceHandleSnake))
            ?? (try? container.decode(String.self, forKey: .sourceHandleCamel))

        mediaType = (try? container.decode(MediaType.self, forKey: .mediaTypeSnake))
            ?? (try? container.decode(MediaType.self, forKey: .mediaTypeCamel))

        revealLevel = (try? container.decode(RevealLevel.self, forKey: .revealLevelSnake))
            ?? (try? container.decode(RevealLevel.self, forKey: .revealLevelCamel))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(gameId, forKey: .gameIdSnake)
        try container.encode(teamId, forKey: .teamIdSnake)
        try container.encode(postUrl, forKey: .postUrlSnake)
        try container.encode(postedAt, forKey: .postedAtSnake)
        try container.encode(hasVideo, forKey: .hasVideoSnake)
        try container.encodeIfPresent(videoUrl, forKey: .videoUrlSnake)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrlSnake)
        try container.encodeIfPresent(tweetText, forKey: .tweetTextSnake)
        try container.encodeIfPresent(sourceHandle, forKey: .sourceHandleSnake)
        try container.encodeIfPresent(mediaType, forKey: .mediaTypeSnake)
        try container.encodeIfPresent(revealLevel, forKey: .revealLevelSnake)
    }

    init(
        id: Int,
        gameId: Int,
        teamId: String,
        postUrl: String,
        postedAt: String,
        hasVideo: Bool,
        videoUrl: String? = nil,
        imageUrl: String? = nil,
        tweetText: String? = nil,
        sourceHandle: String? = nil,
        mediaType: MediaType? = nil,
        revealLevel: RevealLevel? = nil
    ) {
        self.id = id
        self.gameId = gameId
        self.teamId = teamId
        self.postUrl = postUrl
        self.postedAt = postedAt
        self.hasVideo = hasVideo
        self.videoUrl = videoUrl
        self.imageUrl = imageUrl
        self.tweetText = tweetText
        self.sourceHandle = sourceHandle
        self.mediaType = mediaType
        self.revealLevel = revealLevel
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

