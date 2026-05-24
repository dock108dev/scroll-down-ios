import SwiftUI

struct StreamControlBar: View {
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
        VStack(alignment: .leading, spacing: 7) {
            Picker("Stream mode", selection: $selectedMode) {
                ForEach(DetailStreamMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("detail.streamModePicker")

            HStack(spacing: 8) {
                Text(contextLine)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(contextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .accessibilityIdentifier("detail.streamControls")

                Spacer(minLength: 0)

                if showsInlineJumpLatest {
                    Button {
                        SportsFeedback.impact()
                        onJumpLatest()
                    } label: {
                        Text("Jump latest")
                    }
                    .buttonStyle(.sportsControl(tone: .newPlay, compact: true))
                    .accessibilityLabel("Jump to latest")
                    .accessibilityIdentifier("detail.jumpEnd")
                }

                Menu {
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
                    Image(systemName: isGamePinned ? "pin.fill" : "ellipsis")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isGamePinned ? SportsTheme.Tone.pinned.accent : SportsTheme.Colors.secondaryInk)
                        .frame(width: 36, height: 36)
                        .background(SportsTheme.Colors.paperInset, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous))
                }
                .accessibilityLabel(isGamePinned ? "Game actions, pinned" : "Game actions")
                .accessibilityIdentifier("detail.gameActions")
            }
        }
        .sportsSurface(.streamControlBar, accent: renderer.theme.accentColor)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var showsInlineJumpLatest: Bool {
        newPlayCount > 0 && !canResume
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
