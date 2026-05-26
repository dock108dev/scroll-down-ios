import CoreGraphics
import SwiftUI
import UIKit

enum SnapshotDevice: String, CaseIterable {
    case phoneSmall
    case phoneCompact
    case phoneLarge
    case phoneLandscape
    case iPadMiniPortrait
    case iPad11Portrait
    case iPad13Portrait
    case iPad11Landscape
    case iPad13Landscape

    var size: CGSize {
        switch self {
        case .phoneSmall:
            return CGSize(width: 375, height: 667)
        case .phoneCompact:
            return CGSize(width: 393, height: 852)
        case .phoneLarge:
            return CGSize(width: 430, height: 932)
        case .phoneLandscape:
            return CGSize(width: 852, height: 393)
        case .iPadMiniPortrait:
            return CGSize(width: 744, height: 1_133)
        case .iPad11Portrait:
            return CGSize(width: 834, height: 1_194)
        case .iPad13Portrait:
            return CGSize(width: 1_032, height: 1_376)
        case .iPad11Landscape:
            return CGSize(width: 1_194, height: 834)
        case .iPad13Landscape:
            return CGSize(width: 1_376, height: 1_032)
        }
    }

    var scale: CGFloat {
        switch self {
        case .phoneSmall:
            return 2
        case .phoneCompact, .phoneLarge, .phoneLandscape:
            return 3
        case .iPadMiniPortrait,
             .iPad11Portrait,
             .iPad13Portrait,
             .iPad11Landscape,
             .iPad13Landscape:
            return 2
        }
    }

    var userInterfaceIdiom: UIUserInterfaceIdiom {
        switch self {
        case .phoneSmall, .phoneCompact, .phoneLarge, .phoneLandscape:
            return .phone
        case .iPadMiniPortrait,
             .iPad11Portrait,
             .iPad13Portrait,
             .iPad11Landscape,
             .iPad13Landscape:
            return .pad
        }
    }

    var defaultHorizontalSizeClass: UIUserInterfaceSizeClass {
        switch self {
        case .phoneSmall, .phoneCompact, .phoneLarge:
            return .compact
        case .phoneLandscape,
             .iPadMiniPortrait,
             .iPad11Portrait,
             .iPad13Portrait,
             .iPad11Landscape,
             .iPad13Landscape:
            return .regular
        }
    }

    var defaultVerticalSizeClass: UIUserInterfaceSizeClass {
        switch self {
        case .phoneLandscape:
            return .compact
        case .phoneSmall,
             .phoneCompact,
             .phoneLarge,
             .iPadMiniPortrait,
             .iPad11Portrait,
             .iPad13Portrait,
             .iPad11Landscape,
             .iPad13Landscape:
            return .regular
        }
    }

    var isPad: Bool {
        userInterfaceIdiom == .pad
    }

    func supports(width: SnapshotWidth) -> Bool {
        !width.isPadWidth || isPad
    }

    func resolvedTraits(for width: SnapshotWidth) -> SnapshotResolvedTraits {
        SnapshotResolvedTraits(
            displayScale: scale,
            userInterfaceIdiom: userInterfaceIdiom,
            horizontalSizeClass: width.horizontalSizeClass ?? defaultHorizontalSizeClass,
            verticalSizeClass: width.verticalSizeClass ?? defaultVerticalSizeClass
        )
    }

    @MainActor
    func traits(for width: SnapshotWidth) -> UITraitCollection {
        resolvedTraits(for: width).uiTraits
    }
}

enum SnapshotWidth: String, CaseIterable {
    case compact
    case standard
    case large
    case splitNarrow
    case splitMedium
    case tabletReadable
    case tabletWide
    case iPadMiniFull
    case iPad11Full
    case iPad13Full
    case iPad11LandscapeFull
    case iPad13LandscapeFull

    var points: CGFloat {
        switch self {
        case .compact:
            return 343
        case .standard:
            return 393
        case .large:
            return 430
        case .splitNarrow:
            return 472
        case .splitMedium:
            return 744
        case .tabletReadable:
            return 720
        case .tabletWide:
            return 860
        case .iPadMiniFull:
            return 744
        case .iPad11Full:
            return 834
        case .iPad13Full:
            return 1_032
        case .iPad11LandscapeFull:
            return 1_194
        case .iPad13LandscapeFull:
            return 1_376
        }
    }

    var horizontalSizeClass: UIUserInterfaceSizeClass? {
        switch self {
        case .compact, .standard, .large, .splitNarrow:
            return .compact
        case .splitMedium,
             .tabletReadable,
             .tabletWide,
             .iPadMiniFull,
             .iPad11Full,
             .iPad13Full,
             .iPad11LandscapeFull,
             .iPad13LandscapeFull:
            return .regular
        }
    }

    var verticalSizeClass: UIUserInterfaceSizeClass? {
        switch self {
        case .compact,
             .standard,
             .large,
             .splitNarrow,
             .splitMedium,
             .tabletReadable,
             .tabletWide,
             .iPadMiniFull,
             .iPad11Full,
             .iPad13Full,
             .iPad11LandscapeFull,
             .iPad13LandscapeFull:
            return .regular
        }
    }

    var isPadWidth: Bool {
        switch self {
        case .compact, .standard, .large:
            return false
        case .splitNarrow,
             .splitMedium,
             .tabletReadable,
             .tabletWide,
             .iPadMiniFull,
             .iPad11Full,
             .iPad13Full,
             .iPad11LandscapeFull,
             .iPad13LandscapeFull:
            return true
        }
    }

    static func fullWidth(for device: SnapshotDevice) -> SnapshotWidth {
        switch device {
        case .phoneSmall:
            return .compact
        case .phoneCompact:
            return .standard
        case .phoneLarge, .phoneLandscape:
            return .large
        case .iPadMiniPortrait:
            return .iPadMiniFull
        case .iPad11Portrait:
            return .iPad11Full
        case .iPad13Portrait:
            return .iPad13Full
        case .iPad11Landscape:
            return .iPad11LandscapeFull
        case .iPad13Landscape:
            return .iPad13LandscapeFull
        }
    }
}

struct SnapshotResolvedTraits: Equatable {
    let displayScale: CGFloat
    let userInterfaceIdiom: UIUserInterfaceIdiom
    let horizontalSizeClass: UIUserInterfaceSizeClass
    let verticalSizeClass: UIUserInterfaceSizeClass

    @MainActor
    var uiTraits: UITraitCollection {
        UITraitCollection { traits in
            traits.displayScale = displayScale
            traits.userInterfaceIdiom = userInterfaceIdiom
            traits.horizontalSizeClass = horizontalSizeClass
            traits.verticalSizeClass = verticalSizeClass
        }
    }

    var swiftUIHorizontalSizeClass: UserInterfaceSizeClass? {
        horizontalSizeClass.swiftUIValue
    }

    var swiftUIVerticalSizeClass: UserInterfaceSizeClass? {
        verticalSizeClass.swiftUIValue
    }
}

extension UIUserInterfaceSizeClass {
    var swiftUIValue: UserInterfaceSizeClass? {
        switch self {
        case .compact:
            return .compact
        case .regular:
            return .regular
        case .unspecified:
            return nil
        @unknown default:
            return nil
        }
    }
}
