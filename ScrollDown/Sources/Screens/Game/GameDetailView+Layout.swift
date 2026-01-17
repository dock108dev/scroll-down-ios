import SwiftUI

// MARK: - Layout Constants

enum GameDetailLayout {
    // MARK: - Adaptive Spacing (iPad: much tighter for density, stacked feel)
    static func sectionSpacing(_ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 12 : 20 // iPad: nearly half the spacing for stacked feel
    }

    static let textSpacing: CGFloat = 12
    static let listSpacing: CGFloat = 8
    static let smallSpacing: CGFloat = 4

    static func cardSpacing(_ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 6 : 16
    }

    static let cardSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 20

    static let compactCardSpacing: CGFloat = 8  // Reduced spacing for compact mode

    // MARK: - Adaptive Padding (iPad: constrained max-width containers)
    static func horizontalPadding(_ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 32 : 20
    }

    static let horizontalPadding: CGFloat = 20

    static let bottomPadding: CGFloat = 32
    static let bulletSize: CGFloat = 6
    static let bulletOffset: CGFloat = 6
    static let navigationSpacing: CGFloat = 12
    static let navigationHorizontalPadding: CGFloat = 16
    static let navigationVerticalPadding: CGFloat = 8
    static let statsColumnSpacing: CGFloat = 12
    static let statColumnWidth: CGFloat = 48
    static let statsHorizontalPadding: CGFloat = 16

    // MARK: - Adaptive Stats Table (iPad: wider, no horizontal scroll)
    static func statsTableWidth(_ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 480 : 360
    }

    static let finalScoreSize: CGFloat = 40
    static let sectionSpacingCompact: CGFloat = 8
    static let sectionHorizontalPaddingCompact: CGFloat = 4
    static let summaryMinHeight: CGFloat = 72
    static let viewingPillHorizontalPadding: CGFloat = 12
    static let viewingPillVerticalPadding: CGFloat = 6
    static let viewingPillTopPadding: CGFloat = 12
    static let resumePromptPadding: CGFloat = 16
    static let resumePromptSpacing: CGFloat = 8
    static let resumeButtonSpacing: CGFloat = 12
    static let contextPadding: CGFloat = 12
    static let contextCornerRadius: CGFloat = 8
    static let scrollCoordinateSpace = "gameScrollView"

    // MARK: - iPad-specific constants (tighter constraints for density)
    static let maxContentWidth: CGFloat = 700 // Tighter max width for better reading density on iPad
    static let statsTableMaxWidth: CGFloat = 550 // Tighter stats table width for iPad
}

enum GameDetailConstants {
    static let statPlaceholder = "--"
    static let scorePlaceholder = "--"
}

struct PlayRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct TimelineFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct ScrollViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct SectionFramePreferenceKey: PreferenceKey {
    static var defaultValue: [GameSection: CGRect] = [:]

    static func reduce(value: inout [GameSection: CGRect], nextValue: () -> [GameSection: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}
