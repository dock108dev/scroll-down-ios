import SwiftUI

struct TeamComparisonRowView: View {
    let stat: GameDetailViewModel.TeamComparisonStat
    let homeTeam: String
    let awayTeam: String

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            Text(stat.name)
                .font(.subheadline.weight(.semibold))

            HStack(spacing: Layout.barSpacing) {
                VStack(alignment: .leading, spacing: Layout.valueSpacing) {
                    Text(awayTeam)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ComparisonBar(value: stat.awayValue, maxValue: maxValue, alignment: .leading)
                    Text(stat.awayDisplay)
                        .font(.caption.weight(.semibold))
                }

                VStack(alignment: .trailing, spacing: Layout.valueSpacing) {
                    Text(homeTeam)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ComparisonBar(value: stat.homeValue, maxValue: maxValue, alignment: .trailing)
                    Text(stat.homeDisplay)
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(Layout.padding)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stat.name)
        .accessibilityValue("Away \(stat.awayDisplay), home \(stat.homeDisplay)")
    }

    private var maxValue: Double {
        max(stat.homeValue ?? 0, stat.awayValue ?? 0)
    }
}

private struct ComparisonBar: View {
    let value: Double?
    let maxValue: Double
    let alignment: Alignment

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let fill = barWidth(totalWidth: width)
            ZStack(alignment: alignment) {
                Capsule()
                    .fill(Color(.systemGray4))
                Capsule()
                    .fill(Color.blue)
                    .frame(width: fill)
            }
        }
        .frame(height: Layout.barHeight)
        .accessibilityHidden(true)
    }

    private func barWidth(totalWidth: CGFloat) -> CGFloat {
        guard let value, maxValue > 0 else {
            return totalWidth * Layout.fallbackRatio
        }
        let ratio = min(value / maxValue, 1)
        return totalWidth * ratio
    }
}

private enum Layout {
    static let spacing: CGFloat = 8
    static let barSpacing: CGFloat = 16
    static let valueSpacing: CGFloat = 6
    static let padding: CGFloat = 12
    static let cornerRadius: CGFloat = 12
    static let barHeight: CGFloat = 8
    static let fallbackRatio: CGFloat = 0.3
}

#Preview {
    TeamComparisonRowView(
        stat: GameDetailViewModel.TeamComparisonStat(
            name: "Field %",
            homeValue: 0.52,
            awayValue: 0.44,
            homeDisplay: "0.520",
            awayDisplay: "0.440"
        ),
        homeTeam: "Home",
        awayTeam: "Away"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
