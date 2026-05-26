import SwiftUI

func scoreboardReachViewportFrame(
    width: CGFloat,
    height: CGFloat,
    obscuredBottomHeight: CGFloat = 0
) -> CGRect {
    CGRect(
        x: 0,
        y: 0,
        width: width,
        height: max(0, height - max(0, obscuredBottomHeight))
    )
}

func hasScoreboardEnteredViewport(
    itemFrame: CGRect,
    viewportFrame: CGRect,
    minimumVisiblePoints: CGFloat = 48,
    minimumVisibleRatio: CGFloat = 0.25
) -> Bool {
    guard itemFrame.height > 0 else { return false }
    let visibleHeight = max(
        0,
        min(itemFrame.maxY, viewportFrame.maxY) - max(itemFrame.minY, viewportFrame.minY)
    )
    let requiredVisibleHeight = min(minimumVisiblePoints, itemFrame.height * minimumVisibleRatio)
    return visibleHeight >= requiredVisibleHeight
}

struct ScoreboardCardHeader: View {
    let presentation: ScoreboardPresentation

    var body: some View {
        HStack(spacing: 8) {
            SportsBadge(text: presentation.stateText ?? "Result", tone: .scoreboard)
            Spacer()
            Text(presentation.totalHeader)
                .font(SportsTheme.Typography.statusPill)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
        }
    }
}

struct ScoreboardContent: View {
    let presentation: ScoreboardPresentation

    var body: some View {
        Group {
            switch presentation.layout {
            case .leaderboard:
                LeaderboardScoreboard(presentation: presentation)
            case .segmentTable:
                SegmentScoreboard(presentation: presentation)
            case .soccerSummary:
                SimpleScoreboard(presentation: presentation, emphasizesGoals: true)
            case .simpleTotal:
                SimpleScoreboard(presentation: presentation, emphasizesGoals: false)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        [
            presentation.stateText,
            presentation.rows.map { row in
                var pieces = ["\(row.title) \(row.totalText)"]
                if row.isWinner {
                    pieces.append("winner")
                }
                if let record = row.recordText {
                    pieces.append(record)
                }
                return pieces.joined(separator: ", ")
            }.joined(separator: ". ")
        ]
        .compactMap { $0?.nilIfBlank }
        .joined(separator: ". ")
    }
}

private struct SegmentScoreboard: View {
    let presentation: ScoreboardPresentation

    var body: some View {
        ScoreboardWidthAwareContent(fallbackWidth: fallbackContentWidth) { availableWidth in
            let metrics = segmentScoreboardMetrics(availableWidth: availableWidth)

            ScrollView(.horizontal, showsIndicators: metrics.requiresHorizontalScroll) {
                VStack(spacing: 0) {
                    HStack(spacing: Self.columnSpacing) {
                        Text("Team")
                            .frame(width: metrics.teamColumnWidth, alignment: .leading)
                        ForEach(presentation.segments) { segment in
                            Text(segment.label)
                                .frame(width: metrics.numericColumnWidth, alignment: .trailing)
                        }
                        Text(presentation.totalHeader)
                            .frame(width: metrics.numericColumnWidth, alignment: .trailing)
                    }
                    .font(SportsTheme.Typography.statusPill)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    .padding(.bottom, 6)

                    ForEach(Array(presentation.rows.enumerated()), id: \.element.id) { index, row in
                        if index > 0 {
                            Divider()
                        }
                        HStack(spacing: Self.columnSpacing) {
                            ScoreboardTeamLabel(row: row)
                                .frame(width: metrics.teamColumnWidth, alignment: .leading)
                            ForEach(presentation.segments) { segment in
                                Text(segment.values[row.side.scoreboardKey] ?? "-")
                                    .font(SportsTheme.Typography.statTable)
                                    .foregroundStyle(SportsTheme.Colors.ink)
                                    .monospacedDigit()
                                    .frame(width: metrics.numericColumnWidth, alignment: .trailing)
                            }
                            Text(row.totalText)
                                .font(SportsTheme.Typography.scoreNumber)
                                .foregroundStyle(SportsTheme.Colors.ink)
                                .monospacedDigit()
                                .frame(width: metrics.numericColumnWidth, alignment: .trailing)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .frame(width: metrics.contentWidth, alignment: .leading)
            }
        }
    }

    private var fallbackContentWidth: CGFloat {
        let numericColumnCount = presentation.segments.count + 1
        return Self.minimumTeamWidth
            + CGFloat(numericColumnCount) * Self.minimumNumericColumnWidth
            + CGFloat(numericColumnCount) * Self.columnSpacing
    }

    private func segmentScoreboardMetrics(availableWidth: CGFloat) -> SegmentScoreboardMetrics {
        let segmentCount = presentation.segments.count
        let numericColumnCount = segmentCount + 1
        let spacingWidth = CGFloat(numericColumnCount) * Self.columnSpacing
        let comfortableNumericWidth: CGFloat = segmentCount > 5 ? 28 : 34
        let minimumContentWidth = Self.minimumTeamWidth
            + CGFloat(numericColumnCount) * Self.minimumNumericColumnWidth
            + spacingWidth
        let cappedAvailableWidth = min(max(availableWidth, 0), Self.maximumContentWidth)

        if cappedAvailableWidth < minimumContentWidth {
            return SegmentScoreboardMetrics(
                contentWidth: minimumContentWidth,
                teamColumnWidth: Self.minimumTeamWidth,
                numericColumnWidth: Self.minimumNumericColumnWidth,
                requiresHorizontalScroll: true
            )
        }

        let comfortableFixedWidth = CGFloat(numericColumnCount) * comfortableNumericWidth + spacingWidth
        let rawTeamWidth = cappedAvailableWidth - comfortableFixedWidth

        if rawTeamWidth >= Self.minimumTeamWidth {
            let teamWidth = min(rawTeamWidth, Self.maximumTeamWidth)
            let contentWidth = teamWidth + CGFloat(numericColumnCount) * comfortableNumericWidth + spacingWidth
            return SegmentScoreboardMetrics(
                contentWidth: contentWidth,
                teamColumnWidth: teamWidth,
                numericColumnWidth: comfortableNumericWidth,
                requiresHorizontalScroll: false
            )
        }

        let availableForNumeric = cappedAvailableWidth - Self.minimumTeamWidth - spacingWidth
        let numericWidth = max(
            Self.minimumNumericColumnWidth,
            min(comfortableNumericWidth, floor(availableForNumeric / CGFloat(numericColumnCount)))
        )
        let contentWidth = Self.minimumTeamWidth + CGFloat(numericColumnCount) * numericWidth + spacingWidth

        return SegmentScoreboardMetrics(
            contentWidth: contentWidth,
            teamColumnWidth: Self.minimumTeamWidth,
            numericColumnWidth: numericWidth,
            requiresHorizontalScroll: false
        )
    }

    private static let columnSpacing: CGFloat = 6
    private static let minimumTeamWidth: CGFloat = 96
    private static let maximumTeamWidth: CGFloat = 240
    private static let minimumNumericColumnWidth: CGFloat = 24
    private static let maximumContentWidth: CGFloat = 460
}

private struct SimpleScoreboard: View {
    let presentation: ScoreboardPresentation
    let emphasizesGoals: Bool

    var body: some View {
        ScoreboardWidthAwareContent(fallbackWidth: Self.minimumContentWidth) { availableWidth in
            let contentWidth = simpleScoreboardWidth(availableWidth: availableWidth)

            VStack(spacing: 0) {
                ForEach(Array(presentation.rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        Divider()
                    }
                    HStack(spacing: 10) {
                        ScoreboardTeamLabel(row: row)
                        Spacer(minLength: 12)
                        Text(row.totalText)
                            .font(SportsTheme.Typography.scoreNumber)
                            .foregroundStyle(SportsTheme.Colors.ink)
                            .monospacedDigit()
                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .padding(.vertical, 7)
                }
            }
        }
    }

    private func simpleScoreboardWidth(availableWidth: CGFloat) -> CGFloat {
        max(Self.minimumContentWidth, min(availableWidth, Self.maximumContentWidth))
    }

    private static let minimumContentWidth: CGFloat = 220
    private static let maximumContentWidth: CGFloat = 360
}

private struct LeaderboardScoreboard: View {
    let presentation: ScoreboardPresentation

    var body: some View {
        ScoreboardWidthAwareContent(fallbackWidth: Self.minimumContentWidth) { availableWidth in
            let metrics = leaderboardScoreboardMetrics(availableWidth: availableWidth)

            ScrollView(.horizontal, showsIndicators: metrics.requiresHorizontalScroll) {
                VStack(spacing: 0) {
                    HStack(spacing: Self.columnSpacing) {
                        Text("Player")
                            .frame(
                                width: Self.rankColumnWidth + Self.columnSpacing + metrics.playerColumnWidth,
                                alignment: .leading
                            )
                        Text(presentation.totalHeader)
                            .frame(width: Self.totalColumnWidth, alignment: .trailing)
                    }
                    .font(SportsTheme.Typography.statusPill)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    .padding(.bottom, 6)

                    ForEach(Array(presentation.rows.enumerated()), id: \.element.id) { index, row in
                        if index > 0 {
                            Divider()
                        }
                        HStack(spacing: Self.columnSpacing) {
                            Text("\(index + 1)")
                                .font(SportsTheme.Typography.statusPill)
                                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                                .frame(width: Self.rankColumnWidth, alignment: .leading)
                            ScoreboardTeamLabel(row: row)
                                .frame(width: metrics.playerColumnWidth, alignment: .leading)
                            Text(row.totalText)
                                .font(SportsTheme.Typography.scoreNumber)
                                .foregroundStyle(SportsTheme.Colors.ink)
                                .monospacedDigit()
                                .frame(width: Self.totalColumnWidth, alignment: .trailing)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .frame(width: metrics.contentWidth, alignment: .leading)
            }
        }
    }

    private func leaderboardScoreboardMetrics(availableWidth: CGFloat) -> LeaderboardScoreboardMetrics {
        let contentWidth = max(Self.minimumContentWidth, min(availableWidth, Self.maximumContentWidth))
        let playerColumnWidth = contentWidth
            - Self.rankColumnWidth
            - Self.totalColumnWidth
            - Self.columnSpacing * 2
        return LeaderboardScoreboardMetrics(
            contentWidth: contentWidth,
            playerColumnWidth: playerColumnWidth,
            requiresHorizontalScroll: availableWidth < Self.minimumContentWidth
        )
    }

    private static let minimumContentWidth: CGFloat = 280
    private static let maximumContentWidth: CGFloat = 420
    private static let rankColumnWidth: CGFloat = 24
    private static let totalColumnWidth: CGFloat = 72
    private static let columnSpacing: CGFloat = 10
}

private struct ScoreboardTeamLabel: View {
    let row: ScoreboardRowPresentation

    var body: some View {
        HStack(spacing: 8) {
            Text(row.abbreviation ?? row.title)
                .font(SportsTheme.Typography.statusPill)
                .foregroundStyle(SportsTheme.Team.accent(for: row.abbreviation, fallback: SportsTheme.Tone.scoreboard.accent))
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(
                    SportsTheme.Team.accent(for: row.abbreviation, fallback: SportsTheme.Tone.scoreboard.accent).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: SportsTheme.Radius.badge, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(row.title)
                        .font(SportsTheme.Typography.momentHeadline.weight(row.isWinner ? .bold : .semibold))
                        .foregroundStyle(SportsTheme.Colors.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if row.isWinner {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(SportsTheme.Tone.scoreboard.accent)
                    }
                }
                if let recordText = row.recordText {
                    Text(recordText)
                        .font(SportsTheme.Typography.statusPill)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SegmentScoreboardMetrics {
    let contentWidth: CGFloat
    let teamColumnWidth: CGFloat
    let numericColumnWidth: CGFloat
    let requiresHorizontalScroll: Bool
}

private struct LeaderboardScoreboardMetrics {
    let contentWidth: CGFloat
    let playerColumnWidth: CGFloat
    let requiresHorizontalScroll: Bool
}

private struct ScoreboardWidthAwareContent<Content: View>: View {
    @State private var measuredWidth: CGFloat = 0

    let fallbackWidth: CGFloat
    private let content: (CGFloat) -> Content

    init(fallbackWidth: CGFloat, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.fallbackWidth = fallbackWidth
        self.content = content
    }

    var body: some View {
        content(measuredWidth > 0 ? measuredWidth : fallbackWidth)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ScoreboardAvailableWidthPreferenceKey.self, value: proxy.size.width)
                }
            }
            .onPreferenceChange(ScoreboardAvailableWidthPreferenceKey.self) { measuredWidth = $0 }
    }
}

private struct ScoreboardAvailableWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension GameParticipantRole {
    var scoreboardKey: String {
        switch self {
        case .away:
            return "away"
        case .home:
            return "home"
        case .other(let value):
            return value
        }
    }
}
