import Foundation

struct PersistedHomeSnapshot: Codable, Equatable {
    let windowKey: String
    let fetchedAt: Date
    let games: [Game]
}

struct PlayCursor: Codable, Comparable, Equatable {
    let sequence: Int?
    let eventID: String?

    static func < (left: PlayCursor, right: PlayCursor) -> Bool {
        if let leftSequence = left.sequence,
           let rightSequence = right.sequence {
            return leftSequence < rightSequence
        }
        return false
    }

    func isAfter(_ previous: PlayCursor) -> Bool {
        if let sequence,
           let previousSequence = previous.sequence {
            return sequence > previousSequence
        }
        if let eventID,
           let previousEventID = previous.eventID {
            return eventID != previousEventID
        }
        return false
    }
}

struct BackgroundRefreshRecord: Codable, Equatable {
    let startedAt: Date
    var completedAt: Date?
    var success: Bool
    var homeWindowKey: String?
    var refreshedGameIds: [Int]
    var failedGameIds: [Int]
    var skippedPinnedGameIds: [Int]
    var errorMessage: String?
}

enum FavoriteGameNotificationPayloadKeys {
    static let category = "favorite-game"
    static let route = "route"
    static let gameId = "gameId"
    static let leagueCode = "leagueCode"
    static let gameDate = "gameDate"
    static let awayTeam = "awayTeam"
    static let homeTeam = "homeTeam"
    static let awayTeamAbbr = "awayTeamAbbr"
    static let homeTeamAbbr = "homeTeamAbbr"
    static let status = "status"
    static let unreadState = "unreadState"
    static let estimatedReadingMinutes = "estimatedReadingMinutes"
    static let playCount = "playCount"
    static let newPlayCount = "newPlayCount"
}

enum FavoriteGameNotificationTapBridge {
    static let notificationName = Notification.Name("FavoriteGameNotificationTapped")

    static func post(userInfo: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
    }

    static func gameId(from userInfo: [AnyHashable: Any]?) -> Int? {
        guard let value = userInfo?[FavoriteGameNotificationPayloadKeys.gameId] else { return nil }
        if let intValue = value as? Int {
            return intValue
        }
        if let stringValue = value as? String {
            return Int(stringValue)
        }
        return nil
    }
}

enum FavoriteGameNotificationEligibility: String, Codable, Equatable {
    case upcoming
    case live
    case finalUnread
    case newPlays
}

enum FavoriteGameNotificationStatus: String, Codable, Equatable {
    case upcoming
    case live
    case final
}

struct FavoriteGameNotificationPayload: Codable, Equatable {
    let gameId: Int
    let leagueCode: String
    let gameDate: Date
    let awayTeam: String
    let homeTeam: String
    let awayTeamAbbr: String?
    let homeTeamAbbr: String?
    let status: FavoriteGameNotificationStatus
    let unreadState: FavoriteGameNotificationEligibility
    let estimatedReadingMinutes: Int?
    let playCount: Int
    let newPlayCount: Int

    var userInfo: [String: Any] {
        var info: [String: Any] = [
            FavoriteGameNotificationPayloadKeys.route: FavoriteGameNotificationPayloadKeys.category,
            FavoriteGameNotificationPayloadKeys.gameId: gameId,
            FavoriteGameNotificationPayloadKeys.leagueCode: leagueCode,
            FavoriteGameNotificationPayloadKeys.gameDate: ISO8601DateFormatter().string(from: gameDate),
            FavoriteGameNotificationPayloadKeys.awayTeam: awayTeam,
            FavoriteGameNotificationPayloadKeys.homeTeam: homeTeam,
            FavoriteGameNotificationPayloadKeys.status: status.rawValue,
            FavoriteGameNotificationPayloadKeys.unreadState: unreadState.rawValue,
            FavoriteGameNotificationPayloadKeys.playCount: playCount,
            FavoriteGameNotificationPayloadKeys.newPlayCount: newPlayCount
        ]
        if let awayTeamAbbr {
            info[FavoriteGameNotificationPayloadKeys.awayTeamAbbr] = awayTeamAbbr
        }
        if let homeTeamAbbr {
            info[FavoriteGameNotificationPayloadKeys.homeTeamAbbr] = homeTeamAbbr
        }
        if let estimatedReadingMinutes {
            info[FavoriteGameNotificationPayloadKeys.estimatedReadingMinutes] = estimatedReadingMinutes
        }
        return info
    }
}

struct FavoriteGameNotificationPlan: Equatable {
    let key: String
    let identifier: String
    let title: String
    let body: String
    let payload: FavoriteGameNotificationPayload
}

enum FavoriteGameNotificationPlanner {
    static func plans(
        games: [Game],
        snapshot: LocalGameStateSnapshot,
        now: Date
    ) -> [FavoriteGameNotificationPlan] {
        guard !snapshot.favoriteTeamIds.isEmpty else { return [] }
        return games
            .filter { isFavoriteMatch($0, favoriteTeamIds: snapshot.favoriteTeamIds) }
            .compactMap { plan(for: $0, snapshot: snapshot, now: now) }
            .filter { !snapshot.favoriteNotificationKeys.contains($0.key) }
    }

    private static func plan(
        for game: Game,
        snapshot: LocalGameStateSnapshot,
        now: Date
    ) -> FavoriteGameNotificationPlan? {
        guard GameParticipantVisibility.hasConcreteParticipants(game),
              let away = game.awayParticipant,
              let home = game.homeParticipant else {
            return nil
        }

        let progress = snapshot.progressByGameId[game.id]
        let pinned = snapshot.pinnedGamesById[game.id]
        let playCount = max(game.progress.eventCount ?? 0, progress?.lastKnownEventCount ?? 0, pinned?.summaryPlayCountBaseline ?? 0)
        let newPlayCount = max(progress?.newEventCount ?? 0, pinned?.newEventCount ?? 0)
        let eligibility = eligibility(
            for: game,
            playCount: playCount,
            newPlayCount: newPlayCount,
            progress: progress,
            now: now
        )
        guard let eligibility else { return nil }

        let status = status(for: game)
        let readingMinutes = readingMinutes(for: max(playCount, newPlayCount))
        let payload = FavoriteGameNotificationPayload(
            gameId: game.id,
            leagueCode: game.leagueCode.uppercased(),
            gameDate: game.scheduledStart,
            awayTeam: away.name,
            homeTeam: home.name,
            awayTeamAbbr: away.abbreviation,
            homeTeamAbbr: home.abbreviation,
            status: status,
            unreadState: eligibility,
            estimatedReadingMinutes: readingMinutes,
            playCount: playCount,
            newPlayCount: newPlayCount
        )

        return FavoriteGameNotificationPlan(
            key: key(for: game.id, eligibility: eligibility, playCount: playCount, newPlayCount: newPlayCount),
            identifier: "favorite-game-\(game.id)-\(eligibility.rawValue)",
            title: "\(away.name) at \(home.name)",
            body: body(for: game, eligibility: eligibility, playCount: playCount, newPlayCount: newPlayCount, readingMinutes: readingMinutes),
            payload: payload
        )
    }

    private static func eligibility(
        for game: Game,
        playCount: Int,
        newPlayCount: Int,
        progress: GameProgressRecord?,
        now: Date
    ) -> FavoriteGameNotificationEligibility? {
        if newPlayCount > 0, !game.status.isPregame {
            return .newPlays
        }
        if game.status.isLive {
            return .live
        }
        if game.status.isFinal, playCount > 0, (progress?.readEventCount ?? 0) < playCount {
            return .finalUnread
        }
        if game.status.isPregame, game.scheduledStart >= now {
            return .upcoming
        }
        return nil
    }

    private static func status(for game: Game) -> FavoriteGameNotificationStatus {
        if game.status.isFinal {
            return .final
        }
        if game.status.isLive {
            return .live
        }
        return .upcoming
    }

    private static func body(
        for game: Game,
        eligibility: FavoriteGameNotificationEligibility,
        playCount: Int,
        newPlayCount: Int,
        readingMinutes: Int?
    ) -> String {
        let league = game.leagueCode.uppercased()
        let readingText = readingMinutes.map { $0 == 1 ? "1 min read" : "\($0) mins read" }
        switch eligibility {
        case .upcoming:
            return "\(league) game starts at \(DateFormatters.timeOnly.string(from: game.scheduledStart))."
        case .live:
            return [league, "game is live", readingText].compactMap(\.self).joined(separator: " · ")
        case .finalUnread:
            return ["Catch-up ready", readingText, "\(playCount) plays"].compactMap(\.self).joined(separator: " · ")
        case .newPlays:
            let newText = newPlayCount == 1 ? "1 new play" : "\(newPlayCount) new plays"
            return [newText, readingText].compactMap(\.self).joined(separator: " · ")
        }
    }

    private static func key(
        for gameId: Int,
        eligibility: FavoriteGameNotificationEligibility,
        playCount: Int,
        newPlayCount: Int
    ) -> String {
        switch eligibility {
        case .upcoming, .live:
            return "favorite-game:\(gameId):\(eligibility.rawValue)"
        case .finalUnread:
            return "favorite-game:\(gameId):final:\(playCount)"
        case .newPlays:
            return "favorite-game:\(gameId):new:\(playCount):\(newPlayCount)"
        }
    }

    private static func readingMinutes(for playCount: Int) -> Int? {
        guard playCount > 0 else { return nil }
        return max(1, Int(ceil(Double(playCount) / 12.0)))
    }

    private static func isFavoriteMatch(_ game: Game, favoriteTeamIds: Set<String>) -> Bool {
        game.participants.contains { participant in
            guard let teamID = participant.favoriteTeamID else { return false }
            return favoriteTeamIds.contains(teamID)
        }
    }
}

enum PlayCursorExtractor {
    static func latestCursor(from detail: GameDetail) -> PlayCursor? {
        guard let event = detail.events.max(by: { left, right in
            if left.sequence != right.sequence {
                return left.sequence < right.sequence
            }
            return left.id < right.id
        }) else {
            return nil
        }
        return PlayCursor(sequence: event.sequence, eventID: event.normalizedSourceEventID ?? event.id)
    }
}
