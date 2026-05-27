import Foundation

extension BaseballRenderer {
    var explicitContainerKeys: [String] {
        ["prePitch", "pre_pitch", "prepitch", "before", "situationBefore", "situation_before", "stateBefore", "state_before"]
    }

    var explicitBaseStateKeys: [String] {
        ["prePitchBaseState", "baseStateBefore", "basesBefore"]
    }

    var genericBaseStateKeys: [String] {
        ["baseState", "base_state", "baseSituation", "base_situation", "runners", "runnerState", "runner_state", "baseOccupancy", "base_occupancy"]
    }

    var explicitBaseArrayKeys: [String] {
        ["prePitchBases", "prePitchOccupiedBases", "occupiedBasesBefore", "basesOccupiedBefore", "runnersOnBefore"]
    }

    var genericBaseArrayKeys: [String] {
        ["occupiedBases", "basesOccupied", "runnersOn", "occupied_bases", "bases_occupied", "runners_on"]
    }

    var explicitBaseMaskKeys: [String] {
        ["prePitchBaseMask", "baseMaskBefore", "basesCodeBefore", "baseOccupancyMaskBefore"]
    }

    var genericBaseMaskKeys: [String] {
        ["baseMask", "basesMask", "baseOccupancyMask", "basesCode"]
    }

    var explicitOutsKeys: [String] {
        ["outsBefore", "outs_before", "outsBeforePlay", "outs_before_play", "prePitchOuts", "pre_pitch_outs"]
    }

    var genericOutsKeys: [String] {
        ["outs", "outCount", "out_count"]
    }

    var explicitCountTextKeys: [String] {
        ["countBefore", "count_before", "prePitchCount", "pre_pitch_count"]
    }

    var explicitCountObjectKeys: [String] {
        ["countBefore", "prePitchCount"]
    }

    var genericCountTextKeys: [String] {
        ["count", "pitchCount", "pitch_count"]
    }

    var explicitBallCountKeys: [String] {
        ["ballsBefore", "balls_before", "prePitchBalls", "pre_pitch_balls"]
    }

    var genericBallCountKeys: [String] {
        ["balls", "ballCount", "ball_count"]
    }

    var explicitStrikeCountKeys: [String] {
        ["strikesBefore", "strikes_before", "prePitchStrikes", "pre_pitch_strikes"]
    }

    var genericStrikeCountKeys: [String] {
        ["strikes", "strikeCount", "strike_count"]
    }

    var explicitInningKeys: [String] {
        ["inning", "inningNumber", "inningHalf", "halfInning", "topBottom", "inningState", "periodLabel", "inningLabel"]
    }

    var explicitBattingTeamKeys: [String] {
        ["battingTeamAbbreviation", "battingTeamId", "battingTeamRole", "battingSide", "offenseTeamAbbreviation", "offenseTeamId", "offenseTeamRole"]
    }
}

extension JSONValue {
    var textValue: String? {
        switch self {
        case .string(let value):
            return value
        case .number(let value) where value.rounded() == value:
            return String(Int(value))
        case .number(let value):
            return String(value)
        default:
            return nil
        }
    }
}

struct BaseballPrePitchState: Hashable, Sendable {
    let baseState: BaseballBaseState?
    let outs: Int?
    let inning: Int?
    let inningHalf: BaseballInningHalf?
    let count: BaseballPitchCount?
    let battingTeam: BaseballBattingTeam?
    let sourceConfidence: BaseballPrePitchSourceConfidence
}

struct BaseballBaseState: Hashable, Sendable {
    let occupiedBases: Set<BaseballBase>
    let label: String
}

struct BaseballPitchCount: Hashable, Sendable {
    let balls: Int
    let strikes: Int

    init?(balls: Int, strikes: Int) {
        guard (0...3).contains(balls), (0...2).contains(strikes) else { return nil }
        self.balls = balls
        self.strikes = strikes
    }

    var label: String {
        "\(balls)-\(strikes)"
    }
}

struct BaseballBattingTeam: Hashable, Sendable {
    let id: String?
    let abbreviation: String?
    let side: GameParticipantRole?

    init(id: String? = nil, abbreviation: String? = nil, side: GameParticipantRole? = nil) {
        self.id = id
        self.abbreviation = abbreviation
        self.side = side
    }
}

struct BaseballInningState: Hashable, Sendable {
    let inning: Int?
    let inningHalf: BaseballInningHalf?

    init(inning: Int? = nil, inningHalf: BaseballInningHalf? = nil) {
        self.inning = inning
        self.inningHalf = inningHalf
    }
}

enum BaseballInningHalf: Hashable, Sendable {
    case top
    case bottom

    var displayName: String {
        switch self {
        case .top:
            return "Top"
        case .bottom:
            return "Bottom"
        }
    }
}

enum BaseballPrePitchSourceConfidence: Hashable, Sendable {
    case explicitPrePitch
    case explicitGeneric
    case derivedFromPeriod
    case ambiguousResultMetadata
    case missing

    var allowsSportDiagram: Bool {
        switch self {
        case .explicitPrePitch, .explicitGeneric:
            return true
        case .derivedFromPeriod, .ambiguousResultMetadata, .missing:
            return false
        }
    }
}
