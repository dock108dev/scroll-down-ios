import Foundation

struct BaseballSituationInputs {
    let baseState: BaseballBaseState?
    let battingOwnership: GameEventSituationOwnership?
    let outs: Int?
    let periodText: String?
    let fallbackPeriodText: String?
    let contextLine: String?
    let pressureLine: String?
    let count: String?
    let confidenceDecision: SituationBlockDecision
}

enum BaseballSituationPeriodTextStyle {
    case compact
    case expanded
}
