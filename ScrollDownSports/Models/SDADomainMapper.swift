import Foundation

enum SDADomainMapper {
    static func games(from response: SDAGameListResponseDTO) -> [Game] {
        response.games.map(game(from:))
    }

    static func detail(from response: SDAGameDetailResponseDTO) -> GameDetail {
        let game = game(
            from: response.game,
            hasPbp: !response.plays.isEmpty,
            playCount: nil
        )
        return GameDetail(
            game: game,
            teamStats: response.teamStats,
            playerStats: response.playerStats,
            events: response.plays.map { event(from: $0, participants: game.participants) },
            mlbBatters: response.mlbBatters,
            mlbPitchers: response.mlbPitchers,
            nhlSkaters: response.nhlSkaters,
            nhlGoalies: response.nhlGoalies
        )
    }

    static func detail(from response: SDACardFeedResponseDTO, fallbackState: GameFeedFallbackState = .none) -> GameDetail {
        let game = game(from: response)
        let events = response.cards.map { event(from: $0, participants: game.participants) }
        let metadata = GameDetailFeedMetadata(
            source: .normalizedFeed,
            generationStatus: feedGenerationStatus(from: response.generation.status),
            fallbackState: fallbackState
        )
        return GameDetail(
            game: game,
            teamStats: response.teamStats ?? [],
            playerStats: response.playerStats ?? [],
            events: events,
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil,
            feedMetadata: metadata
        )
    }

    static func game(from dto: SDAGameSummaryDTO) -> Game {
        game(
            id: dto.id,
            leagueCode: dto.leagueCode,
            gameDate: dto.gameDate,
            localGameDate: dto.localGameDate,
            status: dto.status,
            homeTeam: dto.homeTeam,
            awayTeam: dto.awayTeam,
            homeTeamID: dto.homeTeamId,
            awayTeamID: dto.awayTeamId,
            homeTeamAbbr: dto.homeTeamAbbr,
            awayTeamAbbr: dto.awayTeamAbbr,
            currentPeriod: dto.currentPeriod,
            currentPeriodLabel: dto.currentPeriodLabel,
            gameClock: dto.gameClock,
            score: dto.score,
            hasPbp: dto.hasPbp,
            playCount: dto.playCount,
            presentation: dto.presentation,
            eligibility: dto.eligibility,
            scoreboard: dto.scoreboard
        )
    }

    static func game(from response: SDACardFeedResponseDTO) -> Game {
        let dto = response.game
        let participants = [
            GameParticipant(
                id: participantID(dto.awayTeamId, fallback: "away"),
                role: .away,
                name: dto.awayTeam?.nilIfBlank ?? "Away",
                abbreviation: dto.awayTeamAbbr?.nilIfBlank
            ),
            GameParticipant(
                id: participantID(dto.homeTeamId, fallback: "home"),
                role: .home,
                name: dto.homeTeam?.nilIfBlank ?? "Home",
                abbreviation: dto.homeTeamAbbr?.nilIfBlank
            )
        ]
        let status = dto.status?.nilIfBlank ?? "scheduled"
        let eventCount = response.generation.cardCount > 0 ? response.generation.cardCount : response.cards.count
        return Game(
            id: dto.gameId,
            sport: Sport(leagueCode: dto.league),
            leagueCode: dto.league,
            scheduledStart: Date(timeIntervalSince1970: 0),
            localDateLabel: nil,
            status: GameStatus(rawValue: status),
            participants: participants,
            scoreState: scoreState(scoreSnapshot: nil, score: dto.score, participants: participants),
            presentation: nil,
            scoreboard: gameScoreboard(from: dto.scoreboard),
            progress: GameProgress(
                selectedMode: .timeline,
                periodOrdinal: response.cards.last?.period.ordinal,
                periodLabel: response.cards.last?.period.label,
                clockLabel: response.cards.last?.displayTime ?? response.cards.last?.clock,
                eventCount: eventCount,
                lastReadEventID: nil,
                scrollFallback: nil,
                reachedScoreboard: false,
                updatedAt: nil,
                restoredAt: nil,
                persistence: GameProgressPersistence(storageKey: "game-\(dto.gameId)-progress")
            ),
            availableFeatures: GameAvailableFeatures(
                hasTimeline: !response.cards.isEmpty,
                hasStats: !(response.teamStats ?? []).isEmpty || !(response.playerStats ?? []).isEmpty,
                hasScoreboard: dto.score != nil
            )
        )
    }

    static func game(from dto: SDAGameDTO) -> Game {
        game(from: dto, hasPbp: nil, playCount: nil)
    }

    static func game(from dto: SDAGameDTO, hasPbp: Bool?, playCount: Int?) -> Game {
        game(
            id: dto.id,
            leagueCode: dto.leagueCode,
            gameDate: dto.gameDate,
            localGameDate: dto.localGameDate,
            status: dto.status,
            homeTeam: dto.homeTeam,
            awayTeam: dto.awayTeam,
            homeTeamID: dto.homeTeamId,
            awayTeamID: dto.awayTeamId,
            homeTeamAbbr: dto.homeTeamAbbr,
            awayTeamAbbr: dto.awayTeamAbbr,
            currentPeriod: dto.currentPeriod,
            currentPeriodLabel: dto.currentPeriodLabel,
            gameClock: dto.gameClock,
            score: dto.score,
            hasPbp: hasPbp,
            playCount: playCount,
            presentation: dto.presentation,
            eligibility: dto.eligibility,
            scoreboard: dto.scoreboard
        )
    }

    static func event(from dto: SDAPlayDTO, participants: [GameParticipant]) -> GameEvent {
        let mappedPresentation = eventPresentation(
            from: dto.presentation,
            displayType: dto.displayType,
            scoreDisplay: dto.scoreDisplay,
            clockLabel: dto.clockLabel
        )
        let scoreAfter = scoreState(
            scoreSnapshot: dto.scoreboard?.scoreAfter ?? dto.scoreAfter,
            score: dto.score,
            participants: participants
        )
        let scoreBefore = (dto.scoreboard?.scoreBefore ?? dto.scoreBefore).map {
            scoreState(scoreSnapshot: $0, score: nil, participants: participants)
        }
        let owningRole = participantRole(for: dto.teamAbbreviation, participants: participants)
        let headline = EventLabelResolver.customerHeadline(
            presentationHeadline: dto.presentation?.headline,
            presentationBody: dto.presentation?.body,
            description: dto.description,
            displayType: dto.displayType
        )
        let detail = eventDetail(presentation: dto.presentation, headline: headline, playerName: dto.playerName)
        let importanceMetadata = eventImportance(from: dto.importance)
        let delta = scoreDelta(
            dto.scoreboard?.scoreDelta ?? dto.scoreDelta,
            owningRole: owningRole,
            scoreBefore: scoreBefore,
            scoreAfter: scoreAfter,
            participants: participants
        )
        let modeEligibility = dto.modeEligibility

        return GameEvent(
            id: dto.id,
            sourceEventID: dto.eventId,
            sequence: dto.playIndex,
            periodOrdinal: dto.quarter,
            periodLabel: dto.periodLabel,
            clockLabel: dto.clockLabel,
            teamOwnership: owningRole,
            teamAbbreviation: dto.teamAbbreviation,
            eventType: dto.displayType,
            contentDepth: nil,
            importance: importance(dto.importance),
            eligibleModes: eligibleModes(from: modeEligibility),
            usesBackendModeEligibility: true,
            presentation: mappedPresentation,
            normalizedCard: normalizedPlayCard(from: dto.card ?? dto.presentation?.playCard, participants: participants),
            importanceMetadata: importanceMetadata,
            headline: headline,
            detail: detail,
            rawText: [dto.rawFeedText, dto.rawDescription, dto.presentation == nil ? dto.description : nil].firstNonBlank,
            rawFeedSource: dto.rawFeedSource?.nilIfBlank,
            rawFeedUpdatedAt: dto.rawFeedUpdatedAt?.nilIfBlank,
            scoreBefore: scoreBefore,
            scoreAfter: scoreAfter,
            scoreDelta: delta,
            situationBefore: situation(from: dto.situationBefore, participants: participants),
            situationAfter: situation(from: dto.situationAfter, participants: participants),
            sportMetadata: sportMetadata(from: dto)
        )
    }
}

extension GameEligibilityData {
    var hasAnyStats: Bool {
        if teamStats?.isEligible == true || playerStats?.isEligible == true {
            return true
        }
        if teamStats?.isEligible == false && playerStats?.isEligible == false {
            return false
        }
        return true
    }
}
