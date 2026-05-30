import SwiftUI
import XCTest
@testable import ScrollDownSports

final class DetailChromeDensityTests: XCTestCase {
    func testDensityResolvesForDynamicTypeWidthAndContentWeight() {
        XCTAssertEqual(
            DetailChromeDensity.resolve(dynamicTypeSize: .medium, availableWidth: 520),
            .regular
        )
        XCTAssertEqual(
            DetailChromeDensity.resolve(dynamicTypeSize: .medium, availableWidth: 340),
            .compact
        )
        XCTAssertEqual(
            DetailChromeDensity.resolve(dynamicTypeSize: .medium, availableWidth: 520, contentWeight: 1.5),
            .compact
        )
        XCTAssertEqual(
            DetailChromeDensity.resolve(dynamicTypeSize: .xxxLarge, availableWidth: 520),
            .compact
        )
        XCTAssertEqual(
            DetailChromeDensity.resolve(dynamicTypeSize: .xxxLarge, availableWidth: 400),
            .stacked
        )
        XCTAssertEqual(
            DetailChromeDensity.resolve(dynamicTypeSize: .xxxLarge, availableWidth: 520, contentWeight: 1.3),
            .stacked
        )
        XCTAssertEqual(
            DetailChromeDensity.resolve(dynamicTypeSize: .accessibility1, availableWidth: 520),
            .stacked
        )
        XCTAssertEqual(
            DetailChromeDensity.resolve(dynamicTypeSize: .accessibility3, availableWidth: 520),
            .accessibility
        )
    }

    func testDynamicTypeAccessibilityThresholds() {
        XCTAssertFalse(DynamicTypeSize.xxxLarge.isDetailChromeAccessibility)
        XCTAssertTrue(DynamicTypeSize.accessibility1.isDetailChromeAccessibility)
        XCTAssertFalse(DynamicTypeSize.accessibility2.isSevereDetailChromeAccessibility)
        XCTAssertTrue(DynamicTypeSize.accessibility3.isSevereDetailChromeAccessibility)
    }

    func testShortChromeLabelsPreserveUsefulContext() {
        XCTAssertEqual(DetailChromeLabelFormatter.shortReturnLabel("Back to 7th"), "Back 7")
        XCTAssertEqual(DetailChromeLabelFormatter.shortReturnLabel("Back to latest"), "Back")
        XCTAssertEqual(DetailChromeLabelFormatter.shortEndLabel("End"), "End")
        XCTAssertEqual(DetailChromeLabelFormatter.shortEndLabel("Box Score"), "End")
        XCTAssertEqual(DetailChromeLabelFormatter.shortProgressLabel("8 of 10 read"), "8 of 10")
        XCTAssertEqual(DetailChromeLabelFormatter.shortProgressLabel("Live edge"), "Live edge")
    }
}
