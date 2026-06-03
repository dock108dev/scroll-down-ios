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
            renderType: .standardPBP,
            narrative: nil,
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
        let renderType = NormalizedPlayCardRenderType(cardFeedValue: dto.renderType)
        let narrative = normalizedNarrative(from: dto)
        let metaLeadIn = [dto.leadIn.nilIfBlank, dto.teamContext?.nilIfBlank]
            .compactMap(\.self)
            .joined(separator: " · ")
        let stageSetting = setupContextText(
            stageSetting: dto.stageSetting,
            leadIn: dto.leadIn,
            scoreBefore: dto.scoreBefore,
            teamRole: teamRole,
            teamAbbreviation: teamAbbreviation,
            participants: participants
        )
        let payoffText = scorePayoffText(
            scoreBefore: dto.scoreBefore,
            scoreAfter: dto.scoreAfter,
            scoreChange: dto.scoreChange,
            teamRole: teamRole,
            teamAbbreviation: teamAbbreviation,
            participants: participants
        )
        let impactText = distinctNarrativeContextText(
            dto.impact,
            comparedWith: [payoffText, dto.description, dto.headline].compactMap(\.self).joined(separator: " ")
        )
        let contextItems = [
            normalizedContextItem(
                id: "stage-\(dto.id)",
                kind: .status,
                text: stageSetting,
                tone: .neutral,
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
            impactText.map {
                NormalizedPlayCardResultItem(id: "impact-\(dto.id)", text: $0, tone: .context, priority: 10)
            },
            payoffText.map {
                NormalizedPlayCardResultItem(id: "score-change-\(dto.id)", text: $0, tone: .scoring, priority: 20)
            }
        ].compactMap(\.self)

        return NormalizedPlayCard(
            schemaVersion: 1,
            cardID: dto.id,
            renderType: renderType,
            narrative: narrative,
            visualImportance: normalizedImportance(dto.visualImportance),
            accent: NormalizedPlayCardAccent(
                tone: nil,
                participantRole: teamRole,
                teamAbbreviation: teamAbbreviation
            ),
            clock: (dto.displayTime ?? dto.clock)?.nilIfBlank.map {
                NormalizedPlayCardText(text: $0, tone: .secondary, maxLines: 1)
            },
            leadIn: metaLeadIn.nilIfBlank.map {
                NormalizedPlayCardText(text: $0, tone: .context, maxLines: nil)
            },
            headline: NormalizedPlayCardText(
                text: dto.headline.nilIfBlank ?? narrative?.playLine ?? "Play details unavailable",
                tone: nil,
                maxLines: nil
            ),
            body: (dto.rawPlayText ?? dto.description).nilIfBlank.map {
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
            situation: nil,
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
}
