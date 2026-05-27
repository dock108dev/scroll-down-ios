import Foundation

struct BasketballHalfCourtDiagram: Hashable {
    let possessionText: String
    let clockText: String?
    let shotClockText: String?
    let scoreText: String?
    let bonusText: String?
    let shotText: String?
    let locationText: String?
    let freeThrowText: String?
    let shotLocation: BasketballDiagramShotLocation?
    let pressure: Double?
}

struct BasketballDiagramShotLocation: Hashable {
    let x: Double
    let y: Double
    let label: String?
}

struct BasketballSituationInputs: Hashable, Sendable {
    let state: BasketballSituationState?
    let confidenceDecision: SituationBlockDecision
}

struct BasketballSituationState: Hashable, Sendable {
    let schemaVersion: Int
    let stateTiming: BasketballStateTiming
    let periodText: String?
    let clockText: String?
    let possession: BasketballPossessionState?
    let shotClock: BasketballShotClockState?
    let bonus: BasketballBonusState?
    let shot: BasketballShotState?
    let freeThrows: BasketballFreeThrowState?
}

enum BasketballStateTiming: String, Hashable, Sendable {
    case preEvent
    case eventMoment
    case postEvent
    case interval
    case unknown
}

struct BasketballPossessionState: Hashable, Sendable {
    let participantRole: GameParticipantRole?
    let teamAbbreviation: String?
    let teamLabel: String?
    let phase: BasketballPossessionPhase
    let confidence: BasketballFieldConfidence

    var hasTeamIdentity: Bool {
        participantRole != nil || teamAbbreviation?.nilIfBlank != nil || teamLabel?.nilIfBlank != nil
    }

    var displayText: String {
        teamAbbreviation?.nilIfBlank ?? teamLabel?.nilIfBlank ?? participantRole?.displayName ?? "Team"
    }
}

enum BasketballPossessionPhase: String, Hashable, Sendable {
    case liveBall
    case inbound
    case freeThrow
    case jumpBall
    case deadBall
    case unknown

    var label: String? {
        switch self {
        case .liveBall:
            return nil
        case .inbound:
            return "Inbound"
        case .freeThrow:
            return "Free throws"
        case .jumpBall:
            return "Jump ball"
        case .deadBall:
            return "Dead ball"
        case .unknown:
            return nil
        }
    }
}

struct BasketballShotClockState: Hashable, Sendable {
    let seconds: Double?
    let displayText: String?
    let status: BasketballShotClockStatus
    let confidence: BasketballFieldConfidence

    var metricText: String? {
        switch status {
        case .running:
            if let displayText = displayText?.nilIfBlank {
                return displayText
            }
            return seconds.map(Self.secondsText)
        case .stopped:
            if let displayText = displayText?.nilIfBlank {
                return "Stopped at \(displayText)"
            }
            return seconds.map { "Stopped at \(Self.secondsText($0))" }
        case .off:
            return "Off"
        case .expired:
            return "Expired"
        case .unknown:
            return nil
        }
    }

    var pressure: Double? {
        guard let seconds, status == .running else { return nil }
        return max(0, min(1, (10 - seconds) / 10))
    }

    var pressureLabel: String? {
        guard let pressure else { return nil }
        if pressure >= 0.85 { return "End of clock" }
        if pressure >= 0.60 { return "Late clock" }
        if pressure >= 0.30 { return "Clock pressure" }
        return nil
    }

    private static func secondsText(_ seconds: Double) -> String {
        seconds.rounded() == seconds ? String(Int(seconds)) : String(format: "%.1f", seconds)
    }
}

enum BasketballShotClockStatus: String, Hashable, Sendable {
    case running
    case stopped
    case off
    case expired
    case unknown
}

struct BasketballBonusState: Hashable, Sendable {
    let possessionTeamStatus: BasketballBonusStatus?
    let possessionTeamFoulsToBonus: Int?
    let confidence: BasketballFieldConfidence

    var metricText: String? {
        switch possessionTeamStatus {
        case .some(.doubleBonus):
            return "Double bonus"
        case .some(.bonus):
            return "In bonus"
        case .some(.none):
            if let fouls = possessionTeamFoulsToBonus, fouls > 0 {
                return fouls == 1 ? "1 to bonus" : "\(fouls) to bonus"
            }
            return nil
        case .some(.unknown), nil:
            return nil
        }
    }

    var pressure: Double {
        switch possessionTeamStatus {
        case .some(.doubleBonus):
            return 1
        case .some(.bonus):
            return 0.75
        case .some(.none):
            return possessionTeamFoulsToBonus == 1 ? 0.40 : 0
        case .some(.unknown), nil:
            return 0
        }
    }
}

enum BasketballBonusStatus: String, Hashable, Sendable {
    case none
    case bonus
    case doubleBonus
    case unknown
}

struct BasketballShotState: Hashable, Sendable {
    let result: BasketballShotResult?
    let value: Int?
    let location: BasketballShotLocation?
    let confidence: BasketballFieldConfidence

    var metricText: String? {
        let valueText = value.map { "\($0)PT" }
        let resultText = result?.label
        return [valueText, resultText].compactMap { $0?.nilIfBlank }.joined(separator: " ").nilIfBlank
    }
}

enum BasketballShotResult: String, Hashable, Sendable {
    case made
    case missed
    case blocked
    case fouled
    case unknown

    var label: String? {
        switch self {
        case .made:
            return "made"
        case .missed:
            return "missed"
        case .blocked:
            return "blocked"
        case .fouled:
            return "fouled"
        case .unknown:
            return nil
        }
    }
}

struct BasketballShotLocation: Hashable, Sendable {
    let coordinateSystem: BasketballShotCoordinateSystem
    let x: Double?
    let y: Double?
    let zone: BasketballShotZone?
    let confidence: BasketballFieldConfidence

    var label: String? {
        zone?.label
    }
}

enum BasketballShotCoordinateSystem: String, Hashable, Sendable {
    case normalizedHalfCourt
    case normalizedFullCourt
    case feetFromBasket
    case providerNative
    case unknown
}

enum BasketballShotZone: String, Hashable, Sendable {
    case restrictedArea
    case paint
    case midrange
    case leftCornerThree
    case rightCornerThree
    case aboveBreakThree
    case backcourt
    case unknown

    var label: String? {
        switch self {
        case .restrictedArea:
            return "Restricted area"
        case .paint:
            return "Paint"
        case .midrange:
            return "Midrange"
        case .leftCornerThree:
            return "Left corner"
        case .rightCornerThree:
            return "Right corner"
        case .aboveBreakThree:
            return "Above break"
        case .backcourt:
            return "Backcourt"
        case .unknown:
            return nil
        }
    }
}

struct BasketballFreeThrowState: Hashable, Sendable {
    let attemptNumber: Int?
    let totalAttempts: Int?

    var metricText: String? {
        guard let attemptNumber, let totalAttempts, attemptNumber > 0, totalAttempts > 0 else {
            return nil
        }
        return "\(attemptNumber) of \(totalAttempts)"
    }
}

enum BasketballFieldConfidence: Int, Hashable, Sendable {
    case missing = 1
    case ambiguous = 2
    case derived = 3
    case verifiedDerived = 4
    case explicit = 5

    var canRenderAssertiveState: Bool {
        rawValue >= Self.verifiedDerived.rawValue
    }
}

private extension GameParticipantRole {
    var displayName: String {
        switch self {
        case .home:
            return "Home"
        case .away:
            return "Away"
        case .other(let value):
            return value
        }
    }
}
