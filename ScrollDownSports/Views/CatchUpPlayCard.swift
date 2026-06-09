import SwiftUI

struct CatchUpPlayCard: View {
    let event: GameEvent
    let presentation: GameEventPresentation
    let selectedMode: DetailStreamMode
    let rawFeedKey: String?
    let isRawFeedExpanded: Bool
    let onRawFeedExpansionChange: (String, Bool) -> Void

    var body: some View {
        switch cardPath {
        case .importantNarrative(let narrative):
            ImportantNarrativePlayCard(
                event: event,
                presentation: presentation,
                narrative: narrative
            )
        case .standardPBP:
            StandardPBPPlayCard(
                presentation: presentation,
                event: event,
                rawFeedKey: rawFeedKey,
                isRawFeedExpanded: isRawFeedExpanded,
                onRawFeedExpansionChange: onRawFeedExpansionChange
            )
        case .fullPBP:
            FullPBPPlayCard(
                presentation: presentation,
                event: event,
                rawFeedKey: rawFeedKey,
                isRawFeedExpanded: isRawFeedExpanded,
                onRawFeedExpansionChange: onRawFeedExpansionChange
            )
        case .unavailable:
            PlayUnavailableCard(presentation: presentation, event: event)
        }
    }

    private var cardPath: CatchUpPlayCardPath {
        guard let card = event.normalizedCard else {
            return selectedMode == .full ? .fullPBP : .standardPBP
        }

        switch selectedMode {
        case .key:
            if card.renderType == .importantNarrative {
                guard let narrative = card.narrative else { return .unavailable }
                return .importantNarrative(narrative)
            }
            return .standardPBP
        case .flow:
            return .standardPBP
        case .full:
            return .fullPBP
        }
    }
}

private enum CatchUpPlayCardPath {
    case importantNarrative(NormalizedPlayCardNarrative)
    case standardPBP
    case fullPBP
    case unavailable
}

struct ImportantNarrativePlayCard: View {
    let event: GameEvent
    let presentation: GameEventPresentation
    let narrative: NormalizedPlayCardNarrative

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            EventMarker(importance: event.cardVisualImportance, accent: teamColor)
            VStack(alignment: .leading, spacing: 6) {
                metaRow
                Text(narrative.setupLine)
                    .font(SportsTheme.Typography.momentDetail.weight(.semibold))
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(narrative.playLine)
                    .font(SportsTheme.Typography.momentDetail)
                    .foregroundStyle(SportsTheme.Colors.ink.opacity(0.88))
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
                Text(narrative.updateLine)
                    .font(SportsTheme.Typography.metadata.weight(.bold))
                    .foregroundStyle(teamColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(SportsTheme.Surface.eventCard.background, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                .stroke(SportsTheme.Stroke.subdued(), lineWidth: 0.75)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(presentation.accessibilityLabel ?? narrative.playLine)
    }

    private var metaRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                Text(metaText)
                    .font(SportsTheme.Typography.metadata.weight(.bold))
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let team = visibleTeamBadgeText {
                    teamBadge(team)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(metaText)
                    .font(SportsTheme.Typography.metadata.weight(.bold))
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                if let team = visibleTeamBadgeText {
                    teamBadge(team)
                }
            }
        }
    }

    private var metaText: String {
        event.normalizedCard?.leadIn?.text.nilIfBlank
            ?? presentation.leadIn?.nilIfBlank
            ?? event.clockText
    }

    private var visibleTeamBadgeText: String? {
        guard let team = presentation.teamAbbreviation?.nilIfBlank,
              PlayRowContentFilter.shouldShowContextTeamBadge(team, leadIn: metaText) else {
            return nil
        }
        return team
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

    private var teamColor: Color {
        SportsTheme.Team.accent(
            for: presentation.teamAbbreviation,
            fallback: event.cardVisualImportance.accentColor
        )
    }
}

struct StandardPBPPlayCard: View {
    let presentation: GameEventPresentation
    let event: GameEvent
    let rawFeedKey: String?
    let isRawFeedExpanded: Bool
    let onRawFeedExpansionChange: (String, Bool) -> Void

    var body: some View {
        PlayRow(
            presentation: presentation.pbpCardPresentation,
            importance: event.cardVisualImportance,
            displayDensity: event.displayDensity(for: .flow),
            rawFeedKey: rawFeedKey,
            isRawFeedExpanded: isRawFeedExpanded,
            onRawFeedExpansionChange: onRawFeedExpansionChange
        )
    }
}

struct FullPBPPlayCard: View {
    let presentation: GameEventPresentation
    let event: GameEvent
    let rawFeedKey: String?
    let isRawFeedExpanded: Bool
    let onRawFeedExpansionChange: (String, Bool) -> Void

    var body: some View {
        PlayRow(
            presentation: presentation.pbpCardPresentation,
            importance: event.cardVisualImportance,
            displayDensity: event.displayDensity(for: .full),
            rawFeedKey: rawFeedKey,
            isRawFeedExpanded: isRawFeedExpanded,
            onRawFeedExpansionChange: onRawFeedExpansionChange
        )
    }
}

struct PlayUnavailableCard: View {
    let presentation: GameEventPresentation
    let event: GameEvent

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            EventMarker(importance: .medium, accent: SportsTheme.Tone.neutral.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.clockText)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                Text("Play details unavailable")
                    .font(SportsTheme.Typography.momentHeadline)
                    .foregroundStyle(SportsTheme.Colors.ink)
                Text(presentation.detail?.nilIfBlank ?? "Game Data Not Found")
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.ink.opacity(0.82))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(SportsTheme.Colors.paperRaised, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                .stroke(SportsTheme.Stroke.subdued(), lineWidth: 0.75)
        )
    }
}

private extension EventVisualImportance {
    var accentColor: Color {
        switch self {
        case .critical:
            SportsTheme.Tone.critical.accent
        case .high:
            SportsTheme.Tone.scoring.accent
        case .medium:
            SportsTheme.Tone.newPlay.accent
        case .low:
            SportsTheme.Tone.neutral.accent
        }
    }
}

private extension GameEventPresentation {
    var pbpCardPresentation: GameEventPresentation {
        guard isNormalizedCard else { return self }
        var copy = self
        copy.contextItems = PlayRowContentFilter.compactNormalizedContextItems(for: self)
        copy.resultItems = []
        copy.situation = nil
        copy.situationAccessibilityText = nil
        return copy
    }
}
