import SwiftUI

enum DetailChromeDensity {
    case regular
    case compact
    case stacked
    case accessibility

    static func resolve(
        dynamicTypeSize: DynamicTypeSize,
        availableWidth: CGFloat,
        contentWeight: CGFloat = 1
    ) -> DetailChromeDensity {
        if dynamicTypeSize >= .accessibility3 {
            return .accessibility
        }

        if dynamicTypeSize >= .accessibility1 {
            return .stacked
        }

        if dynamicTypeSize >= .xxxLarge {
            return availableWidth < 430 || contentWeight > 1.2 ? .stacked : .compact
        }

        if availableWidth < 360 || contentWeight > 1.45 {
            return .compact
        }

        return .regular
    }
}

extension DynamicTypeSize {
    var isDetailChromeAccessibility: Bool {
        self >= .accessibility1
    }

    var isSevereDetailChromeAccessibility: Bool {
        self >= .accessibility3
    }
}

enum DetailChromeLabelFormatter {
    static func shortReturnLabel(_ label: String) -> String {
        let digits = label.filter(\.isNumber)
        if !digits.isEmpty {
            return "Back \(digits)"
        }
        return "Back"
    }

    static func shortEndLabel(_ label: String) -> String {
        label.count > 8 ? "End" : label
    }

    static func shortProgressLabel(_ label: String) -> String {
        label.hasSuffix(" read") ? label.replacingOccurrences(of: " read", with: "") : label
    }
}
