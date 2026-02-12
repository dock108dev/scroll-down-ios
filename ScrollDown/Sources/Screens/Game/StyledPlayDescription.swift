import SwiftUI

// MARK: - Styled Play Description

/// Provides visual hierarchy for play descriptions
/// - Emphasizes: Action words (MISS, makes, REBOUND, GOAL, etc.)
/// - De-emphasizes: Metadata in parentheses, distances, zones
/// - Maintains: Player names at primary contrast
struct StyledPlayDescription: View {
    let description: String
    let playType: String?
    let font: Font

    var body: some View {
        Text(styledDescription)
            .font(font)
    }

    private var styledDescription: AttributedString {
        var result = AttributedString(description)

        // Set base style - primary text color
        result.foregroundColor = DesignSystem.TextColor.primary

        // 1. Emphasize action keywords (bold + slightly brighter)
        let actionKeywords = [
            // Basketball
            "MISS", "makes", "REBOUND", "STEAL", "BLOCK", "TURNOVER",
            "FOUL", "FREE THROW", "DUNK", "LAYUP", "Jump Shot", "3PT",
            // Hockey
            "GOAL", "SHOT", "SAVE", "HIT", "PENALTY", "FACEOFF",
            "GIVEAWAY", "TAKEAWAY", "Blocked Shot",
            // Football
            "TOUCHDOWN", "INTERCEPTION", "FUMBLE", "SACK", "RUSH",
            "PASS", "PUNT", "FIELD GOAL", "SAFETY",
            // General
            "Timeout", "Substitution"
        ]

        for keyword in actionKeywords {
            emphasizeKeyword(keyword, in: &result, caseInsensitive: true)
        }

        // 2. De-emphasize parenthetical content (stats, counts)
        // Pattern: anything in parentheses like "(3 PTS)" or "(Off:1 Def:0)"
        deemphasizeParentheses(in: &result)

        // 3. De-emphasize distance/location info
        // Pattern: "from 25 ft", "in the paint", "at the rim"
        let locationPatterns = [
            "from \\d+('| ft)",  // "from 25 ft" or "from 25'"
            "in the paint",
            "at the rim",
            "from the top of the key",
            "from the corner",
            "from downtown"
        ]
        for pattern in locationPatterns {
            deemphasizePattern(pattern, in: &result)
        }

        // 4. De-emphasize zone info for hockey
        // Pattern: "Offensive Zone", "Defensive Zone", "Neutral Zone"
        let zonePatterns = ["Offensive Zone", "Defensive Zone", "Neutral Zone"]
        for zone in zonePatterns {
            deemphasizeExact(zone, in: &result)
        }

        return result
    }

    /// Makes a keyword bold/semibold for emphasis
    private func emphasizeKeyword(_ keyword: String, in attributed: inout AttributedString, caseInsensitive: Bool) {
        let searchString = caseInsensitive ? description.lowercased() : description
        let keywordLower = caseInsensitive ? keyword.lowercased() : keyword
        let attrLength = attributed.characters.count

        var searchStart = searchString.startIndex
        while let range = searchString.range(of: keywordLower, range: searchStart..<searchString.endIndex) {
            // Convert String range to AttributedString range
            let startOffset = searchString.distance(from: searchString.startIndex, to: range.lowerBound)
            let endOffset = searchString.distance(from: searchString.startIndex, to: range.upperBound)

            guard startOffset < attrLength, endOffset <= attrLength else {
                searchStart = range.upperBound
                continue
            }

            let attrStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset)
            attributed[attrStart..<attrEnd].font = font.weight(.semibold)

            searchStart = range.upperBound
        }
    }

    /// De-emphasizes content within parentheses
    private func deemphasizeParentheses(in attributed: inout AttributedString) {
        let attrLength = attributed.characters.count
        var searchStart = description.startIndex

        while let openParen = description.range(of: "(", range: searchStart..<description.endIndex),
              let closeParen = description.range(of: ")", range: openParen.upperBound..<description.endIndex) {
            let fullRange = openParen.lowerBound..<closeParen.upperBound

            let startOffset = description.distance(from: description.startIndex, to: fullRange.lowerBound)
            let endOffset = description.distance(from: description.startIndex, to: fullRange.upperBound)

            guard startOffset < attrLength, endOffset <= attrLength else {
                searchStart = closeParen.upperBound
                continue
            }

            let attrStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset)
            attributed[attrStart..<attrEnd].foregroundColor = DesignSystem.TextColor.tertiary
            attributed[attrStart..<attrEnd].font = font

            searchStart = closeParen.upperBound
        }
    }

    /// De-emphasizes text matching a regex pattern
    private func deemphasizePattern(_ pattern: String, in attributed: inout AttributedString) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return }

        let nsString = description as NSString
        let matches = regex.matches(in: description, range: NSRange(location: 0, length: nsString.length))
        let attrLength = attributed.characters.count

        for match in matches {
            let startOffset = match.range.location
            let endOffset = match.range.location + match.range.length

            guard startOffset < attrLength, endOffset <= attrLength else { continue }

            let attrStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset)
            attributed[attrStart..<attrEnd].foregroundColor = DesignSystem.TextColor.tertiary
        }
    }

    /// De-emphasizes exact string matches
    private func deemphasizeExact(_ text: String, in attributed: inout AttributedString) {
        let attrLength = attributed.characters.count
        var searchStart = description.startIndex

        while let range = description.range(of: text, options: .caseInsensitive, range: searchStart..<description.endIndex) {
            let startOffset = description.distance(from: description.startIndex, to: range.lowerBound)
            let endOffset = description.distance(from: description.startIndex, to: range.upperBound)

            guard startOffset < attrLength, endOffset <= attrLength else {
                searchStart = range.upperBound
                continue
            }

            let attrStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset)
            attributed[attrStart..<attrEnd].foregroundColor = DesignSystem.TextColor.tertiary

            searchStart = range.upperBound
        }
    }
}
