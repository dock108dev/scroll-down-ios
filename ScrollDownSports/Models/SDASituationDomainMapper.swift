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
