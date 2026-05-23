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

        HStack(alignment: .top, spacing: 12) {
            SportsTeamRail(color: railColor)

            VStack(alignment: .leading, spacing: 11) {
                HomeCardMetadataRow(
                    state: cardState,
                    presentation: presentation
                )
                .padding(.trailing, 38)

                if cardState.usesStrongLiveTreatment {
                    HomeLiveStrip(text: cardState.statusText)
                }

                Text(presentation.headline ?? game.matchupText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 3) {
                    if let away = game.awayParticipant {
                        TeamLine(abbreviation: away.abbreviation, name: away.name)
                    }
                    if let home = game.homeParticipant {
                        TeamLine(abbreviation: home.abbreviation, name: home.name)
                    }
                }

                HomeCardContext(state: cardState)

                if cardState.showsScoreRows {
                    HomeCardScoreRows(rows: cardState.scoreRows)
                } else if let scoreCueText = cardState.scoreCueText {
                    HomeScoreCue(text: scoreCueText)
                }

                HomeCardActionRow(label: cardState.primaryActionLabel, phase: cardState.phase)
            }
        }
        .sportsSurface(.gameCard, accent: accent(for: cardState, fallback: presentation.accentColor))
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
            if let statusBadgeText = state.statusBadgeText {
                SportsBadge(text: statusBadgeText, tone: tone, filled: state.phase == .live)
            }
            if state.showsPinnedBadge {
                SportsBadge(text: "PINNED", tone: .pinned, filled: false)
            }
            if let newPlayText = state.newPlayText {
                SportsBadge(text: newPlayText.uppercased(), tone: .newPlay, filled: false)
            }
        }
    }

    private var tone: SportsTheme.Tone {
        switch state.phase {
        case .live:
            return .live
        case .final:
            return .final
        case .scheduled, .other:
            return .neutral
        }
    }
}

private struct HomeLiveStrip: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(SportsTheme.Tone.live.accent)
                .frame(width: 7, height: 7)
            Text("Live now")
                .font(.caption.weight(.black))
                .foregroundStyle(SportsTheme.Tone.live.accent)
            Text(text)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(
            SportsTheme.Tone.live.subtleFill,
            in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
        )
    }
}

private struct HomeCardContext: View {
    let state: HomeGameCardState

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(state.contextText, systemImage: contextIcon)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(contextColor)
            if let progressText = state.progressText {
                Label(progressText, systemImage: "arrow.uturn.forward")
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Tone.newPlay.accent)
            }
        }
    }

    private var contextIcon: String {
        if state.newPlayText != nil {
            return "sparkles"
        }
        if state.scoreCueText != nil {
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
        if state.newPlayText != nil {
            return SportsTheme.Tone.newPlay.accent
        }
        if state.scoreCueText != nil {
            return SportsTheme.Tone.scoreboard.accent
        }
        return SportsTheme.Colors.secondaryInk
    }
}

private struct HomeScoreCue: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle")
                .font(.caption.weight(.bold))
            Text(text)
                .font(SportsTheme.Typography.metadata)
            Spacer(minLength: 0)
        }
        .foregroundStyle(SportsTheme.Tone.scoreboard.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            SportsTheme.Tone.scoreboard.subtleFill,
            in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
        )
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

private struct HomeCardActionRow: View {
    let label: String
    let phase: HomeGameCardPhase

    var body: some View {
        HStack(spacing: 8) {
            Label(label, systemImage: icon)
                .font(.subheadline.weight(.bold))
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(tone.accent)
        .padding(.top, 2)
    }

    private var icon: String {
        switch label.lowercased() {
        case let value where value.contains("resume"):
            return "arrow.uturn.forward"
        case let value where value.contains("stream"):
            return "play.circle.fill"
        case let value where value.contains("catch"):
            return "sparkles"
        case let value where value.contains("recap"):
            return "doc.text"
        case let value where value.contains("box"):
            return "number.square"
        case let value where value.contains("preview"):
            return "calendar"
        default:
            return phase == .live ? "play.circle.fill" : "arrow.right.circle"
        }
    }

    private var tone: SportsTheme.Tone {
        switch phase {
        case .live:
            return .live
        case .final:
            return .final
        case .scheduled:
            return .neutral
        case .other:
            return .newPlay
        }
    }
}

private struct TeamLine: View {
    let abbreviation: String?
    let name: String

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
