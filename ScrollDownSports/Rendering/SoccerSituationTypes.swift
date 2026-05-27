import Foundation

struct SoccerPitchStripDiagram: Hashable {
    let setPieceText: String
    let locationText: String?
    let attackingTeamAbbreviation: String?
    let ballX: Double?
    let ballY: Double?
    let highlightsGoalArea: Bool
}

struct SoccerSituationInputs: Hashable, Sendable {
    let state: SoccerSituationState?
    let confidenceDecision: SituationBlockDecision
}

struct SoccerSituationState: Hashable, Sendable {
    let clockText: String
    let scoreText: String
    let attackingTeam: SoccerAttackingTeam
    let restartKind: SoccerRestartKind
    let phase: SoccerSetPiecePhase
    let location: SoccerLocationState
    let confidenceScore: Double

    var setupText: String {
        [restartKind.shortLabel, location.label]
            .compactMap { $0?.nilIfBlank }
            .joined(separator: " · ")
    }
}

struct SoccerAttackingTeam: Hashable, Sendable {
    let participantRole: GameParticipantRole?
    let teamAbbreviation: String?
    let teamLabel: String?

    var hasTeamIdentity: Bool {
        participantRole != nil || teamAbbreviation?.nilIfBlank != nil || teamLabel?.nilIfBlank != nil
    }
}

struct SoccerLocationState: Hashable, Sendable {
    let x: Double?
    let y: Double?
    let zone: SoccerFieldZone?
    let side: SoccerFieldSide?
    let distanceToGoal: Double?
    let angleToGoalDegrees: Double?
    let attackingThird: Bool

    var hasExplicitContext: Bool {
        x != nil || y != nil || zone != nil || side != nil || distanceToGoal != nil || attackingThird
    }

    var label: String? {
        if let zoneLabel = zone?.label, let sideLabel = side?.label {
            return "\(zoneLabel) · \(sideLabel)"
        }
        return zone?.label ?? side?.label ?? (attackingThird ? "Attacking third" : nil)
    }
}

enum SoccerRestartKind: String, Hashable, Sendable {
    case corner
    case directFreeKick
    case indirectFreeKick
    case penaltyKick
    case unknown

    var shortLabel: String? {
        switch self {
        case .corner:
            return "Corner"
        case .directFreeKick, .indirectFreeKick:
            return "Free kick"
        case .penaltyKick:
            return "Penalty"
        case .unknown:
            return nil
        }
    }
}

enum SoccerSetPiecePhase: String, Hashable, Sendable {
    case awarded
    case setup
    case unknown
}

enum SoccerFieldZone: String, Hashable, Sendable {
    case attackingThird
    case finalEighth
    case penaltyArea
    case sixYardBox
    case unknown

    var label: String? {
        switch self {
        case .attackingThird:
            return "Attacking third"
        case .finalEighth:
            return "Near goal"
        case .penaltyArea:
            return "Penalty area"
        case .sixYardBox:
            return "Six-yard box"
        case .unknown:
            return nil
        }
    }
}

enum SoccerFieldSide: String, Hashable, Sendable {
    case left
    case right
    case center
    case unknown

    var label: String? {
        switch self {
        case .left:
            return "Left side"
        case .right:
            return "Right side"
        case .center:
            return "Central"
        case .unknown:
            return nil
        }
    }
}
