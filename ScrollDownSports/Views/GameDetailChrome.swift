import SwiftUI

struct GameHeaderView: View {
    let game: Game
    let renderer: any SportRenderer
    let isPinned: Bool
    let newPlayCount: Int

    var body: some View {
        let presentation = renderer.gameHeaderPresentation(for: game)

        HStack(alignment: .top, spacing: 8) {
            SportsTeamRail(color: presentation.accentColor)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(presentation.leagueLabel)
                        .font(SportsTheme.Typography.leagueCode)
                        .foregroundStyle(Color(red: 0.641, green: 0.867, blue: 0.388))
                    Text(statusLine)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.textOnFill.opacity(0.72))
                    Spacer()
                }

                if let away = game.awayParticipant {
                    DetailTeamLine(abbreviation: away.abbreviation, name: away.name, isInverted: true)
                }
                if let home = game.homeParticipant {
                    DetailTeamLine(abbreviation: home.abbreviation, name: home.name, isInverted: true)
                }

                Text(contextLine)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(contextColor)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(SportsTheme.Tone.scoreboard.accent, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                .stroke(presentation.accentColor.opacity(0.20), lineWidth: 1)
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
        newPlayCount > 0 ? Color(red: 0.980, green: 0.510, blue: 0.216) : SportsTheme.Colors.textOnFill.opacity(0.72)
    }
}

private struct DetailTeamLine: View {
    let abbreviation: String?
    let name: String
    var isInverted = false

    var body: some View {
        HStack(spacing: 8) {
            Text(abbreviation ?? shortName)
                .font(SportsTheme.Typography.teamAbbreviation)
                .monospaced()
                .foregroundStyle(isInverted ? SportsTheme.Colors.textOnFill.opacity(0.72) : SportsTheme.Colors.ink)
                .frame(width: 42, alignment: .leading)
            Text(name)
                .font(SportsTheme.Typography.detailTeamName)
                .foregroundStyle(isInverted ? SportsTheme.Colors.textOnFill : SportsTheme.Colors.ink)
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

        VStack(alignment: .leading, spacing: 8) {
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

struct DetailLoadErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Unable to load game",
                systemImage: "wifi.exclamationmark",
                description: Text(message)
            )

            Button {
                SportsFeedback.impact()
                retry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .frame(minHeight: 44)
            }
            .buttonStyle(.sportsControl(tone: .critical, compact: false))
            .accessibilityIdentifier("detail.retry")
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("detail.loadError")
    }
}

struct ResumeBanner: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.sportsLayoutMetrics) private var layout

    @State private var showStartOverConfirmation = false

    let description: String
    let onResume: () -> Void
    let onJumpLatest: () -> Void
    let onStartOver: () -> Void

    var body: some View {
        let density = DetailChromeDensity.resolve(
            dynamicTypeSize: dynamicTypeSize,
            availableWidth: layout.detailContentWidth,
            contentWeight: contentWeight
        )

        Group {
            switch density {
            case .regular:
                inlineLayout(descriptionLineLimit: nil)
            case .compact:
                inlineLayout(descriptionLineLimit: 2)
            case .stacked:
                stackedLayout
            case .accessibility:
                accessibilityLayout
            }
        }
        .sportsSurface(.streamControlBar, accent: SportsTheme.Tone.newPlay.accent)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func inlineLayout(descriptionLineLimit: Int?) -> some View {
        HStack(spacing: 8) {
            resumeIcon

            Text(description)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.ink)
                .lineLimit(descriptionLineLimit)
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
            .frame(minHeight: 44)

            resumeOverflowMenu(iconOnly: true)
        }
    }

    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 8) {
                resumeIcon

                Text(description)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("detail.resumeBanner")
            }

            HStack(spacing: 8) {
                resumeButton(compact: false)
                    .frame(maxWidth: .infinity)

                resumeOverflowMenu(iconOnly: false)
            }
        }
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                resumeIcon

                Text(description)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("detail.resumeBanner")
            }

            resumeButton(compact: false)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                Button {
                    SportsFeedback.impact()
                    onJumpLatest()
                } label: {
                    Label("Jump latest", systemImage: "arrow.down.to.line")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.sportsControl(tone: .newPlay, compact: false))
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityLabel("Jump to latest")
                .accessibilityIdentifier("detail.jumpEnd")

                resumeOverflowMenu(iconOnly: false)
            }
        }
    }

    private var resumeIcon: some View {
        Image(systemName: "bookmark.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(SportsTheme.Tone.newPlay.accent)
            .frame(width: 18, height: 18)
    }

    private func resumeButton(compact: Bool) -> some View {
        Button {
            SportsFeedback.impact()
            onResume()
        } label: {
            Text("Resume")
                .frame(maxWidth: compact ? nil : .infinity)
        }
        .accessibilityIdentifier("detail.resume")
        .buttonStyle(.sportsControl(tone: .newPlay, filled: true, compact: compact))
        .frame(minHeight: 44)
    }

    private func resumeOverflowMenu(iconOnly: Bool) -> some View {
        Menu {
            Button {
                SportsFeedback.impact()
                onJumpLatest()
            } label: {
                Label("Jump latest", systemImage: "arrow.down.to.line")
            }

            Button(role: .destructive) {
                SportsFeedback.selection()
                showStartOverConfirmation = true
            } label: {
                Label("Start over", systemImage: "restart")
            }
        } label: {
            if iconOnly {
                Image(systemName: "ellipsis")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    .frame(width: 44, height: 44)
                    .background(SportsTheme.Colors.paperInset, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous))
            } else {
                Label("More", systemImage: "ellipsis")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.sportsControl(tone: .newPlay, compact: false))
        .frame(minHeight: 44)
        .accessibilityLabel("More resume actions")
        .accessibilityIdentifier("detail.resume.more")
        .confirmationDialog(
            "Start over?",
            isPresented: $showStartOverConfirmation,
            titleVisibility: .visible
        ) {
            Button("Start Over", role: .destructive) {
                onStartOver()
            }
            Button("Keep Saved Position", role: .cancel) {}
        } message: {
            Text("This clears your saved play position for this game, but keeps the game pinned and keeps scoreboard progress.")
        }
    }

    private var contentWeight: CGFloat {
        var weight: CGFloat = 1
        if description.count > 24 {
            weight += 0.20
        }
        if description.count > 40 {
            weight += 0.35
        }
        return weight
    }
}
