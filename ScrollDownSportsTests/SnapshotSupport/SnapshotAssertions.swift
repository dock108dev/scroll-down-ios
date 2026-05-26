import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
func assertSwiftUISnapshot<V: View>(
    of view: V,
    named name: String,
    width: SnapshotWidth = .standard,
    height: CGFloat? = nil,
    device: SnapshotDevice = .phoneCompact,
    colorScheme: ColorScheme = SnapshotEnvironment.colorScheme,
    dynamicTypeSize: DynamicTypeSize = SnapshotEnvironment.dynamicTypeSize,
    precision: Float = 0.995,
    perceptualPrecision: Float = 0.98,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line
) {
    precondition(
        device.supports(width: width),
        "iPad snapshot widths must use an iPad SnapshotDevice."
    )

    let resolvedTraits = device.resolvedTraits(for: width)
    let host = SnapshotHost(
        width: width.points,
        horizontalSizeClass: resolvedTraits.swiftUIHorizontalSizeClass,
        verticalSizeClass: resolvedTraits.swiftUIVerticalSizeClass,
        colorScheme: colorScheme,
        dynamicTypeSize: dynamicTypeSize
    ) {
        view
    }
    let layout: SwiftUISnapshotLayout = if let height {
        .fixed(width: width.points, height: height)
    } else {
        .sizeThatFits
    }

    assertSnapshot(
        of: host,
        as: .image(
            precision: precision,
            perceptualPrecision: perceptualPrecision,
            layout: layout,
            traits: resolvedTraits.uiTraits
        ),
        named: [
            name,
            width.rawValue,
            device.rawValue,
            colorScheme.snapshotName,
            dynamicTypeSize.snapshotName
        ].joined(separator: "-"),
        file: file,
        testName: testName,
        line: line
    )
}

@MainActor
func assertSwiftUIDeviceSnapshot<V: View>(
    of view: V,
    named name: String,
    device: SnapshotDevice,
    colorScheme: ColorScheme = SnapshotEnvironment.colorScheme,
    dynamicTypeSize: DynamicTypeSize = SnapshotEnvironment.dynamicTypeSize,
    precision: Float = 0.995,
    perceptualPrecision: Float = 0.98,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line
) {
    let width = SnapshotWidth.fullWidth(for: device)
    let resolvedTraits = device.resolvedTraits(for: width)
    let host = SnapshotHost(
        width: device.size.width,
        minHeight: device.size.height,
        horizontalSizeClass: resolvedTraits.swiftUIHorizontalSizeClass,
        verticalSizeClass: resolvedTraits.swiftUIVerticalSizeClass,
        colorScheme: colorScheme,
        dynamicTypeSize: dynamicTypeSize
    ) {
        view
    }

    assertSnapshot(
        of: host,
        as: .image(
            precision: precision,
            perceptualPrecision: perceptualPrecision,
            layout: .fixed(width: device.size.width, height: device.size.height),
            traits: resolvedTraits.uiTraits
        ),
        named: [
            name,
            device.rawValue,
            colorScheme.snapshotName,
            dynamicTypeSize.snapshotName
        ].joined(separator: "-"),
        file: file,
        testName: testName,
        line: line
    )
}

private extension ColorScheme {
    var snapshotName: String {
        switch self {
        case .light:
            return "light"
        case .dark:
            return "dark"
        @unknown default:
            return "unknown"
        }
    }
}

private extension DynamicTypeSize {
    var snapshotName: String {
        switch self {
        case .xSmall:
            return "xSmall"
        case .small:
            return "small"
        case .medium:
            return "medium"
        case .large:
            return "large"
        case .xLarge:
            return "xLarge"
        case .xxLarge:
            return "xxLarge"
        case .xxxLarge:
            return "xxxLarge"
        case .accessibility1:
            return "accessibility1"
        case .accessibility2:
            return "accessibility2"
        case .accessibility3:
            return "accessibility3"
        case .accessibility4:
            return "accessibility4"
        case .accessibility5:
            return "accessibility5"
        @unknown default:
            return "unknown"
        }
    }
}
