import SwiftUI

// MARK: - Layout Constants

enum GameDetailLayout {
    static let sectionSpacing: CGFloat = 20
    static let textSpacing: CGFloat = 12
    static let listSpacing: CGFloat = 8
    static let smallSpacing: CGFloat = 4
    static let cardSpacing: CGFloat = 16
    static let compactCardSpacing: CGFloat = 8  // Reduced spacing for compact mode
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
    static let statsTableWidth: CGFloat = 360
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
}

enum GameDetailConstants {
    static let statFallback = "--"
    static let scoreFallback = "--"
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
