import Foundation

extension SDADomainMapper {
    static func situation(
        from dto: SDAEventSituationDTO?,
        participants: [GameParticipant]
    ) -> GameEventSituationSnapshot? {
        guard let dto else { return nil }
        return GameEventSituationSnapshot(
            schemaVersion: dto.schemaVersion,
            sport: dto.sport,
            display: dto.display.map {
                GameEventSituationDisplay(
                    headline: $0.headline?.nilIfBlank,
                    subheadline: $0.subheadline?.nilIfBlank,
                    tokens: ($0.tokens ?? []).compactMap(\.nilIfBlank),
                    accessibilityLabel: $0.accessibilityLabel?.nilIfBlank
                )
            },
            score: dto.score.map { score(from: $0, participants: participants) },
            period: dto.period.map {
                GameEventSituationPeriod(
                    ordinal: $0.ordinal,
                    label: $0.label?.nilIfBlank,
                    phase: $0.phase?.nilIfBlank
                )
            },
            clock: dto.clock.map {
                GameEventSituationClock(label: $0.label?.nilIfBlank, secondsRemaining: $0.secondsRemaining)
            },
            possession: dto.possession,
            sportState: sportState(from: dto.sportState),
            pressure: dto.pressure.map {
                GameEventSituationPressure(
                    level: $0.level?.nilIfBlank,
                    rank: $0.rank,
                    winProbability: $0.winProbability,
                    leverageIndex: $0.leverageIndex
                )
            },
            confidence: dto.confidence.map {
                GameEventSituationConfidence(
                    level: $0.level?.nilIfBlank,
                    source: $0.source?.nilIfBlank,
                    reasons: $0.reasons ?? []
                )
            }
        )
    }

    static func normalizedPlayCard(
        from dto: SDANormalizedPlayCardDTO?,
        participants: [GameParticipant]
    ) -> NormalizedPlayCard? {
        guard let dto, let headline = normalizedText(from: dto.headline) else { return nil }
        let contextItems = (dto.contextItems ?? []).compactMap(normalizedContextItem)
        let resultItems = (dto.resultItems ?? [])
            .compactMap(normalizedResultItem)
            .sorted { left, right in
                if left.priority == right.priority { return left.id < right.id }
                return left.priority < right.priority
            }
        let accessibility = normalizedAccessibility(
            from: dto.accessibility,
            fallbackPieces: [dto.clock?.text, dto.leadIn?.text, headline.text, dto.body?.text, dto.score?.value]
        )

        return NormalizedPlayCard(
            schemaVersion: dto.schemaVersion ?? 1,
            cardID: dto.cardId?.nilIfBlank,
            visualImportance: normalizedImportance(dto.visualImportance),
            accent: normalizedAccent(from: dto.accent),
            clock: normalizedText(from: dto.clock),
            leadIn: normalizedText(from: dto.leadIn),
            headline: headline,
            body: normalizedText(from: dto.body),
            contextItems: contextItems,
            resultItems: resultItems,
            score: normalizedScore(from: dto.score),
            team: normalizedTeam(from: dto.team, participants: participants),
            situation: normalizedSituation(from: dto.situation),
            rawFeed: normalizedRawFeed(from: dto.rawFeed),
            accessibility: accessibility
        )
    }

    static func normalizedPlayCard(
        from dto: SDANarrativeCardDTO,
        participants: [GameParticipant]
    ) -> NormalizedPlayCard {
        let teamRole = participantRole(from: dto.team.side)
        let teamAbbreviation = dto.team.abbreviation?.nilIfBlank
        let contextItems = [
            normalizedContextItem(
                id: "stage-\(dto.id)",
                kind: .status,
                text: dto.stageSetting,
                tone: .secondary,
                participantRole: nil,
                teamAbbreviation: nil
            ),
            normalizedContextItem(
                id: "team-\(dto.id)",
                kind: .teamBadge,
                text: teamAbbreviation ?? dto.team.name,
                tone: nil,
                participantRole: teamRole,
                teamAbbreviation: teamAbbreviation
            )
        ].compactMap(\.self)
        let resultItems = [
            dto.impact?.nilIfBlank.map {
                NormalizedPlayCardResultItem(id: "impact-\(dto.id)", text: $0, tone: .context, priority: 10)
            }
        ].compactMap(\.self)
        let situation = dto.situation.summary?.nilIfBlank.map {
            NormalizedPlayCardSituation(
                title: $0,
                periodText: dto.period.label?.nilIfBlank,
                setupText: nil,
                contextLine: nil,
                pressureLine: nil,
                sport: dto.sport,
                layout: "pressureBoardFallback",
                ownership: nil,
                accent: nil,
                dataConfidence: dto.situation.raw == nil ? "fallback" : "contract"
            )
        }

        return NormalizedPlayCard(
            schemaVersion: 1,
            cardID: dto.id,
            visualImportance: normalizedImportance(dto.visualImportance),
            accent: NormalizedPlayCardAccent(
                tone: nil,
                participantRole: teamRole,
                teamAbbreviation: teamAbbreviation
            ),
            clock: (dto.displayTime ?? dto.clock)?.nilIfBlank.map {
                NormalizedPlayCardText(text: $0, tone: .secondary, maxLines: 1)
            },
            leadIn: dto.leadIn.nilIfBlank.map {
                NormalizedPlayCardText(text: $0, tone: .context, maxLines: nil)
            },
            headline: NormalizedPlayCardText(text: dto.headline, tone: nil, maxLines: nil),
            body: dto.description.nilIfBlank.map {
                NormalizedPlayCardText(text: $0, tone: .secondary, maxLines: nil)
            },
            contextItems: contextItems,
            resultItems: resultItems,
            score: nil,
            team: normalizedTeam(
                participantRole: teamRole,
                abbreviation: teamAbbreviation,
                displayName: dto.team.name,
                participants: participants
            ),
            situation: situation,
            rawFeed: nil,
            accessibility: NormalizedPlayCardAccessibility(
                label: EventLabelResolver.customerAccessibilityText(
                    preferred: nil,
                    fallbackPieces: [dto.displayTime, dto.headline, dto.description]
                ) ?? dto.headline,
                value: nil,
                hint: nil,
                situationSummary: dto.situation.summary?.nilIfBlank
            )
        )
    }

    private static func normalizedContextItem(
        id: String,
        kind: NormalizedPlayCardContextKind,
        text: String?,
        tone: NormalizedPlayCardTone?,
        participantRole: GameParticipantRole?,
        teamAbbreviation: String?
    ) -> NormalizedPlayCardContextItem? {
        guard let text = text?.nilIfBlank else { return nil }
        return NormalizedPlayCardContextItem(
            id: id,
            kind: kind,
            text: text,
            tone: tone,
            participantRole: participantRole,
            teamAbbreviation: teamAbbreviation
        )
    }

    private static func normalizedTeam(
        participantRole: GameParticipantRole?,
        abbreviation: String?,
        displayName: String?,
        participants: [GameParticipant]
    ) -> NormalizedPlayCardTeam? {
        let participant = participants.first {
            if let participantRole, $0.role == participantRole { return true }
            return $0.abbreviation?.caseInsensitiveCompare(abbreviation ?? "") == .orderedSame
        }
        let displayName = displayName?.nilIfBlank ?? participant?.name.nilIfBlank
        let label = displayName ?? abbreviation
        guard participantRole != nil || abbreviation != nil || displayName != nil else { return nil }
        return NormalizedPlayCardTeam(
            participantRole: participantRole,
            abbreviation: abbreviation ?? participant?.abbreviation?.nilIfBlank,
            displayName: displayName,
            label: label
        )
    }

    private static func normalizedText(from dto: SDANormalizedPlayCardTextDTO?) -> NormalizedPlayCardText? {
        guard let text = dto?.text?.nilIfBlank else { return nil }
        return NormalizedPlayCardText(
            text: text,
            tone: normalizedTone(dto?.tone),
            maxLines: dto?.maxLines
        )
    }

    private static func normalizedContextItem(
        from dto: SDANormalizedPlayCardContextItemDTO
    ) -> NormalizedPlayCardContextItem? {
        guard let text = dto.text?.nilIfBlank else { return nil }
        let kind = normalizedContextKind(dto.kind)
        return NormalizedPlayCardContextItem(
            id: dto.id?.nilIfBlank ?? "\(kind.rawValue)-\(stableCardIDPart(for: text))",
            kind: kind,
            text: text,
            tone: normalizedTone(dto.tone),
            participantRole: participantRole(from: dto.participantRole),
            teamAbbreviation: dto.teamAbbreviation?.nilIfBlank
        )
    }

    private static func normalizedResultItem(
        from dto: SDANormalizedPlayCardResultItemDTO
    ) -> NormalizedPlayCardResultItem? {
        guard let text = dto.text?.nilIfBlank else { return nil }
        return NormalizedPlayCardResultItem(
            id: dto.id?.nilIfBlank ?? "result-\(stableCardIDPart(for: text))",
            text: text,
            tone: normalizedTone(dto.tone),
            priority: dto.priority ?? 100
        )
    }

    private static func normalizedScore(from dto: SDANormalizedPlayCardScoreDTO?) -> NormalizedPlayCardScore? {
        guard let dto else { return nil }
        let label = dto.label?.nilIfBlank
        let value = dto.value?.nilIfBlank
        guard label != nil || value != nil || dto.isScoringPlay == true else { return nil }
        return NormalizedPlayCardScore(
            label: label,
            value: value,
            isScoringPlay: dto.isScoringPlay ?? false,
            spoilerPolicy: normalizedSpoilerPolicy(dto.spoilerPolicy)
        )
    }

    private static func normalizedTeam(
        from dto: SDANormalizedPlayCardTeamDTO?,
        participants: [GameParticipant]
    ) -> NormalizedPlayCardTeam? {
        guard let dto else { return nil }
        let role = participantRole(from: dto.participantRole)
        let abbreviation = dto.abbreviation?.nilIfBlank
        let participant = participants.first {
            if let role, $0.role == role { return true }
            return $0.abbreviation?.caseInsensitiveCompare(abbreviation ?? "") == .orderedSame
        }
        let displayName = dto.displayName?.nilIfBlank ?? participant?.name.nilIfBlank
        let label = dto.label?.nilIfBlank ?? displayName
        guard role != nil || abbreviation != nil || displayName != nil || label != nil else { return nil }
        return NormalizedPlayCardTeam(
            participantRole: role,
            abbreviation: abbreviation ?? participant?.abbreviation?.nilIfBlank,
            displayName: displayName,
            label: label
        )
    }

    private static func normalizedSituation(
        from dto: SDANormalizedPlayCardSituationDTO?
    ) -> NormalizedPlayCardSituation? {
        guard let dto, let title = dto.title?.nilIfBlank else { return nil }
        return NormalizedPlayCardSituation(
            title: title,
            periodText: dto.periodText?.nilIfBlank,
            setupText: dto.setupText?.nilIfBlank,
            contextLine: dto.contextLine?.nilIfBlank,
            pressureLine: dto.pressureLine?.nilIfBlank,
            sport: dto.sport?.nilIfBlank ?? "generic",
            layout: dto.layout?.nilIfBlank ?? "pressureBoardFallback",
            ownership: normalizedSituationOwnership(from: dto.ownership),
            accent: normalizedAccent(from: dto.accent),
            dataConfidence: dto.dataConfidence?.nilIfBlank ?? "contract"
        )
    }

    private static func normalizedSituationOwnership(
        from dto: SDANormalizedPlayCardSituationOwnershipDTO?
    ) -> NormalizedPlayCardSituationOwnership? {
        guard let dto else { return nil }
        let role = dto.role?.nilIfBlank ?? "association"
        let participantRole = participantRole(from: dto.participantRole)
        let teamAbbreviation = dto.teamAbbreviation?.nilIfBlank
        let teamLabel = dto.teamLabel?.nilIfBlank
        guard participantRole != nil || teamAbbreviation != nil || teamLabel != nil else { return nil }
        return NormalizedPlayCardSituationOwnership(
            role: role,
            participantRole: participantRole,
            teamAbbreviation: teamAbbreviation,
            teamLabel: teamLabel,
            confidence: dto.confidence?.nilIfBlank ?? "explicit"
        )
    }

    private static func normalizedRawFeed(from dto: SDANormalizedPlayCardRawFeedDTO?) -> NormalizedPlayCardRawFeed? {
        guard let dto else { return nil }
        let text = dto.text?.nilIfBlank
        let source = dto.source?.nilIfBlank
        let updatedAt = dto.updatedAt?.nilIfBlank
        guard text != nil || source != nil || updatedAt != nil else { return nil }
        return NormalizedPlayCardRawFeed(
            text: text,
            source: source,
            updatedAt: updatedAt,
            disclosureTitle: dto.disclosureTitle?.nilIfBlank
        )
    }

    private static func normalizedAccessibility(
        from dto: SDANormalizedPlayCardAccessibilityDTO?,
        fallbackPieces: [String?]
    ) -> NormalizedPlayCardAccessibility {
        let label = dto?.label?.nilIfBlank ?? fallbackPieces.compactMap { $0?.nilIfBlank }.joined(separator: ". ")
        return NormalizedPlayCardAccessibility(
            label: label,
            value: dto?.value?.nilIfBlank,
            hint: dto?.hint?.nilIfBlank,
            situationSummary: dto?.situationSummary?.nilIfBlank
        )
    }

    private static func normalizedAccent(from dto: SDANormalizedPlayCardAccentDTO?) -> NormalizedPlayCardAccent? {
        guard let dto else { return nil }
        let tone = normalizedTone(dto.tone)
        let role = participantRole(from: dto.participantRole)
        let teamAbbreviation = dto.teamAbbreviation?.nilIfBlank
        guard tone != nil || role != nil || teamAbbreviation != nil else { return nil }
        return NormalizedPlayCardAccent(tone: tone, participantRole: role, teamAbbreviation: teamAbbreviation)
    }

    private static func normalizedImportance(_ value: String?) -> NormalizedPlayCardImportance {
        switch value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "critical", "important":
            return .critical
        case "high", "standard":
            return .high
        case "low", "basic":
            return .low
        default:
            return .medium
        }
    }

    private static func normalizedTone(_ value: String?) -> NormalizedPlayCardTone? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return nil }
        return NormalizedPlayCardTone(rawValue: value)
    }

    private static func normalizedContextKind(_ value: String?) -> NormalizedPlayCardContextKind {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return .metadata }
        return NormalizedPlayCardContextKind(rawValue: value) ?? .metadata
    }

    private static func normalizedSpoilerPolicy(_ value: String?) -> NormalizedPlayCardSpoilerPolicy {
        switch value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "always_show", "alwaysshow":
            return .alwaysShow
        case "final_only", "finalonly":
            return .finalOnly
        default:
            return .hideUntilReveal
        }
    }

    private static func participantRole(from value: String?) -> GameParticipantRole? {
        switch value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
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

    private static func stableCardIDPart(for text: String) -> String {
        text.normalizedLabelKey.unicodeScalars.reduce(UInt32(2_166_136_261)) { hash, scalar in
            (hash ^ UInt32(scalar.value)) &* 16_777_619
        }
        .description
    }

    private static func score(
        from dto: SDAScoreSnapshotDTO,
        participants: [GameParticipant]
    ) -> ScoreState {
        ScoreState(participantScores: participants.map { participant in
            let value: Int?
            switch participant.role {
            case .home:
                value = dto.home
            case .away:
                value = dto.away
            case .other:
                value = nil
            }
            return ParticipantScore(participantID: participant.id, participantRole: participant.role, score: value)
        })
    }

    private static func sportState(from dto: SDASituationSportStateDTO?) -> GameEventSituationSportState? {
        guard let dto else { return nil }
        return GameEventSituationSportState(
            baseball: dto.baseball.map {
                GameEventBaseballSituation(
                    inning: $0.inning,
                    half: $0.half?.nilIfBlank,
                    outs: $0.outs,
                    balls: $0.balls,
                    strikes: $0.strikes,
                    bases: $0.bases.map {
                        GameEventBaseballBases(first: $0.first, second: $0.second, third: $0.third)
                    },
                    baseState: $0.baseState?.nilIfBlank,
                    battingTeamAbbreviation: $0.battingTeamAbbreviation?.nilIfBlank,
                    fieldingTeamAbbreviation: $0.fieldingTeamAbbreviation?.nilIfBlank,
                    batterName: $0.batterName?.nilIfBlank,
                    pitcherName: $0.pitcherName?.nilIfBlank
                )
            },
            football: dto.football,
            hockey: dto.hockey,
            basketball: dto.basketball,
            soccer: dto.soccer,
            golf: dto.golf,
            tennis: dto.tennis
        )
    }
}
