import SwiftUI

struct StatSectionList: View {
    let sections: [StatSectionPresentation]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sections) { section in
                if let title = section.title {
                    Text(title)
                        .font(SportsTheme.Typography.teamName)
                        .foregroundStyle(.secondary)
                }

                if let emptyMessage = section.emptyMessage {
                    UnavailableText(emptyMessage)
                }

                if !section.highlights.isEmpty {
                    StatHighlightGroup(highlights: section.highlights)
                }

                if let comparison = section.comparison {
                    TeamComparisonTable(comparison: comparison)
                }

                ForEach(section.tables) { table in
                    CompactStatTable(table: table)
                }

                ForEach(section.cards) { card in
                    StatCard(title: card.title, subtitle: card.subtitle) {
                        StatPills(items: card.items.map { ($0.label, $0.value) })
                    }
                }
            }
        }
    }
}

private struct StatHighlightGroup: View {
    let highlights: [StatHighlightPresentation]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Impact")
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)

            VStack(spacing: 6) {
                ForEach(highlights) { highlight in
                    StatHighlightRow(highlight: highlight)
                }
            }
        }
    }
}

private struct StatHighlightRow: View {
    let highlight: StatHighlightPresentation

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            SportsTeamRail(color: highlight.accentTone.accent)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let rank = highlight.rank {
                        Text("#\(rank)")
                            .font(SportsTheme.Typography.statusPill.monospacedDigit())
                            .foregroundStyle(highlight.accentTone.accent)
                    }
                    Text(highlight.title)
                        .font(SportsTheme.Typography.momentHeadline)
                        .foregroundStyle(SportsTheme.Colors.ink)
                        .lineLimit(1)
                    Text(highlight.subtitle)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }

                Text(highlight.headline)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .lineLimit(2)

                if !highlight.stats.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(highlight.stats) { stat in
                            HStack(spacing: 4) {
                                Text(stat.label)
                                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                                Text(stat.value)
                                    .foregroundStyle(highlight.accentTone.accent)
                                    .monospacedDigit()
                            }
                            .font(SportsTheme.Typography.statTable)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sportsSurface(.statSummary, accent: highlight.accentTone.accent)
    }
}

private struct TeamComparisonTable: View {
    let comparison: StatComparisonPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(comparison.title)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)

            Grid(alignment: .trailing, horizontalSpacing: 8, verticalSpacing: 0) {
                GridRow {
                    Text("")
                    ForEach(comparison.columns) { column in
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(column.title)
                                .font(SportsTheme.Typography.statTable)
                                .foregroundStyle(SportsTheme.Colors.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                            if let subtitle = column.subtitle {
                                Text(subtitle)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.vertical, 7)

                Divider().gridCellColumns(comparison.columns.count + 1)

                ForEach(Array(comparison.rows.enumerated()), id: \.element.id) { index, row in
                    GridRow {
                        Text(row.label)
                            .font(SportsTheme.Typography.statTable)
                            .foregroundStyle(SportsTheme.Colors.secondaryInk)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(comparison.columns) { column in
                            Text(row.values[column.id] ?? "-")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(SportsTheme.Colors.ink)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 7)
                    .background(index.isMultiple(of: 2) ? SportsTheme.Colors.paperInset.opacity(0.55) : Color.clear)

                    if index < comparison.rows.count - 1 {
                        Divider().gridCellColumns(comparison.columns.count + 1)
                    }
                }
            }
            .padding(.horizontal, 8)
            .background(SportsTheme.Colors.paper, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.row))
            .overlay(
                RoundedRectangle(cornerRadius: SportsTheme.Radius.row)
                    .stroke(SportsTheme.Stroke.subdued(), lineWidth: SportsTheme.Stroke.standard)
            )
        }
    }
}

private struct CompactStatTable: View {
    let table: StatTablePresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(table.title)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)

            WidthAwareContent(fallbackWidth: intrinsicContentWidth) { availableWidth in
                let metrics = statTableWidthMetrics(availableWidth: availableWidth)

                ScrollView(.horizontal, showsIndicators: metrics.requiresHorizontalScroll) {
                    LazyVStack(spacing: 0) {
                        tableHeader(metrics: metrics)
                        Divider()
                        ForEach(Array(table.rows.enumerated()), id: \.element.id) { index, row in
                            tableRow(row, isTinted: index.isMultiple(of: 2), metrics: metrics)
                            if index < table.rows.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .frame(width: metrics.contentWidth, alignment: .leading)
                    .background(SportsTheme.Colors.paper, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.row))
                    .overlay(
                        RoundedRectangle(cornerRadius: SportsTheme.Radius.row)
                            .stroke(SportsTheme.Stroke.subdued(), lineWidth: SportsTheme.Stroke.standard)
                    )
                }
            }
        }
    }

    private var intrinsicContentWidth: CGFloat {
        table.columns.reduce(CGFloat.zero) { partialResult, column in
            partialResult + column.width + Self.cellHorizontalPadding
        }
    }

    private func tableHeader(metrics: StatTableWidthMetrics) -> some View {
        HStack(spacing: 0) {
            ForEach(table.columns) { column in
                tableCell(column.label, column: column, isHeader: true, metrics: metrics)
            }
        }
        .padding(.vertical, 6)
    }

    private func tableRow(
        _ row: StatTableRowPresentation,
        isTinted: Bool,
        metrics: StatTableWidthMetrics
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(table.columns) { column in
                tableCell(row.values[column.id] ?? "-", column: column, isHeader: false, metrics: metrics)
            }
        }
        .padding(.vertical, 6)
        .background(isTinted ? SportsTheme.Colors.paperInset.opacity(0.55) : Color.clear)
    }

    private func tableCell(
        _ value: String,
        column: StatTableColumnPresentation,
        isHeader: Bool,
        metrics: StatTableWidthMetrics
    ) -> some View {
        Text(value)
            .font(isHeader ? SportsTheme.Typography.statTable : .caption)
            .foregroundStyle(isHeader ? SportsTheme.Colors.secondaryInk : SportsTheme.Colors.ink)
            .monospacedDigit()
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: metrics.columnWidths[column.id] ?? column.width, alignment: column.alignment.swiftUIAlignment)
            .padding(.horizontal, 6)
    }

    private func statTableWidthMetrics(availableWidth: CGFloat) -> StatTableWidthMetrics {
        let baseContentWidth = intrinsicContentWidth
        let primaryExpandableID = table.columns.first(where: { $0.alignment == .leading })?.id
        let allowedSlack = max(0, min(availableWidth - baseContentWidth, Self.maxTextExpansion))
        var columnWidths: [String: CGFloat] = [:]

        for column in table.columns {
            let resolvedWidth = if column.id == primaryExpandableID {
                min(column.width + allowedSlack, Self.maxTextColumnWidth)
            } else {
                column.width
            }
            columnWidths[column.id] = resolvedWidth
        }

        let resolvedContentWidth = table.columns.reduce(CGFloat.zero) { partialResult, column in
            partialResult + (columnWidths[column.id] ?? column.width) + Self.cellHorizontalPadding
        }

        return StatTableWidthMetrics(
            contentWidth: max(baseContentWidth, resolvedContentWidth),
            columnWidths: columnWidths,
            requiresHorizontalScroll: resolvedContentWidth > availableWidth + 0.5
        )
    }

    private static let cellHorizontalPadding: CGFloat = 12
    private static let maxTextExpansion: CGFloat = 96
    private static let maxTextColumnWidth: CGFloat = 220
}

private struct StatTableWidthMetrics {
    let contentWidth: CGFloat
    let columnWidths: [String: CGFloat]
    let requiresHorizontalScroll: Bool
}

private extension StatTableColumnAlignment {
    var swiftUIAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }
}
