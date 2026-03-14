//
//  SimFrame.swift
//  ScrollDown
//
//  A single frame of the simulation playback — represents one plate appearance.
//

import Foundation

struct SimFrame: Identifiable {
    let id = UUID()
    let inning: Int
    let isTopHalf: Bool
    let outs: Int
    let runnersOnBase: [Bool]  // [first, second, third]
    let batterSilhouette: SilhouetteState
    let pitcherSilhouette: SilhouetteState
    let outcome: PAOutcome
    let description: String
    let awayScoreSoFar: Int
    let homeScoreSoFar: Int

    static let empty = SimFrame(
        inning: 1, isTopHalf: true, outs: 0,
        runnersOnBase: [false, false, false],
        batterSilhouette: .ready, pitcherSilhouette: .ready,
        outcome: .none, description: "Ready to play",
        awayScoreSoFar: 0, homeScoreSoFar: 0
    )
}

enum PAOutcome: String {
    case none
    case single
    case double_
    case triple
    case homeRun
    case walk
    case strikeout
    case groundOut
    case flyOut
    case lineOut

    var emoji: String {
        switch self {
        case .none: return ""
        case .single: return "1B"
        case .double_: return "2B"
        case .triple: return "3B"
        case .homeRun: return "HR"
        case .walk: return "BB"
        case .strikeout: return "K"
        case .groundOut: return "GO"
        case .flyOut: return "FO"
        case .lineOut: return "LO"
        }
    }

    var isHit: Bool {
        switch self {
        case .single, .double_, .triple, .homeRun: return true
        default: return false
        }
    }

    var isOut: Bool {
        switch self {
        case .strikeout, .groundOut, .flyOut, .lineOut: return true
        default: return false
        }
    }
}

enum SilhouetteState {
    case ready
    case swinging
    case running
    case pitching
    case celebrating
    case dejected
}
