import SwiftUI

enum GameDetailScrollAnchor: Hashable {
    case top
    case latest
    case event(String)
    case scoreboard
}

struct DetailEventVisibilityFrame: Equatable {
    let anchorID: String
    let readIndex: Int
    let sequence: Int
    let eventID: String?
    let label: String
    let frame: CGRect
}

struct DetailEventVisibilityPreferenceKey: PreferenceKey {
    static let defaultValue: [DetailEventVisibilityFrame] = []

    static func reduce(value: inout [DetailEventVisibilityFrame], nextValue: () -> [DetailEventVisibilityFrame]) {
        value.append(contentsOf: nextValue())
    }
}

struct DetailScoreboardVisibilityPreferenceKey: PreferenceKey {
    static let defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

struct DetailBottomAffordanceHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct DetailLatestAnchorPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct DetailTopChromePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

struct DetailResumeState {
    let target: GameEvent
    let description: String
}

struct PlayByPlaySection: View {
    let game: Game
    let events: [GameEvent]
    let renderer: any SportRenderer
    let selectedMode: DetailStreamMode
    let scoreSpoilerPolicy: ScoreSpoilerPolicy
    let expandedRawFeedKeys: Set<String>
    let onRawFeedExpansionChange: (String, Bool) -> Void
    @Environment(\.sportsLayoutMetrics) private var layout

    init(
        game: Game,
        events: [GameEvent],
        renderer: any SportRenderer,
        selectedMode: DetailStreamMode,
        scoreSpoilerPolicy: ScoreSpoilerPolicy = .revealed,
        expandedRawFeedKeys: Set<String>,
        onRawFeedExpansionChange: @escaping (String, Bool) -> Void
    ) {
        self.game = game
        self.events = events
        self.renderer = renderer
        self.selectedMode = selectedMode
        self.scoreSpoilerPolicy = scoreSpoilerPolicy
        self.expandedRawFeedKeys = expandedRawFeedKeys
        self.onRawFeedExpansionChange = onRawFeedExpansionChange
    }

    var body: some View {
        CatchUpSection(title: selectedMode.sectionTitle, systemImage: "sparkles") {
            switch contentState {
            case .rawEmpty:
                UnavailableText("No play-by-play data yet.")
            case .modeEmpty(let mode):
                UnavailableText(mode.emptyStateMessage)
            case .populated(let rowVisibleEvents, let groups):
                VStack(alignment: .leading, spacing: streamGroupSpacing) {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: eventRowSpacing) {
                            PeriodGroupHeader(label: group.label, accent: renderer.theme.accentColor)
                            ForEach(group.events) { event in
                                let readIndex = readIndex(for: event)
                                let presentation = eventPresentation(
                                    for: event,
                                    periodGroupLabel: group.label,
                                    visibleEvents: rowVisibleEvents
                                )
                                let rawFeedKey = event.rawFeedExpansionKey(game: game)
                                PlayRow(
                                    presentation: presentation,
                                    importance: event.visualImportance,
                                    rawFeedKey: rawFeedKey,
                                    isRawFeedExpanded: rawFeedKey.map { expandedRawFeedKeys.contains($0) } ?? false,
                                    onRawFeedExpansionChange: onRawFeedExpansionChange
                                )
                                    .id(GameDetailScrollAnchor.event(event.detailAnchorID))
                                    .accessibilityIdentifier("detail.event.\(event.normalizedSourceEventID ?? event.id)")
                                    .background {
                                        GeometryReader { geometry in
                                            Color.clear.preference(
                                                key: DetailEventVisibilityPreferenceKey.self,
                                                value: [
                                                    DetailEventVisibilityFrame(
                                                        anchorID: event.detailAnchorID,
                                                        readIndex: readIndex,
                                                        sequence: event.sequence,
                                                        eventID: event.normalizedSourceEventID ?? event.id,
                                                        label: presentation.clockText,
                                                        frame: geometry.frame(in: .named("game-detail-scroll"))
                                                    )
                                                ]
                                            )
                                        }
                                    }
                            }
                        }
                    }
                    StreamTerminalMarker(game: game)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("detail.playByPlay")
    }

    private var contentState: PlayByPlayContentState {
        if events.isEmpty {
            return .rawEmpty
        }
        let rowVisibleEvents = visibleEvents
        if rowVisibleEvents.isEmpty {
            return .modeEmpty(selectedMode)
        }
        return .populated(rowVisibleEvents, periodGroups(for: rowVisibleEvents))
    }

    private var streamGroupSpacing: CGFloat {
        layout.sectionSpacing
    }

    private var eventRowSpacing: CGFloat {
        max(7, layout.rowSpacing - 1)
    }

    private enum PlayByPlayContentState {
        case rawEmpty
        case modeEmpty(DetailStreamMode)
        case populated([GameEvent], [GameEventPeriodGroup])
    }

    private var visibleEvents: [GameEvent] {
        selectedMode.visibleDedupedEvents(dedupedEvents)
    }

    private var dedupedEvents: [GameEvent] {
        DetailStreamMode.dedupedEvents(from: events)
    }

    private func periodGroups(for visibleEvents: [GameEvent]) -> [GameEventPeriodGroup] {
        renderer.periodGroups(for: visibleEvents)
    }

    private func readIndex(for event: GameEvent) -> Int {
        dedupedEvents.firstIndex(of: event) ?? 0
    }

    private func eventPresentation(
        for event: GameEvent,
        periodGroupLabel: String,
        visibleEvents: [GameEvent]
    ) -> GameEventPresentation {
        guard let visibleEventIndex = visibleEvents.firstIndex(of: event) else {
            return renderer.eventPresentation(for: event, periodGroupLabel: periodGroupLabel)
        }
        return renderer.eventPresentation(
            for: event,
            periodGroupLabel: periodGroupLabel,
            context: SportRendererSituationContext(
                game: game,
                selectedMode: selectedMode,
                visibleEvents: visibleEvents,
                eventIndex: visibleEventIndex,
                scoreSpoilerPolicy: scoreSpoilerPolicy
            )
        )
    }
}

struct PlayerStatsSection: View {
    let detail: GameDetail
    let renderer: any SportRenderer
    @Binding private var isExpanded: Bool

    init(detail: GameDetail, renderer: any SportRenderer, isExpanded: Binding<Bool> = .constant(false)) {
        self.detail = detail
        self.renderer = renderer
        _isExpanded = isExpanded
    }

    var body: some View {
        CollapsibleCatchUpSection(
            title: "Player Stats",
            systemImage: "person.3",
            collapsedSummary: "Top performers and full player tables are available.",
            expandedSummary: "Player payoff stats stay with the recap below the feed.",
            expandButtonTitle: "Show player stats",
            collapseButtonTitle: "Hide player stats",
            isExpanded: $isExpanded
        ) {
            StatSectionList(sections: renderer.statsPresentation(for: detail).playerSections)
        }
    }
}

struct TeamStatsSection: View {
    let detail: GameDetail
    let renderer: any SportRenderer
    @Binding private var isExpanded: Bool

    init(detail: GameDetail, renderer: any SportRenderer, isExpanded: Binding<Bool> = .constant(false)) {
        self.detail = detail
        self.renderer = renderer
        _isExpanded = isExpanded
    }

    var body: some View {
        CollapsibleCatchUpSection(
            title: "Team Stats",
            systemImage: "chart.bar.xaxis",
            collapsedSummary: "Team comparison and totals are available.",
            expandedSummary: "Team payoff stats stay with the recap below the feed.",
            expandButtonTitle: "Show team stats",
            collapseButtonTitle: "Hide team stats",
            isExpanded: $isExpanded
        ) {
            StatSectionList(sections: [renderer.statsPresentation(for: detail).teamSection])
        }
    }
}

struct BoxScoreSection: View {
    let game: Game
    let renderer: any SportRenderer
    @Binding private var externalScoreRevealed: Bool
    @State private var localScoreRevealed: Bool
    private let usesExternalScoreRevealed: Bool

    init(game: Game, renderer: any SportRenderer, scoreInitiallyRevealed: Bool = true) {
        self.game = game
        self.renderer = renderer
        _externalScoreRevealed = .constant(scoreInitiallyRevealed)
        _localScoreRevealed = State(initialValue: scoreInitiallyRevealed)
        usesExternalScoreRevealed = false
    }

    init(game: Game, renderer: any SportRenderer, scoreRevealed: Binding<Bool>) {
        self.game = game
        self.renderer = renderer
        _externalScoreRevealed = scoreRevealed
        _localScoreRevealed = State(initialValue: scoreRevealed.wrappedValue)
        usesExternalScoreRevealed = true
    }

    var body: some View {
        let presentation = renderer.scoreboardPresentation(for: game)

        CatchUpSection(title: presentation.title, systemImage: presentation.systemImage) {
            if isScoreRevealed {
                VStack(spacing: 9) {
                    BoxScorePayoffHeader(
                        title: "Box score payoff",
                        subtitle: "Final scoring context for the feed you just read.",
                        accent: presentation.accentColor
                    )
                    ScoreboardCardHeader(presentation: presentation)
                    if let finalScoreText {
                        Text(finalScoreText)
                            .font(SportsTheme.Typography.metadata.weight(.semibold))
                            .foregroundStyle(SportsTheme.Colors.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("detail.boxScore.finalScore")
                    }
                    ScoreboardContent(presentation: presentation)

                    if let gameStateText = presentation.stateText {
                        Text(gameStateText)
                            .font(SportsTheme.Typography.metadata)
                            .foregroundStyle(presentation.stateColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .sportsSurface(.scoreboardCard, accent: presentation.accentColor)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "eye.slash")
                            .foregroundStyle(presentation.accentColor)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(presentation.revealTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SportsTheme.Colors.ink)
                            Text(presentation.revealDescription)
                                .font(SportsTheme.Typography.momentDetail)
                                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                            Text("Scores stay hidden until you choose to reveal them. Revealing shows the box score payoff and score-aware feed context for this visit.")
                                .font(SportsTheme.Typography.metadata)
                                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Button {
                        SportsFeedback.impact()
                        revealScore()
                    } label: {
                        Label(presentation.revealButtonTitle, systemImage: "eye")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.sportsControl(tone: .scoreboard))
                    .accessibilityLabel("Reveal box score")
                    .accessibilityHint("Shows the score and scoreboard payoff section.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .sportsSurface(.scoreboardCard, accent: presentation.accentColor)
            }
        }
    }

    private var isScoreRevealed: Bool {
        game.status.isFinal || (usesExternalScoreRevealed ? externalScoreRevealed : localScoreRevealed)
    }

    private func revealScore() {
        if usesExternalScoreRevealed {
            externalScoreRevealed = true
        } else {
            localScoreRevealed = true
        }
    }

    private var finalScoreText: String? {
        guard
            game.status.isFinal,
            let away = game.awayParticipant,
            let home = game.homeParticipant,
            let awayScore = game.scoreState.away,
            let homeScore = game.scoreState.home
        else {
            return nil
        }
        return "\(away.name) \(awayScore), \(home.name) \(homeScore)"
    }
}

private struct BoxScorePayoffHeader: View {
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.seal")
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(accent)
                Text(subtitle)
                    .font(SportsTheme.Typography.momentDetail)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
