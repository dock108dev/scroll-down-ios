import Foundation

struct NonFieldPressureBoard: Hashable, Sendable {
    let title: String
    let setupText: String?
    let contextLine: String?
    let pressureLine: String?
    let sport: GameEventSituationSport
    let metrics: [PressureBoardSituationMetric]
    let priority: SituationCardPriority
    let densityKey: String?
    let tone: SportsTheme.Tone
    let dataConfidence: GameEventSituationDataConfidence
}

enum NonFieldPressureBoardBuilder {
    static func presentation(
        for event: GameEvent,
        board: NonFieldPressureBoard
    ) -> GameEventSituationPresentation {
        let association = association(for: event)
        return GameEventSituationPresentation(
            title: board.title,
            periodText: nil,
            setupText: board.setupText,
            contextLine: board.contextLine,
            pressureLine: board.pressureLine,
            sport: board.sport,
            layout: .pressureBoardFallback,
            ownership: association,
            diagram: .pressureBoardFallback(
                PressureBoardSituationDiagram(
                    associations: association.map { [$0] } ?? [],
                    metrics: board.metrics
                )
            ),
            accent: GameEventSituationAccent(
                ownership: association?.participantRole ?? event.teamOwnership,
                teamAbbreviation: association?.teamAbbreviation ?? event.teamAbbreviation,
                teamLabel: association?.teamLabel ?? event.presentation?.teamLabel,
                tone: board.tone
            ),
            dataConfidence: board.dataConfidence
        )
    }

    private static func association(for event: GameEvent) -> GameEventSituationOwnership? {
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
}

enum GolfPressureClassifier {
    static func board(for event: GameEvent) -> NonFieldPressureBoard? {
        let state = GolfPressureState(event: event)
        guard state.hasLeaderboardPressureSignal else { return nil }
        let priority = priority(for: event, state: state)
        guard priority != .routine else { return nil }

        let title = title(for: event, state: state)
        let metrics = metrics(for: event, state: state)
        guard !metrics.isEmpty || state.contextLine != nil else { return nil }

        return NonFieldPressureBoard(
            title: title,
            setupText: state.contextLine,
            contextLine: contextLine(for: state),
            pressureLine: pressureLine(for: event, state: state),
            sport: .golf,
            metrics: metrics,
            priority: priority,
            densityKey: densityKey(for: event, state: state),
            tone: tone(for: event, priority: priority),
            dataConfidence: .explicitGenericEventContext
        )
    }

    private static func title(for event: GameEvent, state: GolfPressureState) -> String {
        switch nonFieldNormalized(event.eventType) {
        case "lead_change", "takes_lead":
            return "Lead change"
        case "ties_lead":
            return "Tied at the top"
        case "within_one":
            return "One shot back"
        case "eagle":
            return "Eagle swing"
        case "birdie":
            return "Birdie pressure"
        case "bogey":
            return "Dropped shot"
        case "double_bogey":
            return "Major drop"
        case "par_save":
            return "Pressure save"
        case "cut_line", "near_cut_line", "makes_cut_position", "falls_below_cut":
            return "Cut-line pressure"
        default:
            return state.movement != nil ? "Leaderboard movement" : "Leaderboard pressure"
        }
    }

    private static func contextLine(for state: GolfPressureState) -> String? {
        [
            state.rank.map { "Rank \($0)" },
            state.scoreToPar.map { "To par \($0)" },
            state.strokesBack.map { "\($0) back" },
            state.movement
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: " · ")
            .nilIfBlank
    }

    private static func pressureLine(for event: GameEvent, state: GolfPressureState) -> String? {
        if event.importanceMetadata?.isLeadChange == true {
            return "Lead change"
        }
        if state.movement != nil {
            return nil
        }
        if state.strokesBack != nil {
            return "Leaderboard chase"
        }
        if event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
            return "Scoring swing"
        }
        if event.importanceMetadata?.isKeyMoment == true || event.isKeyMoment {
            return "Key tournament moment"
        }
        return "Tournament pressure"
    }

    private static func metrics(for event: GameEvent, state: GolfPressureState) -> [PressureBoardSituationMetric] {
        var metrics: [PressureBoardSituationMetric] = []
        appendMetric(label: "Hole", value: state.hole.map(String.init), emphasis: .primary, to: &metrics)
        appendMetric(label: "Rank", value: state.rank, emphasis: .pressure, to: &metrics)
        appendMetric(label: "To par", value: state.scoreToPar, emphasis: .pressure, to: &metrics)
        appendMetric(label: "Back", value: state.strokesBack, emphasis: .pressure, to: &metrics)
        appendMetric(
            label: "Play",
            value: EventLabelResolver.customerLabel(from: event.presentation?.eventTypeLabel)
                ?? EventLabelResolver.customerLabel(from: event.eventType),
            emphasis: .secondary,
            to: &metrics
        )
        return metrics
    }

    private static func priority(for event: GameEvent, state: GolfPressureState) -> SituationCardPriority {
        let eventType = nonFieldNormalized(event.eventType)
        if event.visualImportance == .critical {
            return .bigMoment
        }
        if ["lead_change", "takes_lead"].contains(eventType) {
            return .bigMoment
        }
        if ["ties_lead", "within_one", "double_bogey", "cut_line", "falls_below_cut"].contains(eventType) {
            return .keyMoment
        }
        if event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
            return .scoringSwing
        }
        if event.visualImportance == .high || event.importanceMetadata?.isKeyMoment == true || event.isKeyMoment {
            return .keyMoment
        }
        if state.hasMovement || event.visualImportance == .medium {
            return .notable
        }
        return .routine
    }

    private static func tone(for event: GameEvent, priority: SituationCardPriority) -> SportsTheme.Tone {
        if priority == .bigMoment || event.importanceMetadata?.isLeadChange == true {
            return .critical
        }
        if priority == .scoringSwing || event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
            return .scoring
        }
        return .neutral
    }

    private static func densityKey(for event: GameEvent, state: GolfPressureState) -> String? {
        [
            event.periodLabel,
            state.hole.map { "hole-\($0)" },
            state.rank.map { "rank-\($0)" },
            state.scoreToPar,
            state.movement,
            event.teamAbbreviation,
            event.eventType,
            event.presentation?.primaryLabel
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: "|")
            .nilIfBlank
    }
}

enum TennisPressureClassifier {
    static func board(for event: GameEvent) -> NonFieldPressureBoard? {
        let state = TennisPressureState(event: event)
        guard state.hasPointPressureSignal else { return nil }
        let priority = priority(for: event, state: state)
        guard priority != .routine else { return nil }

        let metrics = metrics(for: event, state: state)
        guard !metrics.isEmpty || state.contextLine != nil else { return nil }

        return NonFieldPressureBoard(
            title: title(for: event, state: state),
            setupText: state.contextLine,
            contextLine: contextLine(for: state),
            pressureLine: pressureLine(for: event, state: state),
            sport: .tennis,
            metrics: metrics,
            priority: priority,
            densityKey: densityKey(for: event, state: state),
            tone: tone(for: event, priority: priority),
            dataConfidence: .explicitGenericEventContext
        )
    }

    private static func title(for event: GameEvent, state: TennisPressureState) -> String {
        let eventType = nonFieldNormalized(event.eventType)
        if state.isMatchPoint || eventType == "match_point" {
            return "Match point"
        }
        if eventType == "match_point_saved" {
            return "Match point saved"
        }
        if eventType == "match_won" {
            return "Match decided"
        }
        if state.isSetPoint || eventType == "set_point" {
            return "Set point"
        }
        if eventType == "set_point_saved" {
            return "Set point saved"
        }
        if eventType == "set_won" {
            return "Set decided"
        }
        if state.isBreakPoint || eventType == "break_point" {
            return "Break point"
        }
        if eventType == "break_point_saved" {
            return "Break point saved"
        }
        if eventType == "break_point_converted" {
            return "Break converted"
        }
        if state.isDeuce || eventType == "deuce" {
            return "Deuce pressure"
        }
        if eventType == "advantage" || nonFieldNormalized(state.pointState) == "advantage" {
            return "Advantage point"
        }
        if state.isTiebreak || eventType == "tiebreak_swing" {
            return "Tiebreak pressure"
        }
        return "Point pressure"
    }

    private static func contextLine(for state: TennisPressureState) -> String? {
        [
            state.pointState,
            state.server.map { "Server \($0)" }
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: " · ")
            .nilIfBlank
    }

    private static func pressureLine(for event: GameEvent, state: TennisPressureState) -> String? {
        if state.isMatchPoint || nonFieldNormalized(event.eventType).contains("match_point") {
            return "Match point"
        }
        if state.isBreakPoint || nonFieldNormalized(event.eventType).contains("break_point") {
            return "Break chance"
        }
        if state.isSetPoint || nonFieldNormalized(event.eventType).contains("set_point") {
            return "Set point"
        }
        if state.isDeuce {
            return "Deuce"
        }
        if state.isTiebreak {
            return "Tiebreak pressure"
        }
        if state.server != nil {
            return "Service pressure"
        }
        return "Point pressure"
    }

    private static func metrics(for event: GameEvent, state: TennisPressureState) -> [PressureBoardSituationMetric] {
        var metrics: [PressureBoardSituationMetric] = []
        appendMetric(label: "Set", value: state.setText, emphasis: .primary, to: &metrics)
        appendMetric(label: "Game", value: state.gameText, emphasis: .primary, to: &metrics)
        appendMetric(label: "Point", value: state.pointState, emphasis: .pressure, to: &metrics)
        appendMetric(label: "Server", value: state.server, emphasis: .team, to: &metrics)
        appendMetric(
            label: "Play",
            value: EventLabelResolver.customerLabel(from: event.presentation?.eventTypeLabel)
                ?? EventLabelResolver.customerLabel(from: event.eventType),
            emphasis: .secondary,
            to: &metrics
        )
        return metrics
    }

    private static func priority(for event: GameEvent, state: TennisPressureState) -> SituationCardPriority {
        let eventType = nonFieldNormalized(event.eventType)
        if event.visualImportance == .critical {
            return .bigMoment
        }
        if state.isMatchPoint || ["match_point", "match_point_saved", "match_won", "break_point_converted", "set_won"].contains(eventType) {
            return .bigMoment
        }
        if state.isSetPoint || state.isBreakPoint || ["set_point", "break_point", "tiebreak_swing"].contains(eventType) {
            return .keyMoment
        }
        if ["set_point_saved", "break_point_saved"].contains(eventType) {
            return .scoringSwing
        }
        if event.visualImportance == .high || event.importanceMetadata?.isKeyMoment == true || event.isKeyMoment {
            return .keyMoment
        }
        if event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
            return .scoringSwing
        }
        if state.isDeuce || eventType == "advantage" {
            return event.visualImportance == .low ? .routine : .notable
        }
        if state.hasScoreState && event.visualImportance == .medium {
            return .notable
        }
        return .routine
    }

    private static func tone(for event: GameEvent, priority: SituationCardPriority) -> SportsTheme.Tone {
        if priority == .bigMoment {
            return .critical
        }
        if priority == .scoringSwing || event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil {
            return .scoring
        }
        return .neutral
    }

    private static func densityKey(for event: GameEvent, state: TennisPressureState) -> String? {
        [
            state.setText,
            state.gameText,
            state.pointState,
            state.server,
            event.periodLabel,
            event.clockLabel,
            event.teamAbbreviation,
            event.eventType,
            event.presentation?.primaryLabel
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: "|")
            .nilIfBlank
    }
}
