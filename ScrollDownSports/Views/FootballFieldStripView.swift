import SwiftUI

struct FootballFieldStripView: View {
    let strip: FootballFieldStripDiagram
    let accent: Color

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? 6 : 5) {
            GeometryReader { proxy in
                field(in: proxy.size)
            }
            .frame(height: dynamicTypeSize.isAccessibilitySize ? 42 : 34)
            legend
        }
        .padding(.horizontal, 7)
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 7 : 6)
        .background(SportsTheme.Colors.paperRaised)
        .overlay(
            RoundedRectangle(cornerRadius: SportsTheme.Radius.row, style: .continuous)
                .stroke(SportsTheme.Stroke.subdued(SportsTheme.Colors.scorebookLine), lineWidth: SportsTheme.Stroke.standard)
        )
        .clipShape(RoundedRectangle(cornerRadius: SportsTheme.Radius.row, style: .continuous))
    }

    private func field(in size: CGSize) -> some View {
        let geometry = FootballFieldStripGeometry(size: size)
        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(SportsTheme.Colors.paper.opacity(0.70))
            endZone(x: geometry.leftEdgeX, width: geometry.endZoneWidth)
            endZone(x: geometry.rightEndZoneX, width: geometry.endZoneWidth)
            if strip.isRedZone {
                redZoneBand(geometry: geometry)
            }
            midfieldLine(geometry: geometry)
            if let firstDownX = strip.firstDownX {
                markerLine(
                    x: geometry.xPosition(for: firstDownX),
                    color: SportsTheme.Tone.scoring.accent,
                    dash: [3, 2]
                )
            }
            markerLine(x: geometry.xPosition(for: strip.lineOfScrimmageX), color: accent, dash: [])
            ballMarker(x: geometry.xPosition(for: strip.lineOfScrimmageX), y: size.height * 0.50)
        }
    }

    private var legend: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 7) { legendContent }
            VStack(alignment: .leading, spacing: 3) { legendContent }
        }
    }

    @ViewBuilder
    private var legendContent: some View {
        Text(strip.downDistanceText)
            .font(SportsTheme.Typography.statTable)
            .foregroundStyle(SportsTheme.Colors.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.76)
        Text(strip.yardLineText)
            .font(SportsTheme.Typography.statusPill)
            .foregroundStyle(SportsTheme.Colors.secondaryInk)
            .lineLimit(1)
            .minimumScaleFactor(0.76)
        if let possessionText = strip.possessionText?.nilIfBlank {
            Text(possessionText)
                .font(SportsTheme.Typography.statusPill)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
    }

    private func endZone(x: CGFloat, width: CGFloat) -> some View {
        Rectangle()
            .fill(SportsTheme.Colors.scorebookLine.opacity(0.14))
            .frame(width: width)
            .offset(x: x)
    }

    private func redZoneBand(geometry: FootballFieldStripGeometry) -> some View {
        Rectangle()
            .fill(SportsTheme.Tone.critical.accent.opacity(0.10))
            .frame(width: geometry.redZoneWidth)
            .offset(x: geometry.redZoneX)
    }

    private func midfieldLine(geometry: FootballFieldStripGeometry) -> some View {
        Rectangle()
            .fill(SportsTheme.Colors.scorebookLine.opacity(0.30))
            .frame(width: 1)
            .offset(x: geometry.xPosition(for: 50))
    }

    private func markerLine(x: CGFloat, color: Color, dash: [CGFloat]) -> some View {
        Path { path in
            path.move(to: CGPoint(x: x, y: 4))
            path.addLine(to: CGPoint(x: x, y: 30))
        }
        .stroke(color.opacity(0.78), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: dash))
    }

    private func ballMarker(x: CGFloat, y: CGFloat) -> some View {
        Capsule()
            .fill(accent)
            .frame(width: 10, height: 6)
            .rotationEffect(.degrees(-18))
            .position(x: x, y: y)
    }
}

private struct FootballFieldStripGeometry {
    let size: CGSize

    var leftEdgeX: CGFloat { 0 }
    var endZoneWidth: CGFloat { max(10, size.width * 0.09) }
    var rightEndZoneX: CGFloat { size.width - endZoneWidth }
    var redZoneWidth: CGFloat { max(18, size.width * 0.18) }
    var redZoneX: CGFloat { size.width - endZoneWidth - redZoneWidth }

    func xPosition(for fieldX: Double) -> CGFloat {
        let clamped = min(max(fieldX, 0), 100)
        return endZoneWidth + (size.width - endZoneWidth * 2) * CGFloat(clamped / 100)
    }
}
