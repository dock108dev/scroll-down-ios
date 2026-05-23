import SwiftUI
import UIKit

enum SportsTheme {
    enum Colors {
        static let paper = adaptive(
            light: UIColor(red: 0.976, green: 0.961, blue: 0.922, alpha: 1),
            dark: UIColor(red: 0.071, green: 0.075, blue: 0.086, alpha: 1)
        )
        static let paperInset = adaptive(
            light: UIColor(red: 0.996, green: 0.988, blue: 0.961, alpha: 1),
            dark: UIColor(red: 0.103, green: 0.108, blue: 0.122, alpha: 1)
        )
        static let paperRaised = adaptive(
            light: UIColor(red: 1, green: 0.996, blue: 0.980, alpha: 1),
            dark: UIColor(red: 0.133, green: 0.138, blue: 0.157, alpha: 1)
        )
        static let ink = adaptive(
            light: UIColor(red: 0.051, green: 0.067, blue: 0.086, alpha: 1),
            dark: UIColor(red: 0.929, green: 0.925, blue: 0.890, alpha: 1)
        )
        static let secondaryInk = adaptive(
            light: UIColor(red: 0.329, green: 0.337, blue: 0.345, alpha: 1),
            dark: UIColor(red: 0.710, green: 0.702, blue: 0.659, alpha: 1)
        )
        static let hairline = adaptive(
            light: UIColor(red: 0.804, green: 0.776, blue: 0.710, alpha: 1),
            dark: UIColor(red: 0.263, green: 0.271, blue: 0.302, alpha: 1)
        )
        static let textOnFill = Color.white

        private static func adaptive(light: UIColor, dark: UIColor) -> Color {
            Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            })
        }
    }

    enum Typography {
        static let appTitle = Font.largeTitle.weight(.black)
        static let sectionTitle = Font.title3.weight(.bold)
        static let teamName = Font.headline.weight(.semibold)
        static let detailTeamName = Font.title3.weight(.bold)
        static let metadata = Font.caption.weight(.semibold)
        static let momentHeadline = Font.body.weight(.semibold)
        static let momentDetail = Font.body
        static let rawFeedText = Font.caption.monospaced()
        static let statTable = Font.caption.weight(.semibold)
        static let statusPill = Font.caption2.weight(.bold)
        static let leagueCode = Font.caption.weight(.black)
        static let teamAbbreviation = Font.subheadline.weight(.black)
    }

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 14
        static let section: CGFloat = 18
        static let badgeVertical: CGFloat = 3
        static let badgeHorizontal: CGFloat = 7
    }

    enum Radius {
        static let card: CGFloat = 8
        static let control: CGFloat = 7
        static let badge: CGFloat = 5
        static let rail: CGFloat = 2
        static let row: CGFloat = 6
    }

    enum Stroke {
        static let standard: CGFloat = 1

        static func accent(_ color: Color) -> Color {
            color.opacity(0.22)
        }

        static func subdued(_ color: Color = Colors.hairline) -> Color {
            color.opacity(0.72)
        }
    }

    enum Background {
        static var page: LinearGradient {
            LinearGradient(
                colors: [
                    Colors.paper,
                    Colors.paperInset,
                    Color(red: 0.922, green: 0.902, blue: 0.847).opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    enum Tone: String, CaseIterable {
        case live
        case final
        case pinned
        case scoring
        case critical
        case defensivePitching
        case neutral
        case newPlay
        case scoreboard

        var accent: Color {
            switch self {
            case .live:
                return Color(red: 0.760, green: 0.106, blue: 0.125)
            case .final:
                return Color(red: 0.176, green: 0.263, blue: 0.384)
            case .pinned:
                return Color(red: 0.365, green: 0.243, blue: 0.529)
            case .scoring:
                return Color(red: 0.706, green: 0.329, blue: 0.110)
            case .critical:
                return Color(red: 0.553, green: 0.145, blue: 0.125)
            case .defensivePitching:
                return Color(red: 0.168, green: 0.383, blue: 0.494)
            case .neutral:
                return Color(red: 0.408, green: 0.412, blue: 0.400)
            case .newPlay:
                return Color(red: 0.188, green: 0.314, blue: 0.612)
            case .scoreboard:
                return Color(red: 0.125, green: 0.157, blue: 0.220)
            }
        }

        var subtleFill: Color {
            accent.opacity(0.13)
        }
    }

    enum Team {
        private static let restrainedPalette: [Color] = [
            Color(red: 0.376, green: 0.463, blue: 0.224),
            Color(red: 0.741, green: 0.318, blue: 0.125),
            Color(red: 0.148, green: 0.390, blue: 0.511),
            Color(red: 0.178, green: 0.246, blue: 0.514),
            Color(red: 0.475, green: 0.251, blue: 0.541),
            Color(red: 0.560, green: 0.310, blue: 0.153)
        ]

        static func accent(for abbreviation: String?, fallback: Color = Tone.neutral.accent) -> Color {
            guard let abbreviation, !abbreviation.isEmpty else {
                return fallback
            }
            let total = abbreviation.uppercased().unicodeScalars.reduce(0) { $0 + Int($1.value) }
            return restrainedPalette[total % restrainedPalette.count]
        }
    }

    enum Surface {
        case gameCard
        case gameHeaderCard
        case eventCard
        case streamControlBar
        case scoreboardCard
        case statSummary
        case compactTableRow

        var background: Color {
            switch self {
            case .gameCard, .gameHeaderCard, .scoreboardCard:
                return Colors.paperRaised
            case .eventCard, .statSummary:
                return Colors.paperInset
            case .streamControlBar, .compactTableRow:
                return Colors.paper
            }
        }

        var padding: CGFloat {
            switch self {
            case .compactTableRow:
                return Spacing.small
            case .streamControlBar, .statSummary:
                return Spacing.medium
            default:
                return Spacing.large
            }
        }

        var radius: CGFloat {
            switch self {
            case .compactTableRow:
                return Radius.row
            case .streamControlBar:
                return Radius.control
            default:
                return Radius.card
            }
        }
    }
}

struct SportsBadge: View {
    let text: String
    let tone: SportsTheme.Tone
    var filled = true

    var body: some View {
        Text(text)
            .font(SportsTheme.Typography.statusPill)
            .foregroundStyle(filled ? SportsTheme.Colors.textOnFill : tone.accent)
            .padding(.vertical, SportsTheme.Spacing.badgeVertical)
            .padding(.horizontal, SportsTheme.Spacing.badgeHorizontal)
            .background(
                filled ? tone.accent : tone.subtleFill,
                in: RoundedRectangle(cornerRadius: SportsTheme.Radius.badge, style: .continuous)
            )
    }
}

struct SportsTeamRail: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: SportsTheme.Radius.rail, style: .continuous)
            .fill(color)
            .frame(width: 4)
            .padding(.vertical, 3)
    }
}

struct SportsCompactTableRow: View {
    let label: String
    let value: String
    var tone: SportsTheme.Tone = .neutral

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(SportsTheme.Colors.ink)
            Text(label)
                .font(SportsTheme.Typography.statTable)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
        }
        .sportsSurface(.compactTableRow, accent: tone.accent)
    }
}

private struct SportsSurfaceModifier: ViewModifier {
    let surface: SportsTheme.Surface
    let accent: Color?

    func body(content: Content) -> some View {
        content
            .padding(surface.padding)
            .background(
                surface.background,
                in: RoundedRectangle(cornerRadius: surface.radius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: surface.radius, style: .continuous)
                    .stroke(strokeColor, lineWidth: SportsTheme.Stroke.standard)
            )
    }

    private var strokeColor: Color {
        if let accent {
            return SportsTheme.Stroke.accent(accent)
        }
        return SportsTheme.Stroke.subdued()
    }
}

extension View {
    func sportsSurface(_ surface: SportsTheme.Surface, accent: Color? = nil) -> some View {
        modifier(SportsSurfaceModifier(surface: surface, accent: accent))
    }
}

@MainActor
enum SportsFeedback {
    static func selection() {
        guard !AppEnvironment.isRunningTests else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard !AppEnvironment.isRunningTests else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

struct SportsControlButtonStyle: ButtonStyle {
    let tone: SportsTheme.Tone
    var filled = false
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(compact ? SportsTheme.Typography.metadata : .subheadline.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.vertical, compact ? 7 : 9)
            .padding(.horizontal, compact ? 10 : 12)
            .background(backgroundColor(configuration: configuration), in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
                    .stroke(borderColor(configuration: configuration), lineWidth: SportsTheme.Stroke.standard)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        filled ? SportsTheme.Colors.textOnFill : tone.accent
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        let base = filled ? tone.accent : tone.subtleFill
        return configuration.isPressed ? base.opacity(filled ? 0.82 : 0.22) : base
    }

    private func borderColor(configuration: Configuration) -> Color {
        let base = filled ? tone.accent.opacity(0.0) : SportsTheme.Stroke.accent(tone.accent)
        return configuration.isPressed ? tone.accent.opacity(0.34) : base
    }
}

extension ButtonStyle where Self == SportsControlButtonStyle {
    static func sportsControl(
        tone: SportsTheme.Tone = .neutral,
        filled: Bool = false,
        compact: Bool = false
    ) -> SportsControlButtonStyle {
        SportsControlButtonStyle(tone: tone, filled: filled, compact: compact)
    }
}
