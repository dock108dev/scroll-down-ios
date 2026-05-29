import SwiftUI

struct SituationSummaryPanel: View {
    let situation: GameEventSituationPresentation

    @Environment(\.sportsLayoutMetrics) private var layout
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if shouldShowSituationStrip {
                situationStrip
            }
            if let diagram = situation.diagram {
                diagramView(diagram)
            }
        }
        .padding(.leading, 8)
        .frame(maxWidth: diagramSizing.panelMaxWidth, alignment: .leading)
        .overlay(alignment: .leading) {
            Capsule()
                .fill(accent.opacity(0.42))
                .frame(width: 2)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func diagramView(_ diagram: GameEventSituationDiagram) -> some View {
        switch diagram {
        case .baseballDiamond(let baseball):
            BaseballDiamondSituationView(
                situation: baseball,
                accent: accent,
                scoreDelta: nil,
                fieldSide: diagramSizing.baseballFieldSide
            )
            .frame(
                width: diagramSizing.baseballFrame.width,
                height: diagramSizing.baseballFrame.height,
                alignment: .leading
            )
            .padding(.top, 1)
        case .footballFieldStrip(let football):
            FootballFieldStripView(
                strip: football,
                accent: accent
            )
            .frame(
                maxWidth: diagramSizing.pressureMaxWidth,
                minHeight: diagramSizing.pressureMinHeight,
                maxHeight: diagramSizing.pressureMaxHeight,
                alignment: .leading
            )
            .padding(.top, 1)
        case .hockeyRinkStrip(let hockey):
            HockeyRinkStripView(
                strip: hockey,
                accent: accent
            )
            .frame(
                maxWidth: diagramSizing.pressureMaxWidth,
                minHeight: diagramSizing.pressureMinHeight,
                maxHeight: diagramSizing.pressureMaxHeight,
                alignment: .leading
            )
            .padding(.top, 1)
        case .basketballHalfCourt(let basketball):
            BasketballHalfCourtPressureView(
                diagram: basketball,
                accent: accent
            )
            .frame(
                maxWidth: diagramSizing.pressureMaxWidth,
                minHeight: diagramSizing.pressureMinHeight,
                maxHeight: diagramSizing.pressureMaxHeight,
                alignment: .leading
            )
            .padding(.top, 1)
        case .soccerPitchStrip(let soccer):
            SoccerPitchStripView(
                diagram: soccer,
                accent: accent
            )
            .frame(
                maxWidth: diagramSizing.pressureMaxWidth,
                minHeight: diagramSizing.pressureMinHeight,
                maxHeight: diagramSizing.pressureMaxHeight,
                alignment: .leading
            )
            .padding(.top, 1)
        case .pressureBoardFallback(let pressureBoard):
            PressureBoardFallbackView(
                situation: pressureBoard,
                accent: accent,
                metricLimit: diagramSizing.pressureMetricLimit
            )
                .frame(
                    maxWidth: diagramSizing.pressureMaxWidth,
                    minHeight: diagramSizing.pressureMinHeight,
                    maxHeight: diagramSizing.pressureMaxHeight,
                    alignment: .leading
                )
                .padding(.top, 1)
        }
    }

    private var accent: Color {
        situation.accent.color
    }

    private var diagramSizing: SituationDiagramSizing {
        SituationDiagramSizing(layout: layout, dynamicTypeSize: dynamicTypeSize)
    }

    private var shouldShowSituationStrip: Bool {
        !(situation.sport == .baseball && situation.layout == .pressureBoardFallback)
    }

    private var situationStrip: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                stripContent(allowsWrapping: false)
            }
            VStack(alignment: .leading, spacing: 3) {
                stripContent(allowsWrapping: true)
            }
        }
    }

    @ViewBuilder
    private func stripContent(allowsWrapping: Bool) -> some View {
        if let periodText = situation.periodText?.nilIfBlank {
            Text(periodText)
                .font(SportsTheme.Typography.statusPill)
                .foregroundStyle(SportsTheme.Colors.ink)
                .lineLimit(allowsWrapping ? 2 : 1)
                .minimumScaleFactor(allowsWrapping ? 0.86 : 0.78)
                .fixedSize(horizontal: false, vertical: true)
        }
        if let ownership = situation.ownership {
            OwnershipLabel(ownership: ownership, accent: accent, allowsWrapping: allowsWrapping)
        }
        if let setupText = situation.setupText?.nilIfBlank {
            Text(setupText)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.ink)
                .lineLimit(allowsWrapping ? 2 : 1)
                .minimumScaleFactor(allowsWrapping ? 0.86 : 0.78)
                .fixedSize(horizontal: false, vertical: true)
        }
        if situation.sport != .baseball {
            if let pressureLine = PlayRowContentFilter.prePlaySituationText(situation.pressureLine) {
                Text(pressureLine)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(situation.accent.tone.accent)
                    .lineLimit(allowsWrapping ? 2 : 1)
                    .minimumScaleFactor(allowsWrapping ? 0.86 : 0.78)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let contextLine = PlayRowContentFilter.prePlaySituationText(situation.contextLine) {
                Text(contextLine)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    .lineLimit(allowsWrapping ? 2 : 1)
                    .minimumScaleFactor(allowsWrapping ? 0.86 : 0.78)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct OwnershipLabel: View {
    let ownership: GameEventSituationOwnership
    let accent: Color
    let allowsWrapping: Bool

    var body: some View {
        HStack(spacing: 5) {
            ownershipMarker
            Text(ownership.displayLabel)
                .font(SportsTheme.Typography.statusPill)
                .foregroundStyle(SportsTheme.Colors.ink)
                .lineLimit(allowsWrapping ? 2 : 1)
                .minimumScaleFactor(allowsWrapping ? 0.86 : 0.78)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var ownershipMarker: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(accent.opacity(0.24))
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(accent.opacity(0.42), lineWidth: 1)
            )
            .frame(width: 9, height: 9)
    }
}

private struct BaseballDiamondSituationView: View {
    let situation: BaseballSituationDiagram
    let accent: Color
    let scoreDelta: String?
    let fieldSide: CGFloat

    private var scorebook: BaseballScorebookNotation {
        BaseballScorebookNotation(
            outs: situation.outs,
            count: situation.count,
            scoreDelta: scoreDelta
        )
    }

    var body: some View {
        HStack(spacing: 7) {
            BaseballDiamondFieldView(situation: situation, accent: accent)
                .frame(width: fieldSide, height: fieldSide)
            if scorebook.hasEntries {
                BaseballScorebookStack(scorebook: scorebook, accent: accent)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}


private struct BaseballDiamondFieldView: View {
    let situation: BaseballSituationDiagram
    let accent: Color

    @ScaledMetric(relativeTo: .caption) private var baseSize: CGFloat = 11
    @ScaledMetric(relativeTo: .caption) private var homeSize: CGFloat = 9
    @ScaledMetric(relativeTo: .caption) private var moundSize: CGFloat = 5
    @ScaledMetric(relativeTo: .caption) private var lineWidth: CGFloat = 1

    var body: some View {
        GeometryReader { proxy in
            let geometry = BaseballDiamondGeometry(size: proxy.size)
            ZStack {
                geometry.infieldPath
                    .fill(SportsTheme.Colors.paperRaised.opacity(0.72))
                geometry.infieldPath
                    .stroke(SportsTheme.Stroke.subdued(SportsTheme.Colors.scorebookLine), lineWidth: resolvedLineWidth)
                Circle()
                    .fill(SportsTheme.Colors.scorebookLine.opacity(0.50))
                    .frame(width: geometry.resolvedMoundSize(moundSize), height: geometry.resolvedMoundSize(moundSize))
                    .position(geometry.mound)
                homePlate(size: geometry.resolvedHomeSize(homeSize))
                    .position(geometry.home)
                ForEach(BaseballBase.allCases, id: \.self) { base in
                    BaseballBaseMarker(
                        base: base,
                        occupied: situation.occupiedBases.contains(base),
                        accent: accent,
                        size: geometry.resolvedBaseSize(baseSize)
                    )
                    .position(geometry.point(for: base))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var resolvedLineWidth: CGFloat {
        min(max(lineWidth, 0.75), 1.5)
    }

    private func homePlate(size: CGFloat) -> some View {
        HomePlateShape()
            .fill(SportsTheme.Colors.paperRaised)
            .overlay(HomePlateShape().stroke(SportsTheme.Stroke.subdued(), lineWidth: SportsTheme.Stroke.standard))
            .frame(width: size, height: size)
    }
}

private struct BaseballBaseMarker: View {
    let base: BaseballBase
    let occupied: Bool
    let accent: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: max(1.5, size * 0.18), style: .continuous)
                .fill(occupied ? accent.opacity(0.70) : SportsTheme.Colors.paperRaised.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: max(1.5, size * 0.18), style: .continuous)
                        .stroke(occupied ? accent.opacity(0.54) : SportsTheme.Colors.scorebookLine.opacity(0.34), lineWidth: 1)
                )
                .rotationEffect(.degrees(45))
            if occupied {
                Text(base.shortLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(SportsTheme.Colors.textOnFill)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(width: size + 6, height: size + 6)
    }
}

private struct PressureBoardFallbackView: View {
    let situation: PressureBoardSituationDiagram
    let accent: Color
    let metricLimit: Int

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(displayMetrics.enumerated()), id: \.offset) { index, metric in
                if index > 0 {
                    SportsTheme.Colors.hairline.opacity(0.56)
                        .frame(height: 1)
                }
                PressureBoardMetricRow(metric: metric, accent: accent)
            }
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
        .accessibilityElement(children: .ignore)
        .accessibilityHidden(true)
    }

    private var displayMetrics: [PressureBoardSituationMetric] {
        if !situation.metrics.isEmpty {
            return Array(situation.metrics.prefix(metricLimit))
        }
        return situation.associations.prefix(2).map { ownership in
            PressureBoardSituationMetric(
                label: "Team",
                value: ownership.teamAbbreviation ?? ownership.teamLabel ?? ownership.role.displayName,
                emphasis: .team
            )
        }
    }
}

private struct PressureBoardMetricRow: View {
    let metric: PressureBoardSituationMetric
    let accent: Color

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 7) {
            Text(metric.label.uppercased())
                .font(SportsTheme.Typography.statusPill)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                .lineLimit(1)
                .minimumScaleFactor(labelMinimumScaleFactor)
                .allowsTightening(true)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: labelColumnWidth, alignment: .leading)
            Text(metric.value)
                .font(valueFont)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 0.86 : 0.72)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 22 : 18, alignment: .center)
    }

    private var labelColumnWidth: CGFloat {
        if AppEnvironment.isRunningUITests {
            return dynamicTypeSize.isAccessibilitySize ? 120 : 112
        }
        return dynamicTypeSize.isAccessibilitySize ? 72 : 64
    }

    private var labelMinimumScaleFactor: CGFloat {
        AppEnvironment.isRunningUITests ? 0.58 : 0.72
    }

    private var valueFont: Font {
        switch metric.emphasis {
        case .primary, .pressure:
            return SportsTheme.Typography.statTable
        case .team:
            return SportsTheme.Typography.teamAbbreviation
        case .secondary:
            return SportsTheme.Typography.statusPill
        }
    }

    private var valueColor: Color {
        switch metric.emphasis {
        case .team, .pressure:
            return accent
        case .primary:
            return SportsTheme.Colors.ink
        case .secondary:
            return SportsTheme.Colors.secondaryInk
        }
    }
}

private struct SituationDiagramSizing {
    let panelMaxWidth: CGFloat
    let baseballFrame: CGSize
    let baseballFieldSide: CGFloat
    let pressureMaxWidth: CGFloat
    let pressureMinHeight: CGFloat
    let pressureMaxHeight: CGFloat?
    let pressureMetricLimit: Int

    init(layout: SportsLayoutMetrics, dynamicTypeSize: DynamicTypeSize) {
        let readableWidth = layout.detailContentWidth
        let isReadable = readableWidth >= 600
        let isAccessibility = dynamicTypeSize.isAccessibilitySize

        panelMaxWidth = isReadable ? 420 : .infinity
        pressureMaxWidth = if isReadable {
            isAccessibility ? 320 : 280
        } else {
            isAccessibility ? 240 : 210
        }
        pressureMinHeight = isAccessibility ? 64 : 58
        pressureMaxHeight = isAccessibility ? nil : 92
        pressureMetricLimit = isAccessibility ? 3 : 4

        if isReadable {
            baseballFieldSide = isAccessibility ? 68 : 60
            baseballFrame = CGSize(width: isAccessibility ? 162 : 150, height: isAccessibility ? 76 : 68)
        } else {
            baseballFieldSide = isAccessibility ? 58 : 50
            baseballFrame = CGSize(width: isAccessibility ? 146 : 132, height: isAccessibility ? 66 : 58)
        }
    }
}

private struct BaseballDiamondGeometry {
    let rect: CGRect
    let home: CGPoint
    let mound: CGPoint
    let first: CGPoint
    let second: CGPoint
    let third: CGPoint

    init(size: CGSize) {
        let side = min(size.width, size.height)
        let originX = (size.width - side) / 2
        let originY = (size.height - side) / 2
        rect = CGRect(x: originX, y: originY, width: side, height: side)
        let center = CGPoint(x: rect.midX, y: rect.midY + side * 0.05)
        home = CGPoint(x: center.x, y: center.y + side * 0.31)
        mound = CGPoint(x: center.x, y: center.y + side * 0.05)
        first = CGPoint(x: center.x + side * 0.285, y: center.y + side * 0.035)
        second = CGPoint(x: center.x, y: center.y - side * 0.245)
        third = CGPoint(x: center.x - side * 0.285, y: center.y + side * 0.035)
    }

    var infieldPath: Path {
        Path { path in
            path.move(to: home)
            path.addLine(to: first)
            path.addLine(to: second)
            path.addLine(to: third)
            path.closeSubpath()
        }
    }

    func point(for base: BaseballBase) -> CGPoint {
        switch base {
        case .first:
            return first
        case .second:
            return second
        case .third:
            return third
        }
    }

    func resolvedBaseSize(_ baseSize: CGFloat) -> CGFloat {
        min(max(baseSize, rect.width * 0.12), rect.width * 0.20)
    }

    func resolvedHomeSize(_ homeSize: CGFloat) -> CGFloat {
        min(max(homeSize, rect.width * 0.13), rect.width * 0.20)
    }

    func resolvedMoundSize(_ moundSize: CGFloat) -> CGFloat {
        min(max(moundSize, rect.width * 0.07), rect.width * 0.11)
    }
}

private struct HomePlateShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.38))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.38))
        path.closeSubpath()
        return path
    }
}
