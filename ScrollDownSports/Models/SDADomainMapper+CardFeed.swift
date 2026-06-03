import Foundation

extension SDADomainMapper {
    static func event(from dto: SDANarrativeCardDTO, participants: [GameParticipant]) -> GameEvent {
        let owningRole = participantRole(forSide: dto.team.side)
        let scoreBefore = dto.scoreBefore.map { scoreState(scoreSnapshot: $0, score: nil, participants: participants) }
        let scoreAfter = scoreState(scoreSnapshot: dto.scoreAfter, score: nil, participants: participants)
        let delta = scoreDelta(
            dto.scoreChange,
            owningRole: owningRole,
            scoreBefore: scoreBefore,
            scoreAfter: scoreAfter,
            participants: participants
        )
        let normalizedCard = normalizedPlayCard(from: dto, participants: participants)

        return GameEvent(
            id: dto.id,
            sourceEventID: dto.sourcePlayId,
            sequence: dto.playIndex,
            periodOrdinal: dto.period.ordinal,
            periodLabel: dto.period.label,
            clockLabel: dto.displayTime ?? dto.clock,
            teamOwnership: owningRole,
            teamAbbreviation: dto.team.abbreviation,
            eventType: dto.eventType?.nilIfBlank ?? dto.tags.first?.nilIfBlank,
            contentDepth: EventContentDepth(cardFeedValue: dto.contentDepth),
            importance: importance(dto.importance),
            eligibleModes: eligibleModes(from: dto.modeEligibility),
            usesBackendModeEligibility: true,
            presentation: EventPresentationData(
                headline: normalizedCard.headline.text.nilIfBlank,
                shortHeadline: nil,
                body: dto.description.nilIfBlank,
                primaryLabel: normalizedCard.leadIn?.text.nilIfBlank,
                secondaryLabel: normalizedCard.contextItems.first { $0.kind == .status }?.text.nilIfBlank,
                tertiaryLabel: normalizedCard.resultItems.last?.text.nilIfBlank,
                timeLabel: (dto.displayTime ?? dto.clock)?.nilIfBlank,
                accessibilityLabel: EventLabelResolver.customerAccessibilityText(
                    preferred: nil,
                    fallbackPieces: [dto.displayTime, dto.headline, dto.description]
                ),
                eventTypeLabel: dto.tags.first?.nilIfBlank,
                teamLabel: dto.team.abbreviation?.nilIfBlank ?? dto.team.name?.nilIfBlank,
                playerLabel: nil,
                scoreLabel: nil
            ),
            normalizedCard: normalizedCard,
            importanceMetadata: eventImportance(from: dto.importance),
            headline: dto.headline,
            detail: dto.description.nilIfBlank,
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: scoreBefore,
            scoreAfter: scoreAfter,
            scoreDelta: delta,
            sportMetadata: [
                "playIndex": .number(Double(dto.playIndex)),
                "contentDepth": .string(dto.contentDepth),
                "renderType": .string(dto.renderType)
            ]
        )
    }

    static func game(
        id: Int,
        leagueCode: String,
        gameDate: Date,
        localGameDate: String?,
        status: String,
        homeTeam: String,
        awayTeam: String,
        homeTeamID: Int?,
        awayTeamID: Int?,
        homeTeamAbbr: String?,
        awayTeamAbbr: String?,
        currentPeriod: Int?,
        currentPeriodLabel: String?,
        gameClock: String?,
        score: SDAScoreDTO?,
        hasPbp: Bool?,
        playCount: Int?,
        presentation: SDAMobilePresentationDTO?,
        eligibility: SDAGameEligibilityDTO?,
        scoreboard: SDAScoreboardDTO?
    ) -> Game {
        let participants = [
            GameParticipant(id: participantID(awayTeamID, fallback: "away"), role: .away, name: awayTeam, abbreviation: awayTeamAbbr),
            GameParticipant(id: participantID(homeTeamID, fallback: "home"), role: .home, name: homeTeam, abbreviation: homeTeamAbbr)
        ]
        let mappedScoreboard = gameScoreboard(from: scoreboard)
        let scoreState = scoreState(scoreboard: scoreboard, score: score, participants: participants)
        let mappedEligibility = gameEligibility(from: eligibility)

        return Game(
            id: id,
            sport: Sport(leagueCode: leagueCode),
            leagueCode: leagueCode,
            scheduledStart: gameDate,
            localDateLabel: localGameDate,
            status: GameStatus(
                rawValue: status,
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

    static func scoreState(
        scoreboard: SDAScoreboardDTO?,
        score: SDAScoreDTO?,
        participants: [GameParticipant]
    ) -> ScoreState {
        return ScoreState(participantScores: participants.map { participant in
            let scoreboardScore = (scoreboard?.competitors ?? []).first {
                participantRole(forSide: $0.side) == participant.role
            }?.score
            let value: Int?
            switch participant.role {
            case .home:
                value = scoreboardScore ?? score?.home
            case .away:
                value = scoreboardScore ?? score?.away
            case .other:
                value = nil
            }
            return ParticipantScore(participantID: participant.id, participantRole: participant.role, score: value)
        })
    }

    static func scoreState(
        scoreSnapshot: SDAScoreSnapshotDTO?,
        score: SDAScoreDTO?,
        participants: [GameParticipant]
    ) -> ScoreState {
        ScoreState(participantScores: participants.map { participant in
            let value: Int?
            switch participant.role {
            case .home:
                value = scoreSnapshot?.home ?? score?.home
            case .away:
                value = scoreSnapshot?.away ?? score?.away
            case .other:
                value = nil
            }
            return ParticipantScore(participantID: participant.id, participantRole: participant.role, score: value)
        })
    }

    static func participantRole(for abbreviation: String?, participants: [GameParticipant]) -> GameParticipantRole? {
        guard let abbreviation = abbreviation?.lowercased(), !abbreviation.isEmpty else { return nil }
        return participants.first { $0.abbreviation?.lowercased() == abbreviation }?.role
    }

    static func participantID(_ teamID: Int?, fallback: String) -> String {
        teamID.map(String.init) ?? fallback
    }

    static func participantRole(forSide side: String?) -> GameParticipantRole? {
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

    static func importance(_ dto: SDAEventImportanceDTO) -> GameEventImportance {
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

    static func gamePresentation(from dto: SDAMobilePresentationDTO?) -> GamePresentationData? {
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

    static func gameEligibility(from dto: SDAGameEligibilityDTO?) -> GameEligibilityData? {
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

    static func modeEligibility(from dto: SDAModeEligibilityDTO?) -> ModeEligibilityData? {
        guard let dto else { return nil }
        return ModeEligibilityData(
            isEligible: dto.isEligible,
            reason: dto.reason?.nilIfBlank,
            minimumEventCount: dto.minimumEventCount,
            availableEventCount: dto.availableEventCount
        )
    }

    static func gameScoreboard(from dto: SDAScoreboardDTO?) -> GameScoreboardData? {
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

    static func scoreboardCompetitor(from dto: SDAScoreboardCompetitorDTO) -> ScoreboardCompetitorData? {
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

    static func scoreboardSegment(from dto: SDAScoreboardSegmentDTO) -> ScoreboardSegmentData? {
        guard let label = dto.label?.nilIfBlank else { return nil }
        return ScoreboardSegmentData(label: label, away: dto.away?.nilIfBlank, home: dto.home?.nilIfBlank)
    }

    static func eventPresentation(
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

    static func eventDetail(presentation: SDAMobilePresentationDTO?, headline: String, playerName: String?) -> String? {
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

    static func eventImportance(from dto: SDAEventImportanceDTO) -> EventImportanceData {
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

    static func eligibleModes(from dto: SDAEventModeEligibilityDTO) -> Set<GameMode> {
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

    static func scoreDelta(
        _ dto: SDAScoreDeltaDTO?,
        owningRole: GameParticipantRole?,
        scoreBefore: ScoreState?,
        scoreAfter: ScoreState,
        participants: [GameParticipant]
    ) -> ScoreDelta? {
        guard let dto else { return nil }
        let role = participantRole(forSide: dto.side ?? dto.participantRole) ?? owningRole
        let participant = participants.first { $0.role == role }
        return ScoreDelta(
            participantID: dto.participantID ?? participant?.id,
            participantRole: role,
            before: dto.before ?? role.flatMap { scoreBefore?.score(for: $0) },
            after: dto.after ?? role.flatMap { scoreAfter.score(for: $0) },
            change: dto.change
        )
    }

    static func scoreDelta(
        _ dto: SDACardScoreChangeDTO?,
        owningRole: GameParticipantRole?,
        scoreBefore: ScoreState?,
        scoreAfter: ScoreState,
        participants: [GameParticipant]
    ) -> ScoreDelta? {
        guard let dto else { return nil }
        let role: GameParticipantRole?
        if dto.home != 0 {
            role = .home
        } else if dto.away != 0 {
            role = .away
        } else {
            role = owningRole
        }
        let participant = participants.first { $0.role == role }
        let change: Int?
        switch role {
        case .home:
            change = dto.home
        case .away:
            change = dto.away
        case .other, .none:
            change = nil
        }
        guard role != nil || change != nil else { return nil }
        return ScoreDelta(
            participantID: participant?.id,
            participantRole: role,
            before: role.flatMap { scoreBefore?.score(for: $0) },
            after: role.flatMap { scoreAfter.score(for: $0) },
            change: change
        )
    }

    static func sportMetadata(from dto: SDAPlayDTO) -> [String: JSONValue] {
        var metadata = dto.sportMetadata ?? [:]
        metadata.merge(dto.metadata ?? [:]) { _, new in new }
        metadata["playIndex"] = .number(Double(dto.playIndex))
        return metadata
    }

    static func feedGenerationStatus(from value: String) -> GameFeedGenerationStatus {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "no_pbp_yet", "nopbpyet":
            return .noPbpYet
        case "unsupported_sport", "unsupportedsport":
            return .unsupportedSport
        case "generation_pending", "generationpending":
            return .generationPending
        case "validation_blocked", "validationblocked":
            return .validationBlocked
        case "stale_regenerating", "staleregenerating":
            return .staleRegenerating
        case "ready":
            return .ready
        default:
            return .unknown
        }
    }

}
