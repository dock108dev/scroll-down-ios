extension BaseballRenderer {
    func firstClassBaseballPrePitchState(from situation: GameEventSituationSnapshot) -> BaseballPrePitchState {
        guard situation.schemaVersion >= 1,
              ["mlb", "baseball"].contains(situation.normalizedSport),
              situation.hasTypedBaseballDiagramConfidence,
              let baseball = situation.sportState?.baseball else {
            return Self.missingFirstClassPrePitchState
        }

        let baseState = baseballBaseState(from: baseball)
        let outs = outsCount(from: baseball)
        let count = pitchCount(from: baseball)
        let period = inningState(from: baseball, period: situation.period)
        let battingTeam = battingTeam(from: baseball, inningHalf: period.inningHalf)
        let hasState = baseState != nil
            || outs != nil
            || count != nil
            || period.inning != nil
            || period.inningHalf != nil
            || battingTeam != nil

        return BaseballPrePitchState(
            baseState: baseState,
            outs: outs,
            inning: period.inning,
            inningHalf: period.inningHalf,
            count: count,
            battingTeam: battingTeam,
            sourceConfidence: hasState ? .explicitPrePitch : .missing
        )
    }

    private static var missingFirstClassPrePitchState: BaseballPrePitchState {
        BaseballPrePitchState(
            baseState: nil,
            outs: nil,
            inning: nil,
            inningHalf: nil,
            count: nil,
            battingTeam: nil,
            sourceConfidence: .missing
        )
    }

    private func baseballBaseState(from baseball: GameEventBaseballSituation) -> BaseballBaseState? {
        if let bases = baseball.bases {
            guard bases.first != nil || bases.second != nil || bases.third != nil else {
                return nil
            }
            var occupiedBases = Set<BaseballBase>()
            if bases.first == true { occupiedBases.insert(.first) }
            if bases.second == true { occupiedBases.insert(.second) }
            if bases.third == true { occupiedBases.insert(.third) }
            return BaseballBaseState(
                occupiedBases: occupiedBases,
                label: baseballBaseStateLabel(for: occupiedBases)
            )
        }

        guard let baseState = baseball.baseState?.nilIfBlank else { return nil }
        switch normalizedSituationMetadataKey(baseState) {
        case "empty", "bases_empty", "none", "no_runners", "nobody_on":
            return BaseballBaseState(occupiedBases: [], label: baseballBaseStateLabel(for: []))
        case "runner_on_first", "runner_on_1st", "first", "1b", "1st":
            return BaseballBaseState(occupiedBases: [.first], label: baseballBaseStateLabel(for: [.first]))
        case "runner_on_second", "runner_on_2nd", "second", "2b", "2nd":
            return BaseballBaseState(occupiedBases: [.second], label: baseballBaseStateLabel(for: [.second]))
        case "runner_on_third", "runner_on_3rd", "third", "3b", "3rd":
            return BaseballBaseState(occupiedBases: [.third], label: baseballBaseStateLabel(for: [.third]))
        case "runners_on_first_and_second", "first_and_second", "1st_and_2nd":
            return BaseballBaseState(occupiedBases: [.first, .second], label: baseballBaseStateLabel(for: [.first, .second]))
        case "runners_on_first_and_third", "first_and_third", "1st_and_3rd", "runners_on_corners":
            return BaseballBaseState(occupiedBases: [.first, .third], label: baseballBaseStateLabel(for: [.first, .third]))
        case "runners_on_second_and_third", "second_and_third", "2nd_and_3rd":
            return BaseballBaseState(occupiedBases: [.second, .third], label: baseballBaseStateLabel(for: [.second, .third]))
        case "bases_loaded", "loaded", "full", "loaded_bases":
            return BaseballBaseState(occupiedBases: [.first, .second, .third], label: baseballBaseStateLabel(for: [.first, .second, .third]))
        default:
            return nil
        }
    }

    private func outsCount(from baseball: GameEventBaseballSituation) -> Int? {
        guard let outs = baseball.outs, (0...2).contains(outs) else { return nil }
        return outs
    }

    private func pitchCount(from baseball: GameEventBaseballSituation) -> BaseballPitchCount? {
        guard let balls = baseball.balls, let strikes = baseball.strikes else { return nil }
        return BaseballPitchCount(balls: balls, strikes: strikes)
    }

    private func inningState(
        from baseball: GameEventBaseballSituation,
        period: GameEventSituationPeriod?
    ) -> BaseballInningState {
        BaseballInningState(
            inning: baseball.inning ?? period?.ordinal,
            inningHalf: firstClassInningHalf(from: baseball.half ?? period?.phase)
        )
    }

    private func battingTeam(
        from baseball: GameEventBaseballSituation,
        inningHalf: BaseballInningHalf?
    ) -> BaseballBattingTeam? {
        if let abbreviation = baseball.battingTeamAbbreviation?.nilIfBlank {
            return BaseballBattingTeam(abbreviation: abbreviation)
        }
        guard let inningHalf else { return nil }
        return BaseballBattingTeam(side: inningHalf == .top ? .away : .home)
    }

    private func firstClassInningHalf(from value: String?) -> BaseballInningHalf? {
        guard let value = value?.nilIfBlank else { return nil }
        switch normalizedSituationMetadataKey(value) {
        case "top", "top_half", "t", "away":
            return .top
        case "bottom", "bot", "bottom_half", "b", "home":
            return .bottom
        default:
            return nil
        }
    }
}
