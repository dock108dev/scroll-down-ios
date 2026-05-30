import SwiftUI

struct PressureBoardFallbackView: View {
    let situation: PressureBoardSituationDiagram
    let accent: Color
    let metricLimit: Int
    let suppressedMetricTexts: [String]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder
    var body: some View {
        if !displayMetrics.isEmpty {
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
    }

    private var displayMetrics: [PressureBoardSituationMetric] {
        if !situation.metrics.isEmpty {
            return Array(situation.metrics.filter(shouldShowMetric).prefix(metricLimit))
        }
        return situation.associations.prefix(2).map { ownership in
            PressureBoardSituationMetric(
                label: "Team",
                value: ownership.teamAbbreviation ?? ownership.teamLabel ?? ownership.role.displayName,
                emphasis: .team
            )
        }.filter(shouldShowMetric)
    }

    private func shouldShowMetric(_ metric: PressureBoardSituationMetric) -> Bool {
        suppressedMetricTexts.contains {
            PlayRowContentFilter.duplicatesMeaning(metric.value, comparedWith: $0)
                || PlayRowContentFilter.duplicatesMeaning($0, comparedWith: metric.value)
        } == false
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
