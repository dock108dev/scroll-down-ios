import SwiftUI

struct GameHeaderView: View {
    let game: Game
    let renderer: any SportRenderer
    let isPinned: Bool
    let newPlayCount: Int

    var body: some View {
        let presentation = renderer.gameHeaderPresentation(for: game)

        HStack(alignment: .top, spacing: 10) {
            SportsTeamRail(color: presentation.accentColor)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(presentation.leagueLabel)
                        .font(SportsTheme.Typography.leagueCode)
                        .foregroundStyle(presentation.accentColor)
                    Text(statusLine)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    Spacer()
                }

                if let away = game.awayParticipant {
                    DetailTeamLine(abbreviation: away.abbreviation, name: away.name)
                }
                if let home = game.homeParticipant {
                    DetailTeamLine(abbreviation: home.abbreviation, name: home.name)
                }

                Text(contextLine)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(contextColor)
            }
        }
        .padding(12)
        .background(SportsTheme.Surface.gameHeaderCard.background, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                .stroke(SportsTheme.Stroke.accent(presentation.accentColor), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(presentation.accessibilityLabel ?? presentation.headline ?? game.matchupText)
    }

    private var statusLine: String {
        let presentation = renderer.gameHeaderPresentation(for: game)
        let status: String
        if game.status.isLive {
            status = presentation.statusText ?? "Live"
        } else if game.status.isFinal {
            status = "Final"
        } else {
            status = DateFormatters.timeOnly.string(from: game.scheduledStart)
        }
        return "\(status) · \(DateFormatters.daySubtitle.string(from: game.scheduledStart))"
    }

    private var contextLine: String {
        if newPlayCount > 0 {
            return "\(newPlayCount) new"
        }
        if game.status.isFinal || game.status.isLive {
            return "Catch up"
        }
        return "Preview"
    }

    private var contextColor: Color {
        newPlayCount > 0 ? SportsTheme.Tone.newPlay.accent : SportsTheme.Colors.secondaryInk
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
            HStack(spacing: 7) {
                Text(count == 1 ? "1 new" : "\(count) new")
                    .font(SportsTheme.Typography.metadata)
                Text("·")
                    .font(SportsTheme.Typography.metadata)
                    .opacity(0.8)
                Text("jump latest")
                    .font(SportsTheme.Typography.metadata)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
                    .fill(SportsTheme.Tone.newPlay.accent)
            )
            .shadow(color: .black.opacity(0.14), radius: 6, y: 2)
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
