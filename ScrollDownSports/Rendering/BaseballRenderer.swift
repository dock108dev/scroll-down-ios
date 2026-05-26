import Foundation

struct BaseballRenderer: GenericSportRendererBacked {
    let generic = GenericSportRenderer(leagueCode: "MLB", sportLabel: "Baseball")

    func eventPresentation(for event: GameEvent) -> GameEventPresentation {
        GameEventPresentation(event: event, detail: baseballDetail(for: event))
    }

    func scoreboardPresentation(for game: Game) -> ScoreboardPresentation {
        var presentation = generic.scoreboardPresentation(for: game)
        presentation.title = presentation.segments.isEmpty ? "Final Score" : "Line Score"
        presentation.totalHeader = "R"
        return presentation
    }

    func statsPresentation(for detail: GameDetail) -> GameStatsPresentation {
        GameStatsPresentation(
            playerSections: StatPresentationBuilder.baseballPlayerSections(for: detail),
            teamSection: generic.teamStatSection(for: detail)
        )
    }

    private func baseballDetail(for event: GameEvent) -> String? {
        let detail = event.detail?.nilIfBlank.flatMap { value in
            event.headline.range(of: value, options: [.caseInsensitive, .diacriticInsensitive]) == nil ? value : nil
        }
        let situation = baseballSituation(for: event)

        return [detail, situation]
            .compactMap { $0?.nilIfBlank }
            .joined(separator: " · ")
            .nilIfBlank
    }

    private func baseballSituation(for event: GameEvent) -> String? {
        let baseState = baseStateLabel(from: event.sportMetadata)
        let parts = [
            importanceContext(for: event, hasBaseState: baseState != nil),
            baseState,
            outsLabel(for: event),
            countLabel(from: event.sportMetadata)
        ]
        return parts
            .compactMap { $0?.nilIfBlank }
            .joined(separator: " · ")
            .nilIfBlank
    }

    private func importanceContext(for event: GameEvent, hasBaseState: Bool) -> String? {
        if event.importanceMetadata?.isLeadChange == true {
            return "Lead change"
        }
        if event.importanceMetadata?.isTyingPlay == true {
            return "Tying play"
        }

        for reason in event.importanceMetadata?.reasons ?? [] {
            switch normalizedMetadataKey(reason) {
            case "runner_aboard":
                if !hasBaseState { return "Runner aboard" }
            case "runners_in_scoring_position", "runner_in_scoring_position":
                return "Runner in scoring position"
            case "bases_loaded":
                if !hasBaseState { return "Bases loaded" }
            case "late_game":
                return "Late inning"
            default:
                continue
            }
        }
        return nil
    }

    private func baseStateLabel(from metadata: [String: JSONValue]) -> String? {
        guard let raw = metadataText(["baseState", "base_state", "baseSituation", "runners"], in: metadata) else {
            return nil
        }
        switch normalizedMetadataKey(raw) {
        case "empty", "bases_empty", "none":
            return "Bases empty"
        case "runner_on_first", "runner_on_1st", "man_on_first", "man_on_1st":
            return "Runner on 1st"
        case "runner_on_second", "runner_on_2nd", "man_on_second", "man_on_2nd":
            return "Runner on 2nd"
        case "runner_on_third", "runner_on_3rd", "man_on_third", "man_on_3rd":
            return "Runner on 3rd"
        case "runners_on_first_and_second", "runners_on_1st_and_2nd", "first_and_second", "1st_and_2nd":
            return "Runners on 1st and 2nd"
        case "runners_on_first_and_third", "runners_on_1st_and_3rd", "first_and_third", "1st_and_3rd":
            return "Runners on 1st and 3rd"
        case "runners_on_second_and_third", "runners_on_2nd_and_3rd", "second_and_third", "2nd_and_3rd":
            return "Runners on 2nd and 3rd"
        case "bases_loaded", "loaded":
            return "Bases loaded"
        default:
            return raw.replacingOccurrences(of: "_", with: " ").capitalized.nilIfBlank
        }
    }

    private func outsLabel(for event: GameEvent) -> String? {
        let metadata = event.sportMetadata
        if let outs = metadataInteger(["outs", "outCount"], in: metadata) {
            return outs == 1 ? "1 out" : "\(outs) outs"
        }
        guard let clockLabel = event.clockLabel?.lowercased(), clockLabel.contains("out"),
              let match = clockLabel.range(of: #"\d+"#, options: .regularExpression),
              let outs = Int(clockLabel[match]) else {
            return nil
        }
        return outs == 1 ? "1 out" : "\(outs) outs"
    }

    private func countLabel(from metadata: [String: JSONValue]) -> String? {
        if let count = metadataText(["count", "pitchCount"], in: metadata) {
            return count.contains("count") ? count : "\(count) count"
        }
        guard let balls = metadataInteger(["balls", "ballCount"], in: metadata),
              let strikes = metadataInteger(["strikes", "strikeCount"], in: metadata) else {
            return nil
        }
        return "\(balls)-\(strikes) count"
    }

    private func metadataText(_ keys: [String], in metadata: [String: JSONValue]) -> String? {
        for key in keys {
            if let value = metadata[key]?.displayString.nilIfBlank {
                return value
            }
        }
        return nil
    }

    private func metadataInteger(_ keys: [String], in metadata: [String: JSONValue]) -> Int? {
        for key in keys {
            if let number = metadata[key]?.numberValue {
                return Int(number)
            }
            if let text = metadata[key]?.displayString.nilIfBlank,
               let value = Int(text) {
                return value
            }
        }
        return nil
    }

    private func normalizedMetadataKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}
