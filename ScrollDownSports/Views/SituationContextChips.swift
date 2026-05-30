import SwiftUI

struct SituationContextChip: Hashable {
    enum Tone {
        case period
        case ownership
        case state
        case pressure
        case context
    }

    let text: String
    let tone: Tone
    let showsMarker: Bool
}

struct SituationContextChipRow: View {
    let chips: [SituationContextChip]
    let accent: Color

    var body: some View {
        FlowLayout(spacing: 5) {
            ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                SituationContextChipView(chip: chip, accent: accent)
            }
        }
    }
}

private struct SituationContextChipView: View {
    let chip: SituationContextChip
    let accent: Color

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 4) {
            if chip.showsMarker {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accent.opacity(0.30))
                    .frame(width: 8, height: 8)
            }
            Text(chip.text)
                .font(font)
                .foregroundStyle(foreground)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 0.86 : 0.74)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 4 : 3)
        .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? 220 : 180, alignment: .leading)
        .background(background, in: Capsule())
        .overlay(Capsule().strokeBorder(border, lineWidth: 1))
    }

    private var font: Font {
        switch chip.tone {
        case .period, .ownership, .pressure:
            return SportsTheme.Typography.statusPill
        case .state, .context:
            return SportsTheme.Typography.metadata
        }
    }

    private var foreground: Color {
        switch chip.tone {
        case .ownership, .pressure:
            return accent
        case .context:
            return SportsTheme.Colors.secondaryInk
        case .period, .state:
            return SportsTheme.Colors.ink
        }
    }

    private var background: Color {
        switch chip.tone {
        case .ownership, .pressure:
            return accent.opacity(0.10)
        default:
            return SportsTheme.Colors.paperRaised.opacity(0.72)
        }
    }

    private var border: Color {
        switch chip.tone {
        case .ownership, .pressure:
            return accent.opacity(0.30)
        default:
            return SportsTheme.Colors.hairline.opacity(0.64)
        }
    }
}

enum SituationContextChipBuilder {
    static func chips(for situation: GameEventSituationPresentation) -> [SituationContextChip] {
        var chips: [SituationContextChip] = []
        append(periodText(for: situation), tone: .period, to: &chips)
        append(situation.ownership?.displayLabel, tone: .ownership, showsMarker: true, to: &chips)
        appendSetupChips(for: situation, to: &chips)
        if situation.sport != .baseball {
            append(PlayRowContentFilter.prePlaySituationText(situation.pressureLine), tone: .pressure, to: &chips)
            append(PlayRowContentFilter.prePlaySituationText(situation.contextLine), tone: .context, to: &chips)
        }
        return deduplicated(chips)
    }

    private static func appendSetupChips(
        for situation: GameEventSituationPresentation,
        to chips: inout [SituationContextChip]
    ) {
        if case .baseballDiamond(let diagram) = situation.diagram {
            append(baseStateLabel(for: diagram.occupiedBases), tone: .state, to: &chips)
            append(diagram.outs.map { $0 == 1 ? "1 out" : "\($0) outs" }, tone: .state, to: &chips)
            append(diagram.count.map { "\($0) count" }, tone: .state, to: &chips)
            return
        }
        if case .footballFieldStrip(let diagram) = situation.diagram {
            append(diagram.downDistanceText, tone: .state, to: &chips)
            append(diagram.yardLineText, tone: .state, to: &chips)
            if diagram.isRedZone {
                append("Red zone", tone: .pressure, to: &chips)
            }
            return
        }
        for part in setupParts(for: situation.setupText) {
            append(part, tone: .state, to: &chips)
        }
    }

    private static func periodText(for situation: GameEventSituationPresentation) -> String? {
        guard let text = situation.periodText?.nilIfBlank else { return nil }
        if situation.sport == .baseball,
           let firstToken = text.split(separator: " ").first,
           firstToken.count >= 2,
           ["T", "B"].contains(String(firstToken.prefix(1))) {
            return String(firstToken)
        }
        return text
    }

    private static func setupParts(for text: String?) -> [String] {
        guard let text = text?.nilIfBlank else { return [] }
        let separators = [" · ", " • ", " | "]
        for separator in separators where text.contains(separator) {
            return text.components(separatedBy: separator).compactMap(\.nilIfBlank)
        }
        return [text]
    }

    private static func baseStateLabel(for occupiedBases: Set<BaseballBase>) -> String? {
        switch occupiedBases {
        case [.first]:
            return "Runner on 1st"
        case [.second]:
            return "Runner on 2nd"
        case [.third]:
            return "Runner on 3rd"
        case [.first, .second]:
            return "Runners on 1st and 2nd"
        case [.first, .third]:
            return "Runners on corners"
        case [.second, .third]:
            return "Runners on 2nd and 3rd"
        case [.first, .second, .third]:
            return "Bases loaded"
        default:
            return nil
        }
    }

    private static func append(
        _ text: String?,
        tone: SituationContextChip.Tone,
        showsMarker: Bool = false,
        to chips: inout [SituationContextChip]
    ) {
        guard let text = text?.nilIfBlank else { return }
        chips.append(SituationContextChip(text: text, tone: tone, showsMarker: showsMarker))
    }

    private static func deduplicated(_ chips: [SituationContextChip]) -> [SituationContextChip] {
        var result: [SituationContextChip] = []
        for chip in chips {
            let repeats = result.contains {
                PlayRowContentFilter.duplicatesMeaning(chip.text, comparedWith: $0.text)
                    || PlayRowContentFilter.duplicatesMeaning($0.text, comparedWith: chip.text)
            }
            if !repeats {
                result.append(chip)
            }
        }
        return result
    }
}
