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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(accessibleMatchupLabel), \(statusLine)")
        .accessibilityIdentifier("detail.header")
    }

    private var accessibleMatchupLabel: String {
        let presentation = renderer.gameHeaderPresentation(for: game)
        return ScoreSpoilerFilter.topRegionText(presentation.accessibilityLabel, for: game)
            ?? ScoreSpoilerFilter.topRegionText(presentation.headline, for: game)
            ?? ScoreSpoilerFilter.matchupText(for: game)
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
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("detail.resumeBanner")

            Spacer(minLength: 0)

            Button {
                SportsFeedback.impact()
                onResume()
            } label: {
                Text("Resume")
            }
            .accessibilityIdentifier("detail.resume")
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
                    .frame(minWidth: 44, minHeight: 44)
                    .background(SportsTheme.Colors.paperInset, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous))
            }
            .accessibilityLabel("More resume actions")
            .accessibilityIdentifier("detail.jumpEnd")
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
                .buttonStyle(.sportsControl(tone: .scoreboard, filled: true, compact: true))
                .accessibilityIdentifier("detail.stickyNav.return")
            } else {
                if AppEnvironment.isRunningUITests {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .accessibilityHidden(true)
                } else {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SportsTheme.Colors.textOnFill)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(SportsTheme.Colors.ink, in: Capsule())
                        .accessibilityHidden(true)
                }

                Spacer(minLength: 0)

                Button {
                    SportsFeedback.selection()
                    onTop()
                } label: {
                    Text("Top")
                }
                .buttonStyle(.sportsControl(tone: .scoreboard, filled: true, compact: true))
                .accessibilityIdentifier("detail.stickyNav.top")
            }

            Spacer(minLength: 0)

            Button {
                SportsFeedback.selection()
                onEnd()
            } label: {
                Text(endLabel)
            }
            .buttonStyle(.sportsControl(tone: .scoreboard, filled: true, compact: true))
            .accessibilityIdentifier("detail.stickyNav.end")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(SportsTheme.Colors.paperRaised, in: Capsule())
        .overlay {
            Capsule().strokeBorder(SportsTheme.Colors.hairline.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 44, height: 44)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(title)
                .accessibilityIdentifier("detail.stickyNav")
        }
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
                    .accessibilityHidden(true)
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
        .accessibilityIdentifier("detail.newPlaysAffordance")
    }
}
