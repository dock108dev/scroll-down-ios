import SwiftUI

struct GameHeaderView: View {
    let game: Game
    let renderer: any SportRenderer
    let isPinned: Bool
    let newPlayCount: Int

    var body: some View {
        let presentation = renderer.gameHeaderPresentation(for: game)

        HStack(alignment: .top, spacing: 12) {
            SportsTeamRail(color: presentation.accentColor)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(presentation.leagueLabel)
                        .font(SportsTheme.Typography.leagueCode)
                        .foregroundStyle(presentation.accentColor)
                    Text(presentation.sportLabel)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    Text(DateFormatters.shortTime.string(from: game.scheduledStart))
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    if game.status.isLive {
                        SportsBadge(text: "LIVE", tone: .live)
                    }
                    Spacer()
                }

                Text(presentation.headline ?? game.matchupText)
                    .font(SportsTheme.Typography.appTitle)
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let away = game.awayParticipant {
                    DetailTeamLine(abbreviation: away.abbreviation, name: away.name)
                }
                if let home = game.homeParticipant {
                    DetailTeamLine(abbreviation: home.abbreviation, name: home.name)
                }

                if let progressText = presentation.statusText {
                    Text(progressText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(game.status.isLive ? SportsTheme.Tone.live.accent : SportsTheme.Colors.secondaryInk)
                }

                FlowLayout(spacing: 8) {
                    SportsBadge(text: isPinned ? "PINNED" : "UNPINNED", tone: .pinned, filled: isPinned)
                    SportsBadge(text: "Score at bottom", tone: .scoreboard, filled: false)
                    if let playCountText = presentation.playCountText {
                        SportsBadge(text: playCountText, tone: .neutral, filled: false)
                    }
                    if newPlayCount > 0 {
                        SportsBadge(text: "\(newPlayCount) new", tone: .newPlay)
                    }
                }
            }
        }
        .sportsSurface(.gameHeaderCard, accent: presentation.accentColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(presentation.accessibilityLabel ?? presentation.headline ?? game.matchupText)
    }
}

private struct DetailTeamLine: View {
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
                .font(SportsTheme.Typography.detailTeamName)
                .foregroundStyle(SportsTheme.Colors.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }

    private var shortName: String {
        String(name.split(separator: " ").last?.prefix(4) ?? "TEAM")
    }
}

struct GameHeaderPlaceholder: View {
    let summary: Game
    let renderer: any SportRenderer

    var body: some View {
        let presentation = renderer.gameHeaderPresentation(for: summary)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(presentation.leagueLabel)
                    .font(SportsTheme.Typography.leagueCode)
                    .foregroundStyle(presentation.accentColor)
            }
            Text(presentation.headline ?? summary.matchupText)
                .font(SportsTheme.Typography.appTitle)
                .foregroundStyle(SportsTheme.Colors.ink)
            Text(DateFormatters.shortTime.string(from: summary.scheduledStart))
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
        }
        .sportsSurface(.gameHeaderCard, accent: presentation.accentColor)
    }
}

struct DetailRefreshErrorBanner: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(SportsTheme.Tone.critical.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Couldn’t update")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SportsTheme.Colors.ink)
                Text(message)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button {
                SportsFeedback.impact()
                onRetry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.sportsControl(tone: .critical, compact: true))
        }
        .sportsSurface(.streamControlBar, accent: SportsTheme.Tone.critical.accent)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NewPlaysAffordance: View {
    let count: Int
    let onJumpLatest: () -> Void

    var body: some View {
        Button {
            SportsFeedback.impact()
            onJumpLatest()
        } label: {
            HStack(spacing: 10) {
                Text(count == 1 ? "1 new play" : "\(count) new plays")
                    .font(.subheadline.weight(.semibold))
                Divider()
                    .frame(height: 18)
                    .overlay(.white.opacity(0.35))
                Label("Jump to latest", systemImage: "arrow.down.to.line")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
                    .fill(SportsTheme.Tone.newPlay.accent)
            )
            .shadow(color: .black.opacity(0.16), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityLabel(count == 1 ? "1 new play. Jump to latest" : "\(count) new plays. Jump to latest")
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
