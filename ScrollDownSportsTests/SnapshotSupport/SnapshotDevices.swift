import CoreGraphics
import SnapshotTesting
import UIKit

enum SnapshotDevice: String, CaseIterable {
    case phoneSmall
    case phoneCompact
    case phoneLarge
    case phoneLandscape

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
        }
    }

    var scale: CGFloat {
        switch self {
        case .phoneSmall:
            return 2
        case .phoneCompact, .phoneLarge, .phoneLandscape:
            return 3
        }
    }

    var traits: UITraitCollection {
        UITraitCollection(displayScale: scale)
    }
}

enum SnapshotWidth: String, CaseIterable {
    case compact
    case standard
    case large

    var points: CGFloat {
        switch self {
        case .compact:
            return 343
        case .standard:
            return 393
        case .large:
            return 430
        }
    }
}
