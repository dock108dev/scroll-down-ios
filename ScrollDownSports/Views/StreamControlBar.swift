import SwiftUI

struct StreamControlBar: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.sportsLayoutMetrics) private var layout

    let game: Game
    let renderer: any SportRenderer
    let events: [GameEvent]
    let isGamePinned: Bool
    let isFollowingLiveEdge: Bool
    let newPlayCount: Int
    let canResume: Bool
    @Binding var selectedMode: DetailStreamMode
    let onToggleGamePin: () -> Void
    let onToggleFollowLive: () -> Void
    let onResume: () -> Void
    let onJumpLatest: () -> Void

    var body: some View {
        let density = DetailChromeDensity.resolve(
            dynamicTypeSize: dynamicTypeSize,
            availableWidth: layout.detailContentWidth,
            contentWeight: contentWeight
        )

        VStack(alignment: .leading, spacing: density == .regular ? 7 : 9) {
            streamModeControl

            switch density {
            case .regular:
                regularStatusRow
            case .compact:
                compactStatusRow
            case .stacked:
                stackedStatusRows
            case .accessibility:
                accessibilityStatusRows
            }
        }
        .sportsSurface(.streamControlBar, accent: renderer.theme.accentColor)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var streamModeControl: some View {
        if dynamicTypeSize.isDetailChromeAccessibility {
            Menu {
                ForEach(DetailStreamMode.allCases) { mode in
                    Button {
                        selectedMode = mode
                    } label: {
                        Label(mode.title, systemImage: selectedMode == mode ? "checkmark" : "circle")
                    }
                }
            } label: {
                Label(selectedMode.title, systemImage: "line.3.horizontal.decrease.circle")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.sportsControl(tone: .scoreboard, compact: false))
            .accessibilityLabel("Stream mode")
            .accessibilityValue(selectedMode.title)
            .accessibilityIdentifier("detail.streamModePicker")
        } else {
            Picker("Stream mode", selection: $selectedMode) {
                ForEach(DetailStreamMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("detail.streamModePicker")
        }
    }

    private var regularStatusRow: some View {
        HStack(spacing: 8) {
            contextText(lineLimit: 1)

            Spacer(minLength: 0)

            if showsInlineJumpLatest {
                jumpLatestButton(compact: true)
            }

            actionsMenu(includesJumpLatest: false, emphasizesJumpLatest: false)
        }
    }

    private var compactStatusRow: some View {
        HStack(spacing: 8) {
            contextText(lineLimit: 1)

            Spacer(minLength: 0)

            actionsMenu(includesJumpLatest: showsOverflowJumpLatest, emphasizesJumpLatest: showsOverflowJumpLatest)
        }
    }

    private var stackedStatusRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                contextText(lineLimit: 2)

                Spacer(minLength: 0)

                actionsMenu(includesJumpLatest: false, emphasizesJumpLatest: false)
            }

            if showsFullWidthJumpLatest {
                jumpLatestButton(compact: false)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var accessibilityStatusRows: some View {
        VStack(alignment: .leading, spacing: 9) {
            contextText(lineLimit: nil)

            HStack(spacing: 8) {
                if showsFullWidthJumpLatest {
                    jumpLatestButton(compact: false)
                        .frame(maxWidth: .infinity)
                }

                actionsMenu(includesJumpLatest: false, emphasizesJumpLatest: false)
            }
        }
    }

    private func contextText(lineLimit: Int?) -> some View {
        Text(contextLine)
            .font(SportsTheme.Typography.metadata)
            .foregroundStyle(contextColor)
            .lineLimit(lineLimit)
            .minimumScaleFactor(lineLimit == 1 ? 0.82 : 1)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("detail.streamControls")
    }

    private func jumpLatestButton(compact: Bool) -> some View {
        Button {
            SportsFeedback.impact()
            onJumpLatest()
        } label: {
            Label("Jump latest", systemImage: "arrow.down.to.line")
                .frame(maxWidth: compact ? nil : .infinity)
        }
        .buttonStyle(.sportsControl(tone: .newPlay, filled: !compact, compact: compact))
        .frame(minHeight: 44)
        .accessibilityLabel("Jump to latest")
        .accessibilityIdentifier("detail.jumpEnd")
    }

    private func actionsMenu(includesJumpLatest: Bool, emphasizesJumpLatest: Bool) -> some View {
        Menu {
            if includesJumpLatest {
                Button {
                    SportsFeedback.impact()
                    onJumpLatest()
                } label: {
                    Label("Jump latest", systemImage: "arrow.down.to.line")
                }
            }

            Button {
                SportsFeedback.selection()
                onToggleGamePin()
            } label: {
                Label(isGamePinned ? "Unpin game" : "Pin game", systemImage: isGamePinned ? "pin.slash" : "pin")
            }

            if game.status.isLive {
                Button {
                    SportsFeedback.selection()
                    onToggleFollowLive()
                } label: {
                    Label(
                        isFollowingLiveEdge ? "Stop following" : "Follow live",
                        systemImage: isFollowingLiveEdge ? "pause.circle" : "dot.radiowaves.left.and.right"
                    )
                }
            }
        } label: {
            Image(systemName: actionMenuSystemImage(emphasizesJumpLatest: emphasizesJumpLatest))
                .font(.caption.weight(.bold))
                .foregroundStyle(actionMenuColor(emphasizesJumpLatest: emphasizesJumpLatest))
                .frame(width: 44, height: 44)
                .background(SportsTheme.Colors.paperInset, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous))
        }
        .accessibilityLabel(actionMenuAccessibilityLabel(emphasizesJumpLatest: emphasizesJumpLatest))
        .accessibilityIdentifier("detail.gameActions")
    }

    private var showsInlineJumpLatest: Bool {
        newPlayCount > 0 && !canResume
    }

    private var showsOverflowJumpLatest: Bool {
        newPlayCount > 0 && !canResume
    }

    private var showsFullWidthJumpLatest: Bool {
        newPlayCount > 0 && !canResume
    }

    private var contentWeight: CGFloat {
        var weight: CGFloat = 1
        if newPlayCount > 0 {
            weight += 0.25
        }
        if isGamePinned {
            weight += 0.20
        }
        if game.status.isLive {
            weight += 0.20
        }
        if selectedMode == .full {
            weight += 0.30
        }
        return weight
    }

    private func actionMenuSystemImage(emphasizesJumpLatest: Bool) -> String {
        if emphasizesJumpLatest {
            return "arrow.down.to.line"
        }
        return isGamePinned ? "pin.fill" : "ellipsis"
    }

    private func actionMenuColor(emphasizesJumpLatest: Bool) -> Color {
        if emphasizesJumpLatest {
            return SportsTheme.Tone.newPlay.accent
        }
        return isGamePinned ? SportsTheme.Tone.pinned.accent : SportsTheme.Colors.secondaryInk
    }

    private func actionMenuAccessibilityLabel(emphasizesJumpLatest: Bool) -> String {
        if emphasizesJumpLatest {
            return "Game actions, jump latest available"
        }
        return isGamePinned ? "Game actions, pinned" : "Game actions"
    }

    private var contextLine: String {
        if newPlayCount > 0 {
            return "\(newPlayCount) new"
        }
        let count = selectedMode.count(in: events, game: game)
        if count > 0 {
            return count == 1 ? "\(selectedMode.title) · 1 play" : "\(selectedMode.title) · \(count) plays"
        }
        if game.status.isLive {
            if isGamePinned && isFollowingLiveEdge {
                return "Pinned · following live"
            }
            return isFollowingLiveEdge ? "Following live" : "Live stream"
        }
        if game.status.isFinal {
            return "Final stream"
        }
        if game.status.isPregame {
            return "Preview"
        }
        return isGamePinned ? "Pinned" : "Stream"
    }

    private var contextColor: Color {
        newPlayCount > 0 ? SportsTheme.Tone.newPlay.accent : SportsTheme.Colors.secondaryInk
    }
}
