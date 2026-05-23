import SwiftUI

struct PeriodGroupHeader: View {
    let label: String
    let accent: Color

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: SportsTheme.Radius.rail, style: .continuous)
                .fill(accent)
                .frame(width: 18, height: 3)
            Text(label)
                .font(SportsTheme.Typography.metadata.weight(.bold))
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                .textCase(.uppercase)
            Rectangle()
                .fill(SportsTheme.Colors.hairline.opacity(0.55))
                .frame(height: 1)
        }
        .padding(.horizontal, 2)
        .accessibilityAddTraits(.isHeader)
    }
}

struct StreamTerminalMarker: View {
    let game: Game

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.caption.weight(.black))
                .foregroundStyle(tone.accent)
                .frame(width: 22, height: 22)
                .background(tone.subtleFill, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SportsTheme.Colors.ink)
                Text(subtitle)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
            }
            Spacer(minLength: 0)
        }
        .sportsSurface(.eventCard, accent: tone.accent)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var tone: SportsTheme.Tone {
        game.status.isLive ? .live : .scoreboard
    }

    private var iconName: String {
        game.status.isLive ? "dot.radiowaves.left.and.right" : "flag.checkered"
    }

    private var title: String {
        game.status.isLive ? "Live edge" : "End of play stream"
    }

    private var subtitle: String {
        game.status.isLive ? "New plays will land below this point." : "Stats and the scoreboard payoff follow."
    }
}
