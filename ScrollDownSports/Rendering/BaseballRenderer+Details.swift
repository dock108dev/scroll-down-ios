import Foundation

extension BaseballRenderer {
    func baseballDetail(for event: GameEvent) -> String? {
        event.detail?.nilIfBlank.flatMap { value in
            event.headline.range(of: value, options: [.caseInsensitive, .diacriticInsensitive]) == nil ? value : nil
        }
    }

    func importanceContext(for event: GameEvent, hasBaseState: Bool) -> String? {
        if event.importanceMetadata?.isLeadChange == true {
            return "Lead change"
        }
        if event.importanceMetadata?.isTyingPlay == true {
            return "Tying play"
        }

        for reason in event.importanceMetadata?.reasons ?? [] {
            switch normalizedSituationMetadataKey(reason) {
            case "runner_aboard":
                if !hasBaseState { return "Runner aboard" }
            case "runners_in_scoring_position", "runner_in_scoring_position":
                return "Runner in scoring position"
            case "bases_loaded":
                if !hasBaseState { return "Bases loaded" }
            case "late_game":
                return "Late inning"
            default:
                continue
            }
        }
        return nil
    }

    func scorePressureLine(for event: GameEvent) -> String? {
        ScorePressurePresentation.line(
            for: event,
            teamLabel: event.presentation?.teamLabel ?? event.teamAbbreviation
        )?.text
    }

    func baseballSituationPeriodText(
        for event: GameEvent,
        prePitchState: BaseballPrePitchState,
        battingOwnership: GameEventSituationOwnership?,
        style: BaseballSituationPeriodTextStyle
    ) -> String? {
        let formatterOutput = PeriodLabelFormatter.output(
            sport: .mlb,
            leagueCode: "MLB",
            periodOrdinal: event.periodOrdinal,
            periodLabel: event.periodLabel,
            clockLabel: event.clockLabel
        )
        let inferredHalf = prePitchState.inningHalf
            ?? baseballInningHalf(from: prePitchState.battingTeam?.side)
            ?? baseballInningHalf(from: battingOwnership?.participantRole)
        let inning = prePitchState.inning ?? event.periodOrdinal
        if let inning, let inferredHalf {
            switch style {
            case .compact:
                return [
                    "\(inferredHalf.compactPrefix)\(inning)",
                    formatterOutput.rowClockText.nilIfBlank
                ]
                .compactMap(\.self)
                .joined(separator: " ")
            case .expanded:
                return "\(inferredHalf.displayName) \(ordinal(inning))"
            }
        }
        return formatterOutput.situationText
    }

    func baseballInningHalf(from role: GameParticipantRole?) -> BaseballInningHalf? {
        switch role {
        case .away:
            return .top
        case .home:
            return .bottom
        case .other, nil:
            return nil
        }
    }

    func ordinal(_ value: Int) -> String {
        let suffix: String
        if (11...13).contains(value % 100) {
            suffix = "th"
        } else {
            switch value % 10 {
            case 1:
                suffix = "st"
            case 2:
                suffix = "nd"
            case 3:
                suffix = "rd"
            default:
                suffix = "th"
            }
        }
        return "\(value)\(suffix)"
    }

    func situationTone(for event: GameEvent) -> SportsTheme.Tone {
        if event.importanceMetadata?.isLeadChange == true || event.importanceMetadata?.isTyingPlay == true {
            return .critical
        }
        if event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
            return .scoring
        }
        return .neutral
    }

    func baseballDiagram(
        baseState: BaseballBaseState?,
        battingOwnership: GameEventSituationOwnership?,
        outs: Int?,
        count: String?
    ) -> GameEventSituationDiagram? {
        guard let baseState else {
            return nil
        }
        return .baseballDiamond(
            BaseballSituationDiagram(
                occupiedBases: baseState.occupiedBases,
                batting: battingOwnership,
                outs: outs,
                count: count
            )
        )
    }

    func outsLabel(from outs: Int?) -> String? {
        guard let outs else { return nil }
        return outs == 1 ? "1 out" : "\(outs) outs"
    }

    func battingOwnership(
        for event: GameEvent,
        prePitchState: BaseballPrePitchState,
        game: Game?
    ) -> GameEventSituationOwnership? {
        if let explicit = explicitBattingOwnership(for: event, game: game) {
            return explicit
        }
        if let inningHalf = prePitchState.inningHalf {
            let participantRole: GameParticipantRole = inningHalf == .top ? .away : .home
            let participant = game?.participants.first { $0.role == participantRole }
            return GameEventSituationOwnership(
                role: .batting,
                participantRole: participantRole,
                teamAbbreviation: participant?.abbreviation,
                teamLabel: participant?.name,
                confidence: .derivedFromPeriod
            )
        }
        return eventFallbackOwnership(for: event)
    }

    func eventFallbackOwnership(for event: GameEvent) -> GameEventSituationOwnership? {
        guard event.teamOwnership != nil
            || event.teamAbbreviation?.nilIfBlank != nil
            || event.presentation?.teamLabel?.nilIfBlank != nil else {
            return nil
        }
        return GameEventSituationOwnership(
            role: .association,
            participantRole: event.teamOwnership,
            teamAbbreviation: event.teamAbbreviation,
            teamLabel: event.presentation?.teamLabel,
            confidence: .eventFallback
        )
    }

    func explicitBattingOwnership(for event: GameEvent, game: Game?) -> GameEventSituationOwnership? {
        let abbreviation = [
            event.situationBefore?.sportState?.baseball?.battingTeamAbbreviation,
            situationMetadataText(
                [
                    "battingTeamAbbreviation",
                    "batting_team_abbreviation",
                    "offenseTeamAbbreviation",
                    "offense_team_abbreviation",
                    "attackingTeamAbbreviation",
                    "attacking_team_abbreviation"
                ],
                in: event.sportMetadata
            )
        ].firstNonBlank
        let explicitRole = situationMetadataText(
            [
                "battingTeamRole",
                "batting_team_role",
                "battingSide",
                "batting_side",
                "offenseTeamRole",
                "offense_team_role"
            ],
            in: event.sportMetadata
        ).flatMap(situationParticipantRole(from:))
        let roleParticipant = explicitRole.flatMap { role in
            game?.participants.first { $0.role == role }
        }
        let abbreviationParticipant = abbreviation.flatMap { abbreviation in
            game?.participants.first { participant in
                participant.abbreviation?.caseInsensitiveCompare(abbreviation) == .orderedSame
            }
        }

        guard abbreviation?.nilIfBlank != nil || explicitRole != nil || roleParticipant != nil || abbreviationParticipant != nil else {
            return nil
        }
        if let explicitRole {
            let abbreviationMatchesRole = abbreviationParticipant?.role == explicitRole || abbreviationParticipant == nil
            return GameEventSituationOwnership(
                role: .batting,
                participantRole: explicitRole,
                teamAbbreviation: roleParticipant?.abbreviation ?? (abbreviationMatchesRole ? abbreviation?.nilIfBlank : nil),
                teamLabel: roleParticipant?.name
                    ?? (abbreviationMatchesRole ? abbreviationParticipant?.name : nil)
                    ?? event.presentation?.teamLabel,
                confidence: .explicit
            )
        }
        let participant = abbreviationParticipant
        return GameEventSituationOwnership(
            role: .batting,
            participantRole: participant?.role,
            teamAbbreviation: abbreviation?.nilIfBlank ?? participant?.abbreviation,
            teamLabel: participant?.name ?? event.presentation?.teamLabel,
            confidence: .explicit
        )
    }

}
