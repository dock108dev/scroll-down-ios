import SwiftUI

struct BaseballScorebookNotation: Equatable {
    let outs: Int?
    let count: String?
    let scoreDelta: String?

    init(outs: Int?, count: String?, scoreDelta: String?) {
        self.outs = Self.normalizedOuts(outs)
        self.count = Self.normalizedCount(count)
        self.scoreDelta = scoreDelta?.nilIfBlank
    }

    var hasEntries: Bool {
        outs != nil || count != nil || scoreDelta != nil
    }

    static func normalizedOuts(_ raw: Int?) -> Int? {
        guard let raw, (0...2).contains(raw) else { return nil }
        return raw
    }

    static func normalizedCount(_ raw: String?) -> String? {
        guard let raw = raw?.nilIfBlank else { return nil }
        let parts = raw.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let balls = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let strikes = Int(parts[1].trimmingCharacters(in: .whitespaces)),
              (0...3).contains(balls),
              (0...2).contains(strikes) else {
            return nil
        }
        return "\(balls)-\(strikes)"
    }

    static func scoreDelta(from contextLine: String?) -> String? {
        guard let contextLine = contextLine?.nilIfBlank else { return nil }
        let sides = contextLine.replacingOccurrences(of: "→", with: "->")
            .components(separatedBy: "->")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard sides.count == 2,
              let before = BaseballLeadState(raw: sides[0]),
              let after = BaseballLeadState(raw: sides[1]) else {
            return nil
        }
        if before.margin == 0 {
            if after.margin > 0 { return "UP \(after.margin)" }
            if after.margin < 0 { return "DN \(abs(after.margin))" }
            return nil
        }
        let delta = after.margin - before.margin
        return delta > 0 ? "+\(delta)" : nil
    }
}

struct BaseballScorebookStack: View {
    let scorebook: BaseballScorebookNotation
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let outs = scorebook.outs {
                BaseballOutSlots(outs: outs, accent: accent)
            }
            if let count = scorebook.count {
                BaseballNotationText(text: count, foreground: SportsTheme.Colors.ink)
            }
            if let scoreDelta = scorebook.scoreDelta {
                BaseballNotationText(text: scoreDelta, foreground: accent)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .frame(width: 56, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .leading)
        .background(SportsTheme.Colors.paperInset)
        .overlay(
            RoundedRectangle(cornerRadius: SportsTheme.Radius.badge, style: .continuous)
                .stroke(SportsTheme.Stroke.subdued(SportsTheme.Colors.scorebookLine), lineWidth: SportsTheme.Stroke.standard)
        )
        .clipShape(RoundedRectangle(cornerRadius: SportsTheme.Radius.badge, style: .continuous))
    }
}

private struct BaseballOutSlots: View {
    let outs: Int
    let accent: Color

    @ScaledMetric(relativeTo: .caption2) private var dotSize: CGFloat = 6

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < outs ? accent.opacity(0.76) : SportsTheme.Colors.paperRaised)
                    .overlay(
                        Circle()
                            .stroke(
                                index < outs ? accent.opacity(0.58) : SportsTheme.Colors.scorebookLine.opacity(0.48),
                                lineWidth: SportsTheme.Stroke.standard
                            )
                    )
                    .frame(width: dotSize, height: dotSize)
            }
        }
    }
}

private struct BaseballNotationText: View {
    let text: String
    let foreground: Color

    var body: some View {
        Text(text)
            .font(SportsTheme.Typography.statTable)
            .foregroundStyle(foreground)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.72)
    }
}

private struct BaseballLeadState: Equatable {
    let margin: Int

    init?(raw: String) {
        let normalized = raw.lowercased()
            .replacingOccurrences(of: "lead", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized == "tied" || normalized == "tie" {
            margin = 0
            return
        }
        let parts = normalized.split(separator: " ")
        guard parts.count == 2, let value = Int(parts[1]) else { return nil }
        switch parts[0] {
        case "up":
            margin = value
        case "down", "dn":
            margin = -value
        default:
            return nil
        }
    }
}
