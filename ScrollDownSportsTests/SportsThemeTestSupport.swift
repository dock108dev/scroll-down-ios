import Foundation
import SwiftUI
import UIKit
import XCTest
@testable import ScrollDownSports

extension SportsThemeTests {
    func makeGame(leagueCode: String, scoreboard: GameScoreboardData? = nil) -> Game {
        Game(
            id: 10,
            sport: Sport(leagueCode: leagueCode),
            leagueCode: leagueCode,
            scheduledStart: Date(timeIntervalSince1970: 1_770_000_000),
            localDateLabel: nil,
            status: GameStatus(rawValue: "final"),
            participants: [
                GameParticipant(id: "away", role: .away, name: "Away Team", abbreviation: "AWY"),
                GameParticipant(id: "home", role: .home, name: "Home Team", abbreviation: "HME")
            ],
            scoreState: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "away", participantRole: .away, score: 1),
                    ParticipantScore(participantID: "home", participantRole: .home, score: 2)
                ]
            ),
            presentation: nil,
            scoreboard: scoreboard,
            progress: GameProgress(
                selectedMode: .timeline,
                periodOrdinal: 1,
                periodLabel: nil,
                clockLabel: nil,
                eventCount: 8,
                lastReadEventID: nil,
                scrollFallback: nil,
                reachedScoreboard: false,
                updatedAt: nil,
                restoredAt: nil,
                persistence: nil
            ),
            availableFeatures: GameAvailableFeatures(hasTimeline: true, hasStats: true, hasScoreboard: true)
        )
    }

    func assertContrast(
        _ foreground: Color,
        on background: Color,
        name: String,
        minimum: CGFloat = 4.5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let foregroundColor = UIColor(foreground).resolvedColor(with: traits)
            let backgroundColor = UIColor(background).resolvedColor(with: traits)
            let contrast = contrastRatio(foreground: foregroundColor, background: backgroundColor)
            XCTAssertGreaterThanOrEqual(
                contrast,
                minimum,
                "\(name) \(style == .dark ? "dark" : "light") contrast \(contrast) is below \(minimum)",
                file: file,
                line: line
            )
        }
    }

    func contrastRatio(foreground: UIColor, background: UIColor) -> CGFloat {
        let foregroundLuminance = relativeLuminance(foreground)
        let backgroundLuminance = relativeLuminance(background)
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    func relativeLuminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            XCTFail("Could not resolve color components for contrast")
            return 0
        }

        func linearized(_ component: CGFloat) -> CGFloat {
            component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
    }
}
