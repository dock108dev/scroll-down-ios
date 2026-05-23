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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    SportsFeedback.selection()
                    onToggleGamePin()
                } label: {
                    Label(isGamePinned ? "Unpin game" : "Pin game", systemImage: isGamePinned ? "pin.slash" : "pin")
                }
                .buttonStyle(.sportsControl(tone: .pinned, filled: isGamePinned, compact: true))
                .accessibilityLabel(isGamePinned ? "Unpin game" : "Pin game")
                .scaleEffect(isGamePinned ? 1.03 : 1)
                .animation(.snappy(duration: 0.22), value: isGamePinned)

                if newPlayCount > 0 {
                    SportsBadge(text: "\(newPlayCount) new", tone: .newPlay)
                }

                Spacer(minLength: 0)

                if canResume {
                    Button {
                        SportsFeedback.impact()
                        onResume()
                    } label: {
                        Label("Resume", systemImage: "arrow.uturn.forward")
                    }
                    .buttonStyle(.sportsControl(tone: .newPlay, compact: true))
                }

                Button {
                    SportsFeedback.impact()
                    onJumpLatest()
                } label: {
                    Label("Jump latest", systemImage: "arrow.down.to.line")
                }
                .buttonStyle(.sportsControl(tone: .scoreboard, compact: true))
                .accessibilityLabel("Jump to latest")
            }

            Picker("Stream mode", selection: $selectedMode) {
                ForEach(DetailStreamMode.allCases) { mode in
                    Text("\(mode.title) \(mode.count(in: events, game: game))")
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
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
                    .buttonStyle(.sportsControl(tone: .live, filled: isFollowingLiveEdge))
                    .accessibilityLabel(isFollowingLiveEdge ? "Stop following" : "Follow live")
                    .animation(.snappy(duration: 0.22), value: isFollowingLiveEdge)
                } else {
                    Text(followUnavailableCopy)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                }

                Spacer(minLength: 0)

                Text(modeSummary)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .sportsSurface(.streamControlBar, accent: renderer.theme.accentColor)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var followUnavailableCopy: String {
        if game.status.isFinal {
            return "Final stream"
        }
        if game.status.isPregame {
            return "Follow live when game starts"
        }
        return "Live follow unavailable"
    }

    private var modeSummary: String {
        switch selectedMode {
        case .full:
            return "\(selectedMode.summary) · Score at bottom"
        case .key, .flow:
            return "\(selectedMode.summary) · Full has every play"
        }
    }
}
