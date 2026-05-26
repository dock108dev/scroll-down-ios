import SwiftUI
import UIKit
import XCTest
@testable import ScrollDownSports

final class SportsLayoutMetricsTests: XCTestCase {
    func testCompactPhonePreservesSingleColumnFeel() {
        let metrics = makeMetrics(width: 393, horizontalSizeClass: .compact)

        XCTAssertEqual(metrics.horizontalInset, 16)
        XCTAssertEqual(metrics.detailHorizontalInset, 16)
        XCTAssertEqual(metrics.homeContentMaxWidth, .infinity)
        XCTAssertEqual(metrics.detailContentMaxWidth, .infinity)
        XCTAssertEqual(metrics.homeContentWidth, 361)
        XCTAssertEqual(metrics.detailContentWidth, 361)
        XCTAssertEqual(metrics.cardGridColumns, 1)
        XCTAssertEqual(metrics.stackSpacing, 10)
        XCTAssertFalse(metrics.isSplitNavigationEligible)
    }

    func testSplitNarrowUsesPhoneLikeLayout() {
        let metrics = makeMetrics(width: 507, horizontalSizeClass: .compact, userInterfaceIdiom: .pad)

        XCTAssertEqual(metrics.horizontalInset, 16)
        XCTAssertEqual(metrics.detailHorizontalInset, 16)
        XCTAssertEqual(metrics.homeContentMaxWidth, .infinity)
        XCTAssertEqual(metrics.homeContentWidth, 475)
        XCTAssertEqual(metrics.detailContentWidth, 475)
        XCTAssertEqual(metrics.cardGridColumns, 1)
        XCTAssertFalse(metrics.isSplitNavigationEligible)
    }

    func testSplitMediumBoundsContentWithoutStretchingControls() {
        let metrics = makeMetrics(width: 744, horizontalSizeClass: .regular, userInterfaceIdiom: .pad)

        XCTAssertEqual(metrics.horizontalInset, 24)
        XCTAssertEqual(metrics.detailHorizontalInset, 24)
        XCTAssertEqual(metrics.homeContentMaxWidth, 680)
        XCTAssertEqual(metrics.detailContentMaxWidth, 640)
        XCTAssertEqual(metrics.homeContentWidth, 680)
        XCTAssertEqual(metrics.detailContentWidth, 640)
        XCTAssertEqual(metrics.chromeAlignmentWidth, 640)
        XCTAssertEqual(metrics.cardGridColumns, 1)
        XCTAssertFalse(metrics.isSplitNavigationEligible)
    }

    func testTabletReadableWidthUsesIntentionalMargins() {
        let metrics = makeMetrics(width: 1024, horizontalSizeClass: .regular, userInterfaceIdiom: .pad)

        XCTAssertEqual(metrics.horizontalInset, 32)
        XCTAssertEqual(metrics.detailHorizontalInset, 24)
        XCTAssertEqual(metrics.homeContentWidth, 680)
        XCTAssertEqual(metrics.detailContentWidth, 640)
        XCTAssertEqual(metrics.chromeAlignmentWidth, 640)
        XCTAssertEqual(metrics.cardGridColumns, 1)
        XCTAssertTrue(metrics.isSplitNavigationEligible)
    }

    func testTabletWideNeverStretchesReadableContentEdgeToEdge() {
        let metrics = makeMetrics(width: 1366, horizontalSizeClass: .regular, userInterfaceIdiom: .pad)

        XCTAssertEqual(metrics.homeContentWidth, 680)
        XCTAssertEqual(metrics.detailContentWidth, 640)
        XCTAssertLessThan(metrics.homeContentWidth + metrics.horizontalInset * 2, metrics.availableWidth)
        XCTAssertTrue(metrics.isSplitNavigationEligible)
    }

    func testAccessibilityDynamicTypeKeepsSingleColumnAndLargerRhythm() {
        let metrics = makeMetrics(
            width: 1024,
            horizontalSizeClass: .regular,
            dynamicTypeSize: .accessibility2,
            userInterfaceIdiom: .pad
        )

        XCTAssertEqual(metrics.homeContentMaxWidth, 680)
        XCTAssertEqual(metrics.detailContentMaxWidth, 640)
        XCTAssertEqual(metrics.detailContentWidth, 640)
        XCTAssertEqual(metrics.cardGridColumns, 1)
        XCTAssertEqual(metrics.stackSpacing, 12)
        XCTAssertEqual(metrics.emptyStateMinHeight, 260)
        XCTAssertFalse(metrics.isSplitNavigationEligible)
    }

    func testLandscapeHeightPressureKeepsReadableWidthAndReducesBottomScrollPadding() {
        let metrics = makeMetrics(
            width: 852,
            height: 393,
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            userInterfaceIdiom: .phone
        )

        XCTAssertEqual(metrics.horizontalInset, 24)
        XCTAssertEqual(metrics.detailHorizontalInset, 24)
        XCTAssertEqual(metrics.homeContentWidth, 680)
        XCTAssertEqual(metrics.detailContentWidth, 640)
        XCTAssertEqual(metrics.homeScrollBottomPadding, 18)
        XCTAssertEqual(metrics.detailScrollBottomPadding, 20)
        XCTAssertFalse(metrics.isSplitNavigationEligible)
    }

    private func makeMetrics(
        width: CGFloat,
        height: CGFloat? = nil,
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass? = nil,
        dynamicTypeSize: DynamicTypeSize = .medium,
        userInterfaceIdiom: UIUserInterfaceIdiom = .phone
    ) -> SportsLayoutMetrics {
        SportsLayoutMetrics(
            availableWidth: width,
            availableHeight: height,
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            dynamicTypeSize: dynamicTypeSize,
            userInterfaceIdiom: userInterfaceIdiom
        )
    }
}
