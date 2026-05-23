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

struct ResumeBanner: View {
    let description: String
    let onResume: () -> Void
    let onJumpLatest: () -> Void
    let onStartOver: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bookmark.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(SportsTheme.Tone.newPlay.accent)

            Text(description)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SportsTheme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 0)

            Button {
                SportsFeedback.impact()
                onResume()
            } label: {
                Text("Resume")
            }
            .buttonStyle(.sportsControl(tone: .newPlay, filled: true, compact: true))

            Menu {
                Button {
                    SportsFeedback.impact()
                    onJumpLatest()
                } label: {
                    Label("Jump latest", systemImage: "arrow.down.to.line")
                }

                Button(role: .destructive) {
                    SportsFeedback.selection()
                    onStartOver()
                } label: {
                    Label("Start over", systemImage: "restart")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    .frame(width: 28, height: 28)
                    .background(SportsTheme.Colors.paperInset, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous))
            }
        }
        .sportsSurface(.streamControlBar, accent: SportsTheme.Tone.newPlay.accent)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DetailStickyNavigationBar: View {
    let title: String
    let endLabel: String
    let returnLabel: String?
    let onTop: () -> Void
    let onEnd: () -> Void
    let onReturn: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if let returnLabel {
                Button {
                    SportsFeedback.impact()
                    onReturn()
                } label: {
                    Text(returnLabel)
                        .lineLimit(1)
                }
                .buttonStyle(.sportsControl(tone: .neutral, filled: true, compact: true))
            } else {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 0)

                Button {
                    SportsFeedback.selection()
                    onTop()
                } label: {
                    Text("Top")
                }
                .buttonStyle(.sportsControl(tone: .neutral, filled: false, compact: true))
            }

            Spacer(minLength: 0)

            Button {
                SportsFeedback.selection()
                onEnd()
            } label: {
                Text(endLabel)
            }
            .buttonStyle(.sportsControl(tone: .neutral, filled: false, compact: true))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(SportsTheme.Colors.paper.opacity(0.96), in: Capsule())
        .overlay {
            Capsule().strokeBorder(SportsTheme.Colors.hairline.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

struct PlayByPlaySection: View {
    let game: Game
    let events: [GameEvent]
    let renderer: any SportRenderer
    let selectedMode: DetailStreamMode
    let expandedRawFeedKeys: Set<String>
    let onRawFeedExpansionChange: (String, Bool) -> Void

    var body: some View {
        CatchUpSection(title: selectedMode.sectionTitle, systemImage: "sparkles") {
            if events.isEmpty {
                UnavailableText("No play-by-play data yet.")
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if visibleEvents.isEmpty {
                        UnavailableText(selectedMode.emptyStateMessage)
                    } else {
                        ForEach(periodGroups) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                PeriodGroupHeader(label: group.label, accent: renderer.theme.accentColor)
                                ForEach(group.events) { event in
                                    let readIndex = readIndex(for: event)
                                    let presentation = eventPresentation(for: event, periodGroupLabel: group.label)
                                    let rawFeedKey = event.rawFeedExpansionKey(game: game)
                                    PlayRow(
                                        presentation: presentation,
                                        importance: event.visualImportance,
                                        rawFeedKey: rawFeedKey,
                                        isRawFeedExpanded: rawFeedKey.map { expandedRawFeedKeys.contains($0) } ?? false,
                                        onRawFeedExpansionChange: onRawFeedExpansionChange
                                    )
                                        .id(GameDetailScrollAnchor.event(event.detailAnchorID))
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
        }
    }

    private var visibleEvents: [GameEvent] {
        selectedMode.visibleDedupedEvents(dedupedEvents)
    }

    private var dedupedEvents: [GameEvent] {
        DetailStreamMode.dedupedEvents(from: events)
    }

    private var periodGroups: [GameEventPeriodGroup] {
        renderer.periodGroups(for: visibleEvents)
    }

    private func readIndex(for event: GameEvent) -> Int {
        dedupedEvents.firstIndex(of: event) ?? 0
    }

    private func eventPresentation(for event: GameEvent, periodGroupLabel: String) -> GameEventPresentation {
        renderer.eventPresentation(for: event, periodGroupLabel: periodGroupLabel)
    }
}

private struct PlayRow: View {
    let presentation: GameEventPresentation
    let importance: EventVisualImportance
    let rawFeedKey: String?
    let isRawFeedExpanded: Bool
    let onRawFeedExpansionChange: (String, Bool) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            EventMarker(importance: importance, accent: accentColor)
            VStack(alignment: .leading, spacing: importance == .low ? 4 : 6) {
                contextLine
                Text(presentation.headline)
                    .font(headlineFont)
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if importance != .low, let detail = presentation.detail?.nilIfBlank {
                    Text(detail)
                        .font(SportsTheme.Typography.momentDetail)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let detail = presentation.detail?.nilIfBlank {
                    Text(detail)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .lineLimit(2)
                }
                detailLine
                rawFeedDisclosure
            }
        }
        .padding(importance == .low ? 9 : 11)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                .stroke(SportsTheme.Stroke.accent(accentColor), lineWidth: importance == .low ? 0 : 0.75)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(presentation.accessibilityLabel ?? presentation.headline)
    }

    private var contextLine: some View {
        HStack(spacing: 5) {
            if !presentation.clockText.isEmpty {
                Text(presentation.clockText)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
            }
            if let team = presentation.teamAbbreviation?.nilIfBlank {
                Text(team)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(teamColor)
            }
            if let eventLabel = presentation.eventLabel?.nilIfBlank {
                Text(eventLabel)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(accentColor)
            }
            if importance != .low, !importance.title.isEmpty {
                Text(importance.title)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(accentColor)
            }
        }
    }

    @ViewBuilder
    private var detailLine: some View {
        if let scoringLabel = presentation.scoringLabel?.nilIfBlank {
            Text(scoringLabel)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Tone.scoring.accent)
        } else if let teamLabel = presentation.teamLabel?.nilIfBlank,
                  presentation.teamAbbreviation?.nilIfBlank == nil {
            Text(teamLabel)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(teamColor)
        }
        if importance != .low,
           let scoreLabel = presentation.scoreLabel?.nilIfBlank {
            Text(scoreLabel)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Tone.scoring.accent)
        } else {
            if let scoreLabel = presentation.scoreLabel?.nilIfBlank {
                Text(scoreLabel)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Tone.scoring.accent)
            }
        }
    }

    @ViewBuilder
    private var rawFeedDisclosure: some View {
        if let rawFeedKey,
           let rawFeedText = presentation.rawFeedText?.nilIfBlank {
            Button {
                SportsFeedback.selection()
                onRawFeedExpansionChange(rawFeedKey, !isRawFeedExpanded)
            } label: {
                Label("Feed details", systemImage: isRawFeedExpanded ? "chevron.up" : "chevron.down")
                    .font(SportsTheme.Typography.metadata)
            }
            .buttonStyle(.plain)
            .foregroundStyle(SportsTheme.Colors.secondaryInk)
            .padding(.top, 2)

            if isRawFeedExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rawFeedText)
                        .font(SportsTheme.Typography.rawFeedText)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    if let source = presentation.rawFeedSource?.nilIfBlank {
                        Text(source)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(SportsTheme.Colors.secondaryInk.opacity(0.75))
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SportsTheme.Colors.paper, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.row, style: .continuous))
            }
        }
    }

    private var headlineFont: Font {
        switch importance {
        case .critical:
            return .headline.weight(.bold)
        case .high:
            return .subheadline.weight(.bold)
        case .medium:
            return .subheadline.weight(.semibold)
        case .low:
            return .subheadline.weight(.semibold)
        }
    }

    private var cardBackground: Color {
        switch importance {
        case .critical:
            return accentColor.opacity(0.11)
        case .high, .medium:
            return SportsTheme.Surface.eventCard.background
        case .low:
            return SportsTheme.Colors.paper.opacity(0.72)
        }
    }

    private var accentColor: Color {
        switch importance {
        case .critical:
            return SportsTheme.Tone.critical.accent
        case .high:
            return SportsTheme.Tone.scoring.accent
        case .medium:
            return SportsTheme.Tone.newPlay.accent
        case .low:
            return SportsTheme.Tone.neutral.accent
        }
    }

    private var teamColor: Color {
        SportsTheme.Team.accent(for: presentation.teamAbbreviation, fallback: accentColor)
    }
}

private struct EventMarker: View {
    let importance: EventVisualImportance
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(accent)
                .frame(width: markerSize, height: markerSize)
            Rectangle()
                .fill(accent.opacity(importance == .low ? 0.16 : 0.28))
                .frame(width: importance == .critical ? 2 : 1)
        }
        .frame(width: 14)
    }

    private var markerSize: CGFloat {
        switch importance {
        case .critical: return 12
        case .high: return 10
        case .medium: return 8
        case .low: return 6
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
        CollapsibleCatchUpSection(title: "Player Stats", systemImage: "person.3", isExpanded: $isExpanded) {
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
        CollapsibleCatchUpSection(title: "Team Stats", systemImage: "chart.bar.xaxis", isExpanded: $isExpanded) {
            StatSectionList(sections: [renderer.statsPresentation(for: detail).teamSection])
        }
    }
}

struct BoxScoreSection: View {
    let game: Game
    let renderer: any SportRenderer
    @State private var scoreRevealed: Bool

    init(game: Game, renderer: any SportRenderer, scoreInitiallyRevealed: Bool = true) {
        self.game = game
        self.renderer = renderer
        _scoreRevealed = State(initialValue: scoreInitiallyRevealed)
    }

    var body: some View {
        let presentation = renderer.scoreboardPresentation(for: game)

        CatchUpSection(title: presentation.title, systemImage: presentation.systemImage) {
            if scoreRevealed {
                VStack(spacing: 12) {
                    ScoreboardCardHeader(presentation: presentation)
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
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "eye.slash")
                            .foregroundStyle(presentation.accentColor)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(presentation.revealTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SportsTheme.Colors.ink)
                            Text(presentation.revealDescription)
                                .font(.caption)
                                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        }
                    }

                    Button {
                        SportsFeedback.impact()
                        scoreRevealed = true
                    } label: {
                        Label(presentation.revealButtonTitle, systemImage: "eye")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.sportsControl(tone: .scoreboard))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .sportsSurface(.scoreboardCard, accent: presentation.accentColor)
            }
        }
    }
}
