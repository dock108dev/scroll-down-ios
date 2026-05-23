import SwiftUI

struct GameRowView: View {
    let item: HomeGameItem

    var body: some View {
        let presentation = renderer.gameCardPresentation(for: game)
        let cardState = HomeGameCardState(item: item)
        let railColor = SportsTheme.Team.accent(
            for: game.homeParticipant?.abbreviation ?? game.awayParticipant?.abbreviation,
            fallback: presentation.accentColor
        )

        HStack(alignment: .top, spacing: 10) {
            SportsTeamRail(color: railColor)

            VStack(alignment: .leading, spacing: 8) {
                HomeCardMetadataRow(
                    state: cardState,
                    presentation: presentation
                )
                .padding(.trailing, 38)

                VStack(alignment: .leading, spacing: 3) {
                    if let away = game.awayParticipant {
                        TeamLine(
                            abbreviation: away.abbreviation,
                            name: away.name,
                            scoreText: cardState.showsScoreRows ? cardState.scoreRows.first { $0.id == away.id }?.scoreText : nil
                        )
                    }
                    if let home = game.homeParticipant {
                        TeamLine(
                            abbreviation: home.abbreviation,
                            name: home.name,
                            scoreText: cardState.showsScoreRows ? cardState.scoreRows.first { $0.id == home.id }?.scoreText : nil
                        )
                    }
                }

                HomeCardContext(state: cardState)
            }
        }
        .padding(12)
        .background(
            SportsTheme.Surface.gameCard.background,
            in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                .stroke(SportsTheme.Stroke.accent(accent(for: cardState, fallback: presentation.accentColor)), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous))
        .accessibilityLabel(accessibilityLabel(presentation: presentation, state: cardState))
    }

    private var game: Game {
        item.game
    }

    private var renderer: any SportRenderer {
        SportRendererRegistry.renderer(for: game)
    }

    private func accent(for state: HomeGameCardState, fallback: Color) -> Color {
        switch state.phase {
        case .live:
            return SportsTheme.Tone.live.accent
        case .final:
            return SportsTheme.Tone.final.accent
        case .scheduled:
            return fallback
        case .other:
            return SportsTheme.Tone.neutral.accent
        }
    }

    private func accessibilityLabel(presentation: GameCardPresentation, state: HomeGameCardState) -> String {
        [
            presentation.accessibilityLabel,
            presentation.headline,
            game.matchupText,
            state.statusText,
            state.primaryActionLabel
        ]
        .compactMap { $0?.nilIfBlank }
        .joined(separator: ". ")
    }
}

struct HomePinButton: View {
    let isPinned: Bool
    let action: () -> Void

    var body: some View {
        Button {
            SportsFeedback.selection()
            action()
        } label: {
            Image(systemName: isPinned ? "pin.slash.fill" : "pin")
                .font(.caption.weight(.bold))
                .foregroundStyle(isPinned ? SportsTheme.Colors.textOnFill : SportsTheme.Tone.pinned.accent)
                .frame(width: 30, height: 30)
                .background(
                    isPinned ? SportsTheme.Tone.pinned.accent : SportsTheme.Tone.pinned.subtleFill,
                    in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPinned ? 1.04 : 1)
        .animation(.snappy(duration: 0.22), value: isPinned)
        .accessibilityLabel(isPinned ? "Unpin game" : "Pin game")
    }
}

private struct HomeCardMetadataRow: View {
    let state: HomeGameCardState
    let presentation: GameCardPresentation

    var body: some View {
        FlowLayout(spacing: 7) {
            Text(presentation.leagueLabel)
                .font(SportsTheme.Typography.leagueCode)
                .foregroundStyle(presentation.accentColor)
            Text(state.metadataText)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
            if state.phase == .live {
                Circle()
                    .fill(SportsTheme.Tone.live.accent)
                    .frame(width: 6, height: 6)
            }
        }
    }
}

private struct HomeCardContext: View {
    let state: HomeGameCardState

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: contextIcon)
                .font(.caption2.weight(.bold))
            Text(state.contextText)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(contextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private var contextIcon: String {
        if state.contextText.contains("new") {
            return "sparkles"
        }
        if state.contextText.contains("score at bottom") {
            return "list.bullet.rectangle"
        }
        switch state.phase {
        case .scheduled:
            return "calendar"
        case .live:
            return "dot.radiowaves.left.and.right"
        case .final:
            return "checkmark.seal"
        case .other:
            return "sportscourt"
        }
    }

    private var contextColor: Color {
        if state.contextText.contains("new") || state.contextText.contains("Resume") {
            return SportsTheme.Tone.newPlay.accent
        }
        if state.contextText.contains("score at bottom") {
            return SportsTheme.Tone.scoreboard.accent
        }
        return SportsTheme.Colors.secondaryInk
    }
}

private struct HomeCardScoreRows: View {
    let rows: [HomeGameCardScoreRow]

    var body: some View {
        VStack(spacing: 5) {
            ForEach(rows) { row in
                HStack(spacing: 8) {
                    Text(row.abbreviation)
                        .font(SportsTheme.Typography.teamAbbreviation)
                        .monospaced()
                        .foregroundStyle(row.isWinner ? SportsTheme.Colors.ink : SportsTheme.Colors.secondaryInk)
                        .frame(width: 44, alignment: .leading)
                    Text(row.name)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(row.scoreText)
                        .font(.headline.weight(row.isWinner ? .black : .bold))
                        .monospacedDigit()
                        .foregroundStyle(row.isWinner ? SportsTheme.Colors.ink : SportsTheme.Colors.secondaryInk)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            SportsTheme.Colors.paperInset,
            in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
        )
    }
}

private struct TeamLine: View {
    let abbreviation: String?
    let name: String
    let scoreText: String?

    var body: some View {
        HStack(spacing: 8) {
            Text(abbreviation ?? shortName)
                .font(SportsTheme.Typography.teamAbbreviation)
                .monospaced()
                .foregroundStyle(SportsTheme.Colors.ink)
                .frame(width: 44, alignment: .leading)
            Text(name)
                .font(SportsTheme.Typography.teamName)
                .foregroundStyle(SportsTheme.Colors.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 8)
            if let scoreText {
                Text(scoreText)
                    .font(.headline.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .frame(minWidth: 24, alignment: .trailing)
            }
        }
    }

    private var shortName: String {
        String(name.split(separator: " ").last?.prefix(4) ?? "TEAM")
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
