import SwiftUI

struct GameHeaderView: View {
    let game: Game
    let renderer: any SportRenderer
    let isPinned: Bool
    let newPlayCount: Int
    var progress: GameProgressRecord? = nil

    var body: some View {
        let presentation = renderer.gameHeaderPresentation(for: game)
        GameSummaryCard(
            state: GameSummaryCardState(
                game: game,
                presentation: presentation,
                isPinned: isPinned,
                newPlayCount: newPlayCount,
                progress: progress
            )
        )
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
            Text(
                ScoreSpoilerFilter.topRegionText(presentation.headline, for: summary)
                    ?? ScoreSpoilerFilter.matchupText(for: summary)
            )
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
                .foregroundStyle(SportsTheme.Tone.critical.foreground)
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
            .foregroundStyle(SportsTheme.Tone.newPlay.foreground)
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
