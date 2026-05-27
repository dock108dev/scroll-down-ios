import SwiftUI

struct HockeyRinkStripView: View {
    let strip: HockeyRinkStripDiagram
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            let geometry = HockeyRinkStripGeometry(size: proxy.size)
            ZStack {
                RoundedRectangle(cornerRadius: SportsTheme.Radius.row, style: .continuous)
                    .fill(SportsTheme.Colors.paperRaised)
                zoneHighlight(in: geometry)
                    .fill(accent.opacity(0.18))
                rinkLines(in: geometry)
                net(in: geometry)
                if let puckLocation = strip.puckLocation {
                    puck(location: puckLocation, in: geometry)
                }
                zoneLabel
                    .position(geometry.zoneLabelPoint(for: strip.zone))
            }
            .overlay(
                RoundedRectangle(cornerRadius: SportsTheme.Radius.row, style: .continuous)
                    .stroke(SportsTheme.Stroke.subdued(SportsTheme.Colors.scorebookLine), lineWidth: SportsTheme.Stroke.standard)
            )
            .clipShape(RoundedRectangle(cornerRadius: SportsTheme.Radius.row, style: .continuous))
        }
    }

    private func zoneHighlight(in geometry: HockeyRinkStripGeometry) -> Path {
        Path(geometry.zoneRect(for: strip.zone))
    }

    private func rinkLines(in geometry: HockeyRinkStripGeometry) -> some View {
        ZStack {
            Rectangle()
                .fill(SportsTheme.Colors.scorebookLine.opacity(0.28))
                .frame(width: 1)
                .position(x: geometry.centerX, y: geometry.midY)
            Rectangle()
                .fill(Color.blue.opacity(0.35))
                .frame(width: 1)
                .position(x: geometry.leftBlueLineX, y: geometry.midY)
            Rectangle()
                .fill(Color.blue.opacity(0.35))
                .frame(width: 1)
                .position(x: geometry.rightBlueLineX, y: geometry.midY)
            Capsule()
                .stroke(SportsTheme.Colors.scorebookLine.opacity(0.30), lineWidth: 1)
                .frame(width: geometry.centerCircleSide, height: geometry.centerCircleSide)
                .position(x: geometry.centerX, y: geometry.midY)
        }
    }

    private func net(in geometry: HockeyRinkStripGeometry) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(accent.opacity(0.28))
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(accent.opacity(0.56), lineWidth: 1)
            )
            .frame(width: 4, height: geometry.netHeight)
            .position(x: geometry.attackingNetX(for: strip.zone), y: geometry.midY)
    }

    private func puck(location: HockeyPuckLocation, in geometry: HockeyRinkStripGeometry) -> some View {
        Circle()
            .fill(SportsTheme.Colors.ink)
            .frame(width: 7, height: 7)
            .overlay(Circle().stroke(SportsTheme.Colors.paperRaised, lineWidth: 1))
            .position(geometry.puckPoint(for: location, zone: strip.zone))
    }

    private var zoneLabel: some View {
        Text(strip.attackingTeamAbbreviation?.nilIfBlank ?? strip.zone.label)
            .font(SportsTheme.Typography.statusPill)
            .foregroundStyle(accent)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
    }
}

private struct HockeyRinkStripGeometry {
    let rect: CGRect
    let midY: CGFloat
    let centerX: CGFloat
    let leftBlueLineX: CGFloat
    let rightBlueLineX: CGFloat
    let centerCircleSide: CGFloat
    let netHeight: CGFloat

    init(size: CGSize) {
        let insetRect = CGRect(origin: .zero, size: size).insetBy(dx: 6, dy: 7)
        rect = insetRect.width > 0 && insetRect.height > 0
            ? insetRect
            : CGRect(origin: .zero, size: size)
        midY = rect.midY
        centerX = rect.midX
        leftBlueLineX = rect.minX + rect.width * 0.33
        rightBlueLineX = rect.minX + rect.width * 0.67
        centerCircleSide = min(rect.height * 0.60, 26)
        netHeight = min(max(rect.height * 0.34, 14), 22)
    }

    func zoneRect(for zone: HockeyRinkZone) -> CGRect {
        switch zone {
        case .offensive:
            return CGRect(x: rightBlueLineX, y: rect.minY, width: rect.maxX - rightBlueLineX, height: rect.height)
        case .neutral:
            return CGRect(x: leftBlueLineX, y: rect.minY, width: rightBlueLineX - leftBlueLineX, height: rect.height)
        case .defensive:
            return CGRect(x: rect.minX, y: rect.minY, width: leftBlueLineX - rect.minX, height: rect.height)
        }
    }

    func attackingNetX(for zone: HockeyRinkZone) -> CGFloat {
        switch zone {
        case .offensive, .neutral:
            return rect.maxX - 4
        case .defensive:
            return rect.minX + 4
        }
    }

    func zoneLabelPoint(for zone: HockeyRinkZone) -> CGPoint {
        let zoneRect = zoneRect(for: zone)
        return CGPoint(x: zoneRect.midX, y: rect.minY + max(9, rect.height * 0.22))
    }

    func puckPoint(for location: HockeyPuckLocation, zone: HockeyRinkZone) -> CGPoint {
        let zoneRect = zoneRect(for: zone)
        let x: CGFloat
        let y: CGFloat
        switch location {
        case .slot:
            x = zoneRect.minX + zoneRect.width * 0.62
            y = midY
        case .highSlot:
            x = zoneRect.minX + zoneRect.width * 0.42
            y = midY
        case .leftCircle:
            x = zoneRect.minX + zoneRect.width * 0.48
            y = rect.minY + rect.height * 0.32
        case .rightCircle:
            x = zoneRect.minX + zoneRect.width * 0.48
            y = rect.maxY - rect.height * 0.32
        case .point:
            x = zoneRect.minX + zoneRect.width * 0.18
            y = midY
        case .crease:
            x = zone == .defensive ? zoneRect.minX + zoneRect.width * 0.18 : zoneRect.maxX - zoneRect.width * 0.18
            y = midY
        case .behindNet:
            x = zone == .defensive ? zoneRect.minX + zoneRect.width * 0.08 : zoneRect.maxX - zoneRect.width * 0.08
            y = midY
        }
        return CGPoint(x: x, y: y)
    }
}
