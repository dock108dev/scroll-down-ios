import SwiftUI

struct GameSummaryCard: View {
    let state: GameSummaryCardState

    var body: some View {
        switch state.surface {
        case .home:
            content
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(
                    SportsTheme.Surface.gameCard.background,
                    in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                        .stroke(SportsTheme.Stroke.subdued(), lineWidth: 0.9)
                )
                .shadow(color: SportsTheme.Colors.ink.opacity(0.035), radius: 8, x: 0, y: 3)
                .contentShape(RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(state.accessibilityLabel)
                .accessibilityHint(state.accessibilityHint ?? "")
                .accessibilityAddTraits(.isButton)
        case .detail:
            content
                .sportsSurface(
                    .gameHeaderCard,
                    accent: state.accentColor,
                    usesAccentStroke: state.usesStrongLiveTreatment
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(state.accessibilityLabel)
                .accessibilityIdentifier("detail.header")
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 8) {
            SportsTeamRail(color: state.railColor)

            VStack(alignment: .leading, spacing: verticalSpacing) {
                GameSummaryMetadataRow(state: state)

                VStack(alignment: .leading, spacing: 1) {
                    ForEach(state.teamLines) { line in
                        GameSummaryTeamLineView(
                            gameID: state.gameID,
                            line: line,
                            surface: state.surface
                        )
                    }
                }

                GameSummaryContext(state: state)
                    .accessibilityIdentifier(statusIdentifier)
            }
            .padding(.trailing, trailingReservation)
        }
    }

    private var verticalSpacing: CGFloat {
        switch state.surface {
        case .home:
            return 6
        case .detail:
            return 5
        }
    }

    private var trailingReservation: CGFloat {
        switch state.surface {
        case .home:
            return HomeGameCardLayout.pinTrailingReservation
        case .detail:
            return 0
        }
    }

    private var statusIdentifier: String {
        switch state.surface {
        case .home:
            return "home.gameRow.\(state.gameID).status"
        case .detail:
            return "detail.header.status"
        }
    }
}

private struct GameSummaryMetadataRow: View {
    let state: GameSummaryCardState

    var body: some View {
        FlowLayout(spacing: 7) {
            Text(state.leagueLabel)
                .font(SportsTheme.Typography.leagueCode)
                .foregroundStyle(state.accentColor)
            Text(state.metadataText)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                .accessibilityIdentifier(statusIdentifier)
            if state.phase == .live {
                Circle()
                    .fill(SportsTheme.Tone.live.accent)
                    .frame(width: 6, height: 6)
            }
            if state.surface == .detail, state.showsPinnedBadge {
                Image(systemName: "pin.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(SportsTheme.Tone.pinned.foreground)
                    .accessibilityLabel("Pinned")
            }
        }
    }

    private var statusIdentifier: String {
        switch state.surface {
        case .home:
            return "home.gameRow.\(state.gameID).status"
        case .detail:
            return "detail.header.metadata"
        }
    }
}

private struct GameSummaryContext: View {
    let state: GameSummaryCardState

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: contextIcon)
                .font(.caption2.weight(.bold))
                .accessibilityHidden(true)
            Text(state.contextText)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(contextColor)
                .fixedSize(horizontal: false, vertical: true)
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
            return SportsTheme.Tone.newPlay.foreground
        }
        if state.contextText.contains("score at bottom") {
            return SportsTheme.Tone.scoreboard.foreground
        }
        return SportsTheme.Colors.secondaryInk
    }
}

private struct GameSummaryTeamLineView: View {
    let gameID: Int
    let line: GameSummaryTeamLine
    let surface: GameSummaryCardSurface

    var body: some View {
        HStack(spacing: 8) {
            Text(line.abbreviation)
                .font(SportsTheme.Typography.teamAbbreviation)
                .monospaced()
                .foregroundStyle(teamColor)
                .frame(width: abbreviationWidth, alignment: .leading)
            Text(line.name)
                .font(teamNameFont)
                .foregroundStyle(teamColor)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if line.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(SportsTheme.Tone.pinned.foreground)
                    .accessibilityLabel("Favorite team")
            }
            Spacer(minLength: 8)
            if let scoreText = line.scoreText {
                Text(scoreText)
                    .font(SportsTheme.Typography.scoreNumber)
                    .monospacedDigit()
                    .foregroundStyle(scoreColor)
                    .frame(minWidth: 24, alignment: .trailing)
                    .accessibilityIdentifier(scoreIdentifier)
            }
        }
    }

    private var abbreviationWidth: CGFloat {
        switch surface {
        case .home:
            return 44
        case .detail:
            return 42
        }
    }

    private var teamNameFont: Font {
        switch surface {
        case .home:
            return SportsTheme.Typography.teamName
        case .detail:
            return SportsTheme.Typography.detailTeamName
        }
    }

    private var teamColor: Color {
        SportsTheme.Colors.ink
    }

    private var scoreColor: Color {
        line.isWinner ? SportsTheme.Colors.ink : SportsTheme.Colors.secondaryInk
    }

    private var scoreIdentifier: String {
        switch surface {
        case .home:
            return "home.gameRow.\(gameID).score"
        case .detail:
            return "detail.header.score"
        }
    }
}
