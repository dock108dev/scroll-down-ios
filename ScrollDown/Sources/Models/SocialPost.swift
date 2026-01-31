import Foundation

/// Social post entry in game detail
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

/// Social post API response
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
    let revealLevel: RevealLevel?

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
    func isSafeToShow(outcomeRevealed: Bool) -> Bool {
        guard let revealLevel else {
            return outcomeRevealed
        }

        switch revealLevel {
        case .pre:
            return true
        case .post:
            return outcomeRevealed
        }
    }
}

/// Social post list response
struct SocialPostListResponse: Codable {
    let posts: [SocialPostResponse]
    let total: Int
}
