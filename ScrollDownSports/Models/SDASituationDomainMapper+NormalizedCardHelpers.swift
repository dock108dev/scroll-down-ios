import Foundation

extension SDADomainMapper {
    static func distinctNarrativeContextText(_ text: String?, comparedWith other: String?) -> String? {
        guard let text = text?.nilIfBlank else { return nil }
        guard let other = other?.nilIfBlank else { return text }
        return normalizedNarrativeMeaning(other).contains(normalizedNarrativeMeaning(text)) ? nil : text
    }

    static func normalizedNarrativeMeaning(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func normalizedNarrative(from dto: SDANarrativeCardDTO) -> NormalizedPlayCardNarrative? {
        guard let setup = dto.setupLine?.nilIfBlank,
              let play = dto.playLine?.nilIfBlank,
              let update = dto.updateLine?.nilIfBlank else {
            return nil
        }
        return NormalizedPlayCardNarrative(
            setupLine: setup,
            playLine: play,
            updateLine: update
        )
    }

    static func setupContextText(
        stageSetting: String?,
        leadIn: String?,
        scoreBefore: SDAScoreSnapshotDTO?,
        teamRole: GameParticipantRole?,
        teamAbbreviation: String?,
        participants: [GameParticipant]
    ) -> String? {
        guard let stage = distinctNarrativeContextText(stageSetting, comparedWith: leadIn) else {
            return prePlayScoreText(scoreBefore: scoreBefore, teamRole: teamRole, teamAbbreviation: teamAbbreviation, participants: participants)
        }
        guard let scoreText = prePlayScoreText(
            scoreBefore: scoreBefore,
            teamRole: teamRole,
            teamAbbreviation: teamAbbreviation,
            participants: participants
        ) else {
            return stage
        }
        if let comma = stage.firstIndex(of: ",") {
            let prefix = stage[..<comma]
            let suffixStart = stage.index(after: comma)
            let suffix = stage[suffixStart...].trimmingCharacters(in: .whitespacesAndNewlines)
            return [String(prefix), scoreText, suffix].filter { !$0.isEmpty }.joined(separator: ", ")
        }
        return "\(stage) · \(scoreText)"
    }

    static func prePlayScoreText(
        scoreBefore: SDAScoreSnapshotDTO?,
        teamRole: GameParticipantRole?,
        teamAbbreviation: String?,
        participants: [GameParticipant]
    ) -> String? {
        guard let scoreBefore,
              let away = scoreBefore.away,
              let home = scoreBefore.home else {
            return nil
        }
        guard let teamRole,
              let owner = score(for: teamRole, away: away, home: home),
              let opponentRole = opponentRole(for: teamRole),
              let opponent = score(for: opponentRole, away: away, home: home) else {
            return "Score \(away)-\(home)"
        }
        let team = teamAbbreviation ?? participantAbbreviation(for: teamRole, participants: participants) ?? "Team"
        if owner == opponent {
            return "\(team) tied \(owner)-\(opponent)"
        }
        if owner > opponent {
            return "\(team) up \(owner)-\(opponent)"
        }
        return "\(team) down \(opponent)-\(owner)"
    }

    static func scorePayoffText(
        scoreBefore: SDAScoreSnapshotDTO?,
        scoreAfter: SDAScoreSnapshotDTO?,
        scoreChange: SDACardScoreChangeDTO?,
        teamRole: GameParticipantRole?,
        teamAbbreviation: String?,
        participants: [GameParticipant]
    ) -> String? {
        guard let scoreBefore,
              let scoreAfter,
              let scoringRole = scoreChangeRole(scoreChange) ?? teamRole,
              let opponentRole = opponentRole(for: scoringRole),
              let beforeOwner = score(for: scoringRole, snapshot: scoreBefore),
              let beforeOpponent = score(for: opponentRole, snapshot: scoreBefore),
              let afterOwner = score(for: scoringRole, snapshot: scoreAfter),
              let afterOpponent = score(for: opponentRole, snapshot: scoreAfter),
              afterOwner > beforeOwner else {
            return nil
        }
        let team = teamAbbreviation ?? participantAbbreviation(for: scoringRole, participants: participants) ?? "Team"
        let beforeMargin = beforeOwner - beforeOpponent
        let afterMargin = afterOwner - afterOpponent
        if afterMargin == 0 {
            return "\(team) ties it \(afterOwner)-\(afterOpponent)"
        }
        if beforeMargin <= 0, afterMargin > 0 {
            return "\(team) takes a \(afterOwner)-\(afterOpponent) lead"
        }
        if beforeMargin < 0, afterMargin < 0 {
            return "\(team) cuts it to \(afterOpponent)-\(afterOwner)"
        }
        if beforeMargin > 0, afterMargin > beforeMargin {
            return "\(team) extends lead to \(afterOwner)-\(afterOpponent)"
        }
        return "\(team) makes it \(afterOwner)-\(afterOpponent)"
    }

    static func scoreChangeRole(_ scoreChange: SDACardScoreChangeDTO?) -> GameParticipantRole? {
        guard let scoreChange else { return nil }
        if scoreChange.home > 0 { return .home }
        if scoreChange.away > 0 { return .away }
        return nil
    }

    static func score(for role: GameParticipantRole, snapshot: SDAScoreSnapshotDTO) -> Int? {
        score(for: role, away: snapshot.away, home: snapshot.home)
    }

    static func score(for role: GameParticipantRole, away: Int?, home: Int?) -> Int? {
        switch role {
        case .away:
            return away
        case .home:
            return home
        case .other:
            return nil
        }
    }

    static func opponentRole(for role: GameParticipantRole) -> GameParticipantRole? {
        switch role {
        case .away:
            return .home
        case .home:
            return .away
        case .other:
            return nil
        }
    }

    static func participantAbbreviation(
        for role: GameParticipantRole,
        participants: [GameParticipant]
    ) -> String? {
        participants.first { $0.role == role }?.abbreviation?.nilIfBlank
    }

    static func normalizedContextItem(
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

    static func normalizedTeam(
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

    static func normalizedText(from dto: SDANormalizedPlayCardTextDTO?) -> NormalizedPlayCardText? {
        guard let text = dto?.text?.nilIfBlank else { return nil }
        return NormalizedPlayCardText(
            text: text,
            tone: normalizedTone(dto?.tone),
            maxLines: dto?.maxLines
        )
    }

    static func normalizedContextItem(
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

    static func normalizedResultItem(
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

    static func normalizedScore(from dto: SDANormalizedPlayCardScoreDTO?) -> NormalizedPlayCardScore? {
        guard let dto else { return nil }
        let label = dto.label?.nilIfBlank
        let value = dto.value?.nilIfBlank
        guard label != nil || value != nil || dto.isScoringPlay == true else { return nil }
        return NormalizedPlayCardScore(
            label: label,
            value: value,
            isScoringPlay: dto.isScoringPlay ?? false
        )
    }

    static func normalizedTeam(
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

    static func normalizedSituation(
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

    static func normalizedSituationOwnership(
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

    static func normalizedRawFeed(from dto: SDANormalizedPlayCardRawFeedDTO?) -> NormalizedPlayCardRawFeed? {
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

    static func normalizedAccessibility(
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

    static func normalizedAccent(from dto: SDANormalizedPlayCardAccentDTO?) -> NormalizedPlayCardAccent? {
        guard let dto else { return nil }
        let tone = normalizedTone(dto.tone)
        let role = participantRole(from: dto.participantRole)
        let teamAbbreviation = dto.teamAbbreviation?.nilIfBlank
        guard tone != nil || role != nil || teamAbbreviation != nil else { return nil }
        return NormalizedPlayCardAccent(tone: tone, participantRole: role, teamAbbreviation: teamAbbreviation)
    }

    static func normalizedImportance(_ value: String?) -> NormalizedPlayCardImportance {
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

    static func normalizedTone(_ value: String?) -> NormalizedPlayCardTone? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return nil }
        return NormalizedPlayCardTone(rawValue: value)
    }

    static func normalizedContextKind(_ value: String?) -> NormalizedPlayCardContextKind {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return .metadata }
        return NormalizedPlayCardContextKind(rawValue: value) ?? .metadata
    }

    static func participantRole(from value: String?) -> GameParticipantRole? {
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

    static func stableCardIDPart(for text: String) -> String {
        text.normalizedLabelKey.unicodeScalars.reduce(UInt32(2_166_136_261)) { hash, scalar in
            (hash ^ UInt32(scalar.value)) &* 16_777_619
        }
        .description
    }

    static func score(
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

    static func sportState(from dto: SDASituationSportStateDTO?) -> GameEventSituationSportState? {
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
