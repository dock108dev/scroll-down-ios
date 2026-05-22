import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 320
        let rows = makeRows(subviews: subviews, maxWidth: maxWidth)
        return CGSize(
            width: maxWidth,
            height: rows.reduce(CGFloat.zero) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * spacing
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = makeRows(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func makeRows(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if current.width + size.width + (current.items.isEmpty ? 0 : spacing) > maxWidth, !current.items.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.append(subview: subview, size: size, spacing: spacing)
        }

        if !current.items.isEmpty {
            rows.append(current)
        }

        return rows
    }

    private struct Row {
        var items: [Item] = []
        var width: CGFloat = 0
        var height: CGFloat = 0

        mutating func append(subview: LayoutSubview, size: CGSize, spacing: CGFloat) {
            if !items.isEmpty {
                width += spacing
            }
            items.append(Item(subview: subview, size: size))
            width += size.width
            height = max(height, size.height)
        }
    }

    private struct Item {
        let subview: LayoutSubview
        let size: CGSize
    }
}

