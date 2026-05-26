import CoreGraphics
import SwiftUI
import UIKit
import XCTest

final class SnapshotDeviceWidthModelTests: XCTestCase {
    func testExistingPhoneWidthsKeepNamesAndDimensions() {
        XCTAssertEqual(SnapshotWidth.compact.rawValue, "compact")
        XCTAssertEqual(SnapshotWidth.standard.rawValue, "standard")
        XCTAssertEqual(SnapshotWidth.large.rawValue, "large")

        XCTAssertEqual(SnapshotWidth.compact.points, 343)
        XCTAssertEqual(SnapshotWidth.standard.points, 393)
        XCTAssertEqual(SnapshotWidth.large.points, 430)

        XCTAssertEqual(SnapshotDevice.phoneSmall.size, CGSize(width: 375, height: 667))
        XCTAssertEqual(SnapshotDevice.phoneCompact.size, CGSize(width: 393, height: 852))
        XCTAssertEqual(SnapshotDevice.phoneLarge.size, CGSize(width: 430, height: 932))
    }

    func testIPadDevicesExposeStableCanvasScaleAndDefaultTraits() {
        XCTAssertEqual(SnapshotDevice.iPadMiniPortrait.size, CGSize(width: 744, height: 1_133))
        XCTAssertEqual(SnapshotDevice.iPad11Portrait.size, CGSize(width: 834, height: 1_194))
        XCTAssertEqual(SnapshotDevice.iPad13Portrait.size, CGSize(width: 1_032, height: 1_376))
        XCTAssertEqual(SnapshotDevice.iPad11Landscape.size, CGSize(width: 1_194, height: 834))
        XCTAssertEqual(SnapshotDevice.iPad13Landscape.size, CGSize(width: 1_376, height: 1_032))

        for device in [
            SnapshotDevice.iPadMiniPortrait,
            .iPad11Portrait,
            .iPad13Portrait,
            .iPad11Landscape,
            .iPad13Landscape
        ] {
            XCTAssertEqual(device.scale, 2)
            XCTAssertEqual(device.userInterfaceIdiom, .pad)
            XCTAssertEqual(device.defaultHorizontalSizeClass, .regular)
            XCTAssertEqual(device.defaultVerticalSizeClass, .regular)
        }
    }

    func testIPadWidthsExpressSplitReadableWideAndFullViewports() {
        XCTAssertEqual(SnapshotWidth.splitNarrow.points, 472)
        XCTAssertEqual(SnapshotWidth.splitMedium.points, 744)
        XCTAssertEqual(SnapshotWidth.tabletReadable.points, 720)
        XCTAssertEqual(SnapshotWidth.tabletWide.points, 860)
        XCTAssertEqual(SnapshotWidth.iPadMiniFull.points, 744)
        XCTAssertEqual(SnapshotWidth.iPad11Full.points, 834)
        XCTAssertEqual(SnapshotWidth.iPad13Full.points, 1_032)
        XCTAssertEqual(SnapshotWidth.iPad11LandscapeFull.points, 1_194)
        XCTAssertEqual(SnapshotWidth.iPad13LandscapeFull.points, 1_376)

        XCTAssertEqual(SnapshotWidth.splitNarrow.horizontalSizeClass, .compact)
        XCTAssertEqual(SnapshotWidth.splitMedium.horizontalSizeClass, .regular)
        XCTAssertEqual(SnapshotWidth.tabletReadable.horizontalSizeClass, .regular)
        XCTAssertEqual(SnapshotWidth.tabletWide.horizontalSizeClass, .regular)
        XCTAssertEqual(SnapshotWidth.splitNarrow.verticalSizeClass, .regular)
    }

    func testResolvedTraitsUseWidthSizeClassesAndDeviceIdiom() {
        let narrowPadTraits = SnapshotDevice.iPad11Portrait.resolvedTraits(for: .splitNarrow)

        XCTAssertEqual(narrowPadTraits.displayScale, 2)
        XCTAssertEqual(narrowPadTraits.userInterfaceIdiom, .pad)
        XCTAssertEqual(narrowPadTraits.horizontalSizeClass, .compact)
        XCTAssertEqual(narrowPadTraits.verticalSizeClass, .regular)
        XCTAssertEqual(narrowPadTraits.swiftUIHorizontalSizeClass, .compact)
        XCTAssertEqual(narrowPadTraits.swiftUIVerticalSizeClass, .regular)

        let fullPadTraits = SnapshotDevice.iPad11Landscape.resolvedTraits(for: .iPad11LandscapeFull)
        XCTAssertEqual(fullPadTraits.horizontalSizeClass, .regular)
        XCTAssertEqual(fullPadTraits.verticalSizeClass, .regular)

        let phoneTraits = SnapshotDevice.phoneCompact.resolvedTraits(for: .standard)
        XCTAssertEqual(phoneTraits.displayScale, 3)
        XCTAssertEqual(phoneTraits.userInterfaceIdiom, .phone)
        XCTAssertEqual(phoneTraits.horizontalSizeClass, .compact)
        XCTAssertEqual(phoneTraits.verticalSizeClass, .regular)
    }

    func testPadWidthsRequirePadDevicesButPhoneWidthsCanRunOnPadDevices() {
        XCTAssertFalse(SnapshotDevice.phoneCompact.supports(width: .splitNarrow))
        XCTAssertFalse(SnapshotDevice.phoneLarge.supports(width: .tabletWide))
        XCTAssertTrue(SnapshotDevice.iPad11Portrait.supports(width: .splitNarrow))
        XCTAssertTrue(SnapshotDevice.iPad11Portrait.supports(width: .standard))
        XCTAssertFalse(SnapshotWidth.standard.isPadWidth)
        XCTAssertTrue(SnapshotWidth.tabletReadable.isPadWidth)
    }

    func testFullWidthMapsToDeviceCanvasWidths() {
        XCTAssertEqual(SnapshotWidth.fullWidth(for: .phoneSmall), .compact)
        XCTAssertEqual(SnapshotWidth.fullWidth(for: .phoneCompact), .standard)
        XCTAssertEqual(SnapshotWidth.fullWidth(for: .phoneLarge), .large)
        XCTAssertEqual(SnapshotWidth.fullWidth(for: .iPadMiniPortrait), .iPadMiniFull)
        XCTAssertEqual(SnapshotWidth.fullWidth(for: .iPad11Portrait), .iPad11Full)
        XCTAssertEqual(SnapshotWidth.fullWidth(for: .iPad13Portrait), .iPad13Full)
        XCTAssertEqual(SnapshotWidth.fullWidth(for: .iPad11Landscape), .iPad11LandscapeFull)
        XCTAssertEqual(SnapshotWidth.fullWidth(for: .iPad13Landscape), .iPad13LandscapeFull)
    }
}
