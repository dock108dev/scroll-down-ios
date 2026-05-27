import SwiftUI

struct BasketballHalfCourtPressureView: View {
    let diagram: BasketballHalfCourtDiagram
    let accent: Color

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 8) {
            BasketballHalfCourtGlyph(diagram: diagram, accent: accent)
                .frame(width: dynamicTypeSize.isAccessibilitySize ? 74 : 66)
            VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? 4 : 2) {
                ForEach(Array(displayMetrics.enumerated()), id: \.offset) { _, metric in
                    BasketballMetricChip(metric: metric, accent: accent)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 6 : 5)
        .padding(.horizontal, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SportsTheme.Colors.paperRaised)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(accent.opacity(0.38))
                .frame(width: 2)
        }
        .overlay(
            RoundedRectangle(cornerRadius: SportsTheme.Radius.row, style: .continuous)
                .stroke(SportsTheme.Stroke.subdued(SportsTheme.Colors.scorebookLine), lineWidth: SportsTheme.Stroke.standard)
        )
        .clipShape(RoundedRectangle(cornerRadius: SportsTheme.Radius.row, style: .continuous))
    }

    private var displayMetrics: [BasketballMetric] {
        [
            BasketballMetric(label: "Ball", value: diagram.possessionText, isPressure: false),
            BasketballMetric(label: "Clock", value: diagram.shotClockText ?? diagram.clockText, isPressure: diagram.shotClockText != nil),
            BasketballMetric(label: "Score", value: diagram.scoreText, isPressure: true),
            BasketballMetric(label: "Bonus", value: diagram.bonusText ?? diagram.freeThrowText, isPressure: true),
            BasketballMetric(label: "Shot", value: diagram.shotText ?? diagram.locationText, isPressure: false)
        ]
        .filter { $0.value?.nilIfBlank != nil }
        .prefix(dynamicTypeSize.isAccessibilitySize ? 3 : 4)
        .map(\.self)
    }
}

private struct BasketballHalfCourtGlyph: View {
    let diagram: BasketballHalfCourtDiagram
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let side = min(rect.width, rect.height)
            let court = CGRect(
                x: rect.midX - side * 0.48,
                y: rect.midY - side * 0.40,
                width: side * 0.96,
                height: side * 0.80
            )
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(SportsTheme.Colors.paper.opacity(0.74))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(SportsTheme.Stroke.subdued(SportsTheme.Colors.scorebookLine), lineWidth: 1)
                    )
                    .frame(width: court.width, height: court.height)
                    .position(x: court.midX, y: court.midY)
                BasketballCourtLines(court: court)
                    .stroke(SportsTheme.Colors.scorebookLine.opacity(0.55), lineWidth: 1)
                Circle()
                    .fill(accent.opacity(0.82))
                    .frame(width: 8, height: 8)
                    .position(x: court.midX, y: court.maxY - 7)
                if let shotLocation = diagram.shotLocation {
                    ShotLocationMarker(label: shotLocation.label, accent: accent)
                        .position(
                            x: court.minX + court.width * shotLocation.x,
                            y: court.maxY - court.height * shotLocation.y
                        )
                }
            }
        }
    }
}

private struct BasketballCourtLines: Shape {
    let court: CGRect

    func path(in _: CGRect) -> Path {
        Path { path in
            let hoop = CGPoint(x: court.midX, y: court.maxY - 7)
            path.addEllipse(in: CGRect(x: hoop.x - 3, y: hoop.y - 3, width: 6, height: 6))
            path.addRect(CGRect(x: court.midX - court.width * 0.16, y: court.maxY - court.height * 0.32, width: court.width * 0.32, height: court.height * 0.32))
            path.addArc(
                center: hoop,
                radius: court.width * 0.34,
                startAngle: .degrees(205),
                endAngle: .degrees(335),
                clockwise: false
            )
            path.move(to: CGPoint(x: court.minX, y: court.midY))
            path.addLine(to: CGPoint(x: court.maxX, y: court.midY))
        }
    }
}

private struct ShotLocationMarker: View {
    let label: String?
    let accent: Color

    var body: some View {
        Circle()
            .fill(accent)
            .overlay(Circle().stroke(SportsTheme.Colors.textOnFill.opacity(0.86), lineWidth: 1))
            .frame(width: 9, height: 9)
            .accessibilityLabel(label ?? "Shot location")
    }
}

private struct BasketballMetricChip: View {
    let metric: BasketballMetric
    let accent: Color

    var body: some View {
        HStack(spacing: 5) {
            Text(metric.label.uppercased())
                .font(SportsTheme.Typography.statusPill)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                .frame(width: 34, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(metric.value ?? "")
                .font(metric.isPressure ? SportsTheme.Typography.statTable : SportsTheme.Typography.statusPill)
                .foregroundStyle(metric.isPressure ? accent : SportsTheme.Colors.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 14, alignment: .center)
    }
}

private struct BasketballMetric: Hashable {
    let label: String
    let value: String?
    let isPressure: Bool
}
