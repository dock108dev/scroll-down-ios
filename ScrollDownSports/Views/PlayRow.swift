import SwiftUI

struct PlayRow: View {
    let presentation: GameEventPresentation
    let importance: EventVisualImportance
    let rawFeedKey: String?
    let isRawFeedExpanded: Bool
    let onRawFeedExpansionChange: (String, Bool) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            EventMarker(importance: importance, accent: teamColor)
            VStack(alignment: .leading, spacing: importance == .low ? 3 : 4) {
                if let leadIn = presentation.leadIn?.nilIfBlank {
                    Text(leadIn)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(presentation.headline)
                    .font(SportsTheme.Typography.momentHeadline)
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
                contextLine
                resultContextLine
                if presentation.situation != nil {
                    situationPanel
                }
                if importance != .low, let detail = visibleDetailText {
                    Text(detail)
                        .font(SportsTheme.Typography.momentDetail)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .lineSpacing(1)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let detail = visibleDetailText {
                    Text(detail)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .lineLimit(2)
                }
                detailLine
                rawFeedDisclosure
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                .stroke(SportsTheme.Stroke.subdued(), lineWidth: 0.75)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
        .accessibilityValue(rowAccessibilityValue)
        .accessibilityHint(presentation.accessibilityHint ?? "")
    }

    @ViewBuilder
    private var contextLine: some View {
        if !presentation.contextItems.isEmpty {
            HStack(spacing: 5) {
                ForEach(presentation.contextItems) { item in
                    contextItemView(item)
                }
                Spacer(minLength: 0)
            }
        } else if hasContextLine {
            HStack(spacing: 5) {
                if !presentation.clockText.isEmpty, shouldShowClockInContextLine {
                    if !AppEnvironment.isRunningUITests {
                        Text(presentation.clockText)
                            .font(SportsTheme.Typography.metadata)
                            .foregroundStyle(SportsTheme.Colors.ink)
                    }
                }
                if let team = presentation.teamAbbreviation?.nilIfBlank,
                   PlayRowContentFilter.shouldShowContextTeamBadge(
                    team,
                    situation: presentation.situation
                   ) {
                    teamBadge(team)
                }
                if let eventLabel = PlayRowContentFilter.visibleEventLabel(for: presentation) {
                    Text(eventLabel)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(accentColor)
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func contextItemView(_ item: PlayCardContextItemPresentation) -> some View {
        if item.kind == .clock, AppEnvironment.isRunningUITests {
            EmptyView()
        } else if item.kind == .teamBadge {
            teamBadge(item.text, teamAbbreviation: item.teamAbbreviation)
        } else {
            Text(item.text)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(color(for: item.tone, teamAbbreviation: item.teamAbbreviation))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }

    private var hasContextLine: Bool {
        !presentation.clockText.isEmpty && shouldShowClockInContextLine
            || presentation.teamAbbreviation?.nilIfBlank != nil
                && PlayRowContentFilter.shouldShowContextTeamBadge(
                    presentation.teamAbbreviation ?? "",
                    situation: presentation.situation
                )
            || PlayRowContentFilter.visibleEventLabel(for: presentation) != nil
    }

    private var shouldShowClockInContextLine: Bool {
        guard let situationPeriodText = presentation.situation?.periodText?.nilIfBlank else {
            return true
        }
        return PlayRowContentFilter.duplicatesMeaning(presentation.clockText, comparedWith: situationPeriodText) == false
    }

    private func teamBadge(_ team: String, teamAbbreviation: String? = nil) -> some View {
        let color = SportsTheme.Team.accent(for: teamAbbreviation ?? team, fallback: teamColor)
        return Text(team)
            .font(SportsTheme.Typography.statusPill)
            .foregroundStyle(color)
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: SportsTheme.Radius.badge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SportsTheme.Radius.badge, style: .continuous)
                    .stroke(color.opacity(0.22), lineWidth: SportsTheme.Stroke.standard)
            )
    }

    private var visibleDetailText: String? {
        if presentation.isNormalizedCard {
            return presentation.detail?.nilIfBlank
        }
        return PlayRowContentFilter.visibleDetailText(for: presentation)
    }

    @ViewBuilder
    private var resultContextLine: some View {
        if !presentation.resultItems.isEmpty {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    resultItemsContent
                }
                VStack(alignment: .leading, spacing: 2) {
                    resultItemsContent
                }
            }
        } else if let situation = presentation.situation,
           PlayRowContentFilter.hasResultContext(for: situation) {
            let resultContext = PlayRowContentFilter.visibleResultContext(for: situation)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    resultContextContent(resultContext)
                }
                VStack(alignment: .leading, spacing: 2) {
                    resultContextContent(resultContext)
                }
            }
        }
    }

    private var resultItemsContent: some View {
        ForEach(presentation.resultItems) { item in
            Text(item.text)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(color(for: item.tone, teamAbbreviation: presentation.teamAbbreviation))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }

    @ViewBuilder
    private func resultContextContent(_ resultContext: PlayRowContentFilter.ResultContext) -> some View {
        if let pressureLine = resultContext.pressureLine {
            Text(pressureLine)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(presentation.situation?.accent.tone.foreground ?? accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        if let contextLine = resultContext.contextLine {
            Text(contextLine)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }

    @ViewBuilder
    private var situationPanel: some View {
        if let situation = presentation.situation, !situation.isEmpty {
            SituationSummaryPanel(
                situation: situation,
                suppressedMetricTexts: PlayRowContentFilter.situationMetricSuppressionText(for: presentation)
            )
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var detailLine: some View {
        if let teamLabel = visibleTeamLabel {
            Text(teamLabel)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(teamColor)
        }
        if let scoreLabel = visibleScoreLabel {
            Text(scoreLabel)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.ink)
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
                Label(rawFeedTitle, systemImage: isRawFeedExpanded ? "chevron.up" : "chevron.down")
                    .font(SportsTheme.Typography.metadata)
            }
            .buttonStyle(.plain)
            .foregroundStyle(SportsTheme.Colors.secondaryInk)
            .padding(.top, presentation.situation == nil ? 1 : 0)
            .frame(minHeight: presentation.situation == nil ? 44 : 30, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityLabel(isRawFeedExpanded ? "Hide feed details" : "Show feed details")
            .accessibilityValue(isRawFeedExpanded ? "Expanded" : "Collapsed")

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
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SportsTheme.Colors.paper, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.row, style: .continuous))
            }
        }
    }

    private var cardBackground: Color {
        switch importance {
        case .critical:
            return SportsTheme.Colors.paperRaised
        case .high, .medium:
            return SportsTheme.Surface.eventCard.background
        case .low:
            return SportsTheme.Colors.paperRaised
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

    private var visibleTeamLabel: String? {
        if presentation.isNormalizedCard {
            return presentation.teamLabel?.nilIfBlank
        }
        return PlayRowContentFilter.visibleTeamLabel(for: presentation)
    }

    private var visibleScoreLabel: String? {
        if presentation.isNormalizedCard {
            return presentation.scoreLabel?.nilIfBlank ?? presentation.scoringLabel?.nilIfBlank
        }
        return PlayRowContentFilter.visibleScoreLabel(for: presentation)
    }

    private var rawFeedTitle: String {
        presentation.rawFeedDisclosureTitle?.nilIfBlank ?? "Feed details"
    }

    private func color(for tone: NormalizedPlayCardTone?, teamAbbreviation: String?) -> Color {
        switch tone {
        case .critical:
            return SportsTheme.Tone.critical.foreground
        case .scoring:
            return SportsTheme.Tone.scoring.foreground
        case .possession:
            return SportsTheme.Team.accent(for: teamAbbreviation ?? presentation.teamAbbreviation, fallback: SportsTheme.Tone.newPlay.accent)
        case .context:
            return SportsTheme.Tone.newPlay.foreground
        case .secondary:
            return SportsTheme.Colors.secondaryInk
        case .muted:
            return SportsTheme.Colors.secondaryInk.opacity(0.75)
        case .neutral, .none:
            return SportsTheme.Colors.ink
        }
    }

    private var rowAccessibilityLabel: String {
        presentation.accessibilityLabel ?? presentation.headline
    }

    private var rowAccessibilityValue: String {
        if let value = presentation.accessibilityValue?.nilIfBlank {
            return value
        }
        return PlayRowContentFilter.situationAccessibilityValue(for: presentation)
    }
}

private struct EventMarker: View {
    let importance: EventVisualImportance
    let accent: Color

    var body: some View {
        VStack(spacing: 3) {
            Circle()
                .fill(accent)
                .frame(width: markerSize, height: markerSize)
            Rectangle()
                .fill(accent.opacity(importance == .low ? 0.16 : 0.28))
                .frame(width: importance == .critical ? 2 : 1)
        }
        .frame(width: 10)
    }

    private var markerSize: CGFloat {
        switch importance {
        case .critical: return 10
        case .high: return 9
        case .medium: return 7
        case .low: return 6
        }
    }
}
