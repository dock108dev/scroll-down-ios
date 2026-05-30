import SwiftUI
import UIKit

enum SportsTheme {
    enum Colors {
        static let paper = SportsTheme.adaptiveColor(light: 0xF6F8FB, dark: 0x0B1220)
        static let paperInset = SportsTheme.adaptiveColor(light: 0xF1F4F8, dark: 0x1F2937)
        static let paperRaised = SportsTheme.adaptiveColor(light: 0xFFFFFF, dark: 0x111827)
        static let ink = SportsTheme.adaptiveColor(light: 0x111827, dark: 0xF9FAFB)
        static let secondaryInk = SportsTheme.adaptiveColor(light: 0x667085, dark: 0xD0D5DD)
        static let hairline = SportsTheme.adaptiveColor(light: 0xD8DEE8, dark: 0x344054)
        static let scorebookLine = SportsTheme.adaptiveColor(light: 0xD8DEE8, dark: 0x344054)
        static let textOnFill = SportsTheme.fixedColor(0xFFFFFF)
    }

    enum Typography {
        static let appTitle = Font.custom("Avenir Next Demi Bold", size: 22, relativeTo: .title2)
        static let sectionTitle = Font.custom("Avenir Next Demi Bold", size: 21, relativeTo: .title3)
        static let teamName = Font.custom("Avenir Next Demi Bold", size: 16, relativeTo: .headline)
        static let detailTeamName = Font.custom("Avenir Next Demi Bold", size: 16, relativeTo: .headline)
        static let metadata = Font.custom("Avenir Next Demi Bold", size: 11, relativeTo: .caption)
        static let momentHeadline = Font.custom("Avenir Next Demi Bold", size: 14, relativeTo: .subheadline)
        static let momentDetail = Font.custom("Avenir Next", size: 13, relativeTo: .subheadline)
        static let rawFeedText = Font.caption.monospaced()
        static let statTable = Font.custom("Avenir Next Demi Bold", size: 11, relativeTo: .caption)
        static let statusPill = Font.custom("Avenir Next Demi Bold", size: 11, relativeTo: .caption2)
        static let leagueCode = Font.custom("Avenir Next Condensed", size: 12, relativeTo: .caption).weight(.black)
        static let teamAbbreviation = Font.custom("DIN Alternate", size: 16, relativeTo: .subheadline).weight(.bold)
        static let scoreNumber = Font.custom("DIN Alternate", size: 19, relativeTo: .headline).weight(.bold)
    }

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 10
        static let large: CGFloat = 12
        static let section: CGFloat = 14
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
        static let darkWashAccent = SportsTheme.fixedColor(0x1F2937).opacity(0.62)
        static let lightPaperVeilOpacity = 0.34
        static let darkPaperVeilOpacity = 0.16

        static let wash = LinearGradient(
            colors: [
                Colors.paper,
                Colors.paperInset,
                SportsTheme.fixedColor(0xE9EEF5).opacity(0.42)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let darkWash = LinearGradient(
            colors: [
                Colors.paper,
                Colors.paperInset,
                darkWashAccent
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
                return SportsTheme.fixedColor(0xD92D20)
            case .final:
                return SportsTheme.fixedColor(0x475467)
            case .pinned:
                return SportsTheme.fixedColor(0x334155)
            case .scoring:
                return SportsTheme.fixedColor(0xB54708)
            case .critical:
                return SportsTheme.fixedColor(0xD92D20)
            case .defensivePitching:
                return SportsTheme.fixedColor(0x16835F)
            case .neutral:
                return SportsTheme.fixedColor(0x475467)
            case .newPlay:
                return SportsTheme.fixedColor(0x1D4ED8)
            case .scoreboard:
                return SportsTheme.fixedColor(0x0B1F3A)
            }
        }

        var foreground: Color {
            switch self {
            case .live:
                return SportsTheme.adaptiveColor(light: 0xD92D20, dark: 0xFDA29B)
            case .final:
                return SportsTheme.adaptiveColor(light: 0x475467, dark: 0xD0D5DD)
            case .pinned:
                return SportsTheme.adaptiveColor(light: 0x334155, dark: 0xCBD5E1)
            case .scoring:
                return SportsTheme.adaptiveColor(light: 0xB54708, dark: 0xFDB022)
            case .critical:
                return SportsTheme.adaptiveColor(light: 0xD92D20, dark: 0xFDA29B)
            case .defensivePitching:
                return SportsTheme.adaptiveColor(light: 0x16835F, dark: 0x75E0A7)
            case .neutral:
                return SportsTheme.adaptiveColor(light: 0x475467, dark: 0xD0D5DD)
            case .newPlay:
                return SportsTheme.adaptiveColor(light: 0x1D4ED8, dark: 0x84CAFF)
            case .scoreboard:
                return SportsTheme.adaptiveColor(light: 0x0B1F3A, dark: 0xE4E7EC)
            }
        }

        var subtleFill: Color {
            foreground.opacity(0.13)
        }

        var textOnAccent: Color {
            Colors.textOnFill
        }
    }

    enum Team {
        private static let restrainedPalette: [Color] = [
            SportsTheme.adaptiveColor(light: 0x334155, dark: 0xCBD5E1),
            SportsTheme.adaptiveColor(light: 0x475467, dark: 0xD0D5DD),
            SportsTheme.adaptiveColor(light: 0x667085, dark: 0xE4E7EC),
            SportsTheme.adaptiveColor(light: 0x1F2937, dark: 0xF9FAFB),
            SportsTheme.adaptiveColor(light: 0x344054, dark: 0xD8DEE8),
            SportsTheme.adaptiveColor(light: 0x64748B, dark: 0xB8C2CC)
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
            case .eventCard:
                return Colors.paperRaised
            case .statSummary, .streamControlBar, .compactTableRow:
                return Colors.paperInset
            }
        }

        var padding: CGFloat {
            switch self {
            case .compactTableRow:
                return Spacing.small
            case .streamControlBar, .statSummary:
                return Spacing.medium
            default:
                return Spacing.medium
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

    private static func adaptiveColor(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? uiColor(hex: dark) : uiColor(hex: light)
        })
    }

    private static func fixedColor(_ hex: UInt32) -> Color {
        Color(uiColor: uiColor(hex: hex))
    }

    private static func uiColor(hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

struct SportsPageBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        backgroundWash
            .overlay {
                paperVeilColor
            }
    }

    private var backgroundWash: LinearGradient {
        usesRegularWidthDarkTreatment ? SportsTheme.Background.darkWash : SportsTheme.Background.wash
    }

    private var paperVeilColor: Color {
        SportsTheme.Colors.paper.opacity(
            usesRegularWidthDarkTreatment
                ? SportsTheme.Background.darkPaperVeilOpacity
                : SportsTheme.Background.lightPaperVeilOpacity
        )
    }

    private var usesRegularWidthDarkTreatment: Bool {
        colorScheme == .dark && horizontalSizeClass == .regular
    }
}

struct SportsBadge: View {
    let text: String
    let tone: SportsTheme.Tone
    var filled = true

    var body: some View {
        Text(text)
            .font(SportsTheme.Typography.statusPill)
            .foregroundStyle(filled ? tone.textOnAccent : tone.foreground)
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

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(SportsTheme.Colors.ink)
            Text(label)
                .font(SportsTheme.Typography.statTable)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
        }
        .sportsSurface(.compactTableRow)
    }
}

private struct SportsSurfaceModifier: ViewModifier {
    let surface: SportsTheme.Surface
    let accent: Color?
    let usesAccentStroke: Bool

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
        if usesAccentStroke, let accent {
            return SportsTheme.Stroke.accent(accent)
        }
        return SportsTheme.Stroke.subdued()
    }
}

extension View {
    func sportsSurface(
        _ surface: SportsTheme.Surface,
        accent: Color? = nil,
        usesAccentStroke: Bool = false
    ) -> some View {
        modifier(SportsSurfaceModifier(surface: surface, accent: accent, usesAccentStroke: usesAccentStroke))
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
            .padding(.vertical, compact ? 5 : 8)
            .padding(.horizontal, compact ? 10 : 12)
            .frame(minWidth: 44, minHeight: compact ? 34 : 42)
            .background(backgroundColor(configuration: configuration), in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
                    .stroke(borderColor(configuration: configuration), lineWidth: SportsTheme.Stroke.standard)
            )
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        filled ? tone.textOnAccent : tone.foreground
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        let base = filled ? tone.accent : tone.subtleFill
        return configuration.isPressed ? base.opacity(filled ? 0.82 : 0.22) : base
    }

    private func borderColor(configuration: Configuration) -> Color {
        if filled {
            return configuration.isPressed ? tone.accent.opacity(0.34) : tone.accent.opacity(0.0)
        }
        return configuration.isPressed ? tone.accent.opacity(0.34) : SportsTheme.Stroke.subdued()
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
