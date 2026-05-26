import SwiftUI
import UIKit

struct SportsLayoutMetrics: Equatable {
    let availableWidth: CGFloat
    let availableHeight: CGFloat?
    let horizontalInset: CGFloat
    let detailHorizontalInset: CGFloat
    let homeContentMaxWidth: CGFloat
    let detailContentMaxWidth: CGFloat
    let chromeAlignmentWidth: CGFloat
    let cardGridColumns: Int
    let stackSpacing: CGFloat
    let sectionSpacing: CGFloat
    let rowSpacing: CGFloat
    let bottomInsetPadding: CGFloat
    let homeScrollTopPadding: CGFloat
    let homeScrollBottomPadding: CGFloat
    let detailScrollTopPadding: CGFloat
    let detailScrollBottomPadding: CGFloat
    let stickyHeaderTopPadding: CGFloat
    let stickyHeaderBottomPadding: CGFloat
    let stickyChromeVerticalPadding: CGFloat
    let bottomAffordanceVerticalPadding: CGFloat
    let emptyStateMinHeight: CGFloat
    let loadingStateMinHeight: CGFloat
    let isSplitNavigationEligible: Bool

    init(
        availableWidth: CGFloat,
        availableHeight: CGFloat? = nil,
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass? = nil,
        dynamicTypeSize: DynamicTypeSize,
        userInterfaceIdiom: UIUserInterfaceIdiom? = nil
    ) {
        let width = max(0, availableWidth)
        let height = availableHeight.map { max(0, $0) }
        let isAccessibilityType = dynamicTypeSize.isAccessibilitySize
        let isRegularWidth = horizontalSizeClass == .regular
        let isCompactHeight = verticalSizeClass == .compact
        let usesReadableWidth = isRegularWidth || width >= 700
        let usesExpandedRhythm = usesReadableWidth || width >= 700
        let usesAccessibilityRhythm = isAccessibilityType && usesExpandedRhythm

        let inset: CGFloat
        switch width {
        case ..<700:
            inset = 16
        case ..<900:
            inset = 24
        default:
            inset = 32
        }
        let detailInset: CGFloat = usesReadableWidth ? 24 : 16

        let contentMaxWidth: CGFloat
        if usesReadableWidth {
            contentMaxWidth = 680
        } else {
            contentMaxWidth = .infinity
        }

        let detailMaxWidth: CGFloat
        if usesReadableWidth {
            detailMaxWidth = 640
        } else {
            detailMaxWidth = .infinity
        }

        let readableWidth = Self.resolvedContentWidth(
            availableWidth: width,
            horizontalInset: inset,
            maxWidth: min(contentMaxWidth, detailMaxWidth)
        )
        let heightPressure = (height ?? .greatestFiniteMagnitude) < 430
        let idiomCanHostSplit = userInterfaceIdiom == .pad || width >= 900

        self.availableWidth = width
        self.availableHeight = height
        self.horizontalInset = inset
        self.detailHorizontalInset = detailInset
        self.homeContentMaxWidth = contentMaxWidth
        self.detailContentMaxWidth = detailMaxWidth
        self.chromeAlignmentWidth = readableWidth
        self.cardGridColumns = 1
        self.stackSpacing = usesExpandedRhythm ? 12 : 10
        self.sectionSpacing = usesExpandedRhythm ? 12 : 8
        self.rowSpacing = usesAccessibilityRhythm ? 10 : 8
        self.bottomInsetPadding = usesAccessibilityRhythm ? 16 : 12
        self.homeScrollTopPadding = usesAccessibilityRhythm ? 14 : 12
        self.homeScrollBottomPadding = usesAccessibilityRhythm ? 32 : (heightPressure ? 18 : 24)
        self.detailScrollTopPadding = usesAccessibilityRhythm ? 16 : 14
        self.detailScrollBottomPadding = usesAccessibilityRhythm ? 30 : (heightPressure ? 20 : 24)
        self.stickyHeaderTopPadding = usesAccessibilityRhythm ? 10 : 8
        self.stickyHeaderBottomPadding = usesAccessibilityRhythm ? 12 : 10
        self.stickyChromeVerticalPadding = usesAccessibilityRhythm ? 7 : 5
        self.bottomAffordanceVerticalPadding = usesAccessibilityRhythm ? 10 : 8
        self.emptyStateMinHeight = usesAccessibilityRhythm ? 260 : 220
        self.loadingStateMinHeight = usesAccessibilityRhythm ? 280 : 240
        self.isSplitNavigationEligible = idiomCanHostSplit
            && isRegularWidth
            && !isCompactHeight
            && !isAccessibilityType
            && width >= 900
    }

    var homeContentWidth: CGFloat {
        Self.resolvedContentWidth(
            availableWidth: availableWidth,
            horizontalInset: horizontalInset,
            maxWidth: homeContentMaxWidth
        )
    }

    var detailContentWidth: CGFloat {
        Self.resolvedContentWidth(
            availableWidth: availableWidth,
            horizontalInset: detailHorizontalInset,
            maxWidth: detailContentMaxWidth
        )
    }

    private static func resolvedContentWidth(
        availableWidth: CGFloat,
        horizontalInset: CGFloat,
        maxWidth: CGFloat
    ) -> CGFloat {
        let usableWidth = max(0, availableWidth - horizontalInset * 2)
        guard maxWidth.isFinite else { return usableWidth }
        return min(maxWidth, usableWidth)
    }
}

private struct SportsLayoutMetricsKey: EnvironmentKey {
    static let defaultValue = SportsLayoutMetrics(
        availableWidth: 393,
        horizontalSizeClass: nil,
        dynamicTypeSize: .large
    )
}

extension EnvironmentValues {
    var sportsLayoutMetrics: SportsLayoutMetrics {
        get { self[SportsLayoutMetricsKey.self] }
        set { self[SportsLayoutMetricsKey.self] = newValue }
    }
}

private struct SportsReadableContentModifier: ViewModifier {
    @Environment(\.sportsLayoutMetrics) private var layout
    let maxWidth: KeyPath<SportsLayoutMetrics, CGFloat>
    let horizontalInset: KeyPath<SportsLayoutMetrics, CGFloat>

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: layout[keyPath: maxWidth], alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, layout[keyPath: horizontalInset])
    }
}

extension View {
    func sportsReadableContent(
        maxWidth: KeyPath<SportsLayoutMetrics, CGFloat> = \.homeContentMaxWidth,
        horizontalInset: KeyPath<SportsLayoutMetrics, CGFloat> = \.horizontalInset
    ) -> some View {
        modifier(SportsReadableContentModifier(maxWidth: maxWidth, horizontalInset: horizontalInset))
    }
}
