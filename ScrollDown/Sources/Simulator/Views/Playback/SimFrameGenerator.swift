//
//  SimFrameGenerator.swift
//  ScrollDown
//
//  Generates a plausible game replay from simulation PA probabilities.
//  Uses the most likely final score and PA outcome rates to create a
//  frame-by-frame "movie" of the game.
//

import Foundation

enum SimFrameGenerator {
    /// Generate a sequence of plate appearance frames that produce the most likely final score
    static func generate(from result: SimulatorResult) -> [SimFrame] {
        // Use the most likely score as our target
        guard let topScore = result.mostCommonScores.first,
              let parsed = topScore.parsed else {
            return [SimFrame.empty]
        }

        let targetAway = parsed.away
        let targetHome = parsed.home

        let awayPA = result.awayPaProbabilities ?? defaultPA()
        let homePA = result.homePaProbabilities ?? defaultPA()

        var frames: [SimFrame] = []
        var awayRuns = 0
        var homeRuns = 0

        // Play 9 innings
        for inning in 1...9 {
            // Top half (away batting)
            let topFrames = generateHalfInning(
                inning: inning, isTopHalf: true,
                paProbabilities: awayPA,
                targetRuns: targetAway,
                currentRuns: awayRuns,
                totalInnings: 9,
                currentInning: inning,
                opponentRuns: homeRuns
            )
            for frame in topFrames {
                awayRuns = frame.awayScoreSoFar
                frames.append(SimFrame(
                    inning: frame.inning, isTopHalf: true,
                    outs: frame.outs, runnersOnBase: frame.runnersOnBase,
                    batterSilhouette: frame.batterSilhouette,
                    pitcherSilhouette: frame.pitcherSilhouette,
                    outcome: frame.outcome, description: frame.description,
                    awayScoreSoFar: awayRuns, homeScoreSoFar: homeRuns
                ))
            }

            // Bottom half (home batting) — skip bottom 9 if home already winning
            let skipBottom = inning == 9 && homeRuns > awayRuns
            if !skipBottom {
                let bottomFrames = generateHalfInning(
                    inning: inning, isTopHalf: false,
                    paProbabilities: homePA,
                    targetRuns: targetHome,
                    currentRuns: homeRuns,
                    totalInnings: 9,
                    currentInning: inning,
                    opponentRuns: awayRuns
                )
                for frame in bottomFrames {
                    homeRuns = frame.homeScoreSoFar
                    frames.append(SimFrame(
                        inning: frame.inning, isTopHalf: false,
                        outs: frame.outs, runnersOnBase: frame.runnersOnBase,
                        batterSilhouette: frame.batterSilhouette,
                        pitcherSilhouette: frame.pitcherSilhouette,
                        outcome: frame.outcome, description: frame.description,
                        awayScoreSoFar: awayRuns, homeScoreSoFar: homeRuns
                    ))
                }
            }
        }

        // Final frame
        frames.append(SimFrame(
            inning: 9, isTopHalf: false, outs: 3,
            runnersOnBase: [false, false, false],
            batterSilhouette: awayRuns > homeRuns ? .celebrating : .dejected,
            pitcherSilhouette: homeRuns >= awayRuns ? .celebrating : .dejected,
            outcome: .none,
            description: "Final: \(result.awayTeam) \(awayRuns) - \(result.homeTeam) \(homeRuns)",
            awayScoreSoFar: awayRuns, homeScoreSoFar: homeRuns
        ))

        return frames
    }

    // MARK: - Half Inning Generator

    private static func generateHalfInning(
        inning: Int, isTopHalf: Bool,
        paProbabilities: [String: Double],
        targetRuns: Int,
        currentRuns: Int,
        totalInnings: Int,
        currentInning: Int,
        opponentRuns: Int
    ) -> [SimFrame] {
        var frames: [SimFrame] = []
        var outs = 0
        var runners: [Bool] = [false, false, false]
        var runsThisInning = 0
        let runsNeeded = max(0, targetRuns - currentRuns)
        let inningsLeft = totalInnings - currentInning + 1

        // Spread runs roughly evenly across remaining innings
        let runsThisTarget: Int
        if inningsLeft > 0 {
            runsThisTarget = runsNeeded / inningsLeft + (currentInning <= runsNeeded % inningsLeft ? 1 : 0)
        } else {
            runsThisTarget = 0
        }

        var paCount = 0
        while outs < 3 && paCount < 8 { // cap at 8 PAs per half inning
            paCount += 1
            let outcome = pickOutcome(pa: paProbabilities, needRuns: runsThisTarget > runsThisInning, outs: outs)

            // Process outcome
            var runsScoredThisPA = 0
            switch outcome {
            case .homeRun:
                // Everyone scores + batter
                runsScoredThisPA = 1 + runners.filter { $0 }.count
                runners = [false, false, false]
            case .triple:
                runsScoredThisPA = runners.filter { $0 }.count
                runners = [false, false, true]
            case .double_:
                runsScoredThisPA = (runners[1] ? 1 : 0) + (runners[2] ? 1 : 0)
                let r1scores = runners[0]
                runners = [false, true, false]
                if r1scores { runsScoredThisPA += 1 }
            case .single:
                runsScoredThisPA = runners[2] ? 1 : 0
                let r2advances = runners[1]
                runners = [true, runners[0], r2advances]
                if r2advances && runners[2] { /* already counted */ }
            case .walk:
                if runners[0] && runners[1] && runners[2] {
                    runsScoredThisPA = 1
                }
                // Advance runners forced
                if runners[0] && runners[1] {
                    runners[2] = true
                }
                if runners[0] {
                    runners[1] = true
                }
                runners[0] = true
            case .strikeout, .groundOut, .flyOut, .lineOut:
                outs += 1
                if outcome == .groundOut && outs < 3 && runners[0] {
                    // Possible double play
                    if Bool.random() && paCount > 2 {
                        outs = min(3, outs + 1)
                        runners[0] = false
                    }
                }
            case .none:
                break
            }

            runsThisInning += runsScoredThisPA

            let desc = describePA(outcome: outcome, inning: inning, isTopHalf: isTopHalf, outs: outs, runs: runsScoredThisPA)

            let batter: SilhouetteState = outcome.isHit ? .running : (outcome.isOut ? .dejected : .ready)
            let pitcher: SilhouetteState = outcome.isOut ? .ready : (outcome.isHit ? .dejected : .pitching)

            let aScore = isTopHalf ? currentRuns + runsThisInning : opponentRuns
            let hScore = isTopHalf ? opponentRuns : currentRuns + runsThisInning

            frames.append(SimFrame(
                inning: inning, isTopHalf: isTopHalf,
                outs: outs, runnersOnBase: runners,
                batterSilhouette: batter, pitcherSilhouette: pitcher,
                outcome: outcome, description: desc,
                awayScoreSoFar: isTopHalf ? aScore : opponentRuns,
                homeScoreSoFar: isTopHalf ? opponentRuns : hScore
            ))
        }

        return frames
    }

    // MARK: - Outcome Picker

    private static func pickOutcome(pa: [String: Double], needRuns: Bool, outs: Int) -> PAOutcome {
        // Weight outcomes based on PA probabilities, biased slightly toward target
        let hr = pa["hr"] ?? 0.03
        let triple = pa["triple"] ?? 0.005
        let double_ = pa["double"] ?? 0.05
        let single = pa["single"] ?? 0.15
        let walk = pa["walk"] ?? 0.08
        let strikeout = pa["strikeout"] ?? 0.22

        var weights: [(PAOutcome, Double)] = [
            (.homeRun, hr * (needRuns ? 1.5 : 0.8)),
            (.triple, triple * (needRuns ? 1.3 : 0.9)),
            (.double_, double_ * (needRuns ? 1.2 : 0.9)),
            (.single, single),
            (.walk, walk),
            (.strikeout, strikeout * (needRuns ? 0.8 : 1.1)),
            (.groundOut, (1.0 - hr - triple - double_ - single - walk - strikeout) * 0.5),
            (.flyOut, (1.0 - hr - triple - double_ - single - walk - strikeout) * 0.5)
        ]

        let total = weights.reduce(0.0) { $0 + max(0, $1.1) }
        let roll = Double.random(in: 0..<total)
        var cumulative = 0.0
        for (outcome, weight) in weights {
            cumulative += max(0, weight)
            if roll < cumulative { return outcome }
        }
        return .flyOut
    }

    private static func defaultPA() -> [String: Double] {
        [
            "hr": 0.033, "triple": 0.005, "double": 0.048,
            "single": 0.152, "walk": 0.085, "strikeout": 0.225
        ]
    }

    private static func describePA(outcome: PAOutcome, inning: Int, isTopHalf: Bool, outs: Int, runs: Int) -> String {
        let half = isTopHalf ? "Top" : "Bot"
        let base: String
        switch outcome {
        case .homeRun: base = runs > 1 ? "\(runs)-run homer!" : "Solo home run!"
        case .triple: base = "Triple to the gap"
        case .double_: base = "Double off the wall"
        case .single: base = "Base hit"
        case .walk: base = "Walk"
        case .strikeout: base = "Strikeout"
        case .groundOut: base = "Grounds out"
        case .flyOut: base = "Fly out"
        case .lineOut: base = "Line out"
        case .none: base = ""
        }
        let runsStr = runs > 0 ? " (\(runs) run\(runs > 1 ? "s" : "") score)" : ""
        return "\(half) \(inning) · \(outs) out\(outs != 1 ? "s" : "") · \(base)\(runsStr)"
    }
}
