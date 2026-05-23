import Foundation

enum HomeGameCardPhase: Equatable {
    case scheduled
    case live
    case final
    case other
}

struct HomeGameCardScoreRow: Identifiable, Equatable {
    let id: String
    let abbreviation: String
    let name: String
    let scoreText: String
    let isWinner: Bool
}

struct HomeGameCardState: Equatable {
    let phase: HomeGameCardPhase
    let statusText: String
    let statusBadgeText: String?
    let primaryActionLabel: String
    let contextText: String
    let metadataText: String
    let progressText: String?
    let newPlayText: String?
    let scoreCueText: String?
    let scoreRows: [HomeGameCardScoreRow]
    let showsScoreRows: Bool
    let isPinned: Bool
    let showsPinnedBadge: Bool
    let usesStrongLiveTreatment: Bool

    init(item: HomeGameItem) {
        let game = item.game
        let phase = Self.phase(for: game)
        let capability = HomeGameCardCapability(item: item, phase: phase)

        self.phase = phase
        self.statusText = Self.statusText(for: game, phase: phase)
        self.statusBadgeText = Self.statusBadgeText(for: phase)
        self.primaryActionLabel = Self.primaryActionLabel(for: item, phase: phase, capability: capability)
        self.contextText = Self.contextText(for: item, phase: phase, capability: capability)
        self.metadataText = Self.metadataText(for: game, phase: phase)
        self.progressText = Self.progressText(for: item, capability: capability)
        self.newPlayText = Self.newPlayText(for: item, capability: capability)
        self.scoreCueText = Self.scoreCueText(for: phase, capability: capability)
        self.scoreRows = Self.scoreRows(for: game)
        self.showsScoreRows = capability.canShowScoreRows
        self.isPinned = item.isPinned
        self.showsPinnedBadge = item.isPinned
        self.usesStrongLiveTreatment = phase == .live
    }

    private static func phase(for game: Game) -> HomeGameCardPhase {
        if game.status.isLive { return .live }
        if game.status.isFinal { return .final }
        if game.status.isPregame { return .scheduled }
        if game.scheduledStart > Date() { return .scheduled }
        return .other
    }

    private static func statusText(for game: Game, phase: HomeGameCardPhase) -> String {
        if let label = game.presentation?.statusLabel ?? game.presentation?.primaryLabel {
            return label
        }
        if let scoreboardStatus = game.scoreboard?.statusLabel {
            return scoreboardStatus
        }
        switch phase {
        case .live:
            return game.progress.displayText.nilIfBlank ?? "In progress"
        case .final:
            return "Final"
        case .scheduled:
            return "Scheduled"
        case .other:
            return game.progress.displayText.nilIfBlank ?? "Game update"
        }
    }

    private static func statusBadgeText(for phase: HomeGameCardPhase) -> String? {
        switch phase {
        case .live:
            return "LIVE"
        case .final:
            return "FINAL"
        case .scheduled:
            return "UPCOMING"
        case .other:
            return nil
        }
    }

    private static func primaryActionLabel(
        for item: HomeGameItem,
        phase: HomeGameCardPhase,
        capability: HomeGameCardCapability
    ) -> String {
        if phase == .scheduled {
            return "Preview"
        }
        if let backendLabel = item.game.presentation?.primaryActionLabel?.nilIfBlank,
           labelIsAllowed(backendLabel, phase: phase, capability: capability) {
            return backendLabel
        }
        if capability.canResume {
            return "Resume"
        }
        switch phase {
        case .live:
            return capability.canOpenPlayableStream ? "Open stream" : "Live details"
        case .final:
            if capability.hasOpenedRecap {
                return "Open recap"
            }
            if capability.canCatchUp {
                return "Catch up"
            }
            if item.game.availableFeatures.hasScoreboard {
                return "Open box score"
            }
            return "Game details"
        case .scheduled:
            return "Preview"
        case .other:
            return capability.canCatchUp ? "Catch up" : "Game details"
        }
    }

    private static func labelIsAllowed(
        _ label: String,
        phase: HomeGameCardPhase,
        capability: HomeGameCardCapability
    ) -> Bool {
        let normalized = label.lowercased()
        if normalized.contains("resume") {
            return capability.canResume
        }
        if normalized.contains("catch") {
            return capability.canCatchUp
        }
        if normalized.contains("stream") {
            return capability.canOpenPlayableStream
        }
        if normalized.contains("recap") {
            return phase == .final || capability.hasOpenedRecap
        }
        return true
    }

    private static func contextText(
        for item: HomeGameItem,
        phase: HomeGameCardPhase,
        capability: HomeGameCardCapability
    ) -> String {
        if capability.canResume {
            return compactResumeText(for: item, capability: capability)
        }
        if let newPlayText = newPlayText(for: item, capability: capability) {
            return newPlayText
        }
        if phase == .live && capability.canOpenPlayableStream {
            return "Live stream"
        }
        if phase == .final && capability.canCatchUp {
            if capability.shouldHideScoreBehindCue {
                return "Catch up · score at bottom"
            }
            if let readCount = item.progress?.readEventCount, readCount > 0 {
                return "\(readCount) plays read"
            }
            return "Recap"
        }
        if phase == .final && item.game.availableFeatures.hasScoreboard {
            return "Box score"
        }
        if phase == .scheduled {
            return "Preview"
        }
        return "Details"
    }

    private static func metadataText(for game: Game, phase: HomeGameCardPhase) -> String {
        switch phase {
        case .scheduled:
            return DateFormatters.timeOnly.string(from: game.scheduledStart)
        case .live:
            return "Live"
        case .final:
            return "Final"
        case .other:
            return DateFormatters.timeOnly.string(from: game.scheduledStart)
        }
    }

    private static func progressText(for item: HomeGameItem, capability: HomeGameCardCapability) -> String? {
        guard capability.canResume else { return nil }
        if let displayText = item.game.progress.displayText.nilIfBlank {
            return "Resume from \(displayText)"
        }
        if let readCount = item.progress?.readEventCount,
           readCount > 0 {
            return "\(readCount) plays read"
        }
        return "Resume"
    }

    private static func compactResumeText(for item: HomeGameItem, capability: HomeGameCardCapability) -> String {
        var parts = [progressText(for: item, capability: capability) ?? "Resume"]
        if let newPlayText = newPlayText(for: item, capability: capability) {
            parts.append(newPlayText.replacingOccurrences(of: " plays", with: ""))
        }
        return parts.joined(separator: " · ")
    }

    private static func newPlayText(for item: HomeGameItem, capability: HomeGameCardCapability) -> String? {
        guard capability.canShowNewPlayCount, item.newEventCount > 0 else { return nil }
        return item.newEventCount == 1 ? "1 new" : "\(item.newEventCount) new"
    }

    private static func scoreCueText(for phase: HomeGameCardPhase, capability: HomeGameCardCapability) -> String? {
        guard capability.shouldHideScoreBehindCue else { return nil }
        switch phase {
        case .final:
            return "score at bottom"
        case .live, .other:
            return capability.canCatchUp ? "score at bottom" : nil
        case .scheduled:
            return nil
        }
    }

    private static func scoreRows(for game: Game) -> [HomeGameCardScoreRow] {
        game.participants.compactMap { participant in
            let score = game.scoreState.score(for: participant.role)
            let scoreText = score.map(String.init) ?? scoreTextFromScoreboard(for: participant.role, game: game)
            guard let scoreText else { return nil }
            return HomeGameCardScoreRow(
                id: participant.id,
                abbreviation: participant.abbreviation ?? shortName(for: participant.name),
                name: participant.name,
                scoreText: scoreText,
                isWinner: isWinner(participant.role, game: game)
            )
        }
    }

    private static func scoreTextFromScoreboard(for role: GameParticipantRole, game: Game) -> String? {
        game.scoreboard?.competitors.first { $0.side == role }?.scoreText
    }

    private static func isWinner(_ role: GameParticipantRole, game: Game) -> Bool {
        if let winner = game.scoreboard?.competitors.first(where: { $0.side == role })?.isWinner {
            return winner
        }
        guard game.status.isFinal,
              let home = game.scoreState.home,
              let away = game.scoreState.away,
              home != away else {
            return false
        }
        return (role == .home && home > away) || (role == .away && away > home)
    }

    private static func shortName(for name: String) -> String {
        String(name.split(separator: " ").last?.prefix(4) ?? "TEAM")
    }
}

private struct HomeGameCardCapability {
    let canOpenPlayableStream: Bool
    let canCatchUp: Bool
    let canResume: Bool
    let canShowNewPlayCount: Bool
    let canShowScoreRows: Bool
    let shouldHideScoreBehindCue: Bool
    let hasOpenedRecap: Bool

    init(item: HomeGameItem, phase: HomeGameCardPhase) {
        let game = item.game
        let knownEventCount = max(
            game.progress.eventCount ?? 0,
            item.progress?.lastKnownEventCount ?? 0,
            item.pinnedRecord?.summaryPlayCountBaseline ?? 0
        )
        let hasLocalProgress: Bool
        if let progress = item.progress {
            hasLocalProgress = progress.lastViewedAt != nil
                || progress.lastReadEventIndex != nil
                || progress.lastReadEventID != nil
                || progress.reachedScoreboard
                || progress.selectedMode != .timeline
        } else {
            hasLocalProgress = false
        }
        let hasPriorPlayableContent = hasLocalProgress && knownEventCount > 0
        let hasTimelineContent = game.availableFeatures.hasTimeline || knownEventCount > 0
        let isPregameWithoutPriorContent = phase == .scheduled && !hasPriorPlayableContent
        let canCatchUp = !isPregameWithoutPriorContent && hasTimelineContent
        let hasOpenedRecap = phase == .final && item.reachedScoreboard

        self.canOpenPlayableStream = phase == .live && canCatchUp
        self.canCatchUp = phase != .scheduled && canCatchUp
        self.canResume = hasLocalProgress && canCatchUp && !hasOpenedRecap
        self.canShowNewPlayCount = phase != .scheduled || hasPriorPlayableContent
        self.hasOpenedRecap = hasOpenedRecap
        self.shouldHideScoreBehindCue = game.scoreState.hasAnyScore && !item.reachedScoreboard && (phase == .final || canCatchUp)
        self.canShowScoreRows = game.scoreState.hasAnyScore && !shouldHideScoreBehindCue
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
