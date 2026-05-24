import SwiftUI

struct PeriodGroupHeader: View {
    let label: String
    let accent: Color

    var body: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: SportsTheme.Radius.rail, style: .continuous)
                .fill(accent)
                .frame(width: 28, height: 4)
            if !AppEnvironment.isRunningUITests {
                Text(label)
                    .font(SportsTheme.Typography.teamAbbreviation)
                    .foregroundStyle(SportsTheme.Colors.ink)
            }
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
        HStack(spacing: 8) {
            Rectangle()
                .fill(SportsTheme.Colors.hairline.opacity(0.65))
                .frame(height: 1)
            Text(title)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                .textCase(.uppercase)
            Rectangle()
                .fill(SportsTheme.Colors.hairline.opacity(0.65))
                .frame(height: 1)
        }
        .padding(.vertical, 2)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var title: String {
        game.status.isLive ? "Live edge" : "End of stream"
    }
}
