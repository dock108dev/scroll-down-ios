import SwiftUI

enum HomeGameCardLayout {
    static let pinVisibleSize: CGFloat = 34
    static let pinHitTargetSize: CGFloat = 44
    static let pinOverlayPadding: CGFloat = 9
    static let pinContentGap: CGFloat = 6
    static let pinTrailingReservation = pinHitTargetSize + pinOverlayPadding + pinContentGap
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

struct HomePinButton: View {
    let isPinned: Bool
    let action: () -> Void

    var body: some View {
        Button {
            SportsFeedback.selection()
            action()
        } label: {
            Image(systemName: isPinned ? "pin.slash.fill" : "pin")
                .font(.caption.weight(.bold))
                .foregroundStyle(isPinned ? SportsTheme.Tone.pinned.textOnAccent : SportsTheme.Tone.pinned.foreground)
                .frame(width: HomeGameCardLayout.pinVisibleSize, height: HomeGameCardLayout.pinVisibleSize)
                .background(
                    isPinned ? SportsTheme.Tone.pinned.accent : SportsTheme.Tone.pinned.subtleFill,
                    in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
                )
                .frame(width: HomeGameCardLayout.pinHitTargetSize, height: HomeGameCardLayout.pinHitTargetSize)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .scaleEffect(isPinned ? 1.04 : 1)
        .animation(.snappy(duration: 0.22), value: isPinned)
        .accessibilityLabel(isPinned ? "Unpin game" : "Pin game")
    }
}
