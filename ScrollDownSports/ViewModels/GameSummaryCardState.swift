import SwiftUI

enum GameSummaryCardSurface { case home, detail }

enum GameSummaryScoreVisibility: Equatable {
    case none, hiddenBehindCue(String), visibleRows
}

struct GameSummaryTeamLine: Identifiable {
    let id: String
    let role: GameParticipantRole
    let abbreviation: String
    let name: String
    let scoreText: String?
    let isWinner: Bool
    let isFavorite: Bool
}

struct GameSummaryCardState {
    let gameID: Int
    let phase: HomeGameCardPhase
    let leagueLabel: String
    let sportLabel: String
    let accentColor: Color
    let railColor: Color
    let surface: GameSummaryCardSurface
    let teamLines: [GameSummaryTeamLine]
    let metadataText: String
    let statusText: String
    let statusBadgeText: String?
    let primaryActionLabel: String
    let contextText: String
    let progressText: String?
    let newPlayText: String?
    let scoreCueText: String?
    let scoreRows: [HomeGameCardScoreRow]
    let scoreVisibility: GameSummaryScoreVisibility
    let isPinned: Bool
    let showsPinnedBadge: Bool
    let usesStrongLiveTreatment: Bool
    let accessibilityLabel: String
    let accessibilityHint: String?

    var showsScoreRows: Bool { scoreVisibility == .visibleRows }

    init(item: HomeGameItem, presentation: GameCardPresentation, surface: GameSummaryCardSurface = .home) {
        self.init(
            game: item.game,
            leagueLabel: presentation.leagueLabel,
            sportLabel: presentation.sportLabel,
            accentColor: presentation.accentColor,
            presentationStatusText: presentation.statusText,
            presentationHeadline: presentation.headline,
            presentationAccessibilityLabel: presentation.accessibilityLabel,
            isPinned: item.isPinned,
            pinnedSummaryPlayCount: item.pinnedRecord?.summaryPlayCountBaseline,
            progress: item.progress,
            reachedScoreboard: item.reachedScoreboard,
            newPlayCount: item.newEventCount,
            favoriteTeamIds: item.favoriteTeamIds,
            surface: surface
        )
    }

    init(
        game: Game,
        presentation: GameHeaderPresentation,
        isPinned: Bool,
        newPlayCount: Int,
        progress: GameProgressRecord?,
        reachedScoreboard: Bool? = nil,
        surface: GameSummaryCardSurface = .detail
    ) {
        self.init(
            game: game,
            leagueLabel: presentation.leagueLabel,
            sportLabel: presentation.sportLabel,
            accentColor: presentation.accentColor,
            presentationStatusText: presentation.statusText,
            presentationHeadline: presentation.headline,
            presentationAccessibilityLabel: presentation.accessibilityLabel,
            isPinned: isPinned,
            pinnedSummaryPlayCount: nil,
            progress: progress,
            reachedScoreboard: reachedScoreboard ?? progress?.reachedScoreboard ?? false,
            newPlayCount: newPlayCount,
            favoriteTeamIds: [],
            surface: surface
        )
    }

    private init(
        game: Game,
        leagueLabel: String,
        sportLabel: String,
        accentColor: Color,
        presentationStatusText: String?,
        presentationHeadline: String?,
        presentationAccessibilityLabel: String?,
        isPinned: Bool,
        pinnedSummaryPlayCount: Int?,
        progress: GameProgressRecord?,
        reachedScoreboard: Bool,
        newPlayCount: Int,
        favoriteTeamIds: Set<String>,
        surface: GameSummaryCardSurface
    ) {
        let phase = HomeGameCardPhase.phase(for: game)
        let capability = GameSummaryCapability(
            game: game,
            phase: phase,
            progress: progress,
            pinnedSummaryPlayCount: pinnedSummaryPlayCount,
            reachedScoreboard: reachedScoreboard
        )
        let scoreRows = Self.scoreRows(for: game)
        let scoreVisibility = Self.scoreVisibility(
            scoreRows: scoreRows,
            capability: capability
        )
        let statusText = Self.statusText(
            for: game,
            phase: phase,
            presentationStatusText: presentationStatusText,
            surface: surface
        )
        let primaryActionLabel = Self.primaryActionLabel(
            for: game,
            phase: phase,
            capability: capability
        )
        let progressText = Self.progressText(
            for: game,
            progress: progress,
            capability: capability
        )
        let newPlayText = Self.newPlayText(
            count: newPlayCount,
            capability: capability
        )
        let scoreCueText = Self.scoreCueText(for: phase, capability: capability)
        let contextText = Self.contextText(
            for: game,
            phase: phase,
            capability: capability,
            progressText: progressText,
            newPlayText: newPlayText
        )

        self.gameID = game.id
        self.phase = phase
        self.leagueLabel = leagueLabel
        self.sportLabel = sportLabel
        self.accentColor = accentColor
        self.railColor = SportsTheme.Team.accent(
            for: game.homeParticipant?.abbreviation ?? game.awayParticipant?.abbreviation,
            fallback: accentColor
        )
        self.surface = surface
        self.teamLines = Self.teamLines(
            for: game,
            scoreRows: scoreRows,
            showsScores: scoreVisibility == .visibleRows,
            favoriteTeamIds: favoriteTeamIds
        )
        self.metadataText = Self.metadataText(for: game, phase: phase, statusText: statusText, surface: surface)
        self.statusText = statusText
        self.statusBadgeText = Self.statusBadgeText(for: phase)
        self.primaryActionLabel = primaryActionLabel
        self.contextText = contextText
        self.progressText = progressText
        self.newPlayText = newPlayText
        self.scoreCueText = scoreCueText
        self.scoreRows = scoreRows
        self.scoreVisibility = scoreVisibility
        self.isPinned = isPinned
        self.showsPinnedBadge = isPinned
        self.usesStrongLiveTreatment = phase == .live
        self.accessibilityLabel = Self.accessibilityLabel(
            for: game,
            presentationAccessibilityLabel: presentationAccessibilityLabel,
            presentationHeadline: presentationHeadline,
            statusText: statusText,
            primaryActionLabel: primaryActionLabel
        )
        self.accessibilityHint = "Opens game details."
    }

    private static func statusText(
        for game: Game,
        phase: HomeGameCardPhase,
        presentationStatusText: String?,
        surface: GameSummaryCardSurface
    ) -> String {
        if surface == .detail,
           let label = ScoreSpoilerFilter.topRegionText(presentationStatusText, for: game) {
            return label
        }
        if let label = ScoreSpoilerFilter.topRegionText(game.presentation?.statusLabel ?? game.presentation?.primaryLabel, for: game) {
            return label
        }
        if let scoreboardStatus = ScoreSpoilerFilter.topRegionText(game.scoreboard?.statusLabel, for: game) {
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
        for game: Game,
        phase: HomeGameCardPhase,
        capability: GameSummaryCapability
    ) -> String {
        if phase == .scheduled {
            return "Preview"
        }
        if let backendLabel = game.presentation?.primaryActionLabel?.nilIfBlank,
           ScoreSpoilerFilter.topRegionText(backendLabel, for: game) != nil,
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
            if game.availableFeatures.hasScoreboard {
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
        capability: GameSummaryCapability
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
        for game: Game,
        phase: HomeGameCardPhase,
        capability: GameSummaryCapability,
        progressText: String?,
        newPlayText: String?
    ) -> String {
        if capability.canResume {
            return compactResumeText(
                progressText: progressText,
                readingTimeText: readingTimeText(minutes: capability.remainingReadingMinutes, suffix: "left"),
                newPlayText: newPlayText
            )
        }
        if let newPlayText {
            return newPlayText
        }
        if phase == .live && capability.canOpenPlayableStream {
            return "Live stream"
        }
        if phase == .final && capability.canCatchUp {
            let readTime = readingTimeText(minutes: capability.estimatedReadingMinutes, suffix: "read")
            if capability.shouldHideScoreBehindCue {
                return ["Catch up", readTime, "score at bottom"].compactMap(\.self).joined(separator: " · ")
            }
            if let readCount = capability.readEventCount, readCount > 0 {
                return [
                    "\(readCount) plays read",
                    readingTimeText(minutes: capability.remainingReadingMinutes, suffix: "left") ?? readTime
                ].compactMap(\.self).joined(separator: " · ")
            }
            return readTime ?? "Recap"
        }
        if phase == .final && game.availableFeatures.hasScoreboard {
            return "Box score"
        }
        if phase == .scheduled {
            return "Preview"
        }
        return "Details"
    }

    private static func metadataText(
        for game: Game,
        phase: HomeGameCardPhase,
        statusText: String,
        surface: GameSummaryCardSurface
    ) -> String {
        let base: String
        switch phase {
        case .scheduled:
            base = DateFormatters.timeOnly.string(from: game.scheduledStart)
        case .live:
            base = statusText == "In progress" ? "Live" : statusText
        case .final:
            base = "Final"
        case .other:
            base = DateFormatters.timeOnly.string(from: game.scheduledStart)
        }

        switch surface {
        case .home:
            return base
        case .detail:
            return "\(base) · \(DateFormatters.daySubtitle.string(from: game.scheduledStart))"
        }
    }

    private static func progressText(
        for game: Game,
        progress: GameProgressRecord?,
        capability: GameSummaryCapability
    ) -> String? {
        guard capability.canResume else { return nil }
        if let displayText = game.progress.displayText.nilIfBlank {
            return "Resume from \(displayText)"
        }
        if let readCount = progress?.readEventCount,
           readCount > 0 {
            return "\(readCount) plays read"
        }
        return "Resume"
    }

    private static func compactResumeText(
        progressText: String?,
        readingTimeText: String?,
        newPlayText: String?
    ) -> String {
        var parts = [progressText ?? "Resume"]
        if let readingTimeText {
            parts.append(readingTimeText)
        }
        if let newPlayText {
            parts.append(newPlayText.replacingOccurrences(of: " plays", with: ""))
        }
        return parts.joined(separator: " · ")
    }

    private static func readingTimeText(minutes: Int?, suffix: String) -> String? {
        guard let minutes, minutes > 0 else { return nil }
        let unit = minutes == 1 ? "min" : "mins"
        return "\(minutes) \(unit) \(suffix)"
    }

    private static func newPlayText(count: Int, capability: GameSummaryCapability) -> String? {
        guard capability.canShowNewPlayCount, count > 0 else { return nil }
        return count == 1 ? "1 new" : "\(count) new"
    }

    private static func scoreCueText(for phase: HomeGameCardPhase, capability: GameSummaryCapability) -> String? {
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

    private static func scoreVisibility(
        scoreRows: [HomeGameCardScoreRow],
        capability: GameSummaryCapability
    ) -> GameSummaryScoreVisibility {
        if capability.canShowScoreRows, !scoreRows.isEmpty {
            return .visibleRows
        }
        if capability.shouldHideScoreBehindCue {
            return .hiddenBehindCue("score at bottom")
        }
        return .none
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

    private static func teamLines(
        for game: Game,
        scoreRows: [HomeGameCardScoreRow],
        showsScores: Bool,
        favoriteTeamIds: Set<String>
    ) -> [GameSummaryTeamLine] {
        let orderedParticipants = [
            game.awayParticipant,
            game.homeParticipant
        ].compactMap { $0 }

        return orderedParticipants.map { participant in
            GameSummaryTeamLine(
                id: participant.id,
                role: participant.role,
                abbreviation: participant.abbreviation ?? shortName(for: participant.name),
                name: participant.name,
                scoreText: showsScores ? scoreRows.first { $0.id == participant.id }?.scoreText : nil,
                isWinner: showsScores && isWinner(participant.role, game: game),
                isFavorite: participant.favoriteTeamID.map { favoriteTeamIds.contains($0) } ?? false
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

    private static func accessibilityLabel(
        for game: Game,
        presentationAccessibilityLabel: String?,
        presentationHeadline: String?,
        statusText: String,
        primaryActionLabel: String
    ) -> String {
        [
            ScoreSpoilerFilter.topRegionText(presentationAccessibilityLabel, for: game),
            ScoreSpoilerFilter.topRegionText(presentationHeadline, for: game),
            ScoreSpoilerFilter.matchupText(for: game),
            statusText,
            primaryActionLabel
        ]
        .compactMap { $0?.nilIfBlank }
        .joined(separator: ". ")
    }

    private static func shortName(for name: String) -> String {
        String(name.split(separator: " ").last?.prefix(4) ?? "TEAM")
    }
}
