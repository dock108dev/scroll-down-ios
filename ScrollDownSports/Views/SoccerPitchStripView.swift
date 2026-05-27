import SwiftUI

struct SoccerPitchStripView: View {
    let diagram: SoccerPitchStripDiagram
    let accent: Color

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 8) {
            SoccerPitchGlyph(diagram: diagram, accent: accent)
                .frame(width: dynamicTypeSize.isAccessibilitySize ? 88 : 78)
            VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? 4 : 2) {
                SoccerPitchMetric(label: "Restart", value: diagram.setPieceText, accent: accent, isPressure: true)
                if let location = diagram.locationText?.nilIfBlank {
                    SoccerPitchMetric(label: "Area", value: location, accent: accent, isPressure: false)
                }
                if let team = diagram.attackingTeamAbbreviation?.nilIfBlank {
                    SoccerPitchMetric(label: "Team", value: team, accent: accent, isPressure: false)
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
}

private struct SoccerPitchGlyph: View {
    let diagram: SoccerPitchStripDiagram
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let pitch = CGRect(x: 1, y: rect.midY - 21, width: rect.width - 2, height: 42)
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(SportsTheme.Colors.paper.opacity(0.74))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(SportsTheme.Stroke.subdued(SportsTheme.Colors.scorebookLine), lineWidth: 1)
                    )
                    .frame(width: pitch.width, height: pitch.height)
                    .position(x: pitch.midX, y: pitch.midY)
                SoccerPitchLines(pitch: pitch, highlightsGoalArea: diagram.highlightsGoalArea)
                    .stroke(SportsTheme.Colors.scorebookLine.opacity(0.58), lineWidth: 1)
                Circle()
                    .fill(accent)
                    .overlay(Circle().stroke(SportsTheme.Colors.textOnFill.opacity(0.86), lineWidth: 1))
                    .frame(width: 8, height: 8)
                    .position(ballPosition(in: pitch))
            }
        }
    }

    private func ballPosition(in pitch: CGRect) -> CGPoint {
        let x = diagram.ballX ?? 0.86
        let y = diagram.ballY ?? 0.50
        return CGPoint(
            x: pitch.minX + pitch.width * min(max(x, 0), 1),
            y: pitch.minY + pitch.height * min(max(y, 0), 1)
        )
    }
}

private struct SoccerPitchLines: Shape {
    let pitch: CGRect
    let highlightsGoalArea: Bool

    func path(in _: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: pitch.midX, y: pitch.minY))
            path.addLine(to: CGPoint(x: pitch.midX, y: pitch.maxY))
            path.addEllipse(in: CGRect(x: pitch.midX - 6, y: pitch.midY - 6, width: 12, height: 12))
            let box = CGRect(x: pitch.maxX - pitch.width * 0.22, y: pitch.midY - pitch.height * 0.30, width: pitch.width * 0.22, height: pitch.height * 0.60)
            path.addRect(box)
            if highlightsGoalArea {
                path.addRect(CGRect(x: pitch.maxX - pitch.width * 0.09, y: pitch.midY - pitch.height * 0.16, width: pitch.width * 0.09, height: pitch.height * 0.32))
            }
        }
    }
}

private struct SoccerPitchMetric: View {
    let label: String
    let value: String
    let accent: Color
    let isPressure: Bool

    var body: some View {
        HStack(spacing: 5) {
            Text(label.uppercased())
                .font(SportsTheme.Typography.statusPill)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                .frame(width: 46, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(value)
                .font(isPressure ? SportsTheme.Typography.statTable : SportsTheme.Typography.statusPill)
                .foregroundStyle(isPressure ? accent : SportsTheme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 14, alignment: .center)
    }
}
