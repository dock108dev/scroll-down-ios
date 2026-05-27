import Foundation

struct ScorePressureLine: Hashable, Sendable {
    let role: GameParticipantRole
    let opponentRole: GameParticipantRole
    let before: ScorePressureState
    let after: ScorePressureState?
    let scoredPoints: Int?
    let swingKind: ScoreSwingKind
    let text: String
    let accessibilityText: String
}

enum ScorePressureState: Hashable, Sendable {
    case tied
    case leading(by: Int)
    case trailing(by: Int)

    var margin: Int {
        switch self {
        case .tied:
            return 0
        case .leading(let points):
            return points
        case .trailing(let points):
            return -points
        }
    }

    var shortText: String {
        switch self {
        case .tied:
            return "Tied"
        case .leading(let points):
            return "Up \(points)"
        case .trailing(let points):
            return "Down \(points)"
        }
    }

    var spokenText: String {
        switch self {
        case .tied:
            return "tied"
        case .leading(let points):
            return "up by \(points)"
        case .trailing(let points):
            return "down by \(points)"
        }
    }
}

enum ScoreSwingKind: Hashable, Sendable {
    case none
    case extendsLead
    case cutsDeficit
    case tying
    case goAhead
    case leadChange
}

enum ScorePressurePresentation {
    static func line(for event: GameEvent, teamLabel: String? = nil) -> ScorePressureLine? {
        guard let ownerRole = ownerRole(for: event),
              let opponentRole = opponentRole(for: ownerRole),
              let scoreBefore = event.scoreBefore,
              let ownerBefore = scoreBefore.score(for: ownerRole),
              let opponentBefore = scoreBefore.score(for: opponentRole) else {
            return nil
        }

        let before = state(from: ownerBefore - opponentBefore)
        let scoredPoints = scoredPoints(for: event, ownerRole: ownerRole, ownerBefore: ownerBefore)
        let after = afterState(
            for: event,
            ownerRole: ownerRole,
            opponentRole: opponentRole,
            before: before,
            scoredPoints: scoredPoints
        )
        let resolvedSwingKind: ScoreSwingKind = after.map { Self.swingKind(before: before, after: $0) } ?? .none
        let text = [before.shortText, after?.shortText].compactMap(\.self).joined(separator: " -> ")

        return ScorePressureLine(
            role: ownerRole,
            opponentRole: opponentRole,
            before: before,
            after: after,
            scoredPoints: scoredPoints,
            swingKind: resolvedSwingKind,
            text: text,
            accessibilityText: accessibilityText(teamLabel: teamLabel, before: before, after: after)
        )
    }

    private static func ownerRole(for event: GameEvent) -> GameParticipantRole? {
        if let role = validRole(event.teamOwnership) {
            return role
        }
        guard let deltaRole = validRole(event.scoreDelta?.participantRole),
              isTrustworthyScoringDelta(event.scoreDelta) else {
            return nil
        }
        return deltaRole
    }

    private static func validRole(_ role: GameParticipantRole?) -> GameParticipantRole? {
        switch role {
        case .home, .away:
            return role
        case .other, nil:
            return nil
        }
    }

    private static func opponentRole(for role: GameParticipantRole) -> GameParticipantRole? {
        switch role {
        case .home:
            return .away
        case .away:
            return .home
        case .other:
            return nil
        }
    }

    private static func isTrustworthyScoringDelta(_ delta: ScoreDelta?) -> Bool {
        guard let delta else { return false }
        if let change = delta.change {
            return change > 0
        }
        if let before = delta.before, let after = delta.after {
            return after > before
        }
        return false
    }

    private static func scoredPoints(for event: GameEvent, ownerRole: GameParticipantRole, ownerBefore: Int) -> Int? {
        let isScoringPlay = event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil
        guard isScoringPlay else { return nil }

        if event.scoreDelta?.participantRole == ownerRole,
           let change = event.scoreDelta?.change,
           change > 0 {
            return change
        }
        guard let ownerAfter = event.scoreAfter.score(for: ownerRole) else { return nil }
        let inferred = ownerAfter - ownerBefore
        return inferred > 0 ? inferred : nil
    }

    private static func afterState(
        for event: GameEvent,
        ownerRole: GameParticipantRole,
        opponentRole: GameParticipantRole,
        before: ScorePressureState,
        scoredPoints: Int?
    ) -> ScorePressureState? {
        guard scoredPoints != nil,
              let ownerAfter = event.scoreAfter.score(for: ownerRole),
              let opponentAfter = event.scoreAfter.score(for: opponentRole) else {
            return nil
        }
        let after = state(from: ownerAfter - opponentAfter)
        return after.margin == before.margin ? nil : after
    }

    private static func state(from margin: Int) -> ScorePressureState {
        if margin == 0 { return .tied }
        if margin > 0 { return .leading(by: margin) }
        return .trailing(by: abs(margin))
    }

    private static func swingKind(before: ScorePressureState, after: ScorePressureState) -> ScoreSwingKind {
        let beforeMargin = before.margin
        let afterMargin = after.margin
        guard afterMargin != beforeMargin else { return .none }
        if beforeMargin < 0 && afterMargin > 0 { return .leadChange }
        if beforeMargin <= 0 && afterMargin > 0 { return .goAhead }
        if beforeMargin < 0 && afterMargin == 0 { return .tying }
        if beforeMargin < 0 && afterMargin < 0 && afterMargin > beforeMargin { return .cutsDeficit }
        if beforeMargin > 0 && afterMargin > beforeMargin { return .extendsLead }
        return .none
    }

    private static func accessibilityText(
        teamLabel: String?,
        before: ScorePressureState,
        after: ScorePressureState?
    ) -> String {
        let label = teamLabel?.nilIfBlank ?? "Team"
        if let after {
            return "\(label) was \(before.spokenText) before the play and \(after.spokenText) after the play."
        }
        return "\(label) was \(before.spokenText) before the play."
    }
}
