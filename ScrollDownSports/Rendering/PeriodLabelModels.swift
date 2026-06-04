import Foundation

struct PeriodLabelInput: Equatable {
    let sport: Sport
    let leagueCode: String
    let periodOrdinal: Int?
    let periodLabel: String?
    let clockLabel: String?
    let presentationTimeLabel: String?
}

struct PeriodLabelOutput: Equatable {
    let groupLabel: String?
    let groupKey: String
    let rowClockText: String
    let combinedText: String?
    let situationText: String?
    let resumeText: String?
}
