import SwiftUI

// MARK: - Layout Configuration

/// Layout configuration for compact vs standard modes
/// Compact mode: reduced spacing, tighter typography, collapsed media
/// Standard mode: full spacing, standard typography, visible media
struct TimelineRowLayoutConfig {
    // Spacing
    let contentSpacing: CGFloat
    let textSpacing: CGFloat
    let rowPadding: CGFloat
    let cornerRadius: CGFloat
    let timeColumnWidth: CGFloat
    let dividerWidth: CGFloat
    let timeStackSpacing: CGFloat

    // Typography
    let timeFont: Font
    let periodFont: Font
    let descriptionFont: Font
    let metaFont: Font
    let handleFont: Font
    let timestampFont: Font
    let tweetTextFont: Font

    // Standard layout — tightened spacing, proper contrast
    static let standard = TimelineRowLayoutConfig(
        contentSpacing: 8,
        textSpacing: DesignSystem.Spacing.text,
        rowPadding: DesignSystem.Spacing.elementPadding,
        cornerRadius: DesignSystem.Radius.element,
        timeColumnWidth: 42,
        dividerWidth: 1,
        timeStackSpacing: DesignSystem.Spacing.tight,
        timeFont: DesignSystem.Typography.rowMeta.monospacedDigit(),
        periodFont: DesignSystem.Typography.rowMeta,
        descriptionFont: DesignSystem.Typography.rowTitle,
        metaFont: DesignSystem.Typography.rowMeta,
        handleFont: DesignSystem.Typography.rowMeta.weight(.medium),
        timestampFont: DesignSystem.Typography.rowMeta,
        tweetTextFont: DesignSystem.Typography.rowTitle
    )

    // iPad layout — wider columns, better spacing for larger screens
    static let iPad = TimelineRowLayoutConfig(
        contentSpacing: 12,
        textSpacing: DesignSystem.Spacing.text,
        rowPadding: DesignSystem.Spacing.elementPadding,
        cornerRadius: DesignSystem.Radius.element,
        timeColumnWidth: 50, // Wider time column for better readability
        dividerWidth: 1,
        timeStackSpacing: DesignSystem.Spacing.tight,
        timeFont: DesignSystem.Typography.rowMeta.monospacedDigit(),
        periodFont: DesignSystem.Typography.rowMeta,
        descriptionFont: DesignSystem.Typography.rowTitle,
        metaFont: DesignSystem.Typography.rowMeta,
        handleFont: DesignSystem.Typography.rowMeta.weight(.medium),
        timestampFont: DesignSystem.Typography.rowMeta,
        tweetTextFont: DesignSystem.Typography.rowTitle
    )
}
