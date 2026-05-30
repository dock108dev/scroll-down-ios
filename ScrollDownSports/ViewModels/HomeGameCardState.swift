import Foundation

enum HomeGameCardPhase: Equatable {
    case scheduled
    case live
    case final
    case other

    static func phase(for game: Game) -> HomeGameCardPhase {
        if game.status.isLive { return .live }
        if game.status.isFinal { return .final }
        if game.status.isPregame { return .scheduled }
        if game.scheduledStart > Date() { return .scheduled }
        return .other
    }
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
        self.init(summary: GameSummaryCardState(
            item: item,
            presentation: SportRendererRegistry.renderer(for: item.game).gameCardPresentation(for: item.game)
        ))
    }

    init(summary: GameSummaryCardState) {
        self.phase = summary.phase
        self.statusText = summary.statusText
        self.statusBadgeText = summary.statusBadgeText
        self.primaryActionLabel = summary.primaryActionLabel
        self.contextText = summary.contextText
        self.metadataText = summary.metadataText
        self.progressText = summary.progressText
        self.newPlayText = summary.newPlayText
        self.scoreCueText = summary.scoreCueText
        self.scoreRows = summary.scoreRows
        self.showsScoreRows = summary.showsScoreRows
        self.isPinned = summary.isPinned
        self.showsPinnedBadge = summary.showsPinnedBadge
        self.usesStrongLiveTreatment = summary.usesStrongLiveTreatment
    }
}
