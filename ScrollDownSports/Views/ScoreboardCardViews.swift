import SwiftUI

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
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("Team")
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(presentation.segments) { segment in
                    Text(segment.label)
                        .frame(width: segmentColumnWidth, alignment: .trailing)
                }
                Text(presentation.totalHeader)
                    .frame(width: segmentColumnWidth, alignment: .trailing)
            }
            .font(SportsTheme.Typography.statusPill)
            .foregroundStyle(SportsTheme.Colors.secondaryInk)
            .padding(.bottom, 8)

            ForEach(Array(presentation.rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Divider()
                }
                HStack(spacing: 6) {
                    ScoreboardTeamLabel(row: row)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(presentation.segments) { segment in
                        Text(segment.values[row.side.scoreboardKey] ?? "-")
                            .font(SportsTheme.Typography.statTable)
                            .foregroundStyle(SportsTheme.Colors.ink)
                            .monospacedDigit()
                            .frame(width: segmentColumnWidth, alignment: .trailing)
                    }
                    Text(row.totalText)
                        .font(SportsTheme.Typography.teamName)
                        .foregroundStyle(SportsTheme.Colors.ink)
                        .monospacedDigit()
                        .frame(width: segmentColumnWidth, alignment: .trailing)
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var segmentColumnWidth: CGFloat {
        presentation.segments.count > 5 ? 26 : 34
    }
}

private struct SimpleScoreboard: View {
    let presentation: ScoreboardPresentation
    let emphasizesGoals: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(presentation.rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Divider()
                }
                HStack(spacing: 10) {
                    ScoreboardTeamLabel(row: row)
                    Spacer()
                    Text(row.totalText)
                        .font(emphasizesGoals ? .title.weight(.black) : .title2.weight(.bold))
                        .foregroundStyle(SportsTheme.Colors.ink)
                        .monospacedDigit()
                }
                .padding(.vertical, 9)
            }
        }
    }
}

private struct LeaderboardScoreboard: View {
    let presentation: ScoreboardPresentation

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Player")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(presentation.totalHeader)
                    .frame(width: 72, alignment: .trailing)
            }
            .font(SportsTheme.Typography.statusPill)
            .foregroundStyle(SportsTheme.Colors.secondaryInk)
            .padding(.bottom, 8)

            ForEach(Array(presentation.rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Divider()
                }
                HStack(spacing: 10) {
                    Text("\(index + 1)")
                        .font(SportsTheme.Typography.statusPill)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .frame(width: 24, alignment: .leading)
                    ScoreboardTeamLabel(row: row)
                    Spacer()
                    Text(row.totalText)
                        .font(SportsTheme.Typography.teamName)
                        .foregroundStyle(SportsTheme.Colors.ink)
                        .monospacedDigit()
                        .frame(width: 72, alignment: .trailing)
                }
                .padding(.vertical, 8)
            }
        }
    }
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
                        .font(.subheadline.weight(row.isWinner ? .bold : .semibold))
                        .foregroundStyle(SportsTheme.Colors.ink)
                    if row.isWinner {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(SportsTheme.Tone.scoreboard.accent)
                    }
                }
                if let recordText = row.recordText {
                    Text(recordText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                }
            }
            .lineLimit(2)
        }
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
