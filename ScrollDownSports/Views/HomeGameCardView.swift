import SwiftUI

enum HomeGameCardLayout {
    static let actionVisibleSize: CGFloat = 30
    static let actionHitTargetSize: CGFloat = 44
    static let actionOverlayPadding: CGFloat = 8
    static let actionContentGap: CGFloat = 5
    static let actionTrailingReservation = actionHitTargetSize + actionOverlayPadding + actionContentGap
}

struct GameRowView: View {
    let item: HomeGameItem

    var body: some View {
        let presentation = renderer.gameCardPresentation(for: game)
        GameSummaryCard(state: GameSummaryCardState(item: item, presentation: presentation))
    }

    private var game: Game {
        item.game
    }

    private var renderer: any SportRenderer {
        SportRendererRegistry.renderer(for: game)
    }

}

struct HomeGameActionMenu: View {
    let isPinned: Bool
    let favoriteParticipants: [GameParticipant]
    let isFavoriteTeam: (GameParticipant) -> Bool
    let togglePin: () -> Void
    let toggleFavoriteTeam: (GameParticipant) -> Void

    var body: some View {
        Menu {
            Button {
                SportsFeedback.selection()
                togglePin()
            } label: {
                Label(isPinned ? "Unpin game" : "Pin game", systemImage: isPinned ? "pin.slash" : "pin")
            }
            .accessibilityIdentifier("home.action.pin")

            ForEach(favoriteParticipants) { participant in
                Button {
                    SportsFeedback.selection()
                    toggleFavoriteTeam(participant)
                } label: {
                    Label(
                        favoriteLabel(for: participant),
                        systemImage: isFavoriteTeam(participant) ? "star.slash" : "star"
                    )
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.caption.weight(.bold))
                .foregroundStyle(isPinned ? SportsTheme.Tone.pinned.foreground : SportsTheme.Colors.secondaryInk)
                .frame(width: HomeGameCardLayout.actionVisibleSize, height: HomeGameCardLayout.actionVisibleSize)
                .background(
                    isPinned ? SportsTheme.Tone.pinned.subtleFill : SportsTheme.Colors.paperInset,
                    in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
                )
                .frame(width: HomeGameCardLayout.actionHitTargetSize, height: HomeGameCardLayout.actionHitTargetSize)
        }
        .contentShape(Rectangle())
        .accessibilityLabel(isPinned ? "Game actions, pinned" : "Game actions")
    }

    private func favoriteLabel(for participant: GameParticipant) -> String {
        let teamLabel = participant.abbreviation?.nilIfBlank ?? participant.name
        return isFavoriteTeam(participant) ? "Unfavorite \(teamLabel)" : "Favorite \(teamLabel)"
    }
}
