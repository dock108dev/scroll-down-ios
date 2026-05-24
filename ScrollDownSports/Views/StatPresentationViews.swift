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
        HStack(alignment: .top, spacing: 8) {
            if let rank = highlight.rank {
                Text("\(rank)")
                    .font(SportsTheme.Typography.statusPill.monospacedDigit())
                    .foregroundStyle(SportsTheme.Colors.textOnFill)
                    .frame(width: 20, height: 20)
                    .background(highlight.accentTone.accent, in: Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
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

private struct CompactStatTable: View {
    let table: StatTablePresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(table.title)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    tableHeader
                    Divider()
                    ForEach(Array(table.rows.enumerated()), id: \.element.id) { index, row in
                        tableRow(row, isTinted: index.isMultiple(of: 2))
                        if index < table.rows.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(SportsTheme.Colors.paper, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.row))
                .overlay(
                    RoundedRectangle(cornerRadius: SportsTheme.Radius.row)
                        .stroke(SportsTheme.Stroke.subdued(), lineWidth: SportsTheme.Stroke.standard)
                )
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            ForEach(table.columns) { column in
                tableCell(column.label, column: column, isHeader: true)
            }
        }
        .padding(.vertical, 6)
    }

    private func tableRow(_ row: StatTableRowPresentation, isTinted: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(table.columns) { column in
                tableCell(row.values[column.id] ?? "-", column: column, isHeader: false)
            }
        }
        .padding(.vertical, 6)
        .background(isTinted ? SportsTheme.Colors.paperInset.opacity(0.55) : Color.clear)
    }

    private func tableCell(
        _ value: String,
        column: StatTableColumnPresentation,
        isHeader: Bool
    ) -> some View {
        Text(value)
            .font(isHeader ? SportsTheme.Typography.statTable : .caption)
            .foregroundStyle(isHeader ? SportsTheme.Colors.secondaryInk : SportsTheme.Colors.ink)
            .monospacedDigit()
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: column.width, alignment: column.alignment.swiftUIAlignment)
            .padding(.horizontal, 6)
    }
}

private extension StatTableColumnAlignment {
    var swiftUIAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }
}
