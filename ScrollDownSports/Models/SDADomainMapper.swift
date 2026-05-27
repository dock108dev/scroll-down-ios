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

    static func game(from dto: SDAGameSummaryDTO) -> Game {
        game(
            id: dto.id,
            leagueCode: dto.leagueCode,
            gameDate: dto.gameDate,
            localGameDate: dto.localGameDate,
            status: dto.status,
            homeTeam: dto.homeTeam,
            awayTeam: dto.awayTeam,
            homeTeamAbbr: dto.homeTeamAbbr,
            awayTeamAbbr: dto.awayTeamAbbr,
            currentPeriod: dto.currentPeriod,
            currentPeriodLabel: dto.currentPeriodLabel,
            gameClock: dto.gameClock,
            score: dto.score,
            homeScore: dto.homeScore,
            awayScore: dto.awayScore,
            hasPbp: dto.hasPbp,
            playCount: dto.playCount,
            isLiveFlag: dto.isLiveFlag,
            isFinalFlag: dto.isFinalFlag,
            presentation: dto.presentation,
            eligibility: dto.eligibility,
            scoreboard: dto.scoreboard
        )
    }

    static func game(from dto: SDAGameDTO) -> Game {
        game(from: dto, hasPbp: nil, playCount: nil)
    }

    private static func game(from dto: SDAGameDTO, hasPbp: Bool?, playCount: Int?) -> Game {
        game(
            id: dto.id,
            leagueCode: dto.leagueCode,
            gameDate: dto.gameDate,
            localGameDate: dto.localGameDate,
            status: dto.status,
            homeTeam: dto.homeTeam,
            awayTeam: dto.awayTeam,
            homeTeamAbbr: dto.homeTeamAbbr,
            awayTeamAbbr: dto.awayTeamAbbr,
            currentPeriod: dto.currentPeriod,
            currentPeriodLabel: dto.currentPeriodLabel,
            gameClock: dto.gameClock,
            score: dto.score,
            homeScore: dto.homeScore,
            awayScore: dto.awayScore,
            hasPbp: hasPbp,
            playCount: playCount,
            isLiveFlag: dto.isLiveFlag,
            isFinalFlag: dto.isFinalFlag,
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
            homeScore: dto.homeScore,
            awayScore: dto.awayScore,
            participants: participants
        )
        let scoreBefore = (dto.scoreboard?.scoreBefore ?? dto.scoreBefore).map {
            scoreState(scoreSnapshot: $0, score: nil, homeScore: nil, awayScore: nil, participants: participants)
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
            fallbackScoreChanged: dto.scoreChanged,
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
            importance: importance(dto.importance),
            eligibleModes: eligibleModes(from: modeEligibility),
            usesBackendModeEligibility: true,
            presentation: mappedPresentation,
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

    private static func game(
        id: Int,
        leagueCode: String,
        gameDate: Date,
        localGameDate: String?,
        status: String,
        homeTeam: String,
        awayTeam: String,
        homeTeamAbbr: String?,
        awayTeamAbbr: String?,
        currentPeriod: Int?,
        currentPeriodLabel: String?,
        gameClock: String?,
        score: SDAScoreDTO?,
        homeScore: Int?,
        awayScore: Int?,
        hasPbp: Bool?,
        playCount: Int?,
        isLiveFlag: Bool?,
        isFinalFlag: Bool?,
        presentation: SDAMobilePresentationDTO?,
        eligibility: SDAGameEligibilityDTO?,
        scoreboard: SDAScoreboardDTO?
    ) -> Game {
        let participants = [
            GameParticipant(id: "away", role: .away, name: awayTeam, abbreviation: awayTeamAbbr),
            GameParticipant(id: "home", role: .home, name: homeTeam, abbreviation: homeTeamAbbr)
        ]
        let mappedScoreboard = gameScoreboard(from: scoreboard)
        let scoreState = scoreState(scoreboard: scoreboard, score: score, homeScore: homeScore, awayScore: awayScore, participants: participants)
        let mappedEligibility = gameEligibility(from: eligibility)

        return Game(
            id: id,
            sport: Sport(leagueCode: leagueCode),
            leagueCode: leagueCode,
            scheduledStart: gameDate,
            localDateLabel: localGameDate,
            status: GameStatus(
                rawValue: status,
                isLiveOverride: isLiveFlag,
                isFinalOverride: isFinalFlag,
                displayStateOverride: presentation?.displayState
            ),
            participants: participants,
            scoreState: scoreState,
            presentation: gamePresentation(from: presentation),
            scoreboard: mappedScoreboard,
            progress: GameProgress(
                selectedMode: .timeline,
                periodOrdinal: currentPeriod,
                periodLabel: currentPeriodLabel,
                clockLabel: gameClock,
                eventCount: presentation?.eventCounts?.full ?? playCount,
                lastReadEventID: nil,
                scrollFallback: nil,
                reachedScoreboard: false,
                updatedAt: nil,
                restoredAt: nil,
                persistence: GameProgressPersistence(storageKey: "game-\(id)-progress")
            ),
            availableFeatures: GameAvailableFeatures(
                hasTimeline: mappedEligibility?.playByPlay?.isEligible ?? hasPbp ?? ((playCount ?? 0) > 0),
                hasStats: mappedEligibility?.hasAnyStats ?? true,
                hasScoreboard: mappedEligibility?.boxScore?.isEligible ?? mappedScoreboard?.hasDisplayScore ?? scoreState.hasAnyScore
            )
        )
    }

    private static func scoreState(
        scoreboard: SDAScoreboardDTO?,
        score: SDAScoreDTO?,
        homeScore: Int?,
        awayScore: Int?,
        participants: [GameParticipant]
    ) -> ScoreState {
        return ScoreState(participantScores: participants.map { participant in
            let scoreboardScore = (scoreboard?.competitors ?? []).first {
                participantRole(forSide: $0.side) == participant.role
            }?.score
            let value: Int?
            switch participant.role {
            case .home:
                value = scoreboardScore ?? score?.home ?? homeScore
            case .away:
                value = scoreboardScore ?? score?.away ?? awayScore
            case .other:
                value = nil
            }
            return ParticipantScore(participantID: participant.id, participantRole: participant.role, score: value)
        })
    }

    private static func scoreState(
        scoreSnapshot: SDAScoreSnapshotDTO?,
        score: SDAScoreDTO?,
        homeScore: Int?,
        awayScore: Int?,
        participants: [GameParticipant]
    ) -> ScoreState {
        ScoreState(participantScores: participants.map { participant in
            let value: Int?
            switch participant.role {
            case .home:
                value = scoreSnapshot?.home ?? score?.home ?? homeScore
            case .away:
                value = scoreSnapshot?.away ?? score?.away ?? awayScore
            case .other:
                value = nil
            }
            return ParticipantScore(participantID: participant.id, participantRole: participant.role, score: value)
        })
    }

    private static func participantRole(for abbreviation: String?, participants: [GameParticipant]) -> GameParticipantRole? {
        guard let abbreviation = abbreviation?.lowercased(), !abbreviation.isEmpty else { return nil }
        return participants.first { $0.abbreviation?.lowercased() == abbreviation }?.role
    }

    private static func participantRole(forSide side: String?) -> GameParticipantRole? {
        switch side?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "home":
            return .home
        case "away":
            return .away
        case .some(let value) where !value.isEmpty:
            return .other(value)
        default:
            return nil
        }
    }

    private static func importance(_ dto: SDAEventImportanceDTO) -> GameEventImportance {
        switch dto.level.lowercased() {
        case "primary":
            return .primary
        case "secondary":
            return .secondary
        case "tertiary":
            return .contextual
        default:
            return .contextual
        }
    }

    private static func gamePresentation(from dto: SDAMobilePresentationDTO?) -> GamePresentationData? {
        guard let dto else { return nil }
        return GamePresentationData(
            headline: dto.headline?.nilIfBlank,
            shortHeadline: dto.shortHeadline?.nilIfBlank,
            subheadline: dto.subheadline?.nilIfBlank,
            matchupLabel: dto.matchupLabel?.nilIfBlank,
            primaryLabel: dto.primaryLabel?.nilIfBlank,
            secondaryLabel: dto.secondaryLabel?.nilIfBlank,
            tertiaryLabel: dto.tertiaryLabel?.nilIfBlank,
            accessibilityLabel: dto.accessibilityLabel?.nilIfBlank,
            displayState: dto.displayState?.nilIfBlank,
            visualPriority: dto.visualPriority,
            sortBucket: dto.sortBucket?.nilIfBlank,
            accentRole: dto.theme?.accentRole?.nilIfBlank,
            statusTone: dto.theme?.statusTone?.nilIfBlank,
            eventCounts: dto.eventCounts.map { DetailModeEventCounts(key: $0.key, flow: $0.flow, full: $0.full) },
            statusLabel: (dto.displayLabels?.status ?? dto.primaryLabel)?.nilIfBlank,
            primaryActionLabel: dto.displayLabels?.primaryAction?.nilIfBlank,
            secondaryContextLabel: dto.displayLabels?.secondaryContext?.nilIfBlank,
            scoreboardPlacement: dto.scoreboardPlacement?.nilIfBlank
        )
    }

    private static func gameEligibility(from dto: SDAGameEligibilityDTO?) -> GameEligibilityData? {
        guard let dto else { return nil }
        return GameEligibilityData(
            catchUp: modeEligibility(from: dto.catchUp),
            playByPlay: modeEligibility(from: dto.playByPlay),
            keyMoments: modeEligibility(from: dto.keyMoments),
            boxScore: modeEligibility(from: dto.boxScore),
            teamStats: modeEligibility(from: dto.teamStats),
            playerStats: modeEligibility(from: dto.playerStats),
            liveTracker: modeEligibility(from: dto.liveTracker),
            recap: modeEligibility(from: dto.recap)
        )
    }

    private static func modeEligibility(from dto: SDAModeEligibilityDTO?) -> ModeEligibilityData? {
        guard let dto else { return nil }
        return ModeEligibilityData(
            isEligible: dto.isEligible,
            reason: dto.reason?.nilIfBlank,
            minimumEventCount: dto.minimumEventCount,
            availableEventCount: dto.availableEventCount
        )
    }

    private static func gameScoreboard(from dto: SDAScoreboardDTO?) -> GameScoreboardData? {
        guard let dto else { return nil }
        return GameScoreboardData(
            layout: dto.layout?.nilIfBlank,
            clockLabel: dto.clockLabel?.nilIfBlank,
            periodLabel: dto.periodLabel?.nilIfBlank,
            statusLabel: dto.statusLabel?.nilIfBlank,
            scoreline: dto.scoreline?.nilIfBlank,
            competitors: (dto.competitors ?? []).compactMap(scoreboardCompetitor),
            segments: (dto.segments ?? []).compactMap(scoreboardSegment),
            totals: dto.totals.map { ScoreboardTotalsData(away: $0.away?.nilIfBlank, home: $0.home?.nilIfBlank) }
        )
    }

    private static func scoreboardCompetitor(from dto: SDAScoreboardCompetitorDTO) -> ScoreboardCompetitorData? {
        let fallbackID = [
            dto.teamAbbreviation?.nilIfBlank,
            dto.teamName?.nilIfBlank,
            dto.side?.nilIfBlank
        ].firstNonBlank
        guard let fallbackID else { return nil }
        let role = participantRole(forSide: dto.side) ?? .other(fallbackID)
        let id = dto.side?.nilIfBlank ?? fallbackID
        return ScoreboardCompetitorData(
            id: id,
            side: role,
            teamName: dto.teamName?.nilIfBlank ?? dto.teamAbbreviation?.nilIfBlank ?? id,
            teamAbbreviation: dto.teamAbbreviation?.nilIfBlank,
            score: dto.score,
            scoreText: dto.scoreText?.nilIfBlank,
            isWinner: dto.isWinner,
            recordText: dto.recordText?.nilIfBlank
        )
    }

    private static func scoreboardSegment(from dto: SDAScoreboardSegmentDTO) -> ScoreboardSegmentData? {
        guard let label = dto.label?.nilIfBlank else { return nil }
        return ScoreboardSegmentData(label: label, away: dto.away?.nilIfBlank, home: dto.home?.nilIfBlank)
    }

    private static func eventPresentation(
        from dto: SDAMobilePresentationDTO?,
        displayType: String,
        scoreDisplay: String?,
        clockLabel: String?
    ) -> EventPresentationData {
        return EventPresentationData(
            headline: dto?.headline?.nilIfBlank,
            shortHeadline: dto?.shortHeadline?.nilIfBlank,
            body: dto?.body?.nilIfBlank,
            primaryLabel: dto?.primaryLabel?.nilIfBlank,
            secondaryLabel: dto?.secondaryLabel?.nilIfBlank,
            tertiaryLabel: dto?.tertiaryLabel?.nilIfBlank,
            timeLabel: dto?.timeLabel?.nilIfBlank ?? clockLabel?.nilIfBlank,
            accessibilityLabel: EventLabelResolver.customerText(from: dto?.accessibilityLabel),
            eventTypeLabel: EventLabelResolver.customerLabel(from: dto?.eventTypeLabel)
                ?? EventLabelResolver.customerLabel(from: displayType),
            teamLabel: dto?.teamLabel?.nilIfBlank,
            playerLabel: dto?.playerLabel?.nilIfBlank,
            scoreLabel: dto?.scoreLabel?.nilIfBlank ?? scoreDisplay?.nilIfBlank
        )
    }

    private static func eventDetail(presentation: SDAMobilePresentationDTO?, headline: String, playerName: String?) -> String? {
        if let body = presentation?.body?.nilIfBlank, body != headline {
            return body
        }
        let playerDetail = playerName?.nilIfBlank.flatMap { name in
            headline.range(of: name, options: [.caseInsensitive, .diacriticInsensitive]) == nil ? name : nil
        }
        return [
            presentation?.scoreLabel,
            presentation?.tertiaryLabel,
            playerDetail
        ].firstNonBlank
    }

    private static func eventImportance(from dto: SDAEventImportanceDTO) -> EventImportanceData {
        return EventImportanceData(
            level: dto.level.nilIfBlank,
            rank: dto.rank,
            bucket: dto.bucket?.nilIfBlank,
            reasons: dto.reasons,
            isKeyMoment: dto.isKeyMoment,
            isScoringPlay: dto.isScoringPlay,
            isLeadChange: dto.isLeadChange,
            isTyingPlay: dto.isTyingPlay,
            winProbabilityDelta: dto.winProbabilityDelta
        )
    }

    private static func eligibleModes(from dto: SDAEventModeEligibilityDTO) -> Set<GameMode> {
        var modes = Set<GameMode>()
        if dto.important {
            modes.insert(.timeline)
        }
        if dto.standard {
            modes.insert(.flow)
        }
        if dto.all {
            modes.insert(.stream)
        }
        return modes
    }

    private static func scoreDelta(
        _ dto: SDAScoreDeltaDTO?,
        fallbackScoreChanged: Bool?,
        owningRole: GameParticipantRole?,
        scoreBefore: ScoreState?,
        scoreAfter: ScoreState,
        participants: [GameParticipant]
    ) -> ScoreDelta? {
        let role = participantRole(forSide: dto?.side ?? dto?.participantRole) ?? owningRole
        guard dto != nil || fallbackScoreChanged == true else { return nil }
        let participant = participants.first { $0.role == role }
        return ScoreDelta(
            participantID: dto?.participantID ?? participant?.id,
            participantRole: role,
            before: dto?.before ?? role.flatMap { scoreBefore?.score(for: $0) },
            after: dto?.after ?? role.flatMap { scoreAfter.score(for: $0) },
            change: dto?.change
        )
    }

    private static func sportMetadata(from dto: SDAPlayDTO) -> [String: JSONValue] {
        var metadata = dto.sportMetadata ?? [:]
        metadata.merge(dto.metadata ?? [:]) { _, new in new }
        metadata["playIndex"] = .number(Double(dto.playIndex))
        return metadata
    }
}

private extension GameEligibilityData {
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
