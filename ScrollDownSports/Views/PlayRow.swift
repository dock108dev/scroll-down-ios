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
                contextLine
                if presentation.situation != nil {
                    situationPanel
                }
                Text(presentation.headline)
                    .font(SportsTheme.Typography.momentHeadline)
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
                resultContextLine
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
                .stroke(SportsTheme.Stroke.accent(accentColor), lineWidth: 0.75)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
        .accessibilityValue(rowAccessibilityValue)
    }

    private var contextLine: some View {
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
            if let eventLabel = presentation.eventLabel?.nilIfBlank {
                Text(eventLabel)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(accentColor)
            }
            Spacer(minLength: 0)
        }
    }

    private var shouldShowClockInContextLine: Bool {
        guard let situationPeriodText = presentation.situation?.periodText?.nilIfBlank else {
            return true
        }
        let situationMeaning = PlayRowContentFilter.normalizedMeaning(situationPeriodText)
        let clockMeaning = PlayRowContentFilter.normalizedMeaning(presentation.clockText)
        guard !situationMeaning.isEmpty, !clockMeaning.isEmpty else {
            return true
        }
        return situationMeaning != clockMeaning
            && !situationMeaning.contains(clockMeaning)
            && !clockMeaning.contains(situationMeaning)
    }

    private func teamBadge(_ team: String) -> some View {
        Text(team)
            .font(SportsTheme.Typography.statusPill)
            .foregroundStyle(teamColor)
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(teamColor.opacity(0.12), in: RoundedRectangle(cornerRadius: SportsTheme.Radius.badge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SportsTheme.Radius.badge, style: .continuous)
                    .stroke(teamColor.opacity(0.22), lineWidth: SportsTheme.Stroke.standard)
            )
    }

    private var visibleDetailText: String? {
        PlayRowContentFilter.visibleDetailText(for: presentation)
    }

    @ViewBuilder
    private var resultContextLine: some View {
        if let situation = presentation.situation,
           PlayRowContentFilter.hasResultContext(for: situation) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    resultContextContent(for: situation)
                }
                VStack(alignment: .leading, spacing: 2) {
                    resultContextContent(for: situation)
                }
            }
        }
    }

    @ViewBuilder
    private func resultContextContent(for situation: GameEventSituationPresentation) -> some View {
        if let pressureLine = PlayRowContentFilter.resultContextText(situation.pressureLine) {
            Text(pressureLine)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(situation.accent.tone.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        if let contextLine = PlayRowContentFilter.resultContextText(situation.contextLine) {
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
            SituationSummaryPanel(situation: situation)
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var detailLine: some View {
        if let teamLabel = presentation.teamLabel?.nilIfBlank,
                  presentation.teamAbbreviation?.nilIfBlank == nil {
            Text(teamLabel)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(teamColor)
        }
        if let scoreLabel = presentation.scoreLabel?.nilIfBlank {
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
                Label("Feed details", systemImage: isRawFeedExpanded ? "chevron.up" : "chevron.down")
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

    private var rowAccessibilityLabel: String {
        presentation.accessibilityLabel ?? presentation.headline
    }

    private var rowAccessibilityValue: String {
        PlayRowContentFilter.situationAccessibilityValue(for: presentation)
    }
}

struct PlayRowContentFilter {
    static func visibleDetailText(for presentation: GameEventPresentation) -> String? {
        guard let detail = presentation.detail?.nilIfBlank,
              let situation = presentation.situation else {
            return presentation.detail?.nilIfBlank
        }
        let existingText = [
            presentation.headline,
            presentation.rawFeedText,
            situation.setupText,
            situation.contextLine,
            situation.pressureLine
        ].compactMap { $0?.nilIfBlank }

        guard existingText.contains(where: { duplicatesMeaning(detail, comparedWith: $0) }) == false,
              isPlayerOnlyRepeat(detail, headline: presentation.headline) == false else {
            return nil
        }
        return detail
    }

    static func shouldShowContextTeamBadge(
        _ team: String,
        situation: GameEventSituationPresentation?
    ) -> Bool {
        guard let team = team.nilIfBlank,
              let situation else {
            return team.nilIfBlank != nil
        }
        let matchingSituationLabels = [
            situation.ownership?.teamAbbreviation,
            situation.ownership?.teamLabel,
            situation.accent.teamAbbreviation,
            situation.accent.teamLabel
        ].compactMap { $0?.nilIfBlank }
        return matchingSituationLabels.contains { duplicatesMeaning(team, comparedWith: $0) } == false
    }

    static func situationAccessibilityValue(for presentation: GameEventPresentation) -> String {
        guard let supplement = presentation.situationAccessibilityText?.nilIfBlank else {
            return ""
        }
        let existingText = [
            presentation.accessibilityLabel,
            presentation.headline,
            presentation.detail,
            presentation.clockText,
            presentation.eventLabel,
            presentation.teamAbbreviation,
            presentation.teamLabel,
            presentation.scoringLabel,
            presentation.scoreLabel
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: " ")
        return duplicatesMeaning(supplement, comparedWith: existingText) ? "" : supplement
    }

    static func hasResultContext(for situation: GameEventSituationPresentation) -> Bool {
        resultContextText(situation.pressureLine) != nil
            || resultContextText(situation.contextLine) != nil
    }

    static func resultContextText(_ text: String?) -> String? {
        guard let text = text?.nilIfBlank,
              isResultSensitiveSituationText(text) else {
            return nil
        }
        return text
    }

    static func prePlaySituationText(_ text: String?) -> String? {
        guard let text = text?.nilIfBlank,
              !isResultSensitiveSituationText(text) else {
            return nil
        }
        return text
    }

    static func duplicatesMeaning(_ candidate: String, comparedWith existing: String) -> Bool {
        let normalizedCandidate = normalizedMeaning(candidate)
        let normalizedExisting = normalizedMeaning(existing)
        guard !normalizedCandidate.isEmpty, !normalizedExisting.isEmpty else {
            return false
        }
        if normalizedCandidate == normalizedExisting {
            return true
        }
        let minimumContainedLength = 24
        return normalizedCandidate.count >= minimumContainedLength && normalizedExisting.contains(normalizedCandidate)
            || normalizedExisting.count >= minimumContainedLength && normalizedCandidate.contains(normalizedExisting)
    }

    static func normalizedMeaning(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func isPlayerOnlyRepeat(_ detail: String, headline: String) -> Bool {
        let detailTokens = meaningfulTokens(in: detail)
        guard detailTokens.count >= 2,
              detailTokens.count <= 4 else {
            return false
        }
        let headlineTokens = Set(meaningfulTokens(in: headline))
        return detailTokens.allSatisfy { headlineTokens.contains($0) }
    }

    private static func isResultSensitiveSituationText(_ text: String) -> Bool {
        let normalized = normalizedMeaning(text)
        let metadataKey = normalizedSituationMetadataKey(text)
        if text.contains("->") {
            return true
        }
        if normalized.contains(" to up ")
            || normalized.contains(" to tied")
            || normalized.contains(" to down ")
            || containsEmbeddedDirectionalMovement(normalized) {
            return true
        }
        if normalized.hasPrefix("up ")
            || normalized.hasPrefix("down ") {
            return false
        }
        return metadataKey.contains("lead_change")
            || metadataKey.contains("tying_play")
            || metadataKey.contains("scoring_play")
            || metadataKey.contains("scoring_swing")
            || metadataKey.contains("power_play_finish")
            || metadataKey.contains("finish")
            || metadataKey.contains("go_ahead")
            || metadataKey.contains("cuts_deficit")
            || metadataKey.contains("extends_lead")
    }

    private static func containsEmbeddedDirectionalMovement(_ normalized: String) -> Bool {
        let tokens = normalized.split(separator: " ").map(String.init)
        guard tokens.count >= 3 else { return false }
        for index in 1..<(tokens.count - 1) where (tokens[index] == "up" || tokens[index] == "down") {
            if Int(tokens[index + 1]) != nil {
                return true
            }
        }
        return false
    }

    private static func meaningfulTokens(in text: String) -> [String] {
        normalizedMeaning(text)
            .split(separator: " ")
            .map(String.init)
            .filter { token in
                token.count > 1 && stopWords.contains(token) == false
            }
    }

    private static let stopWords: Set<String> = [
        "a", "an", "and", "at", "by", "for", "from", "in", "into", "of", "on", "out", "the", "to", "with"
    ]
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
